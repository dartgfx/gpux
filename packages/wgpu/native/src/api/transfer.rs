// Queue operations, buffer read/write, buffer mapping, and fence tracking.

use std::sync::atomic::{AtomicI32, Ordering};
use std::sync::Arc;

use crate::handle::*;
use super::types::*;

// =============================================================================
// QUEUE WRITE OPERATIONS
// =============================================================================

/// Compute rows_per_image for write_texture. For block-compressed formats (BC1-BC7),
/// this is the number of block rows; for uncompressed formats, the pixel height.
fn rows_per_image(format: wgpu::TextureFormat, height: u32) -> u32 {
    let (_, bh) = format.block_dimensions();
    if bh > 1 {
        (height + bh - 1) / bh
    } else {
        height
    }
}

pub fn queue_write_buffer(
    queue: &wgpu::Queue,
    buffer_handle: WGPUBuffer,
    offset: u64,
    data: &[u8],
) {
    if buffer_handle == 0 { return; }
    let buf = unsafe { deref_handle::<wgpu::Buffer>(buffer_handle) };
    queue.write_buffer(buf, offset, data);
}

#[allow(clippy::too_many_arguments)]
pub fn queue_write_texture(
    queue: &wgpu::Queue,
    texture_handle: WGPUTexture,
    data: &[u8],
    bytes_per_row: u32,
    width: u32,
    height: u32,
    depth_or_array_layers: u32,
    mip_level: u32,
    origin_x: u32,
    origin_y: u32,
    origin_z: u32,
    aspect: u32,
    explicit_rows_per_image: u32,
) {
    if texture_handle == 0 { return; }
    let tex = unsafe { deref_handle::<wgpu::Texture>(texture_handle) };
    let rows = if explicit_rows_per_image > 0 {
        explicit_rows_per_image
    } else {
        rows_per_image(tex.format(), height)
    };
    queue.write_texture(
        wgpu::TexelCopyTextureInfo {
            texture: tex,
            mip_level,
            origin: wgpu::Origin3d { x: origin_x, y: origin_y, z: origin_z },
            aspect: super::enums::texture_aspect_from_u32(aspect),
        },
        data,
        wgpu::TexelCopyBufferLayout {
            offset: 0,
            bytes_per_row: Some(bytes_per_row),
            rows_per_image: Some(rows),
        },
        wgpu::Extent3d { width, height, depth_or_array_layers },
    );
}

// =============================================================================
// QUEUE SUBMIT
// =============================================================================

pub fn queue_submit(
    queue: &wgpu::Queue,
    command_buffer_handles: &[WGPUCommandBuffer],
) {
    let buffers: Vec<wgpu::CommandBuffer> = command_buffer_handles
        .iter()
        .filter_map(|&handle| {
            if handle == 0 { return None; }
            Some(unsafe { drop_handle::<wgpu::CommandBuffer>(handle) })
        })
        .collect();

    queue.submit(buffers);
}

// =============================================================================
// BUFFER READ (SYNCHRONOUS)
// =============================================================================

pub fn buffer_read_sync(
    device: &wgpu::Device,
    queue: &wgpu::Queue,
    buffer_handle: WGPUBuffer,
    offset: u64,
    size: u64,
    output: &mut [u8],
) -> u64 {
    if buffer_handle == 0 { return 0; }
    let src_buffer = unsafe { deref_handle::<wgpu::Buffer>(buffer_handle) };

    let staging = device.create_buffer(&wgpu::BufferDescriptor {
        label: Some("readback_staging"),
        size,
        usage: wgpu::BufferUsages::COPY_DST | wgpu::BufferUsages::MAP_READ,
        mapped_at_creation: false,
    });

    let mut encoder = device.create_command_encoder(&wgpu::CommandEncoderDescriptor {
        label: Some("readback_encoder"),
    });
    encoder.copy_buffer_to_buffer(src_buffer, offset, &staging, 0, size);
    queue.submit(std::iter::once(encoder.finish()));

    let slice = staging.slice(..);
    let (tx, rx) = std::sync::mpsc::channel();
    slice.map_async(wgpu::MapMode::Read, move |result| {
        let _ = tx.send(result);
    });
    let _ = device.poll(wgpu::PollType::wait_indefinitely());

    match rx.recv() {
        Ok(Ok(())) => {}
        _ => return 0,
    }

    let mapped = slice.get_mapped_range();
    let bytes_to_copy = mapped.len().min(output.len());
    output[..bytes_to_copy].copy_from_slice(&mapped[..bytes_to_copy]);

    drop(mapped);
    staging.unmap();

    bytes_to_copy as u64
}

