use crate::abi::types::*;
use crate::ffi_catch;
use crate::pipeline::ops;
use crate::runtime::handle::*;
use crate::runtime::state::*;

#[export_name = "wgpun_DeviceCreatePipelineLayout"]
pub extern "C" fn wgpuDeviceCreatePipelineLayout(
    device: WGPUDevice,
    desc: *const WGPUPipelineLayoutDescriptor,
) -> WGPUPipelineLayout {
    if device == 0 || desc.is_null() {
        return 0;
    }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let desc = unsafe { &*desc };
        ops::device_create_pipeline_layout(&entry.device, desc)
    })
}

#[export_name = "wgpun_PipelineLayoutRelease"]
pub extern "C" fn wgpuPipelineLayoutRelease(layout: WGPUPipelineLayout) {
    ffi_catch!((), {
        ops::pipeline_layout_release(layout);
    })
}

#[export_name = "wgpun_PipelineLayoutRelease_p"]
pub extern "C" fn pipeline_layout_release_p(ptr: *mut std::ffi::c_void) {
    wgpuPipelineLayoutRelease(ptr as u64);
}

// =============================================================================
// RENDER PIPELINE
// =============================================================================

#[export_name = "wgpun_DeviceCreateRenderPipeline"]
pub extern "C" fn wgpuDeviceCreateRenderPipeline(
    device: WGPUDevice,
    desc: *const WGPURenderPipelineDescriptor,
) -> WGPURenderPipeline {
    if device == 0 || desc.is_null() {
        return 0;
    }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let desc = unsafe { &*desc };
        ops::device_create_render_pipeline(&entry.device, desc)
    })
}

#[export_name = "wgpun_RenderPipelineGetBindGroupLayout"]
pub extern "C" fn wgpuRenderPipelineGetBindGroupLayout(
    pipeline: WGPURenderPipeline,
    index: u32,
) -> WGPUBindGroupLayout {
    ffi_catch!(0, {
        ops::render_pipeline_get_bind_group_layout(pipeline, index)
    })
}

#[export_name = "wgpun_RenderPipelineRelease"]
pub extern "C" fn wgpuRenderPipelineRelease(pipeline: WGPURenderPipeline) {
    ffi_catch!((), {
        ops::render_pipeline_release(pipeline);
    })
}

#[export_name = "wgpun_RenderPipelineRelease_p"]
pub extern "C" fn render_pipeline_release_p(ptr: *mut std::ffi::c_void) {
    wgpuRenderPipelineRelease(ptr as u64);
}

// =============================================================================
// COMPUTE PIPELINE
// =============================================================================

#[export_name = "wgpun_DeviceCreateComputePipeline"]
pub extern "C" fn wgpuDeviceCreateComputePipeline(
    device: WGPUDevice,
    desc: *const WGPUComputePipelineDescriptor,
) -> WGPUComputePipeline {
    if device == 0 || desc.is_null() {
        return 0;
    }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let desc = unsafe { &*desc };
        ops::device_create_compute_pipeline(&entry.device, desc)
    })
}

#[export_name = "wgpun_ComputePipelineGetBindGroupLayout"]
pub extern "C" fn wgpuComputePipelineGetBindGroupLayout(
    pipeline: WGPUComputePipeline,
    index: u32,
) -> WGPUBindGroupLayout {
    ffi_catch!(0, {
        ops::compute_pipeline_get_bind_group_layout(pipeline, index)
    })
}

#[export_name = "wgpun_ComputePipelineRelease"]
pub extern "C" fn wgpuComputePipelineRelease(pipeline: WGPUComputePipeline) {
    ffi_catch!((), {
        ops::compute_pipeline_release(pipeline);
    })
}

#[export_name = "wgpun_ComputePipelineRelease_p"]
pub extern "C" fn compute_pipeline_release_p(ptr: *mut std::ffi::c_void) {
    wgpuComputePipelineRelease(ptr as u64);
}
