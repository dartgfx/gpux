// FFI exports for GPU resources, command encoding, and transfer operations.
//
// Thin wrappers that deref handles and delegate to api/ modules.
// All function bodies are wrapped in ffi_catch! so wgpu-core panics
// (e.g. stale TextureView handles) are caught instead of aborting.

use std::sync::Arc;

use crate::api::resources::{self, label_from_ptr};
use crate::api::types::*;
use crate::api::{commands, transfer};
use crate::handle::*;
use crate::{ffi_catch, LAST_ERROR};

// =============================================================================
// BUFFER
// =============================================================================

#[export_name = "wgpun_DeviceCreateBuffer"]
pub extern "C" fn wgpuDeviceCreateBuffer(
    device: WGPUDevice,
    descriptor: *const WGPUBufferDescriptor,
) -> WGPUBuffer {
    if device == 0 || descriptor.is_null() { return 0; }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let desc = unsafe { &*descriptor };
        resources::device_create_buffer(&entry.device, desc)
    })
}

#[export_name = "wgpun_BufferRelease"]
pub extern "C" fn wgpuBufferRelease(buffer: WGPUBuffer) {
    ffi_catch!((), { resources::buffer_release(buffer); })
}

// =============================================================================
// QUEUE WRITE
// =============================================================================

#[export_name = "wgpun_QueueWriteBuffer"]
pub extern "C" fn wgpuQueueWriteBuffer(
    queue: WGPUQueue,
    buffer: WGPUBuffer,
    offset: u64,
    data: *const u8,
    size: u64,
) {
    if queue == 0 || buffer == 0 || data.is_null() || size == 0 { return; }
    ffi_catch!((), {
        let queue_arc = unsafe { deref_handle::<Arc<wgpu::Queue>>(queue) };
        let data = unsafe { std::slice::from_raw_parts(data, size as usize) };
        transfer::queue_write_buffer(queue_arc, buffer, offset, data);
    })
}

#[export_name = "wgpun_QueueWriteTexture"]
pub extern "C" fn wgpuQueueWriteTexture(
    queue: WGPUQueue,
    texture: WGPUTexture,
    data: *const u8,
    data_size: u64,
    bytes_per_row: u32,
    width: u32,
    height: u32,
    depth_or_array_layers: u32,
    mip_level: u32,
    origin_x: u32,
    origin_y: u32,
    origin_z: u32,
    aspect: u32,
    rows_per_image: u32,
) {
    if queue == 0 || texture == 0 || data.is_null() || data_size == 0 { return; }
    ffi_catch!((), {
        let queue_arc = unsafe { deref_handle::<Arc<wgpu::Queue>>(queue) };
        let data = unsafe { std::slice::from_raw_parts(data, data_size as usize) };
        transfer::queue_write_texture(queue_arc, texture, data, bytes_per_row, width, height, depth_or_array_layers, mip_level, origin_x, origin_y, origin_z, aspect, rows_per_image);
    })
}

// =============================================================================
// TEXTURE
// =============================================================================

#[export_name = "wgpun_DeviceCreateTexture"]
pub extern "C" fn wgpuDeviceCreateTexture(
    device: WGPUDevice,
    descriptor: *const WGPUTextureDescriptor,
) -> WGPUTexture {
    if device == 0 || descriptor.is_null() { return 0; }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let desc = unsafe { &*descriptor };
        resources::device_create_texture(&entry.device, desc)
    })
}

#[export_name = "wgpun_TextureCreateView"]
pub extern "C" fn wgpuTextureCreateView(
    texture: WGPUTexture,
    descriptor: *const WGPUTextureViewDescriptor,
) -> WGPUTextureView {
    if texture == 0 { return 0; }
    ffi_catch!(0, {
        let desc = if descriptor.is_null() { None } else { Some(unsafe { &*descriptor }) };
        resources::texture_create_view(texture, desc)
    })
}

#[export_name = "wgpun_TextureRelease"]
pub extern "C" fn wgpuTextureRelease(texture: WGPUTexture) {
    ffi_catch!((), { resources::texture_release(texture); })
}

#[export_name = "wgpun_TextureViewRelease"]
pub extern "C" fn wgpuTextureViewRelease(view: WGPUTextureView) {
    ffi_catch!((), { resources::texture_view_release(view); })
}

// =============================================================================
// SAMPLER
// =============================================================================

#[export_name = "wgpun_DeviceCreateSampler"]
pub extern "C" fn wgpuDeviceCreateSampler(
    device: WGPUDevice,
    descriptor: *const WGPUSamplerDescriptor,
) -> WGPUSampler {
    if device == 0 || descriptor.is_null() { return 0; }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let desc = unsafe { &*descriptor };
        resources::device_create_sampler(&entry.device, desc)
    })
}

#[export_name = "wgpun_SamplerRelease"]
pub extern "C" fn wgpuSamplerRelease(sampler: WGPUSampler) {
    ffi_catch!((), { resources::sampler_release(sampler); })
}

// =============================================================================
// SHADER MODULE
// =============================================================================

#[export_name = "wgpun_DeviceCreateShaderModule"]
pub extern "C" fn wgpuDeviceCreateShaderModule(
    device: WGPUDevice,
    source: *const u8,
    source_len: u32,
    label: *const std::ffi::c_char,
) -> WGPUShaderModule {
    if device == 0 || source.is_null() || source_len == 0 { return 0; }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let source = unsafe {
            let bytes = std::slice::from_raw_parts(source, source_len as usize);
            match std::str::from_utf8(bytes) {
                Ok(s) => s,
                Err(_) => return 0,
            }
        };
        let lbl = unsafe { label_from_ptr(label) };
        resources::device_create_shader_module(&entry.device, source, lbl)
    })
}

