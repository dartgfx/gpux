use crate::abi::types::*;
use crate::ffi_catch;
use crate::render_pass::ops;

#[export_name = "wgpun_CommandEncoderBeginRenderPass"]
pub extern "C" fn wgpuCommandEncoderBeginRenderPass(
    encoder: WGPUCommandEncoder,
    descriptor: *const WGPURenderPassDescriptor,
) -> WGPURenderPassEncoder {
    if encoder == 0 || descriptor.is_null() {
        return 0;
    }
    ffi_catch!(0, {
        let desc = unsafe { &*descriptor };
        ops::command_encoder_begin_render_pass(encoder, desc)
    })
}

#[export_name = "wgpun_RenderPassEncoderSetPipeline"]
pub extern "C" fn wgpuRenderPassEncoderSetPipeline(
    render_pass: WGPURenderPassEncoder,
    pipeline: WGPURenderPipeline,
) {
    if render_pass == 0 || pipeline == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_pass_set_pipeline(render_pass, pipeline);
    })
}

#[export_name = "wgpun_RenderPassEncoderSetBindGroup"]
pub extern "C" fn wgpuRenderPassEncoderSetBindGroup(
    render_pass: WGPURenderPassEncoder,
    index: u32,
    bind_group: WGPUBindGroup,
    dynamic_offsets: *const u32,
    dynamic_offset_count: u32,
) {
    if render_pass == 0 || bind_group == 0 {
        return;
    }
    ffi_catch!((), {
        let offsets = if dynamic_offset_count > 0 && !dynamic_offsets.is_null() {
            unsafe { std::slice::from_raw_parts(dynamic_offsets, dynamic_offset_count as usize) }
        } else {
            &[]
        };
        ops::render_pass_set_bind_group(render_pass, index, bind_group, offsets);
    })
}

#[export_name = "wgpun_RenderPassEncoderSetVertexBuffer"]
pub extern "C" fn wgpuRenderPassEncoderSetVertexBuffer(
    render_pass: WGPURenderPassEncoder,
    slot: u32,
    buffer: WGPUBuffer,
    offset: u64,
    size: u64,
) {
    if render_pass == 0 || buffer == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_pass_set_vertex_buffer(render_pass, slot, buffer, offset, size);
    })
}

#[export_name = "wgpun_RenderPassEncoderSetIndexBuffer"]
pub extern "C" fn wgpuRenderPassEncoderSetIndexBuffer(
    render_pass: WGPURenderPassEncoder,
    buffer: WGPUBuffer,
    format: u32,
    offset: u64,
    size: u64,
) {
    if render_pass == 0 || buffer == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_pass_set_index_buffer(render_pass, buffer, format, offset, size);
    })
}

#[export_name = "wgpun_RenderPassEncoderDraw"]
pub extern "C" fn wgpuRenderPassEncoderDraw(
    render_pass: WGPURenderPassEncoder,
    vertex_count: u32,
    instance_count: u32,
    first_vertex: u32,
    first_instance: u32,
) {
    if render_pass == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_pass_draw(
            render_pass,
            vertex_count,
            instance_count,
            first_vertex,
            first_instance,
        );
    })
}

#[export_name = "wgpun_RenderPassEncoderDrawIndexed"]
pub extern "C" fn wgpuRenderPassEncoderDrawIndexed(
    render_pass: WGPURenderPassEncoder,
    index_count: u32,
    instance_count: u32,
    first_index: u32,
    base_vertex: i32,
    first_instance: u32,
) {
    if render_pass == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_pass_draw_indexed(
            render_pass,
            index_count,
            instance_count,
            first_index,
            base_vertex,
            first_instance,
        );
    })
}

#[export_name = "wgpun_RenderPassEncoderMultiDrawIndexedIndirect"]
pub extern "C" fn wgpuRenderPassEncoderMultiDrawIndexedIndirect(
    render_pass: WGPURenderPassEncoder,
    indirect_buffer: WGPUBuffer,
    indirect_offset: u64,
    count: u32,
) {
    if render_pass == 0 || indirect_buffer == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_pass_multi_draw_indexed_indirect(
            render_pass,
            indirect_buffer,
            indirect_offset,
            count,
        );
    })
}

#[export_name = "wgpun_RenderPassEncoderDrawIndirect"]
pub extern "C" fn wgpuRenderPassEncoderDrawIndirect(
    render_pass: WGPURenderPassEncoder,
    indirect_buffer: WGPUBuffer,
    indirect_offset: u64,
) {
    if render_pass == 0 || indirect_buffer == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_pass_draw_indirect(render_pass, indirect_buffer, indirect_offset);
    })
}

