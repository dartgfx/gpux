use std::sync::atomic::{AtomicI32, Ordering};
use std::sync::Arc;

use crate::abi::types::*;
use crate::buffer::mapping::state::*;
use crate::runtime::handle::*;

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

    if buffer_handle == 0 {
        return 0;
    }
    let src_buffer = unsafe { deref_handle::<wgpu::Buffer>(buffer_handle) };
    let actual_size = if size == 0 {
        src_buffer.size() - offset
    } else {
        size
    };

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
    if handle == 0 {
        return MAP_STATUS_ERROR;
    }
    let mapping = unsafe { deref_handle::<PendingMapping>(handle) };
    mapping.status.load(Ordering::Acquire)
}

pub fn buffer_map_get_pointer(handle: WGPUBufferMapping) -> *const u8 {
    if handle == 0 {
        return std::ptr::null();
    }
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
    if handle == 0 {
        return std::ptr::null_mut();
    }
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
    if handle == 0 {
        return 0;
    }
    let mapping = unsafe { deref_handle::<PendingMapping>(handle) };
    mapping.size
}

pub fn buffer_unmap(handle: WGPUBufferMapping) {
    if handle == 0 {
        return;
    }
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
