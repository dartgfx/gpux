use crate::abi::types::*;
use crate::runtime::handle::*;
use crate::runtime::label::label_from_ptr;

pub fn device_create_buffer(device: &wgpu::Device, desc: &WGPUBufferDescriptor) -> WGPUBuffer {
    let buffer = device.create_buffer(&wgpu::BufferDescriptor {
        label: unsafe { label_from_ptr(desc.label) },
        size: desc.size,
        usage: wgpu::BufferUsages::from_bits_truncate(desc.usage),
        mapped_at_creation: desc.mapped_at_creation != 0,
    });
    into_handle(buffer)
}

pub fn buffer_release(buffer: WGPUBuffer) {
    if buffer == 0 {
        return;
    }
    unsafe {
        drop_handle::<wgpu::Buffer>(buffer);
    }
}