#[export_name = "wgpun_RenderPassEncoderDrawIndexedIndirect"]
pub extern "C" fn wgpuRenderPassEncoderDrawIndexedIndirect(
    render_pass: WGPURenderPassEncoder,
    indirect_buffer: WGPUBuffer,
    indirect_offset: u64,
) {
    if render_pass == 0 || indirect_buffer == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_pass_draw_indexed_indirect(render_pass, indirect_buffer, indirect_offset);
    })
}

#[export_name = "wgpun_RenderPassEncoderBeginOcclusionQuery"]
pub extern "C" fn wgpuRenderPassEncoderBeginOcclusionQuery(
    render_pass: WGPURenderPassEncoder,
    query_index: u32,
) {
    if render_pass == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_pass_begin_occlusion_query(render_pass, query_index);
    })
}

#[export_name = "wgpun_RenderPassEncoderEndOcclusionQuery"]
pub extern "C" fn wgpuRenderPassEncoderEndOcclusionQuery(render_pass: WGPURenderPassEncoder) {
    if render_pass == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_pass_end_occlusion_query(render_pass);
    })
}

#[export_name = "wgpun_RenderPassEncoderSetViewport"]
pub extern "C" fn wgpuRenderPassEncoderSetViewport(
    render_pass: WGPURenderPassEncoder,
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    min_depth: f32,
    max_depth: f32,
) {
    if render_pass == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_pass_set_viewport(render_pass, x, y, width, height, min_depth, max_depth);
    })
}

#[export_name = "wgpun_RenderPassEncoderSetScissorRect"]
pub extern "C" fn wgpuRenderPassEncoderSetScissorRect(
    render_pass: WGPURenderPassEncoder,
    x: u32,
    y: u32,
    width: u32,
    height: u32,
) {
    if render_pass == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_pass_set_scissor_rect(render_pass, x, y, width, height);
    })
}

#[export_name = "wgpun_RenderPassEncoderSetBlendConstant"]
pub extern "C" fn wgpuRenderPassEncoderSetBlendConstant(
    render_pass: WGPURenderPassEncoder,
    r: f64,
    g: f64,
    b: f64,
    a: f64,
) {
    if render_pass == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_pass_set_blend_constant(render_pass, r, g, b, a);
    })
}

#[export_name = "wgpun_RenderPassEncoderSetStencilReference"]
pub extern "C" fn wgpuRenderPassEncoderSetStencilReference(
    render_pass: WGPURenderPassEncoder,
    reference: u32,
) {
    if render_pass == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_pass_set_stencil_reference(render_pass, reference);
    })
}

#[export_name = "wgpun_RenderPassEncoderInsertDebugMarker"]
pub extern "C" fn wgpuRenderPassEncoderInsertDebugMarker(
    render_pass: WGPURenderPassEncoder,
    label: *const std::ffi::c_char,
) {
    if render_pass == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_pass_insert_debug_marker(render_pass, label);
    })
}

#[export_name = "wgpun_RenderPassEncoderPushDebugGroup"]
pub extern "C" fn wgpuRenderPassEncoderPushDebugGroup(
    render_pass: WGPURenderPassEncoder,
    label: *const std::ffi::c_char,
) {
    if render_pass == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_pass_push_debug_group(render_pass, label);
    })
}

#[export_name = "wgpun_RenderPassEncoderPopDebugGroup"]
pub extern "C" fn wgpuRenderPassEncoderPopDebugGroup(render_pass: WGPURenderPassEncoder) {
    if render_pass == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_pass_pop_debug_group(render_pass);
    })
}

#[export_name = "wgpun_RenderPassEncoderSetImmediates"]
pub extern "C" fn wgpuRenderPassEncoderSetImmediates(
    render_pass: WGPURenderPassEncoder,
    offset: u32,
    data: *const u8,
    data_len: u32,
) {
    if render_pass == 0 || data.is_null() || data_len == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_pass_set_immediates(render_pass, offset, data, data_len);
    })
}

#[export_name = "wgpun_RenderPassEncoderEnd"]
pub extern "C" fn wgpuRenderPassEncoderEnd(
    render_pass: WGPURenderPassEncoder,
) -> WGPUCommandEncoder {
    if render_pass == 0 {
        return 0;
    }
    ffi_catch!(0, { ops::render_pass_end_returning_encoder(render_pass) })
}
