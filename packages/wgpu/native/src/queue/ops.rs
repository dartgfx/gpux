use crate::abi::enums::texture_aspect_from_u32;
use crate::abi::types::*;
use crate::runtime::handle::*;

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
    if buffer_handle == 0 {
        return;
    }
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
    if texture_handle == 0 {
        return;
    }
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
            origin: wgpu::Origin3d {
                x: origin_x,
                y: origin_y,
                z: origin_z,
            },
            aspect: texture_aspect_from_u32(aspect),
        },
        data,
        wgpu::TexelCopyBufferLayout {
            offset: 0,
            bytes_per_row: Some(bytes_per_row),
            rows_per_image: Some(rows),
        },
        wgpu::Extent3d {
            width,
            height,
            depth_or_array_layers,
        },
    );
}

pub fn queue_submit(queue: &wgpu::Queue, command_buffer_handles: &[WGPUCommandBuffer]) {
    let buffers: Vec<wgpu::CommandBuffer> = command_buffer_handles
        .iter()
        .filter_map(|&handle| {
            if handle == 0 {
                return None;
            }
            Some(unsafe { drop_handle::<wgpu::CommandBuffer>(handle) })
        })
        .collect();

    queue.submit(buffers);
}

pub fn queue_get_timestamp_period(queue: &wgpu::Queue) -> f32 {
    queue.get_timestamp_period()
}
