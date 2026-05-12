use crate::abi::enums::*;
use crate::abi::types::*;
use crate::runtime::handle::*;
use crate::runtime::label::label_from_ptr;
use crate::runtime::state::*;

fn u32_option(v: u32) -> Option<u32> {
    if v == u32::MAX {
        None
    } else {
        Some(v)
    }
}

/// Begin a render pass. Consumes the encoder handle, returns a RenderPassWrapper handle.
/// SAFETY: The render pass borrows the encoder. The encoder is recovered via
/// render_pass_end_returning_encoder.
pub fn command_encoder_begin_render_pass(
    encoder_handle: WGPUCommandEncoder,
    desc: &WGPURenderPassDescriptor,
) -> WGPURenderPassEncoder {
    let encoder = unsafe { drop_handle::<wgpu::CommandEncoder>(encoder_handle) };

    let color_attachments: Vec<Option<wgpu::RenderPassColorAttachment>> = if desc
        .color_attachment_count
        > 0
        && !desc.color_attachments.is_null()
    {
        let attachments = unsafe {
            std::slice::from_raw_parts(desc.color_attachments, desc.color_attachment_count as usize)
        };
        attachments
            .iter()
            .map(|a| {
                if a.view == 0 {
                    return None;
                }
                let view = unsafe { deref_handle::<wgpu::TextureView>(a.view) };
                let resolve_target = if a.resolve_target != 0 {
                    Some(unsafe { deref_handle::<wgpu::TextureView>(a.resolve_target) })
                } else {
                    None
                };
                Some(wgpu::RenderPassColorAttachment {
                    view,
                    resolve_target,
                    depth_slice: if a.depth_slice == u32::MAX {
                        None
                    } else {
                        Some(a.depth_slice)
                    },
                    ops: wgpu::Operations {
                        load: load_op_from_u32(
                            a.load_op,
                            wgpu::Color {
                                r: a.clear_r,
                                g: a.clear_g,
                                b: a.clear_b,
                                a: a.clear_a,
                            },
                        ),
                        store: store_op_from_u32(a.store_op),
                    },
                })
            })
            .collect()
    } else {
        vec![]
    };

    let depth_stencil_attachment = if !desc.depth_stencil_attachment.is_null() {
        let ds = unsafe { &*desc.depth_stencil_attachment };
        if ds.view != 0 {
            let view = unsafe { deref_handle::<wgpu::TextureView>(ds.view) };
            Some(wgpu::RenderPassDepthStencilAttachment {
                view,
                depth_ops: Some(wgpu::Operations {
                    load: load_op_from_u32(ds.depth_load_op, ds.depth_clear_value),
                    store: store_op_from_u32(ds.depth_store_op),
                }),
                stencil_ops: Some(wgpu::Operations {
                    load: load_op_from_u32(ds.stencil_load_op, ds.stencil_clear_value),
                    store: store_op_from_u32(ds.stencil_store_op),
                }),
            })
        } else {
            None
        }
    } else {
        None
    };

    let timestamp_writes = if desc.timestamp_writes_query_set != 0 {
        let qs = unsafe { deref_handle::<wgpu::QuerySet>(desc.timestamp_writes_query_set) };
        Some(wgpu::RenderPassTimestampWrites {
            query_set: qs,
            beginning_of_pass_write_index: u32_option(desc.timestamp_writes_beginning),
            end_of_pass_write_index: u32_option(desc.timestamp_writes_end),
        })
    } else {
        None
    };

    let occlusion_query_set = if desc.occlusion_query_set != 0 {
        Some(unsafe { deref_handle::<wgpu::QuerySet>(desc.occlusion_query_set) })
    } else {
        None
    };

    let encoder_box = Box::new(encoder);
    let encoder_ptr = Box::into_raw(encoder_box);

    let render_pass = unsafe {
        (*encoder_ptr).begin_render_pass(&wgpu::RenderPassDescriptor {
            label: label_from_ptr(desc.label),
            color_attachments: &color_attachments,
            depth_stencil_attachment,
            timestamp_writes,
            occlusion_query_set,
            multiview_mask: None,
        })
    };

    let pass_box = Box::new(render_pass);
    let pass_ptr = Box::into_raw(pass_box);

    into_handle(RenderPassWrapper {
        encoder_ptr,
        pass_ptr,
    })
}

