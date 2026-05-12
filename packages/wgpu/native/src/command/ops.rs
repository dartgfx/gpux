use crate::abi::types::*;
use crate::runtime::handle::*;

pub fn device_create_command_encoder(
    device: &wgpu::Device,
    label: Option<&str>,
) -> WGPUCommandEncoder {
    let encoder = device.create_command_encoder(&wgpu::CommandEncoderDescriptor { label });

    into_handle(encoder)
}

pub fn command_encoder_finish(encoder_handle: WGPUCommandEncoder) -> WGPUCommandBuffer {
    let encoder = unsafe { drop_handle::<wgpu::CommandEncoder>(encoder_handle) };
    let command_buffer = encoder.finish();
    into_handle(command_buffer)
}

pub fn command_encoder_copy_buffer_to_buffer(
    encoder_handle: WGPUCommandEncoder,
    source: WGPUBuffer,
    source_offset: u64,
    destination: WGPUBuffer,
    destination_offset: u64,
    size: u64,
) {
    let encoder = unsafe { deref_handle_mut::<wgpu::CommandEncoder>(encoder_handle) };
    let src_buffer = unsafe { deref_handle::<wgpu::Buffer>(source) };
    let dst_buffer = unsafe { deref_handle::<wgpu::Buffer>(destination) };

    encoder.copy_buffer_to_buffer(
        src_buffer,
        source_offset,
        dst_buffer,
        destination_offset,
        size,
    );
}

pub fn command_encoder_clear_buffer(
    encoder_handle: WGPUCommandEncoder,
    buffer: WGPUBuffer,
    offset: u64,
    size: Option<u64>,
) {
    let encoder = unsafe { deref_handle_mut::<wgpu::CommandEncoder>(encoder_handle) };
    let dst_buffer = unsafe { deref_handle::<wgpu::Buffer>(buffer) };

    encoder.clear_buffer(dst_buffer, offset, size);
}

#[allow(clippy::too_many_arguments)]
pub fn command_encoder_copy_texture_to_buffer(
    encoder_handle: WGPUCommandEncoder,
    texture_handle: WGPUTexture,
    buffer_handle: WGPUBuffer,
    bytes_per_row: u32,
    rows_per_image: u32,
    width: u32,
    height: u32,
    depth: u32,
    mip_level: u32,
    origin_x: u32,
    origin_y: u32,
    origin_z: u32,
) {
    let encoder = unsafe { deref_handle_mut::<wgpu::CommandEncoder>(encoder_handle) };
    let texture = unsafe { deref_handle::<wgpu::Texture>(texture_handle) };
    let buffer = unsafe { deref_handle::<wgpu::Buffer>(buffer_handle) };

    encoder.copy_texture_to_buffer(
        wgpu::TexelCopyTextureInfo {
            texture,
            mip_level,
            origin: wgpu::Origin3d {
                x: origin_x,
                y: origin_y,
                z: origin_z,
            },
            aspect: wgpu::TextureAspect::All,
        },
        wgpu::TexelCopyBufferInfo {
            buffer,
            layout: wgpu::TexelCopyBufferLayout {
                offset: 0,
                bytes_per_row: Some(bytes_per_row),
                rows_per_image: if rows_per_image == 0 {
                    None
                } else {
                    Some(rows_per_image)
                },
            },
        },
        wgpu::Extent3d {
            width,
            height,
            depth_or_array_layers: depth,
        },
    );
}