#[export_name = "wgpun_ShaderModuleGetCompilationInfo"]
pub extern "C" fn wgpuShaderModuleGetCompilationInfo(
    module: WGPUShaderModule,
) -> *const std::ffi::c_char {
    if module == 0 { return std::ptr::null(); }
    ffi_catch!(std::ptr::null(), {
        match resources::shader_module_get_compilation_info(module) {
            Some(info) => {
                LAST_ERROR.with(|e| {
                    let cstr = std::ffi::CString::new(info).unwrap_or_default();
                    let ptr = cstr.as_ptr();
                    *e.borrow_mut() = Some(cstr);
                    ptr
                })
            }
            None => std::ptr::null(),
        }
    })
}

#[export_name = "wgpun_ShaderModuleRelease"]
pub extern "C" fn wgpuShaderModuleRelease(module: WGPUShaderModule) {
    ffi_catch!((), { resources::shader_module_release(module); })
}

// =============================================================================
// BIND GROUP LAYOUT
// =============================================================================

#[export_name = "wgpun_DeviceCreateBindGroupLayout"]
pub extern "C" fn wgpuDeviceCreateBindGroupLayout(
    device: WGPUDevice,
    desc: *const WGPUBindGroupLayoutDescriptor,
) -> WGPUBindGroupLayout {
    if device == 0 || desc.is_null() { return 0; }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let desc = unsafe { &*desc };
        resources::device_create_bind_group_layout(&entry.device, desc)
    })
}

#[export_name = "wgpun_BindGroupLayoutRelease"]
pub extern "C" fn wgpuBindGroupLayoutRelease(layout: WGPUBindGroupLayout) {
    ffi_catch!((), { resources::bind_group_layout_release(layout); })
}

// =============================================================================
// BIND GROUP
// =============================================================================

#[export_name = "wgpun_DeviceCreateBindGroup"]
pub extern "C" fn wgpuDeviceCreateBindGroup(
    device: WGPUDevice,
    desc: *const WGPUBindGroupDescriptor,
) -> WGPUBindGroup {
    if device == 0 || desc.is_null() { return 0; }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let desc = unsafe { &*desc };
        resources::device_create_bind_group(&entry.device, desc)
    })
}

#[export_name = "wgpun_BindGroupRelease"]
pub extern "C" fn wgpuBindGroupRelease(group: WGPUBindGroup) {
    ffi_catch!((), { resources::bind_group_release(group); })
}

// =============================================================================
// PIPELINE LAYOUT
// =============================================================================

#[export_name = "wgpun_DeviceCreatePipelineLayout"]
pub extern "C" fn wgpuDeviceCreatePipelineLayout(
    device: WGPUDevice,
    desc: *const WGPUPipelineLayoutDescriptor,
) -> WGPUPipelineLayout {
    if device == 0 || desc.is_null() { return 0; }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let desc = unsafe { &*desc };
        resources::device_create_pipeline_layout(&entry.device, desc)
    })
}

#[export_name = "wgpun_PipelineLayoutRelease"]
pub extern "C" fn wgpuPipelineLayoutRelease(layout: WGPUPipelineLayout) {
    ffi_catch!((), { resources::pipeline_layout_release(layout); })
}

// =============================================================================
// RENDER PIPELINE
// =============================================================================

#[export_name = "wgpun_DeviceCreateRenderPipeline"]
pub extern "C" fn wgpuDeviceCreateRenderPipeline(
    device: WGPUDevice,
    desc: *const WGPURenderPipelineDescriptor,
) -> WGPURenderPipeline {
    if device == 0 || desc.is_null() { return 0; }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let desc = unsafe { &*desc };
        resources::device_create_render_pipeline(&entry.device, desc)
    })
}

#[export_name = "wgpun_RenderPipelineGetBindGroupLayout"]
pub extern "C" fn wgpuRenderPipelineGetBindGroupLayout(
    pipeline: WGPURenderPipeline,
    index: u32,
) -> WGPUBindGroupLayout {
    ffi_catch!(0, { resources::render_pipeline_get_bind_group_layout(pipeline, index) })
}

#[export_name = "wgpun_RenderPipelineRelease"]
pub extern "C" fn wgpuRenderPipelineRelease(pipeline: WGPURenderPipeline) {
    ffi_catch!((), { resources::render_pipeline_release(pipeline); })
}

// =============================================================================
// COMPUTE PIPELINE
// =============================================================================

#[export_name = "wgpun_DeviceCreateComputePipeline"]
pub extern "C" fn wgpuDeviceCreateComputePipeline(
    device: WGPUDevice,
    desc: *const WGPUComputePipelineDescriptor,
) -> WGPUComputePipeline {
    if device == 0 || desc.is_null() { return 0; }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let desc = unsafe { &*desc };
        resources::device_create_compute_pipeline(&entry.device, desc)
    })
}

#[export_name = "wgpun_ComputePipelineGetBindGroupLayout"]
pub extern "C" fn wgpuComputePipelineGetBindGroupLayout(
    pipeline: WGPUComputePipeline,
    index: u32,
) -> WGPUBindGroupLayout {
    ffi_catch!(0, { resources::compute_pipeline_get_bind_group_layout(pipeline, index) })
}

#[export_name = "wgpun_ComputePipelineRelease"]
pub extern "C" fn wgpuComputePipelineRelease(pipeline: WGPUComputePipeline) {
    ffi_catch!((), { resources::compute_pipeline_release(pipeline); })
}

// =============================================================================
// NATIVE FINALIZER WRAPPERS
// =============================================================================
//
// NativeFinalizer in Dart FFI requires `void (*)(void*)` signatures.
// Our release functions take `u64`. These thin wrappers bridge the gap.

#[export_name = "wgpun_BindGroupRelease_p"]
pub extern "C" fn bind_group_release_p(ptr: *mut std::ffi::c_void) {
    wgpuBindGroupRelease(ptr as u64);
}