pub fn queue_get_timestamp_period(queue: &wgpu::Queue) -> f32 {
    queue.get_timestamp_period()
}

// =============================================================================
// ASYNC BUFFER MAPPING
// =============================================================================

pub fn buffer_map_start(
    device: &wgpu::Device,
    queue: &wgpu::Queue,
    buffer_handle: WGPUBuffer,
    offset: u64,
    size: u64,
    mode: u32,
) -> WGPUBufferMapping {
    let map_mode = if mode == 0 {
        BufferMapMode::Read
    } else {
        BufferMapMode::Write
    };

    if buffer_handle == 0 { return 0; }
    let src_buffer = unsafe { deref_handle::<wgpu::Buffer>(buffer_handle) };
    let actual_size = if size == 0 { src_buffer.size() - offset } else { size };

    let mapped_buffer = if map_mode == BufferMapMode::Read {
        let usage = src_buffer.usage();
        if usage.contains(wgpu::BufferUsages::MAP_READ) {
            // Buffer already supports MAP_READ — map directly, no staging needed.
            MappedBuffer::Original(buffer_handle)
        } else {
            // Buffer lacks MAP_READ — stage through a temporary copy.
            let staging = device.create_buffer(&wgpu::BufferDescriptor {
                label: Some("async_map_staging"),
                size: actual_size,
                usage: wgpu::BufferUsages::COPY_DST | wgpu::BufferUsages::MAP_READ,
                mapped_at_creation: false,
            });

            let mut encoder = device.create_command_encoder(&wgpu::CommandEncoderDescriptor {
                label: Some("async_map_copy"),
            });
            encoder.copy_buffer_to_buffer(src_buffer, offset, &staging, 0, actual_size);
            queue.submit(std::iter::once(encoder.finish()));

            MappedBuffer::Staging(staging)
        }
    } else {
        MappedBuffer::Original(buffer_handle)
    };

    let buffer_to_map: &wgpu::Buffer = match &mapped_buffer {
        MappedBuffer::Staging(ref staging) => staging,
        MappedBuffer::Original(handle) => unsafe { deref_handle::<wgpu::Buffer>(*handle) },
    };

    let status = Arc::new(AtomicI32::new(MAP_STATUS_PENDING));
    let status_clone = status.clone();

    let slice = buffer_to_map.slice(..);
    let wgpu_mode = if map_mode == BufferMapMode::Read {
        wgpu::MapMode::Read
    } else {
        wgpu::MapMode::Write
    };

    slice.map_async(wgpu_mode, move |result| {
        let new_status = match result {
            Ok(()) => MAP_STATUS_READY,
            Err(_) => MAP_STATUS_ERROR,
        };
        status_clone.store(new_status, Ordering::Release);
    });

    into_handle(PendingMapping {
        buffer: mapped_buffer,
        mode: map_mode,
        size: actual_size,
        status,
    })
}

pub fn buffer_map_status(handle: WGPUBufferMapping) -> i32 {
    if handle == 0 { return MAP_STATUS_ERROR; }
    let mapping = unsafe { deref_handle::<PendingMapping>(handle) };
    mapping.status.load(Ordering::Acquire)
}

