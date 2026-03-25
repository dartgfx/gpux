// Command encoder, render pass, and compute pass operations.

use crate::handle::*;
use super::enums::*;
use super::resources::label_from_ptr;
use super::types::*;

/// Convert u32::MAX sentinel to None, any other value to Some.
fn u32_option(v: u32) -> Option<u32> {
    if v == u32::MAX { None } else { Some(v) }
}

// =============================================================================
// COMMAND ENCODER OPERATIONS
// =============================================================================

pub fn device_create_command_encoder(
    device: &wgpu::Device,
    label: Option<&str>,
) -> WGPUCommandEncoder {
    let encoder = device.create_command_encoder(&wgpu::CommandEncoderDescriptor {
        label,
    });

    into_handle(encoder)
}

pub fn command_encoder_finish(
    encoder_handle: WGPUCommandEncoder,
) -> WGPUCommandBuffer {
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

    encoder.copy_buffer_to_buffer(src_buffer, source_offset, dst_buffer, destination_offset, size);
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
            origin: wgpu::Origin3d { x: origin_x, y: origin_y, z: origin_z },
            aspect: wgpu::TextureAspect::All,
        },
        wgpu::TexelCopyBufferInfo {
            buffer,
            layout: wgpu::TexelCopyBufferLayout {
                offset: 0,
                bytes_per_row: Some(bytes_per_row),
                rows_per_image: if rows_per_image == 0 { None } else { Some(rows_per_image) },
            },
        },
        wgpu::Extent3d { width, height, depth_or_array_layers: depth },
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
                rows_per_image: if rows_per_image == 0 { None } else { Some(rows_per_image) },
            },
        },
        wgpu::TexelCopyTextureInfo {
            texture,
            mip_level,
            origin: wgpu::Origin3d { x: origin_x, y: origin_y, z: origin_z },
            aspect: wgpu::TextureAspect::All,
        },
        wgpu::Extent3d { width, height, depth_or_array_layers: depth },
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
            origin: wgpu::Origin3d { x: src_origin_x, y: src_origin_y, z: src_origin_z },
            aspect: wgpu::TextureAspect::All,
        },
        wgpu::TexelCopyTextureInfo {
            texture: dst_texture,
            mip_level: dst_mip_level,
            origin: wgpu::Origin3d { x: dst_origin_x, y: dst_origin_y, z: dst_origin_z },
            aspect: wgpu::TextureAspect::All,
        },
        wgpu::Extent3d { width, height, depth_or_array_layers: depth },
    );
}

// =============================================================================
// RENDER PASS OPERATIONS
// =============================================================================