#[export_name = "wgpun_BindGroupLayoutRelease_p"]
pub extern "C" fn bind_group_layout_release_p(ptr: *mut std::ffi::c_void) {
    wgpuBindGroupLayoutRelease(ptr as u64);
}

#[export_name = "wgpun_PipelineLayoutRelease_p"]
pub extern "C" fn pipeline_layout_release_p(ptr: *mut std::ffi::c_void) {
    wgpuPipelineLayoutRelease(ptr as u64);
}

#[export_name = "wgpun_RenderPipelineRelease_p"]
pub extern "C" fn render_pipeline_release_p(ptr: *mut std::ffi::c_void) {
    wgpuRenderPipelineRelease(ptr as u64);
}

#[export_name = "wgpun_ComputePipelineRelease_p"]
pub extern "C" fn compute_pipeline_release_p(ptr: *mut std::ffi::c_void) {
    wgpuComputePipelineRelease(ptr as u64);
}

#[export_name = "wgpun_SamplerRelease_p"]
pub extern "C" fn sampler_release_p(ptr: *mut std::ffi::c_void) {
    wgpuSamplerRelease(ptr as u64);
}

#[export_name = "wgpun_ShaderModuleRelease_p"]
pub extern "C" fn shader_module_release_p(ptr: *mut std::ffi::c_void) {
    wgpuShaderModuleRelease(ptr as u64);
}

#[export_name = "wgpun_TextureViewRelease_p"]
pub extern "C" fn texture_view_release_p(ptr: *mut std::ffi::c_void) {
    wgpuTextureViewRelease(ptr as u64);
}

#[export_name = "wgpun_BufferRelease_p"]
pub extern "C" fn buffer_release_p(ptr: *mut std::ffi::c_void) {
    wgpuBufferRelease(ptr as u64);
}

#[export_name = "wgpun_TextureRelease_p"]
pub extern "C" fn texture_release_p(ptr: *mut std::ffi::c_void) {
    wgpuTextureRelease(ptr as u64);
}

#[export_name = "wgpun_QuerySetRelease_p"]
pub extern "C" fn query_set_release_p(ptr: *mut std::ffi::c_void) {
    wgpuQuerySetRelease(ptr as u64);
}

#[export_name = "wgpun_FenceRelease_p"]
pub extern "C" fn fence_release_p(ptr: *mut std::ffi::c_void) {
    wgpuFenceRelease(ptr as u64);
}

#[export_name = "wgpun_BufferMappingRelease_p"]
pub extern "C" fn buffer_mapping_release_p(ptr: *mut std::ffi::c_void) {
    let handle = ptr as u64;
    if handle == 0 { return; }
    ffi_catch!((), { transfer::buffer_unmap(handle); })
}

// =============================================================================
// COMMAND ENCODER
// =============================================================================

#[export_name = "wgpun_DeviceCreateCommandEncoder"]
pub extern "C" fn wgpuDeviceCreateCommandEncoder(device: WGPUDevice, label: *const std::ffi::c_char) -> WGPUCommandEncoder {
    if device == 0 { return 0; }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let lbl = unsafe { label_from_ptr(label) };
        commands::device_create_command_encoder(&entry.device, lbl)
    })
}

#[export_name = "wgpun_CommandEncoderFinish"]
pub extern "C" fn wgpuCommandEncoderFinish(encoder: WGPUCommandEncoder) -> WGPUCommandBuffer {
    if encoder == 0 { return 0; }
    ffi_catch!(0, { commands::command_encoder_finish(encoder) })
}

#[export_name = "wgpun_CommandEncoderInsertDebugMarker"]
pub extern "C" fn wgpuCommandEncoderInsertDebugMarker(
    encoder: WGPUCommandEncoder,
    label: *const std::ffi::c_char,
) {
    if encoder == 0 { return; }
    ffi_catch!((), { commands::command_encoder_insert_debug_marker(encoder, label); })
}

#[export_name = "wgpun_CommandEncoderPushDebugGroup"]
pub extern "C" fn wgpuCommandEncoderPushDebugGroup(
    encoder: WGPUCommandEncoder,
    label: *const std::ffi::c_char,
) {
    if encoder == 0 { return; }
    ffi_catch!((), { commands::command_encoder_push_debug_group(encoder, label); })
}

#[export_name = "wgpun_CommandEncoderPopDebugGroup"]
pub extern "C" fn wgpuCommandEncoderPopDebugGroup(
    encoder: WGPUCommandEncoder,
) {
    if encoder == 0 { return; }
    ffi_catch!((), { commands::command_encoder_pop_debug_group(encoder); })
}

#[export_name = "wgpun_CommandEncoderCopyBufferToBuffer"]
pub extern "C" fn wgpuCommandEncoderCopyBufferToBuffer(
    encoder: WGPUCommandEncoder,
    source: WGPUBuffer,
    source_offset: u64,
    destination: WGPUBuffer,
    destination_offset: u64,
    size: u64,
) -> u8 {
    if encoder == 0 || source == 0 || destination == 0 { return 0; }
    ffi_catch!(0, {
        commands::command_encoder_copy_buffer_to_buffer(encoder, source, source_offset, destination, destination_offset, size);
        1
    })
}

#[export_name = "wgpun_CommandEncoderClearBuffer"]
pub extern "C" fn wgpuCommandEncoderClearBuffer(
    encoder: WGPUCommandEncoder,
    buffer: WGPUBuffer,
    offset: u64,
    size: u64,
) -> u8 {
    if encoder == 0 || buffer == 0 { return 0; }
    ffi_catch!(0, {
        let size_opt = if size == 0 { None } else { Some(size) };
        commands::command_encoder_clear_buffer(encoder, buffer, offset, size_opt);
        1
    })
}

