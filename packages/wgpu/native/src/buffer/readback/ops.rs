use crate::abi::types::*;
use crate::runtime::handle::*;

pub fn buffer_read_sync(
    device: &wgpu::Device,
    queue: &wgpu::Queue,
    buffer_handle: WGPUBuffer,
    offset: u64,
    size: u64,
    output: &mut [u8],
) -> u64 {
    if buffer_handle == 0 {
        return 0;
    }
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
