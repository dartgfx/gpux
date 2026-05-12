use crate::abi::types::*;
use crate::ffi_catch;
use crate::render_bundle::ops;
use crate::runtime::handle::*;
use crate::runtime::state::*;

#[export_name = "wgpun_DeviceCreateRenderBundleEncoder"]
pub extern "C" fn wgpuDeviceCreateRenderBundleEncoder(
    device: WGPUDevice,
    descriptor: *const WGPURenderBundleEncoderDescriptor,
) -> WGPURenderBundleEncoder {
    if device == 0 || descriptor.is_null() {
        return 0;
    }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let desc = unsafe { &*descriptor };
        ops::device_create_render_bundle_encoder(&entry.device, desc)
    })
}

#[export_name = "wgpun_RenderBundleEncoderSetPipeline"]
pub extern "C" fn wgpuRenderBundleEncoderSetPipeline(
    encoder: WGPURenderBundleEncoder,
    pipeline: WGPURenderPipeline,
) {
    if encoder == 0 || pipeline == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_bundle_encoder_set_pipeline(encoder, pipeline);
    })
}

#[export_name = "wgpun_RenderBundleEncoderSetBindGroup"]
pub extern "C" fn wgpuRenderBundleEncoderSetBindGroup(
    encoder: WGPURenderBundleEncoder,
    index: u32,
    bind_group: WGPUBindGroup,
    dynamic_offsets: *const u32,
    dynamic_offset_count: u32,
) {
    if encoder == 0 || bind_group == 0 {
        return;
    }
    ffi_catch!((), {
        let offsets = if dynamic_offset_count > 0 && !dynamic_offsets.is_null() {
            unsafe { std::slice::from_raw_parts(dynamic_offsets, dynamic_offset_count as usize) }
        } else {
            &[]
        };
        ops::render_bundle_encoder_set_bind_group(encoder, index, bind_group, offsets);
    })
}

#[export_name = "wgpun_RenderBundleEncoderSetVertexBuffer"]
pub extern "C" fn wgpuRenderBundleEncoderSetVertexBuffer(
    encoder: WGPURenderBundleEncoder,
    slot: u32,
    buffer: WGPUBuffer,
    offset: u64,
    size: u64,
) {
    if encoder == 0 || buffer == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_bundle_encoder_set_vertex_buffer(encoder, slot, buffer, offset, size);
    })
}

#[export_name = "wgpun_RenderBundleEncoderSetIndexBuffer"]
pub extern "C" fn wgpuRenderBundleEncoderSetIndexBuffer(
    encoder: WGPURenderBundleEncoder,
    buffer: WGPUBuffer,
    format: u32,
    offset: u64,
    size: u64,
) {
    if encoder == 0 || buffer == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_bundle_encoder_set_index_buffer(encoder, buffer, format, offset, size);
    })
}

#[export_name = "wgpun_RenderBundleEncoderDraw"]
pub extern "C" fn wgpuRenderBundleEncoderDraw(
    encoder: WGPURenderBundleEncoder,
    vertex_count: u32,
    instance_count: u32,
    first_vertex: u32,
    first_instance: u32,
) {
    if encoder == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_bundle_encoder_draw(
            encoder,
            vertex_count,
            instance_count,
            first_vertex,
            first_instance,
        );
    })
}

#[export_name = "wgpun_RenderBundleEncoderDrawIndexed"]
pub extern "C" fn wgpuRenderBundleEncoderDrawIndexed(
    encoder: WGPURenderBundleEncoder,
    index_count: u32,
    instance_count: u32,
    first_index: u32,
    base_vertex: i32,
    first_instance: u32,
) {
    if encoder == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_bundle_encoder_draw_indexed(
            encoder,
            index_count,
            instance_count,
            first_index,
            base_vertex,
            first_instance,
        );
    })
}

#[export_name = "wgpun_RenderBundleEncoderDrawIndirect"]
pub extern "C" fn wgpuRenderBundleEncoderDrawIndirect(
    encoder: WGPURenderBundleEncoder,
    indirect_buffer: WGPUBuffer,
    indirect_offset: u64,
) {
    if encoder == 0 || indirect_buffer == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_bundle_encoder_draw_indirect(encoder, indirect_buffer, indirect_offset);
    })
}

#[export_name = "wgpun_RenderBundleEncoderDrawIndexedIndirect"]
pub extern "C" fn wgpuRenderBundleEncoderDrawIndexedIndirect(
    encoder: WGPURenderBundleEncoder,
    indirect_buffer: WGPUBuffer,
    indirect_offset: u64,
) {
    if encoder == 0 || indirect_buffer == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_bundle_encoder_draw_indexed_indirect(encoder, indirect_buffer, indirect_offset);
    })
}

#[export_name = "wgpun_RenderBundleEncoderSetImmediates"]
pub extern "C" fn wgpuRenderBundleEncoderSetImmediates(
    encoder: WGPURenderBundleEncoder,
    offset: u32,
    data: *const u8,
    data_len: u32,
) {
    if encoder == 0 || data.is_null() || data_len == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_bundle_encoder_set_immediates(encoder, offset, data, data_len);
    })
}

#[export_name = "wgpun_RenderBundleEncoderFinish"]
pub extern "C" fn wgpuRenderBundleEncoderFinish(
    encoder: WGPURenderBundleEncoder,
    label: *const std::ffi::c_char,
) -> WGPURenderBundle {
    if encoder == 0 {
        return 0;
    }
    ffi_catch!(0, { ops::render_bundle_encoder_finish(encoder, label) })
}

#[export_name = "wgpun_RenderPassExecuteBundles"]
pub extern "C" fn wgpuRenderPassExecuteBundles(
    render_pass: WGPURenderPassEncoder,
    bundles: *const WGPURenderBundle,
    count: u32,
) {
    if render_pass == 0 || bundles.is_null() || count == 0 {
        return;
    }
    ffi_catch!((), {
        let bundle_slice = unsafe { std::slice::from_raw_parts(bundles, count as usize) };
        ops::render_pass_execute_bundles(render_pass, bundle_slice);
    })
}

#[export_name = "wgpun_RenderBundleRelease"]
pub extern "C" fn wgpuRenderBundleRelease(bundle: WGPURenderBundle) {
    if bundle == 0 {
        return;
    }
    ffi_catch!((), {
        ops::render_bundle_release(bundle);
    })
}

#[export_name = "wgpun_RenderBundleRelease_p"]
pub extern "C" fn render_bundle_release_p(ptr: *mut std::ffi::c_void) {
    wgpuRenderBundleRelease(ptr as u64);
}