#[export_name = "wgpun_CommandEncoderCopyTextureToBuffer"]
pub extern "C" fn wgpuCommandEncoderCopyTextureToBuffer(
    encoder: WGPUCommandEncoder,
    texture: WGPUTexture,
    buffer: WGPUBuffer,
    bytes_per_row: u32,
    rows_per_image: u32,
    width: u32,
    height: u32,
    depth: u32,
    mip_level: u32,
    origin_x: u32,
    origin_y: u32,
    origin_z: u32,
) -> u8 {
    if encoder == 0 || texture == 0 || buffer == 0 { return 0; }
    ffi_catch!(0, {
        commands::command_encoder_copy_texture_to_buffer(encoder, texture, buffer, bytes_per_row, rows_per_image, width, height, depth, mip_level, origin_x, origin_y, origin_z);
        1
    })
}

#[export_name = "wgpun_CommandEncoderCopyBufferToTexture"]
pub extern "C" fn wgpuCommandEncoderCopyBufferToTexture(
    encoder: WGPUCommandEncoder,
    buffer: WGPUBuffer,
    texture: WGPUTexture,
    bytes_per_row: u32,
    rows_per_image: u32,
    width: u32,
    height: u32,
    depth: u32,
    mip_level: u32,
    origin_x: u32,
    origin_y: u32,
    origin_z: u32,
) -> u8 {
    if encoder == 0 || buffer == 0 || texture == 0 { return 0; }
    ffi_catch!(0, {
        commands::command_encoder_copy_buffer_to_texture(encoder, buffer, texture, bytes_per_row, rows_per_image, width, height, depth, mip_level, origin_x, origin_y, origin_z);
        1
    })
}

#[export_name = "wgpun_CommandEncoderCopyTextureToTexture"]
pub extern "C" fn wgpuCommandEncoderCopyTextureToTexture(
    encoder: WGPUCommandEncoder,
    src_texture: WGPUTexture,
    dst_texture: WGPUTexture,
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
) -> u8 {
    if encoder == 0 || src_texture == 0 || dst_texture == 0 { return 0; }
    ffi_catch!(0, {
        commands::command_encoder_copy_texture_to_texture(encoder, src_texture, dst_texture, width, height, depth, src_mip_level, src_origin_x, src_origin_y, src_origin_z, dst_mip_level, dst_origin_x, dst_origin_y, dst_origin_z);
        1
    })
}

// =============================================================================
// QUEUE SUBMIT
// =============================================================================

#[export_name = "wgpun_QueueSubmit"]
pub extern "C" fn wgpuQueueSubmit(
    queue: WGPUQueue,
    command_buffers: *const WGPUCommandBuffer,
    count: u32,
) {
    if queue == 0 || command_buffers.is_null() || count == 0 { return; }
    ffi_catch!((), {
        let queue_arc = unsafe { deref_handle::<Arc<wgpu::Queue>>(queue) };
        let buffers = unsafe { std::slice::from_raw_parts(command_buffers, count as usize) };
        transfer::queue_submit(queue_arc, buffers);
    })
}

// =============================================================================
// RENDER PASS
// =============================================================================

#[export_name = "wgpun_CommandEncoderBeginRenderPass"]
pub extern "C" fn wgpuCommandEncoderBeginRenderPass(
    encoder: WGPUCommandEncoder,
    descriptor: *const WGPURenderPassDescriptor,
) -> WGPURenderPassEncoder {
    if encoder == 0 || descriptor.is_null() { return 0; }
    ffi_catch!(0, {
        let desc = unsafe { &*descriptor };
        commands::command_encoder_begin_render_pass(encoder, desc)
    })
}

#[export_name = "wgpun_RenderPassEncoderSetPipeline"]
pub extern "C" fn wgpuRenderPassEncoderSetPipeline(
    render_pass: WGPURenderPassEncoder,
    pipeline: WGPURenderPipeline,
) {
    if render_pass == 0 || pipeline == 0 { return; }
    ffi_catch!((), { commands::render_pass_set_pipeline(render_pass, pipeline); })
}