pub fn buffer_map_get_pointer(handle: WGPUBufferMapping) -> *const u8 {
    if handle == 0 { return std::ptr::null(); }
    let mapping = unsafe { deref_handle::<PendingMapping>(handle) };

    if mapping.status.load(Ordering::Acquire) != MAP_STATUS_READY {
        return std::ptr::null();
    }

    let buf: &wgpu::Buffer = match &mapping.buffer {
        MappedBuffer::Staging(ref staging) => staging,
        MappedBuffer::Original(buf_handle) => unsafe { deref_handle::<wgpu::Buffer>(*buf_handle) },
    };
    let slice = buf.slice(..);
    let view = slice.get_mapped_range();
    view.as_ptr()
}

pub fn buffer_map_get_pointer_mut(handle: WGPUBufferMapping) -> *mut u8 {
    if handle == 0 { return std::ptr::null_mut(); }
    let mapping = unsafe { deref_handle_mut::<PendingMapping>(handle) };

    if mapping.status.load(Ordering::Acquire) != MAP_STATUS_READY {
        return std::ptr::null_mut();
    }

    if mapping.mode != BufferMapMode::Write {
        return std::ptr::null_mut();
    }

    let buf: &wgpu::Buffer = match &mapping.buffer {
        MappedBuffer::Original(buf_handle) => unsafe { deref_handle::<wgpu::Buffer>(*buf_handle) },
        _ => return std::ptr::null_mut(),
    };
    let slice = buf.slice(..);
    let mut view = slice.get_mapped_range_mut();
    view.slice(..).as_raw_element_ptr().as_ptr()
}

pub fn buffer_map_get_size(handle: WGPUBufferMapping) -> u64 {
    if handle == 0 { return 0; }
    let mapping = unsafe { deref_handle::<PendingMapping>(handle) };
    mapping.size
}

pub fn buffer_unmap(handle: WGPUBufferMapping) {
    if handle == 0 { return; }
    let mapping = unsafe { drop_handle::<PendingMapping>(handle) };

    match mapping.buffer {
        MappedBuffer::Staging(staging) => {
            staging.unmap();
        }
        MappedBuffer::Original(buf_handle) => {
            let buf = unsafe { deref_handle::<wgpu::Buffer>(buf_handle) };
            buf.unmap();
        }
    }
}

// =============================================================================
// FENCES (GPU WORK COMPLETION TRACKING)
// =============================================================================

pub fn queue_submit_fenced(
    queue: &wgpu::Queue,
    command_buffer_handles: &[WGPUCommandBuffer],
) -> WGPUFence {
    let buffers: Vec<wgpu::CommandBuffer> = command_buffer_handles
        .iter()
        .filter_map(|&handle| {
            if handle == 0 { return None; }
            Some(unsafe { drop_handle::<wgpu::CommandBuffer>(handle) })
        })
        .collect();

    if buffers.is_empty() && !command_buffer_handles.is_empty() {
        return 0;
    }

    let submission_index = queue.submit(buffers);

    into_handle(PendingFence { submission_index })
}

pub fn fence_status(
    device: &wgpu::Device,
    handle: WGPUFence,
) -> i32 {
    if handle == 0 { return 1; }
    let fence = unsafe { deref_handle::<PendingFence>(handle) };
    let result = device.poll(wgpu::PollType::Wait {
        submission_index: Some(fence.submission_index.clone()),
        timeout: Some(std::time::Duration::ZERO),
    });
    match result {
        Ok(_) => 1,
        Err(wgpu::PollError::Timeout) => 0,
        Err(_) => 1,
    }
}

pub fn fence_wait(device: &wgpu::Device, handle: WGPUFence) -> u32 {
    if handle == 0 { return 0; }
    let fence = unsafe { deref_handle::<PendingFence>(handle) };

    let mut iterations = 0u32;
    loop {
        iterations += 1;
        let result = device.poll(wgpu::PollType::Wait {
            submission_index: Some(fence.submission_index.clone()),
            timeout: Some(std::time::Duration::from_micros(100)),
        });
        match result {
            Ok(_) => break,
            Err(wgpu::PollError::Timeout) => continue,
            Err(_) => break,
        }
    }
    iterations
}

pub fn fence_release(handle: WGPUFence) {
    if handle == 0 { return; }
    unsafe { drop_handle::<PendingFence>(handle) };
}
