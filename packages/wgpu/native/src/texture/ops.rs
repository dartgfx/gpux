use crate::abi::enums::*;
use crate::abi::types::*;
use crate::runtime::handle::*;
use crate::runtime::label::label_from_ptr;

pub fn device_create_texture(device: &wgpu::Device, desc: &WGPUTextureDescriptor) -> WGPUTexture {
    let view_formats: Vec<wgpu::TextureFormat> =
        if desc.view_format_count > 0 && !desc.view_formats.is_null() {
            let slice = unsafe {
                std::slice::from_raw_parts(desc.view_formats, desc.view_format_count as usize)
            };
            slice.iter().map(|&f| texture_format_from_u32(f)).collect()
        } else {
            Vec::new()
        };

    let texture = device.create_texture(&wgpu::TextureDescriptor {
        label: unsafe { label_from_ptr(desc.label) },
        size: wgpu::Extent3d {
            width: desc.width,
            height: desc.height,
            depth_or_array_layers: desc.depth_or_array_layers,
        },
        mip_level_count: desc.mip_level_count,
        sample_count: desc.sample_count,
        dimension: texture_dimension_from_u32(desc.dimension),
        format: texture_format_from_u32(desc.format),
        usage: wgpu::TextureUsages::from_bits_truncate(desc.usage),
        view_formats: &view_formats,
    });
    into_handle(texture)
}

pub fn texture_create_view(
    texture_handle: WGPUTexture,
    desc: Option<&WGPUTextureViewDescriptor>,
) -> WGPUTextureView {
    if texture_handle == 0 {
        return 0;
    }
    let tex = unsafe { deref_handle::<wgpu::Texture>(texture_handle) };

    let view = match desc {
        Some(d) => tex.create_view(&wgpu::TextureViewDescriptor {
            label: unsafe { label_from_ptr(d.label) },
            format: Some(texture_format_from_u32(d.format)),
            dimension: Some(texture_view_dimension_from_u32(d.dimension)),
            usage: if d.usage == 0 {
                None
            } else {
                Some(wgpu::TextureUsages::from_bits_truncate(d.usage))
            },
            aspect: texture_aspect_from_u32(d.aspect),
            base_mip_level: d.base_mip_level,
            mip_level_count: if d.mip_level_count == 0 {
                None
            } else {
                Some(d.mip_level_count)
            },
            base_array_layer: d.base_array_layer,
            array_layer_count: if d.array_layer_count == 0 {
                None
            } else {
                Some(d.array_layer_count)
            },
        }),
        None => tex.create_view(&wgpu::TextureViewDescriptor::default()),
    };
    into_handle(view)
}

pub fn texture_release(texture: WGPUTexture) {
    if texture == 0 {
        return;
    }
    unsafe {
        drop_handle::<wgpu::Texture>(texture);
    }
}

pub fn texture_view_release(view: WGPUTextureView) {
    if view == 0 {
        return;
    }
    unsafe {
        drop_handle::<wgpu::TextureView>(view);
    }
}