#[export_name = "wgpun_RenderPassEncoderSetBindGroup"]
pub extern "C" fn wgpuRenderPassEncoderSetBindGroup(
    render_pass: WGPURenderPassEncoder,
    index: u32,
    bind_group: WGPUBindGroup,
    dynamic_offsets: *const u32,
    dynamic_offset_count: u32,
) {
    if render_pass == 0 || bind_group == 0 { return; }
    ffi_catch!((), {
        let offsets = if dynamic_offset_count > 0 && !dynamic_offsets.is_null() {
            unsafe { std::slice::from_raw_parts(dynamic_offsets, dynamic_offset_count as usize) }
        } else {
            &[]
        };
        commands::render_pass_set_bind_group(render_pass, index, bind_group, offsets);
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
    if render_pass == 0 || buffer == 0 { return; }
    ffi_catch!((), { commands::render_pass_set_vertex_buffer(render_pass, slot, buffer, offset, size); })
}

#[export_name = "wgpun_RenderPassEncoderSetIndexBuffer"]
pub extern "C" fn wgpuRenderPassEncoderSetIndexBuffer(
    render_pass: WGPURenderPassEncoder,
    buffer: WGPUBuffer,
    format: u32,
    offset: u64,
    size: u64,
) {
    if render_pass == 0 || buffer == 0 { return; }
    ffi_catch!((), { commands::render_pass_set_index_buffer(render_pass, buffer, format, offset, size); })
}

#[export_name = "wgpun_RenderPassEncoderDraw"]
pub extern "C" fn wgpuRenderPassEncoderDraw(
    render_pass: WGPURenderPassEncoder,
    vertex_count: u32,
    instance_count: u32,
    first_vertex: u32,
    first_instance: u32,
) {
    if render_pass == 0 { return; }
    ffi_catch!((), { commands::render_pass_draw(render_pass, vertex_count, instance_count, first_vertex, first_instance); })
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
    if render_pass == 0 { return; }
    ffi_catch!((), { commands::render_pass_draw_indexed(render_pass, index_count, instance_count, first_index, base_vertex, first_instance); })
}

#[export_name = "wgpun_RenderPassEncoderMultiDrawIndexedIndirect"]
pub extern "C" fn wgpuRenderPassEncoderMultiDrawIndexedIndirect(
    render_pass: WGPURenderPassEncoder,
    indirect_buffer: WGPUBuffer,
    indirect_offset: u64,
    count: u32,
) {
    if render_pass == 0 || indirect_buffer == 0 { return; }
    ffi_catch!((), { commands::render_pass_multi_draw_indexed_indirect(render_pass, indirect_buffer, indirect_offset, count); })
}

#[export_name = "wgpun_RenderPassEncoderDrawIndirect"]
pub extern "C" fn wgpuRenderPassEncoderDrawIndirect(
    render_pass: WGPURenderPassEncoder,
    indirect_buffer: WGPUBuffer,
    indirect_offset: u64,
) {
    if render_pass == 0 || indirect_buffer == 0 { return; }
    ffi_catch!((), { commands::render_pass_draw_indirect(render_pass, indirect_buffer, indirect_offset); })
}

#[export_name = "wgpun_RenderPassEncoderDrawIndexedIndirect"]
pub extern "C" fn wgpuRenderPassEncoderDrawIndexedIndirect(
    render_pass: WGPURenderPassEncoder,
    indirect_buffer: WGPUBuffer,
    indirect_offset: u64,
) {
    if render_pass == 0 || indirect_buffer == 0 { return; }
    ffi_catch!((), { commands::render_pass_draw_indexed_indirect(render_pass, indirect_buffer, indirect_offset); })
}

#[export_name = "wgpun_RenderPassEncoderBeginOcclusionQuery"]
pub extern "C" fn wgpuRenderPassEncoderBeginOcclusionQuery(
    render_pass: WGPURenderPassEncoder,
    query_index: u32,
) {
    if render_pass == 0 { return; }
    ffi_catch!((), { commands::render_pass_begin_occlusion_query(render_pass, query_index); })
}

#[export_name = "wgpun_RenderPassEncoderEndOcclusionQuery"]
pub extern "C" fn wgpuRenderPassEncoderEndOcclusionQuery(
    render_pass: WGPURenderPassEncoder,
) {
    if render_pass == 0 { return; }
    ffi_catch!((), { commands::render_pass_end_occlusion_query(render_pass); })
}

#[export_name = "wgpun_RenderPassEncoderSetViewport"]
pub extern "C" fn wgpuRenderPassEncoderSetViewport(
    render_pass: WGPURenderPassEncoder,
    x: f32, y: f32, width: f32, height: f32, min_depth: f32, max_depth: f32,
) {
    if render_pass == 0 { return; }
    ffi_catch!((), { commands::render_pass_set_viewport(render_pass, x, y, width, height, min_depth, max_depth); })
}

#[export_name = "wgpun_RenderPassEncoderSetScissorRect"]
pub extern "C" fn wgpuRenderPassEncoderSetScissorRect(
    render_pass: WGPURenderPassEncoder,
    x: u32, y: u32, width: u32, height: u32,
) {
    if render_pass == 0 { return; }
    ffi_catch!((), { commands::render_pass_set_scissor_rect(render_pass, x, y, width, height); })
}

#[export_name = "wgpun_RenderPassEncoderSetBlendConstant"]
pub extern "C" fn wgpuRenderPassEncoderSetBlendConstant(
    render_pass: WGPURenderPassEncoder,
    r: f64,
    g: f64,
    b: f64,
    a: f64,
) {
    if render_pass == 0 { return; }
    ffi_catch!((), { commands::render_pass_set_blend_constant(render_pass, r, g, b, a); })
}

#[export_name = "wgpun_RenderPassEncoderSetStencilReference"]
pub extern "C" fn wgpuRenderPassEncoderSetStencilReference(
    render_pass: WGPURenderPassEncoder,
    reference: u32,
) {
    if render_pass == 0 { return; }
    ffi_catch!((), { commands::render_pass_set_stencil_reference(render_pass, reference); })
}

#[export_name = "wgpun_RenderPassEncoderInsertDebugMarker"]
pub extern "C" fn wgpuRenderPassEncoderInsertDebugMarker(
    render_pass: WGPURenderPassEncoder,
    label: *const std::ffi::c_char,
) {
    if render_pass == 0 { return; }
    ffi_catch!((), { commands::render_pass_insert_debug_marker(render_pass, label); })
}

#[export_name = "wgpun_RenderPassEncoderPushDebugGroup"]
pub extern "C" fn wgpuRenderPassEncoderPushDebugGroup(
    render_pass: WGPURenderPassEncoder,
    label: *const std::ffi::c_char,
) {
    if render_pass == 0 { return; }
    ffi_catch!((), { commands::render_pass_push_debug_group(render_pass, label); })
}

#[export_name = "wgpun_RenderPassEncoderPopDebugGroup"]
pub extern "C" fn wgpuRenderPassEncoderPopDebugGroup(
    render_pass: WGPURenderPassEncoder,
) {
    if render_pass == 0 { return; }
    ffi_catch!((), { commands::render_pass_pop_debug_group(render_pass); })
}

#[export_name = "wgpun_RenderPassEncoderSetImmediates"]
pub extern "C" fn wgpuRenderPassEncoderSetImmediates(
    render_pass: WGPURenderPassEncoder,
    offset: u32,
    data: *const u8,
    data_len: u32,
) {
    if render_pass == 0 || data.is_null() || data_len == 0 { return; }
    ffi_catch!((), { commands::render_pass_set_immediates(render_pass, offset, data, data_len); })
}

#[export_name = "wgpun_RenderPassEncoderEnd"]
pub extern "C" fn wgpuRenderPassEncoderEnd(
    render_pass: WGPURenderPassEncoder,
) -> WGPUCommandEncoder {
    if render_pass == 0 { return 0; }
    ffi_catch!(0, { commands::render_pass_end_returning_encoder(render_pass) })
}

// =============================================================================
// COMPUTE PASS
// =============================================================================

#[export_name = "wgpun_CommandEncoderBeginComputePass"]
pub extern "C" fn wgpuCommandEncoderBeginComputePass(
    encoder: WGPUCommandEncoder,
    descriptor: *const WGPUComputePassDescriptor,
) -> WGPUComputePassEncoder {
    if encoder == 0 { return 0; }
    ffi_catch!(0, {
        let desc = if descriptor.is_null() { None } else { Some(unsafe { &*descriptor }) };
        commands::command_encoder_begin_compute_pass(encoder, desc)
    })
}

#[export_name = "wgpun_ComputePassEncoderSetPipeline"]
pub extern "C" fn wgpuComputePassEncoderSetPipeline(
    compute_pass: WGPUComputePassEncoder,
    pipeline: WGPUComputePipeline,
) {
    if compute_pass == 0 || pipeline == 0 { return; }
    ffi_catch!((), { commands::compute_pass_set_pipeline(compute_pass, pipeline); })
}

#[export_name = "wgpun_ComputePassEncoderSetBindGroup"]
pub extern "C" fn wgpuComputePassEncoderSetBindGroup(
    compute_pass: WGPUComputePassEncoder,
    index: u32,
    bind_group: WGPUBindGroup,
    dynamic_offsets: *const u32,
    dynamic_offset_count: u32,
) {
    if compute_pass == 0 || bind_group == 0 { return; }
    ffi_catch!((), {
        let offsets = if dynamic_offset_count > 0 && !dynamic_offsets.is_null() {
            unsafe { std::slice::from_raw_parts(dynamic_offsets, dynamic_offset_count as usize) }
        } else {
            &[]
        };
        commands::compute_pass_set_bind_group(compute_pass, index, bind_group, offsets);
    })
}

#[export_name = "wgpun_ComputePassEncoderDispatchWorkgroups"]
pub extern "C" fn wgpuComputePassEncoderDispatchWorkgroups(
    compute_pass: WGPUComputePassEncoder,
    x: u32, y: u32, z: u32,
) {
    if compute_pass == 0 { return; }
    ffi_catch!((), { commands::compute_pass_dispatch_workgroups(compute_pass, x, y, z); })
}

#[export_name = "wgpun_ComputePassEncoderDispatchWorkgroupsIndirect"]
pub extern "C" fn wgpuComputePassEncoderDispatchWorkgroupsIndirect(
    compute_pass: WGPUComputePassEncoder,
    indirect_buffer: WGPUBuffer,
    indirect_offset: u64,
) {
    if compute_pass == 0 || indirect_buffer == 0 { return; }
    ffi_catch!((), { commands::compute_pass_dispatch_workgroups_indirect(compute_pass, indirect_buffer, indirect_offset); })
}

#[export_name = "wgpun_ComputePassEncoderInsertDebugMarker"]
pub extern "C" fn wgpuComputePassEncoderInsertDebugMarker(
    compute_pass: WGPUComputePassEncoder,
    label: *const std::ffi::c_char,
) {
    if compute_pass == 0 { return; }
    ffi_catch!((), { commands::compute_pass_insert_debug_marker(compute_pass, label); })
}

#[export_name = "wgpun_ComputePassEncoderPushDebugGroup"]
pub extern "C" fn wgpuComputePassEncoderPushDebugGroup(
    compute_pass: WGPUComputePassEncoder,
    label: *const std::ffi::c_char,
) {
    if compute_pass == 0 { return; }
    ffi_catch!((), { commands::compute_pass_push_debug_group(compute_pass, label); })
}

#[export_name = "wgpun_ComputePassEncoderPopDebugGroup"]
pub extern "C" fn wgpuComputePassEncoderPopDebugGroup(
    compute_pass: WGPUComputePassEncoder,
) {
    if compute_pass == 0 { return; }
    ffi_catch!((), { commands::compute_pass_pop_debug_group(compute_pass); })
}

#[export_name = "wgpun_ComputePassEncoderSetImmediates"]
pub extern "C" fn wgpuComputePassEncoderSetImmediates(
    compute_pass: WGPUComputePassEncoder,
    offset: u32,
    data: *const u8,
    data_len: u32,
) {
    if compute_pass == 0 || data.is_null() || data_len == 0 { return; }
    ffi_catch!((), { commands::compute_pass_set_immediates(compute_pass, offset, data, data_len); })
}

#[export_name = "wgpun_ComputePassEncoderEnd"]
pub extern "C" fn wgpuComputePassEncoderEnd(
    compute_pass: WGPUComputePassEncoder,
) -> WGPUCommandEncoder {
    if compute_pass == 0 { return 0; }
    ffi_catch!(0, { commands::compute_pass_end(compute_pass) })
}

// =============================================================================
// RENDER BUNDLE
// =============================================================================

#[export_name = "wgpun_DeviceCreateRenderBundleEncoder"]
pub extern "C" fn wgpuDeviceCreateRenderBundleEncoder(
    device: WGPUDevice,
    descriptor: *const WGPURenderBundleEncoderDescriptor,
) -> WGPURenderBundleEncoder {
    if device == 0 || descriptor.is_null() { return 0; }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let desc = unsafe { &*descriptor };
        commands::device_create_render_bundle_encoder(&entry.device, desc)
    })
}