/// Begin a render pass. Consumes the encoder handle, returns a RenderPassWrapper handle.
/// SAFETY: The render pass borrows the encoder. The encoder is recovered via
/// render_pass_end_returning_encoder.
pub fn command_encoder_begin_render_pass(
    encoder_handle: WGPUCommandEncoder,
    desc: &WGPURenderPassDescriptor,
) -> WGPURenderPassEncoder {
    let encoder = unsafe { drop_handle::<wgpu::CommandEncoder>(encoder_handle) };

    let color_attachments: Vec<Option<wgpu::RenderPassColorAttachment>> = if desc.color_attachment_count > 0 && !desc.color_attachments.is_null() {
        let attachments = unsafe {
            std::slice::from_raw_parts(desc.color_attachments, desc.color_attachment_count as usize)
        };
        attachments.iter().map(|a| {
            if a.view == 0 { return None; }
            let view = unsafe { deref_handle::<wgpu::TextureView>(a.view) };
            let resolve_target = if a.resolve_target != 0 {
                Some(unsafe { deref_handle::<wgpu::TextureView>(a.resolve_target) })
            } else {
                None
            };
            Some(wgpu::RenderPassColorAttachment {
                view,
                resolve_target,
                depth_slice: if a.depth_slice == u32::MAX { None } else { Some(a.depth_slice) },
                ops: wgpu::Operations {
                    load: load_op_from_u32(a.load_op, wgpu::Color {
                        r: a.clear_r,
                        g: a.clear_g,
                        b: a.clear_b,
                        a: a.clear_a,
                    }),
                    store: store_op_from_u32(a.store_op),
                },
            })
        }).collect()
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

    into_handle(RenderPassWrapper { encoder_ptr, pass_ptr })
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
    pass.draw(first_vertex..first_vertex + vertex_count, first_instance..first_instance + instance_count);
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
    pass.draw_indexed(first_index..first_index + index_count, base_vertex, first_instance..first_instance + instance_count);
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

pub fn render_pass_begin_occlusion_query(
    pass_handle: WGPURenderPassEncoder,
    query_index: u32,
) {
    let wrapper = unsafe { deref_handle::<RenderPassWrapper>(pass_handle) };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.begin_occlusion_query(query_index);
}

pub fn render_pass_end_occlusion_query(
    pass_handle: WGPURenderPassEncoder,
) {
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

pub fn render_pass_set_stencil_reference(
    pass_handle: WGPURenderPassEncoder,
    reference: u32,
) {
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

pub fn command_encoder_pop_debug_group(
    encoder_handle: WGPUCommandEncoder,
) {
    let encoder = unsafe { deref_handle_mut::<wgpu::CommandEncoder>(encoder_handle) };

    encoder.pop_debug_group();
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

pub fn render_pass_pop_debug_group(
    pass_handle: WGPURenderPassEncoder,
) {
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

pub fn render_pass_end_returning_encoder(
    pass_handle: WGPURenderPassEncoder,
) -> WGPUCommandEncoder {
    let wrapper = unsafe { drop_handle::<RenderPassWrapper>(pass_handle) };

    unsafe {
        let _pass = Box::from_raw(wrapper.pass_ptr);
        // pass drops here, ending the render pass

        let encoder = *Box::from_raw(wrapper.encoder_ptr);
        into_handle(encoder)
    }
}

// =============================================================================
// COMPUTE PASS OPERATIONS
// =============================================================================

/// Begin a compute pass. Consumes the encoder handle, returns a ComputePassWrapper handle.
/// SAFETY: The compute pass borrows the encoder. The encoder is recovered via
/// compute_pass_end.
pub fn command_encoder_begin_compute_pass(
    encoder_handle: WGPUCommandEncoder,
    desc: Option<&WGPUComputePassDescriptor>,
) -> WGPUComputePassEncoder {
    let encoder = unsafe { drop_handle::<wgpu::CommandEncoder>(encoder_handle) };

    let timestamp_writes = match desc {
        Some(d) if d.timestamp_writes_query_set != 0 => {
            let qs = unsafe { deref_handle::<wgpu::QuerySet>(d.timestamp_writes_query_set) };
            Some(wgpu::ComputePassTimestampWrites {
                query_set: qs,
                beginning_of_pass_write_index: u32_option(d.timestamp_writes_beginning),
                end_of_pass_write_index: u32_option(d.timestamp_writes_end),
            })
        }
        _ => None,
    };

    let encoder_box = Box::new(encoder);
    let encoder_ptr = Box::into_raw(encoder_box);

    let compute_pass = unsafe {
        let pass_label = match desc {
            Some(d) => label_from_ptr(d.label),
            None => None,
        };
        (*encoder_ptr).begin_compute_pass(&wgpu::ComputePassDescriptor {
            label: pass_label,
            timestamp_writes,
        })
    };

    let pass_box = Box::new(compute_pass);
    let pass_ptr = Box::into_raw(pass_box);

    into_handle(ComputePassWrapper { encoder_ptr, pass_ptr })
}

pub fn compute_pass_set_pipeline(
    pass_handle: WGPUComputePassEncoder,
    pipeline_handle: WGPUComputePipeline,
) {
    let wrapper = unsafe { deref_handle::<ComputePassWrapper>(pass_handle) };
    let pipeline = unsafe { deref_handle::<wgpu::ComputePipeline>(pipeline_handle) };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.set_pipeline(pipeline);
}

pub fn compute_pass_set_bind_group(
    pass_handle: WGPUComputePassEncoder,
    index: u32,
    bind_group_id: WGPUBindGroup,
    dynamic_offsets: &[u32],
) {
    let wrapper = unsafe { deref_handle::<ComputePassWrapper>(pass_handle) };

    if bind_group_id == 0 {
        let pass = unsafe { &mut *wrapper.pass_ptr };
        pass.set_bind_group(index, None, dynamic_offsets);
        return;
    }

    let bind_group = unsafe { deref_handle::<wgpu::BindGroup>(bind_group_id) };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.set_bind_group(index, Some(bind_group), dynamic_offsets);
}

pub fn compute_pass_dispatch_workgroups(
    pass_handle: WGPUComputePassEncoder,
    x: u32,
    y: u32,
    z: u32,
) {
    let wrapper = unsafe { deref_handle::<ComputePassWrapper>(pass_handle) };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.dispatch_workgroups(x, y, z);
}

pub fn compute_pass_dispatch_workgroups_indirect(
    pass_handle: WGPUComputePassEncoder,
    indirect_buffer: WGPUBuffer,
    indirect_offset: u64,
) {
    let wrapper = unsafe { deref_handle::<ComputePassWrapper>(pass_handle) };
    let buffer = unsafe { deref_handle::<wgpu::Buffer>(indirect_buffer) };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.dispatch_workgroups_indirect(buffer, indirect_offset);
}

pub fn compute_pass_push_debug_group(
    pass_handle: WGPUComputePassEncoder,
    label: *const std::ffi::c_char,
) {
    let wrapper = unsafe { deref_handle::<ComputePassWrapper>(pass_handle) };

    let label_str = if label.is_null() {
        ""
    } else {
        unsafe { std::ffi::CStr::from_ptr(label).to_str().unwrap_or("") }
    };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.push_debug_group(label_str);
}

pub fn compute_pass_pop_debug_group(
    pass_handle: WGPUComputePassEncoder,
) {
    let wrapper = unsafe { deref_handle::<ComputePassWrapper>(pass_handle) };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.pop_debug_group();
}

pub fn compute_pass_insert_debug_marker(
    pass_handle: WGPUComputePassEncoder,
    label: *const std::ffi::c_char,
) {
    let wrapper = unsafe { deref_handle::<ComputePassWrapper>(pass_handle) };

    let label_str = if label.is_null() {
        ""
    } else {
        unsafe { std::ffi::CStr::from_ptr(label).to_str().unwrap_or("") }
    };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.insert_debug_marker(label_str);
}

pub fn compute_pass_set_immediates(
    pass_handle: WGPUComputePassEncoder,
    offset: u32,
    data: *const u8,
    data_len: u32,
) {
    let wrapper = unsafe { deref_handle::<ComputePassWrapper>(pass_handle) };
    let slice = unsafe { std::slice::from_raw_parts(data, data_len as usize) };
    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.set_immediates(offset, slice);
}

pub fn compute_pass_end(
    pass_handle: WGPUComputePassEncoder,
) -> WGPUCommandEncoder {
    let wrapper = unsafe { drop_handle::<ComputePassWrapper>(pass_handle) };

    unsafe {
        let _pass = Box::from_raw(wrapper.pass_ptr);
        // pass drops here, ending the compute pass

        let encoder = *Box::from_raw(wrapper.encoder_ptr);
        into_handle(encoder)
    }
}

// =============================================================================
// QUERY SET OPERATIONS
// =============================================================================

pub fn device_create_query_set(
    device: &wgpu::Device,
    query_type: u32,
    count: u32,
    label: Option<&str>,
) -> WGPUQuerySet {
    let ty = match query_type {
        1 => wgpu::QueryType::Occlusion,
        _ => wgpu::QueryType::Timestamp,
    };
    let query_set = device.create_query_set(&wgpu::QuerySetDescriptor {
        label,
        ty,
        count,
    });

    into_handle(query_set)
}

pub fn query_set_release(query_set_handle: WGPUQuerySet) {
    unsafe { drop_handle::<wgpu::QuerySet>(query_set_handle) };
}

pub fn command_encoder_write_timestamp(
    encoder_handle: WGPUCommandEncoder,
    query_set_handle: WGPUQuerySet,
    query_index: u32,
) {
    let encoder = unsafe { deref_handle_mut::<wgpu::CommandEncoder>(encoder_handle) };
    let qs = unsafe { deref_handle::<wgpu::QuerySet>(query_set_handle) };

    encoder.write_timestamp(qs, query_index);
}

pub fn command_encoder_resolve_query_set(
    encoder_handle: WGPUCommandEncoder,
    query_set_handle: WGPUQuerySet,
    first_query: u32,
    query_count: u32,
    destination: WGPUBuffer,
    destination_offset: u64,
) {
    let encoder = unsafe { deref_handle_mut::<wgpu::CommandEncoder>(encoder_handle) };
    let qs = unsafe { deref_handle::<wgpu::QuerySet>(query_set_handle) };
    let dst_buffer = unsafe { deref_handle::<wgpu::Buffer>(destination) };

    encoder.resolve_query_set(qs, first_query..first_query + query_count, dst_buffer, destination_offset);
}

// =============================================================================
// RENDER BUNDLE OPERATIONS
// =============================================================================

pub fn device_create_render_bundle_encoder(
    device: &wgpu::Device,
    desc: &WGPURenderBundleEncoderDescriptor,
) -> WGPURenderBundleEncoder {
    let color_formats: Vec<Option<wgpu::TextureFormat>> = if desc.color_format_count > 0 && !desc.color_formats.is_null() {
        let formats = unsafe {
            std::slice::from_raw_parts(desc.color_formats, desc.color_format_count as usize)
        };
        formats.iter().map(|&f| {
            if f == 0xFFFFFFFF { None } else { Some(texture_format_from_u32(f)) }
        }).collect()
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
    encoder.draw(first_vertex..first_vertex + vertex_count, first_instance..first_instance + instance_count);
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
    encoder.draw_indexed(first_index..first_index + index_count, base_vertex, first_instance..first_instance + instance_count);
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