pub fn render_pass_set_pipeline(
    pass_handle: WGPURenderPassEncoder,
    pipeline_handle: WGPURenderPipeline,
) {
    let wrapper = unsafe { deref_handle::<RenderPassWrapper>(pass_handle) };
    let pipeline = unsafe { deref_handle::<wgpu::RenderPipeline>(pipeline_handle) };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.set_pipeline(pipeline);
}

pub fn render_pass_set_bind_group(
    pass_handle: WGPURenderPassEncoder,
    index: u32,
    bind_group_id: WGPUBindGroup,
    dynamic_offsets: &[u32],
) {
    let wrapper = unsafe { deref_handle::<RenderPassWrapper>(pass_handle) };

    if bind_group_id == 0 {
        let pass = unsafe { &mut *wrapper.pass_ptr };
        pass.set_bind_group(index, None, dynamic_offsets);
        return;
    }

    let bind_group = unsafe { deref_handle::<wgpu::BindGroup>(bind_group_id) };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.set_bind_group(index, Some(bind_group), dynamic_offsets);
}

pub fn render_pass_set_vertex_buffer(
    pass_handle: WGPURenderPassEncoder,
    slot: u32,
    buffer_handle: WGPUBuffer,
    offset: u64,
    size: u64,
) {
    let wrapper = unsafe { deref_handle::<RenderPassWrapper>(pass_handle) };
    let buffer = unsafe { deref_handle::<wgpu::Buffer>(buffer_handle) };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    let slice = if size == 0 {
        buffer.slice(offset..)
    } else {
        buffer.slice(offset..offset + size)
    };
    pass.set_vertex_buffer(slot, slice);
}

pub fn render_pass_set_index_buffer(
    pass_handle: WGPURenderPassEncoder,
    buffer_handle: WGPUBuffer,
    format: u32,
    offset: u64,
    size: u64,
) {
    let wrapper = unsafe { deref_handle::<RenderPassWrapper>(pass_handle) };
    let buffer = unsafe { deref_handle::<wgpu::Buffer>(buffer_handle) };

    let index_format = match format {
        0 => wgpu::IndexFormat::Uint16,
        1 => wgpu::IndexFormat::Uint32,
        _ => wgpu::IndexFormat::Uint16,
    };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    let slice = if size == 0 {
        buffer.slice(offset..)
    } else {
        buffer.slice(offset..offset + size)
    };
    pass.set_index_buffer(slice, index_format);
}

pub fn render_pass_draw(
    pass_handle: WGPURenderPassEncoder,
    vertex_count: u32,
    instance_count: u32,
    first_vertex: u32,
    first_instance: u32,
) {
    let wrapper = unsafe { deref_handle::<RenderPassWrapper>(pass_handle) };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.draw(
        first_vertex..first_vertex + vertex_count,
        first_instance..first_instance + instance_count,
    );
}

pub fn render_pass_draw_indexed(
    pass_handle: WGPURenderPassEncoder,
    index_count: u32,
    instance_count: u32,
    first_index: u32,
    base_vertex: i32,
    first_instance: u32,
) {
    let wrapper = unsafe { deref_handle::<RenderPassWrapper>(pass_handle) };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.draw_indexed(
        first_index..first_index + index_count,
        base_vertex,
        first_instance..first_instance + instance_count,
    );
}

pub fn render_pass_multi_draw_indexed_indirect(
    pass_handle: WGPURenderPassEncoder,
    indirect_buffer_handle: WGPUBuffer,
    indirect_offset: u64,
    count: u32,
) {
    let wrapper = unsafe { deref_handle::<RenderPassWrapper>(pass_handle) };
    let buffer = unsafe { deref_handle::<wgpu::Buffer>(indirect_buffer_handle) };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.multi_draw_indexed_indirect(buffer, indirect_offset, count);
}

pub fn render_pass_draw_indirect(
    pass_handle: WGPURenderPassEncoder,
    indirect_buffer_handle: WGPUBuffer,
    indirect_offset: u64,
) {
    let wrapper = unsafe { deref_handle::<RenderPassWrapper>(pass_handle) };
    let buffer = unsafe { deref_handle::<wgpu::Buffer>(indirect_buffer_handle) };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.draw_indirect(buffer, indirect_offset);
}