#[export_name = "wgpun_RenderBundleEncoderSetPipeline"]
pub extern "C" fn wgpuRenderBundleEncoderSetPipeline(
    encoder: WGPURenderBundleEncoder,
    pipeline: WGPURenderPipeline,
) {
    if encoder == 0 || pipeline == 0 { return; }
    ffi_catch!((), { commands::render_bundle_encoder_set_pipeline(encoder, pipeline); })
}

#[export_name = "wgpun_RenderBundleEncoderSetBindGroup"]
pub extern "C" fn wgpuRenderBundleEncoderSetBindGroup(
    encoder: WGPURenderBundleEncoder,
    index: u32,
    bind_group: WGPUBindGroup,
    dynamic_offsets: *const u32,
    dynamic_offset_count: u32,
) {
    if encoder == 0 || bind_group == 0 { return; }
    ffi_catch!((), {
        let offsets = if dynamic_offset_count > 0 && !dynamic_offsets.is_null() {
            unsafe { std::slice::from_raw_parts(dynamic_offsets, dynamic_offset_count as usize) }
        } else {
            &[]
        };
        commands::render_bundle_encoder_set_bind_group(encoder, index, bind_group, offsets);
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
    if encoder == 0 || buffer == 0 { return; }
    ffi_catch!((), { commands::render_bundle_encoder_set_vertex_buffer(encoder, slot, buffer, offset, size); })
}

#[export_name = "wgpun_RenderBundleEncoderSetIndexBuffer"]
pub extern "C" fn wgpuRenderBundleEncoderSetIndexBuffer(
    encoder: WGPURenderBundleEncoder,
    buffer: WGPUBuffer,
    format: u32,
    offset: u64,
    size: u64,
) {
    if encoder == 0 || buffer == 0 { return; }
    ffi_catch!((), { commands::render_bundle_encoder_set_index_buffer(encoder, buffer, format, offset, size); })
}

#[export_name = "wgpun_RenderBundleEncoderDraw"]
pub extern "C" fn wgpuRenderBundleEncoderDraw(
    encoder: WGPURenderBundleEncoder,
    vertex_count: u32,
    instance_count: u32,
    first_vertex: u32,
    first_instance: u32,
) {
    if encoder == 0 { return; }
    ffi_catch!((), { commands::render_bundle_encoder_draw(encoder, vertex_count, instance_count, first_vertex, first_instance); })
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
    if encoder == 0 { return; }
    ffi_catch!((), { commands::render_bundle_encoder_draw_indexed(encoder, index_count, instance_count, first_index, base_vertex, first_instance); })
}

#[export_name = "wgpun_RenderBundleEncoderDrawIndirect"]
pub extern "C" fn wgpuRenderBundleEncoderDrawIndirect(
    encoder: WGPURenderBundleEncoder,
    indirect_buffer: WGPUBuffer,
    indirect_offset: u64,
) {
    if encoder == 0 || indirect_buffer == 0 { return; }
    ffi_catch!((), { commands::render_bundle_encoder_draw_indirect(encoder, indirect_buffer, indirect_offset); })
}

#[export_name = "wgpun_RenderBundleEncoderDrawIndexedIndirect"]
pub extern "C" fn wgpuRenderBundleEncoderDrawIndexedIndirect(
    encoder: WGPURenderBundleEncoder,
    indirect_buffer: WGPUBuffer,
    indirect_offset: u64,
) {
    if encoder == 0 || indirect_buffer == 0 { return; }
    ffi_catch!((), { commands::render_bundle_encoder_draw_indexed_indirect(encoder, indirect_buffer, indirect_offset); })
}

#[export_name = "wgpun_RenderBundleEncoderSetImmediates"]
pub extern "C" fn wgpuRenderBundleEncoderSetImmediates(
    encoder: WGPURenderBundleEncoder,
    offset: u32,
    data: *const u8,
    data_len: u32,
) {
    if encoder == 0 || data.is_null() || data_len == 0 { return; }
    ffi_catch!((), { commands::render_bundle_encoder_set_immediates(encoder, offset, data, data_len); })
}

#[export_name = "wgpun_RenderBundleEncoderFinish"]
pub extern "C" fn wgpuRenderBundleEncoderFinish(
    encoder: WGPURenderBundleEncoder,
    label: *const std::ffi::c_char,
) -> WGPURenderBundle {
    if encoder == 0 { return 0; }
    ffi_catch!(0, { commands::render_bundle_encoder_finish(encoder, label) })
}

#[export_name = "wgpun_RenderPassExecuteBundles"]
pub extern "C" fn wgpuRenderPassExecuteBundles(
    render_pass: WGPURenderPassEncoder,
    bundles: *const WGPURenderBundle,
    count: u32,
) {
    if render_pass == 0 || bundles.is_null() || count == 0 { return; }
    ffi_catch!((), {
        let bundle_slice = unsafe { std::slice::from_raw_parts(bundles, count as usize) };
        commands::render_pass_execute_bundles(render_pass, bundle_slice);
    })
}

#[export_name = "wgpun_RenderBundleRelease"]
pub extern "C" fn wgpuRenderBundleRelease(bundle: WGPURenderBundle) {
    if bundle == 0 { return; }
    ffi_catch!((), { commands::render_bundle_release(bundle); })
}

#[export_name = "wgpun_RenderBundleRelease_p"]
pub extern "C" fn render_bundle_release_p(ptr: *mut std::ffi::c_void) {
    wgpuRenderBundleRelease(ptr as u64);
}

// =============================================================================
// BUFFER READBACK
// =============================================================================

#[export_name = "wgpun_BufferReadSync"]
pub extern "C" fn wgpuBufferReadSync(
    device: WGPUDevice,
    buffer: WGPUBuffer,
    offset: u64,
    size: u64,
    output: *mut u8,
) -> u64 {
    if device == 0 || buffer == 0 || output.is_null() || size == 0 { return 0; }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let output_slice = unsafe { std::slice::from_raw_parts_mut(output, size as usize) };
        transfer::buffer_read_sync(&entry.device, &entry.queue, buffer, offset, size, output_slice)
    })
}

