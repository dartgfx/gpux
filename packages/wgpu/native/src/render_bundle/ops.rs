use crate::abi::enums::*;
use crate::abi::types::*;
use crate::runtime::handle::*;
use crate::runtime::label::label_from_ptr;
use crate::runtime::state::*;

pub fn device_create_render_bundle_encoder(
    device: &wgpu::Device,
    desc: &WGPURenderBundleEncoderDescriptor,
) -> WGPURenderBundleEncoder {
    let color_formats: Vec<Option<wgpu::TextureFormat>> =
        if desc.color_format_count > 0 && !desc.color_formats.is_null() {
            let formats = unsafe {
                std::slice::from_raw_parts(desc.color_formats, desc.color_format_count as usize)
            };
            formats
                .iter()
                .map(|&f| {
                    if f == 0xFFFFFFFF {
                        None
                    } else {
                        Some(texture_format_from_u32(f))
                    }
                })
                .collect()
        } else {
            vec![]
        };

    let depth_stencil = if desc.depth_stencil_format != 0 {
        Some(wgpu::RenderBundleDepthStencil {
            format: texture_format_from_u32(desc.depth_stencil_format),
            depth_read_only: desc.depth_read_only != 0,
            stencil_read_only: desc.stencil_read_only != 0,
        })
    } else {
        None
    };

    let encoder = device.create_render_bundle_encoder(&wgpu::RenderBundleEncoderDescriptor {
        label: unsafe { label_from_ptr(desc.label) },
        color_formats: &color_formats,
        depth_stencil,
        sample_count: desc.sample_count,
        multiview: None,
    });

    into_handle(encoder)
}

pub fn render_bundle_encoder_set_pipeline(
    encoder_handle: WGPURenderBundleEncoder,
    pipeline_handle: WGPURenderPipeline,
) {
    let encoder = unsafe { deref_handle_mut::<wgpu::RenderBundleEncoder>(encoder_handle) };
    let pipeline = unsafe { deref_handle::<wgpu::RenderPipeline>(pipeline_handle) };
    encoder.set_pipeline(pipeline);
}

pub fn render_bundle_encoder_set_bind_group(
    encoder_handle: WGPURenderBundleEncoder,
    index: u32,
    bind_group_id: WGPUBindGroup,
    dynamic_offsets: &[u32],
) {
    let encoder = unsafe { deref_handle_mut::<wgpu::RenderBundleEncoder>(encoder_handle) };

    if bind_group_id == 0 {
        encoder.set_bind_group(index, None, dynamic_offsets);
        return;
    }

    let bind_group = unsafe { deref_handle::<wgpu::BindGroup>(bind_group_id) };
    encoder.set_bind_group(index, Some(bind_group), dynamic_offsets);
}

pub fn render_bundle_encoder_set_vertex_buffer(
    encoder_handle: WGPURenderBundleEncoder,
    slot: u32,
    buffer_handle: WGPUBuffer,
    offset: u64,
    size: u64,
) {
    let encoder = unsafe { deref_handle_mut::<wgpu::RenderBundleEncoder>(encoder_handle) };
    let buffer = unsafe { deref_handle::<wgpu::Buffer>(buffer_handle) };

    let slice = if size == 0 {
        buffer.slice(offset..)
    } else {
        buffer.slice(offset..offset + size)
    };
    encoder.set_vertex_buffer(slot, slice);
}

pub fn render_bundle_encoder_set_index_buffer(
    encoder_handle: WGPURenderBundleEncoder,
    buffer_handle: WGPUBuffer,
    format: u32,
    offset: u64,
    size: u64,
) {
    let encoder = unsafe { deref_handle_mut::<wgpu::RenderBundleEncoder>(encoder_handle) };
    let buffer = unsafe { deref_handle::<wgpu::Buffer>(buffer_handle) };

    let index_format = match format {
        0 => wgpu::IndexFormat::Uint16,
        1 => wgpu::IndexFormat::Uint32,
        _ => wgpu::IndexFormat::Uint16,
    };

    let slice = if size == 0 {
        buffer.slice(offset..)
    } else {
        buffer.slice(offset..offset + size)
    };
    encoder.set_index_buffer(slice, index_format);
}