pub fn render_pass_draw_indexed_indirect(
    pass_handle: WGPURenderPassEncoder,
    indirect_buffer_handle: WGPUBuffer,
    indirect_offset: u64,
) {
    let wrapper = unsafe { deref_handle::<RenderPassWrapper>(pass_handle) };
    let buffer = unsafe { deref_handle::<wgpu::Buffer>(indirect_buffer_handle) };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.draw_indexed_indirect(buffer, indirect_offset);
}

pub fn render_pass_begin_occlusion_query(pass_handle: WGPURenderPassEncoder, query_index: u32) {
    let wrapper = unsafe { deref_handle::<RenderPassWrapper>(pass_handle) };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.begin_occlusion_query(query_index);
}

pub fn render_pass_end_occlusion_query(pass_handle: WGPURenderPassEncoder) {
    let wrapper = unsafe { deref_handle::<RenderPassWrapper>(pass_handle) };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.end_occlusion_query();
}

#[allow(clippy::too_many_arguments)]
pub fn render_pass_set_viewport(
    pass_handle: WGPURenderPassEncoder,
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    min_depth: f32,
    max_depth: f32,
) {
    let wrapper = unsafe { deref_handle::<RenderPassWrapper>(pass_handle) };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.set_viewport(x, y, width, height, min_depth, max_depth);
}

pub fn render_pass_set_scissor_rect(
    pass_handle: WGPURenderPassEncoder,
    x: u32,
    y: u32,
    width: u32,
    height: u32,
) {
    let wrapper = unsafe { deref_handle::<RenderPassWrapper>(pass_handle) };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.set_scissor_rect(x, y, width, height);
}

pub fn render_pass_set_blend_constant(
    pass_handle: WGPURenderPassEncoder,
    r: f64,
    g: f64,
    b: f64,
    a: f64,
) {
    let wrapper = unsafe { deref_handle::<RenderPassWrapper>(pass_handle) };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.set_blend_constant(wgpu::Color { r, g, b, a });
}

pub fn render_pass_set_stencil_reference(pass_handle: WGPURenderPassEncoder, reference: u32) {
    let wrapper = unsafe { deref_handle::<RenderPassWrapper>(pass_handle) };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.set_stencil_reference(reference);
}

pub fn render_pass_insert_debug_marker(
    pass_handle: WGPURenderPassEncoder,
    label: *const std::ffi::c_char,
) {
    let wrapper = unsafe { deref_handle::<RenderPassWrapper>(pass_handle) };

    let label_str = if label.is_null() {
        ""
    } else {
        unsafe { std::ffi::CStr::from_ptr(label).to_str().unwrap_or("") }
    };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.insert_debug_marker(label_str);
}

pub fn render_pass_push_debug_group(
    pass_handle: WGPURenderPassEncoder,
    label: *const std::ffi::c_char,
) {
    let wrapper = unsafe { deref_handle::<RenderPassWrapper>(pass_handle) };

    let label_str = if label.is_null() {
        ""
    } else {
        unsafe { std::ffi::CStr::from_ptr(label).to_str().unwrap_or("") }
    };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.push_debug_group(label_str);
}

pub fn render_pass_pop_debug_group(pass_handle: WGPURenderPassEncoder) {
    let wrapper = unsafe { deref_handle::<RenderPassWrapper>(pass_handle) };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.pop_debug_group();
}

pub fn render_pass_set_immediates(
    pass_handle: WGPURenderPassEncoder,
    offset: u32,
    data: *const u8,
    data_len: u32,
) {
    let wrapper = unsafe { deref_handle::<RenderPassWrapper>(pass_handle) };
    let slice = unsafe { std::slice::from_raw_parts(data, data_len as usize) };
    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.set_immediates(offset, slice);
}

pub fn render_pass_end_returning_encoder(pass_handle: WGPURenderPassEncoder) -> WGPUCommandEncoder {
    let wrapper = unsafe { drop_handle::<RenderPassWrapper>(pass_handle) };

    unsafe {
        let _pass = Box::from_raw(wrapper.pass_ptr);
        // pass drops here, ending the render pass

        let encoder = *Box::from_raw(wrapper.encoder_ptr);
        into_handle(encoder)
    }
}