// =============================================================================
// QUERY SET
// =============================================================================

#[export_name = "wgpun_DeviceCreateQuerySet"]
pub extern "C" fn wgpuDeviceCreateQuerySet(device: WGPUDevice, query_type: u32, count: u32, label: *const std::ffi::c_char) -> WGPUQuerySet {
    if device == 0 { return 0; }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let lbl = unsafe { label_from_ptr(label) };
        commands::device_create_query_set(&entry.device, query_type, count, lbl)
    })
}

#[export_name = "wgpun_QuerySetRelease"]
pub extern "C" fn wgpuQuerySetRelease(query_set: WGPUQuerySet) {
    if query_set == 0 { return; }
    ffi_catch!((), { commands::query_set_release(query_set); })
}

#[export_name = "wgpun_CommandEncoderWriteTimestamp"]
pub extern "C" fn wgpuCommandEncoderWriteTimestamp(
    encoder: WGPUCommandEncoder,
    query_set: WGPUQuerySet,
    query_index: u32,
) -> u8 {
    if encoder == 0 || query_set == 0 { return 0; }
    ffi_catch!(0, {
        commands::command_encoder_write_timestamp(encoder, query_set, query_index);
        1
    })
}

#[export_name = "wgpun_CommandEncoderResolveQuerySet"]
pub extern "C" fn wgpuCommandEncoderResolveQuerySet(
    encoder: WGPUCommandEncoder,
    query_set: WGPUQuerySet,
    first_query: u32,
    query_count: u32,
    destination: WGPUBuffer,
    destination_offset: u64,
) -> u8 {
    if encoder == 0 || query_set == 0 || destination == 0 { return 0; }
    ffi_catch!(0, {
        commands::command_encoder_resolve_query_set(encoder, query_set, first_query, query_count, destination, destination_offset);
        1
    })
}