#[allow(clippy::too_many_arguments)]
pub fn command_encoder_copy_buffer_to_texture(
    encoder_handle: WGPUCommandEncoder,
    buffer_handle: WGPUBuffer,
    texture_handle: WGPUTexture,
    bytes_per_row: u32,
    rows_per_image: u32,
    width: u32,
    height: u32,
    depth: u32,
    mip_level: u32,
    origin_x: u32,
    origin_y: u32,
    origin_z: u32,
) {
    let encoder = unsafe { deref_handle_mut::<wgpu::CommandEncoder>(encoder_handle) };
    let buffer = unsafe { deref_handle::<wgpu::Buffer>(buffer_handle) };
    let texture = unsafe { deref_handle::<wgpu::Texture>(texture_handle) };

    encoder.copy_buffer_to_texture(
        wgpu::TexelCopyBufferInfo {
            buffer,
            layout: wgpu::TexelCopyBufferLayout {
                offset: 0,
                bytes_per_row: Some(bytes_per_row),
                rows_per_image: if rows_per_image == 0 {
                    None
                } else {
                    Some(rows_per_image)
                },
            },
        },
        wgpu::TexelCopyTextureInfo {
            texture,
            mip_level,
            origin: wgpu::Origin3d {
                x: origin_x,
                y: origin_y,
                z: origin_z,
            },
            aspect: wgpu::TextureAspect::All,
        },
        wgpu::Extent3d {
            width,
            height,
            depth_or_array_layers: depth,
        },
    );
}

#[allow(clippy::too_many_arguments)]
pub fn command_encoder_copy_texture_to_texture(
    encoder_handle: WGPUCommandEncoder,
    src_texture_handle: WGPUTexture,
    dst_texture_handle: WGPUTexture,
    width: u32,
    height: u32,
    depth: u32,
    src_mip_level: u32,
    src_origin_x: u32,
    src_origin_y: u32,
    src_origin_z: u32,
    dst_mip_level: u32,
    dst_origin_x: u32,
    dst_origin_y: u32,
    dst_origin_z: u32,
) {
    let encoder = unsafe { deref_handle_mut::<wgpu::CommandEncoder>(encoder_handle) };
    let src_texture = unsafe { deref_handle::<wgpu::Texture>(src_texture_handle) };
    let dst_texture = unsafe { deref_handle::<wgpu::Texture>(dst_texture_handle) };

    encoder.copy_texture_to_texture(
        wgpu::TexelCopyTextureInfo {
            texture: src_texture,
            mip_level: src_mip_level,
            origin: wgpu::Origin3d {
                x: src_origin_x,
                y: src_origin_y,
                z: src_origin_z,
            },
            aspect: wgpu::TextureAspect::All,
        },
        wgpu::TexelCopyTextureInfo {
            texture: dst_texture,
            mip_level: dst_mip_level,
            origin: wgpu::Origin3d {
                x: dst_origin_x,
                y: dst_origin_y,
                z: dst_origin_z,
            },
            aspect: wgpu::TextureAspect::All,
        },
        wgpu::Extent3d {
            width,
            height,
            depth_or_array_layers: depth,
        },
    );
}

pub fn command_encoder_insert_debug_marker(
    encoder_handle: WGPUCommandEncoder,
    label: *const std::ffi::c_char,
) {
    let encoder = unsafe { deref_handle_mut::<wgpu::CommandEncoder>(encoder_handle) };

    let label_str = if label.is_null() {
        ""
    } else {
        unsafe { std::ffi::CStr::from_ptr(label).to_str().unwrap_or("") }
    };

    encoder.insert_debug_marker(label_str);
}

pub fn command_encoder_push_debug_group(
    encoder_handle: WGPUCommandEncoder,
    label: *const std::ffi::c_char,
) {
    let encoder = unsafe { deref_handle_mut::<wgpu::CommandEncoder>(encoder_handle) };

    let label_str = if label.is_null() {
        ""
    } else {
        unsafe { std::ffi::CStr::from_ptr(label).to_str().unwrap_or("") }
    };

    encoder.push_debug_group(label_str);
}

pub fn command_encoder_pop_debug_group(encoder_handle: WGPUCommandEncoder) {
    let encoder = unsafe { deref_handle_mut::<wgpu::CommandEncoder>(encoder_handle) };

    encoder.pop_debug_group();
}
