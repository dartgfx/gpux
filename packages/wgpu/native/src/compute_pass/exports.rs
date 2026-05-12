use crate::abi::types::*;
use crate::compute_pass::ops;
use crate::ffi_catch;

#[export_name = "wgpun_CommandEncoderBeginComputePass"]
pub extern "C" fn wgpuCommandEncoderBeginComputePass(
    encoder: WGPUCommandEncoder,
    descriptor: *const WGPUComputePassDescriptor,
) -> WGPUComputePassEncoder {
    if encoder == 0 {
        return 0;
    }
    ffi_catch!(0, {
        let desc = if descriptor.is_null() {
            None
        } else {
            Some(unsafe { &*descriptor })
        };
        ops::command_encoder_begin_compute_pass(encoder, desc)
    })
}

#[export_name = "wgpun_ComputePassEncoderSetPipeline"]
pub extern "C" fn wgpuComputePassEncoderSetPipeline(
    compute_pass: WGPUComputePassEncoder,
    pipeline: WGPUComputePipeline,
) {
    if compute_pass == 0 || pipeline == 0 {
        return;
    }
    ffi_catch!((), {
        ops::compute_pass_set_pipeline(compute_pass, pipeline);
    })
}

#[export_name = "wgpun_ComputePassEncoderSetBindGroup"]
pub extern "C" fn wgpuComputePassEncoderSetBindGroup(
    compute_pass: WGPUComputePassEncoder,
    index: u32,
    bind_group: WGPUBindGroup,
    dynamic_offsets: *const u32,
    dynamic_offset_count: u32,
) {
    if compute_pass == 0 || bind_group == 0 {
        return;
    }
    ffi_catch!((), {
        let offsets = if dynamic_offset_count > 0 && !dynamic_offsets.is_null() {
            unsafe { std::slice::from_raw_parts(dynamic_offsets, dynamic_offset_count as usize) }
        } else {
            &[]
        };
        ops::compute_pass_set_bind_group(compute_pass, index, bind_group, offsets);
    })
}

#[export_name = "wgpun_ComputePassEncoderDispatchWorkgroups"]
pub extern "C" fn wgpuComputePassEncoderDispatchWorkgroups(
    compute_pass: WGPUComputePassEncoder,
    x: u32,
    y: u32,
    z: u32,
) {
    if compute_pass == 0 {
        return;
    }
    ffi_catch!((), {
        ops::compute_pass_dispatch_workgroups(compute_pass, x, y, z);
    })
}

#[export_name = "wgpun_ComputePassEncoderDispatchWorkgroupsIndirect"]
pub extern "C" fn wgpuComputePassEncoderDispatchWorkgroupsIndirect(
    compute_pass: WGPUComputePassEncoder,
    indirect_buffer: WGPUBuffer,
    indirect_offset: u64,
) {
    if compute_pass == 0 || indirect_buffer == 0 {
        return;
    }
    ffi_catch!((), {
        ops::compute_pass_dispatch_workgroups_indirect(
            compute_pass,
            indirect_buffer,
            indirect_offset,
        );
    })
}

#[export_name = "wgpun_ComputePassEncoderInsertDebugMarker"]
pub extern "C" fn wgpuComputePassEncoderInsertDebugMarker(
    compute_pass: WGPUComputePassEncoder,
    label: *const std::ffi::c_char,
) {
    if compute_pass == 0 {
        return;
    }
    ffi_catch!((), {
        ops::compute_pass_insert_debug_marker(compute_pass, label);
    })
}

#[export_name = "wgpun_ComputePassEncoderPushDebugGroup"]
pub extern "C" fn wgpuComputePassEncoderPushDebugGroup(
    compute_pass: WGPUComputePassEncoder,
    label: *const std::ffi::c_char,
) {
    if compute_pass == 0 {
        return;
    }
    ffi_catch!((), {
        ops::compute_pass_push_debug_group(compute_pass, label);
    })
}

#[export_name = "wgpun_ComputePassEncoderPopDebugGroup"]
pub extern "C" fn wgpuComputePassEncoderPopDebugGroup(compute_pass: WGPUComputePassEncoder) {
    if compute_pass == 0 {
        return;
    }
    ffi_catch!((), {
        ops::compute_pass_pop_debug_group(compute_pass);
    })
}

#[export_name = "wgpun_ComputePassEncoderSetImmediates"]
pub extern "C" fn wgpuComputePassEncoderSetImmediates(
    compute_pass: WGPUComputePassEncoder,
    offset: u32,
    data: *const u8,
    data_len: u32,
) {
    if compute_pass == 0 || data.is_null() || data_len == 0 {
        return;
    }
    ffi_catch!((), {
        ops::compute_pass_set_immediates(compute_pass, offset, data, data_len);
    })
}

#[export_name = "wgpun_ComputePassEncoderEnd"]
pub extern "C" fn wgpuComputePassEncoderEnd(
    compute_pass: WGPUComputePassEncoder,
) -> WGPUCommandEncoder {
    if compute_pass == 0 {
        return 0;
    }
    ffi_catch!(0, { ops::compute_pass_end(compute_pass) })
}