#[export_name = "wgpun_QueueGetTimestampPeriod"]
pub extern "C" fn wgpuQueueGetTimestampPeriod(queue: WGPUQueue) -> f32 {
    if queue == 0 { return 0.0; }
    ffi_catch!(0.0, {
        let queue_arc = unsafe { deref_handle::<Arc<wgpu::Queue>>(queue) };
        transfer::queue_get_timestamp_period(queue_arc)
    })
}

// =============================================================================
// ASYNC BUFFER MAPPING
// =============================================================================

#[export_name = "wgpun_BufferMapStart"]
pub extern "C" fn wgpuBufferMapStart(
    device: WGPUDevice,
    buffer: WGPUBuffer,
    offset: u64,
    size: u64,
    mode: u32,
) -> WGPUBufferMapping {
    if device == 0 || buffer == 0 { return 0; }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        transfer::buffer_map_start(&entry.device, &entry.queue, buffer, offset, size, mode)
    })
}

#[export_name = "wgpun_BufferMapStatus"]
pub extern "C" fn wgpuBufferMapStatus(handle: WGPUBufferMapping) -> i32 {
    if handle == 0 { return -1; }
    ffi_catch!(-1, { transfer::buffer_map_status(handle) })
}

#[export_name = "wgpun_BufferMapGetPointer"]
pub extern "C" fn wgpuBufferMapGetPointer(handle: WGPUBufferMapping) -> *const u8 {
    if handle == 0 { return std::ptr::null(); }
    ffi_catch!(std::ptr::null(), { transfer::buffer_map_get_pointer(handle) })
}

#[export_name = "wgpun_BufferMapGetPointerMut"]
pub extern "C" fn wgpuBufferMapGetPointerMut(handle: WGPUBufferMapping) -> *mut u8 {
    if handle == 0 { return std::ptr::null_mut(); }
    ffi_catch!(std::ptr::null_mut(), { transfer::buffer_map_get_pointer_mut(handle) })
}

#[export_name = "wgpun_BufferMapGetSize"]
pub extern "C" fn wgpuBufferMapGetSize(handle: WGPUBufferMapping) -> u64 {
    if handle == 0 { return 0; }
    ffi_catch!(0, { transfer::buffer_map_get_size(handle) })
}

#[export_name = "wgpun_BufferUnmap"]
pub extern "C" fn wgpuBufferUnmap(handle: WGPUBufferMapping, _original_buffer_id: WGPUBuffer) {
    if handle == 0 { return; }
    ffi_catch!((), { transfer::buffer_unmap(handle); })
}

// =============================================================================
// FENCES
// =============================================================================

#[export_name = "wgpun_QueueSubmitFenced"]
pub extern "C" fn wgpuQueueSubmitFenced(
    queue: WGPUQueue,
    command_buffers: *const WGPUCommandBuffer,
    count: u32,
) -> WGPUFence {
    if queue == 0 { return 0; }
    ffi_catch!(0, {
        let queue_arc = unsafe { deref_handle::<Arc<wgpu::Queue>>(queue) };
        let buffers = if count > 0 && !command_buffers.is_null() {
            unsafe { std::slice::from_raw_parts(command_buffers, count as usize) }
        } else { &[] };
        transfer::queue_submit_fenced(queue_arc, buffers)
    })
}

#[export_name = "wgpun_FenceStatus"]
pub extern "C" fn wgpuFenceStatus(device: WGPUDevice, handle: WGPUFence) -> i32 {
    if device == 0 || handle == 0 { return 1; }
    ffi_catch!(1, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        transfer::fence_status(&entry.device, handle)
    })
}

#[export_name = "wgpun_FenceWait"]
pub extern "C" fn wgpuFenceWait(device: WGPUDevice, handle: WGPUFence) -> u32 {
    if device == 0 || handle == 0 { return 0; }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        transfer::fence_wait(&entry.device, handle)
    })
}

#[export_name = "wgpun_FenceRelease"]
pub extern "C" fn wgpuFenceRelease(handle: WGPUFence) {
    if handle == 0 { return; }
    ffi_catch!((), { transfer::fence_release(handle); })
}