pub fn render_bundle_encoder_draw(
    encoder_handle: WGPURenderBundleEncoder,
    vertex_count: u32,
    instance_count: u32,
    first_vertex: u32,
    first_instance: u32,
) {
    let encoder = unsafe { deref_handle_mut::<wgpu::RenderBundleEncoder>(encoder_handle) };
    encoder.draw(
        first_vertex..first_vertex + vertex_count,
        first_instance..first_instance + instance_count,
    );
}

pub fn render_bundle_encoder_draw_indexed(
    encoder_handle: WGPURenderBundleEncoder,
    index_count: u32,
    instance_count: u32,
    first_index: u32,
    base_vertex: i32,
    first_instance: u32,
) {
    let encoder = unsafe { deref_handle_mut::<wgpu::RenderBundleEncoder>(encoder_handle) };
    encoder.draw_indexed(
        first_index..first_index + index_count,
        base_vertex,
        first_instance..first_instance + instance_count,
    );
}

pub fn render_bundle_encoder_draw_indirect(
    encoder_handle: WGPURenderBundleEncoder,
    indirect_buffer_handle: WGPUBuffer,
    indirect_offset: u64,
) {
    let encoder = unsafe { deref_handle_mut::<wgpu::RenderBundleEncoder>(encoder_handle) };
    let buffer = unsafe { deref_handle::<wgpu::Buffer>(indirect_buffer_handle) };
    encoder.draw_indirect(buffer, indirect_offset);
}

pub fn render_bundle_encoder_draw_indexed_indirect(
    encoder_handle: WGPURenderBundleEncoder,
    indirect_buffer_handle: WGPUBuffer,
    indirect_offset: u64,
) {
    let encoder = unsafe { deref_handle_mut::<wgpu::RenderBundleEncoder>(encoder_handle) };
    let buffer = unsafe { deref_handle::<wgpu::Buffer>(indirect_buffer_handle) };
    encoder.draw_indexed_indirect(buffer, indirect_offset);
}

pub fn render_bundle_encoder_set_immediates(
    encoder_handle: WGPURenderBundleEncoder,
    offset: u32,
    data: *const u8,
    data_len: u32,
) {
    let encoder = unsafe { deref_handle_mut::<wgpu::RenderBundleEncoder>(encoder_handle) };
    let slice = unsafe { std::slice::from_raw_parts(data, data_len as usize) };
    encoder.set_immediates(offset, slice);
}

pub fn render_bundle_encoder_finish(
    encoder_handle: WGPURenderBundleEncoder,
    label: *const std::ffi::c_char,
) -> WGPURenderBundle {
    let encoder = unsafe { drop_handle::<wgpu::RenderBundleEncoder>(encoder_handle) };
    let bundle = encoder.finish(&wgpu::RenderBundleDescriptor {
        label: unsafe { label_from_ptr(label) },
    });
    into_handle(bundle)
}

pub fn render_pass_execute_bundles(
    pass_handle: WGPURenderPassEncoder,
    bundles: &[WGPURenderBundle],
) {
    let wrapper = unsafe { deref_handle::<RenderPassWrapper>(pass_handle) };
    let pass = unsafe { &mut *wrapper.pass_ptr };

    let bundle_refs: Vec<&wgpu::RenderBundle> = bundles
        .iter()
        .map(|&h| unsafe { deref_handle::<wgpu::RenderBundle>(h) })
        .collect();

    pass.execute_bundles(bundle_refs);
}

pub fn render_bundle_release(bundle_handle: WGPURenderBundle) {
    unsafe { drop_handle::<wgpu::RenderBundle>(bundle_handle) };
}
