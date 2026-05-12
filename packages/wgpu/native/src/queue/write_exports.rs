use std::sync::Arc;

use crate::abi::types::*;
use crate::ffi_catch;
use crate::queue::ops;
use crate::runtime::handle::*;

#[export_name = "wgpun_QueueWriteBuffer"]
pub extern "C" fn wgpuQueueWriteBuffer(
    queue: WGPUQueue,
    buffer: WGPUBuffer,
    offset: u64,
    data: *const u8,
    size: u64,
) {
    if queue == 0 || buffer == 0 || data.is_null() || size == 0 {
        return;
    }
    ffi_catch!((), {
        let queue_arc = unsafe { deref_handle::<Arc<wgpu::Queue>>(queue) };
        let data = unsafe { std::slice::from_raw_parts(data, size as usize) };
        ops::queue_write_buffer(queue_arc, buffer, offset, data);
    })
}

#[export_name = "wgpun_QueueWriteTexture"]
pub extern "C" fn wgpuQueueWriteTexture(
    queue: WGPUQueue,
    texture: WGPUTexture,
    data: *const u8,
    data_size: u64,
    bytes_per_row: u32,
    width: u32,
    height: u32,
    depth_or_array_layers: u32,
    mip_level: u32,
    origin_x: u32,
    origin_y: u32,
    origin_z: u32,
    aspect: u32,
    rows_per_image: u32,
) {
    if queue == 0 || texture == 0 || data.is_null() || data_size == 0 {
        return;
    }
    ffi_catch!((), {
        let queue_arc = unsafe { deref_handle::<Arc<wgpu::Queue>>(queue) };
        let data = unsafe { std::slice::from_raw_parts(data, data_size as usize) };
        ops::queue_write_texture(
            queue_arc,
            texture,
            data,
            bytes_per_row,
            width,
            height,
            depth_or_array_layers,
            mip_level,
            origin_x,
            origin_y,
            origin_z,
            aspect,
            rows_per_image,
        );
    })
}
