// Handle type aliases and #[repr(C)] descriptor structs for FFI.

use std::sync::atomic::AtomicI32;
use std::sync::Arc;

// =============================================================================
// HANDLE TYPES
// =============================================================================

pub type WGPUInstance = u64;
pub type WGPUAdapter = u64;
pub type WGPUDevice = u64;
pub type WGPUQueue = u64;
pub type WGPUBuffer = u64;
pub type WGPUTexture = u64;
pub type WGPUTextureView = u64;
pub type WGPUSampler = u64;
pub type WGPUShaderModule = u64;
pub type WGPUBindGroupLayout = u64;
pub type WGPUBindGroup = u64;
pub type WGPUPipelineLayout = u64;
pub type WGPURenderPipeline = u64;
pub type WGPUComputePipeline = u64;
pub type WGPUCommandEncoder = u64;
pub type WGPUCommandBuffer = u64;
pub type WGPURenderPassEncoder = u64;
pub type WGPUComputePassEncoder = u64;
pub type WGPUQuerySet = u64;
pub type WGPUBufferMapping = u64;
pub type WGPUFence = u64;
pub type WGPURenderBundleEncoder = u64;
pub type WGPURenderBundle = u64;

// =============================================================================
// INSTANCE/ADAPTER/DEVICE DESCRIPTOR STRUCTS
// =============================================================================

#[repr(C)]
pub struct WGPUInstanceDescriptor {
    pub validation: u8,
    pub gpu_based_validation: u8,
    /// Backend bitmask: Noop=1, Vulkan=2, Metal=4, DX12=8, GL=16, BrowserWebGpu=32.
    /// 0 = all backends (default).
    pub backends: u32,
}

#[repr(C)]
pub struct WGPURequestAdapterOptions {
    pub power_preference: u32,
    pub force_fallback_adapter: u8,
}

#[repr(C)]
pub struct WGPUAdapterInfo {
    pub vendor: *const std::os::raw::c_char,
    pub architecture: *const std::os::raw::c_char,
    pub device: *const std::os::raw::c_char,
    pub description: *const std::os::raw::c_char,
    pub backend_type: u32,
    pub adapter_type: u32,
    pub vendor_id: u32,
    pub device_id: u32,
    /// Vulkan API version (VK_MAKE_API_VERSION packed u32), 0 on non-Vulkan.
    pub driver_api_version: u32,
}

#[repr(C)]
pub struct WGPUDeviceLimits {
    pub max_texture_dimension_1d: u32,
    pub max_texture_dimension_2d: u32,
    pub max_texture_dimension_3d: u32,
    pub max_texture_array_layers: u32,
    pub max_bind_groups: u32,
    pub max_bind_groups_plus_vertex_buffers: u32,
    pub max_bindings_per_bind_group: u32,
    pub max_dynamic_uniform_buffers_per_pipeline_layout: u32,
    pub max_dynamic_storage_buffers_per_pipeline_layout: u32,
    pub max_sampled_textures_per_shader_stage: u32,
    pub max_samplers_per_shader_stage: u32,
    pub max_storage_buffers_per_shader_stage: u32,
    pub max_storage_textures_per_shader_stage: u32,
    pub max_uniform_buffers_per_shader_stage: u32,
    pub max_uniform_buffer_binding_size: u64,
    pub max_storage_buffer_binding_size: u64,
    pub min_uniform_buffer_offset_alignment: u32,
    pub min_storage_buffer_offset_alignment: u32,
    pub max_vertex_buffers: u32,
    pub max_buffer_size: u64,
    pub max_vertex_attributes: u32,
    pub max_vertex_buffer_array_stride: u32,
    pub max_inter_stage_shader_variables: u32,
    pub max_color_attachments: u32,
    pub max_color_attachment_bytes_per_sample: u32,
    pub max_compute_workgroup_storage_size: u32,
    pub max_compute_invocations_per_workgroup: u32,
    pub max_compute_workgroup_size_x: u32,
    pub max_compute_workgroup_size_y: u32,
    pub max_compute_workgroup_size_z: u32,
    pub max_compute_workgroups_per_dimension: u32,
    /// Maximum size of immediate (push constant) data in bytes (0 = none).
    pub max_immediate_size: u32,
}

#[repr(C)]
pub struct WGPUDeviceDescriptor {
    /// Bitmask of required features (bit positions match GpuFeatureName enum order).
    pub required_features: u32,
    /// Pointer to required limits, or null for defaults.
    pub required_limits: *const WGPUDeviceLimits,
    /// If non-zero, request bindless texture extensions (wgpu-specific).
    pub bindless_textures: u8,
    /// If non-zero, request IMMEDIATES feature (push constants).
    pub immediates: u8,
    pub label: *const std::os::raw::c_char,
}

// =============================================================================
// C STRUCT DESCRIPTORS
// =============================================================================

#[repr(C)]
pub struct WGPUBufferDescriptor {
    pub size: u64,
    pub usage: u32,
    pub mapped_at_creation: u8,
    pub label: *const std::ffi::c_char,
}

#[repr(C)]
pub struct WGPUTextureDescriptor {
    pub width: u32,
    pub height: u32,
    pub depth_or_array_layers: u32,
    pub mip_level_count: u32,
    pub sample_count: u32,
    pub dimension: u32,
    pub format: u32,
    pub usage: u32,
    pub view_format_count: u32,
    pub view_formats: *const u32,
    pub label: *const std::ffi::c_char,
}

#[repr(C)]
pub struct WGPUTextureViewDescriptor {
    pub format: u32,
    pub dimension: u32,
    pub base_mip_level: u32,
    pub mip_level_count: u32,
    pub base_array_layer: u32,
    pub array_layer_count: u32,
    pub aspect: u32,
    /// TextureUsages flags (0 = inherit from texture).
    pub usage: u32,
    pub label: *const std::ffi::c_char,
}

#[repr(C)]
pub struct WGPUSamplerDescriptor {
    pub address_mode_u: u32,
    pub address_mode_v: u32,
    pub address_mode_w: u32,
    pub mag_filter: u32,
    pub min_filter: u32,
    pub mipmap_filter: u32,
    pub lod_min_clamp: f32,
    pub lod_max_clamp: f32,
    pub compare: u32,
    pub max_anisotropy: u16,
    pub label: *const std::ffi::c_char,
}

#[repr(C)]
pub struct WGPURenderPassColorAttachment {
    pub view: WGPUTextureView,
    pub resolve_target: WGPUTextureView,
    pub load_op: u32,
    pub store_op: u32,
    pub clear_r: f64,
    pub clear_g: f64,
    pub clear_b: f64,
    pub clear_a: f64,
    /// Depth slice for 3D texture render targets (u32::MAX = None).
    pub depth_slice: u32,
}

#[repr(C)]
pub struct WGPURenderPassDepthStencilAttachment {
    pub view: WGPUTextureView,
    pub depth_load_op: u32,
    pub depth_store_op: u32,
    pub depth_clear_value: f32,
    pub depth_read_only: u8,
    pub stencil_load_op: u32,
    pub stencil_store_op: u32,
    pub stencil_clear_value: u32,
    pub stencil_read_only: u8,
}

#[repr(C)]
pub struct WGPURenderPassDescriptor {
    pub color_attachments: *const WGPURenderPassColorAttachment,
    pub color_attachment_count: u32,
    pub depth_stencil_attachment: *const WGPURenderPassDepthStencilAttachment,
    pub occlusion_query_set: WGPUQuerySet,
    /// Max draw calls (0 = use default 50_000_000).
    pub max_draw_count: u64,
    /// Timestamp writes query set handle (0 = none).
    pub timestamp_writes_query_set: WGPUQuerySet,
    /// Query index for beginning timestamp.
    pub timestamp_writes_beginning: u32,
    /// Query index for end timestamp.
    pub timestamp_writes_end: u32,
    pub label: *const std::ffi::c_char,
}

// =============================================================================
// BIND GROUP LAYOUT DESCRIPTORS
// =============================================================================

pub const BINDING_TYPE_BUFFER: u32 = 0;
pub const BINDING_TYPE_SAMPLER: u32 = 1;
pub const BINDING_TYPE_TEXTURE: u32 = 2;
pub const BINDING_TYPE_STORAGE_TEXTURE: u32 = 3;

#[repr(C)]
pub struct WGPUBindGroupLayoutEntry {
    pub binding: u32,
    pub visibility: u32,
    pub binding_type: u32,
    pub buffer_type: u32,
    pub has_dynamic_offset: u8,
    pub min_binding_size: u64,
    pub sampler_type: u32,
    pub texture_sample_type: u32,
    pub texture_view_dimension: u32,
    pub texture_multisampled: u8,
    /// Number of elements for binding arrays (0 = not an array).
    pub count: u32,
}

#[repr(C)]
pub struct WGPUBindGroupLayoutDescriptor {
    pub entries: *const WGPUBindGroupLayoutEntry,
    pub entry_count: u32,
    pub label: *const std::ffi::c_char,
}

// =============================================================================
// BIND GROUP DESCRIPTORS
// =============================================================================

#[repr(C)]
pub struct WGPUBindGroupEntry {
    pub binding: u32,
    pub resource_type: u32,
    pub resource: u64,
    pub offset: u64,
    pub size: u64,
}

#[repr(C)]
pub struct WGPUBindGroupDescriptor {
    pub layout: WGPUBindGroupLayout,
    pub entries: *const WGPUBindGroupEntry,
    pub entry_count: u32,
    pub label: *const std::ffi::c_char,
}

// =============================================================================
// PIPELINE LAYOUT DESCRIPTORS
// =============================================================================

#[repr(C)]
pub struct WGPUPipelineLayoutDescriptor {
    pub bind_group_layouts: *const WGPUBindGroupLayout,
    pub bind_group_layout_count: u32,
    /// Size in bytes of immediate (push constant) data. 0 = none.
    pub immediate_size: u32,
    pub label: *const std::ffi::c_char,
}

// =============================================================================
// RENDER PIPELINE DESCRIPTORS
// =============================================================================

#[repr(C)]
pub struct WGPUVertexAttribute {
    pub format: u32,
    pub offset: u64,
    pub shader_location: u32,
}

#[repr(C)]
pub struct WGPUVertexBufferLayout {
    pub array_stride: u64,
    pub step_mode: u32,
    pub attributes: *const WGPUVertexAttribute,
    pub attribute_count: u32,
}

#[repr(C)]
pub struct WGPUVertexState {
    pub module: WGPUShaderModule,
    pub entry_point: *const std::ffi::c_char,
    pub buffers: *const WGPUVertexBufferLayout,
    pub buffer_count: u32,
    pub constant_count: u32,
    pub constant_keys: *const *const std::ffi::c_char,
    pub constant_values: *const f64,
}

#[repr(C)]
pub struct WGPUBlendComponent {
    pub operation: u32,
    pub src_factor: u32,
    pub dst_factor: u32,
}

#[repr(C)]
pub struct WGPUColorTargetState {
    pub format: u32,
    pub blend_enabled: u8,
    pub blend_color: WGPUBlendComponent,
    pub blend_alpha: WGPUBlendComponent,
    pub write_mask: u32,
}

#[repr(C)]
pub struct WGPUFragmentState {
    pub module: WGPUShaderModule,
    pub entry_point: *const std::ffi::c_char,
    pub targets: *const WGPUColorTargetState,
    pub target_count: u32,
    pub constant_count: u32,
    pub constant_keys: *const *const std::ffi::c_char,
    pub constant_values: *const f64,
}

#[repr(C)]
pub struct WGPUDepthStencilState {
    pub format: u32,
    pub depth_write_enabled: u8,
    pub depth_compare: u32,
    pub depth_bias: i32,
    pub depth_bias_slope_scale: f32,
    pub depth_bias_clamp: f32,
    pub stencil_front_compare: u32,
    pub stencil_front_fail_op: u32,
    pub stencil_front_depth_fail_op: u32,
    pub stencil_front_pass_op: u32,
    pub stencil_back_compare: u32,
    pub stencil_back_fail_op: u32,
    pub stencil_back_depth_fail_op: u32,
    pub stencil_back_pass_op: u32,
    pub stencil_read_mask: u32,
    pub stencil_write_mask: u32,
}

#[repr(C)]
pub struct WGPURenderPipelineDescriptor {
    pub layout: WGPUPipelineLayout,
    pub vertex: WGPUVertexState,
    pub fragment: WGPUFragmentState,
    pub primitive_topology: u32,
    pub strip_index_format: u32,
    pub front_face: u32,
    pub cull_mode: u32,
    pub unclipped_depth: u8,
    pub depth_stencil_enabled: u8,
    pub depth_stencil: WGPUDepthStencilState,
    pub multisample_count: u32,
    pub multisample_mask: u32,
    pub alpha_to_coverage_enabled: u8,
    pub label: *const std::ffi::c_char,
}

// =============================================================================
// COMPUTE PASS DESCRIPTOR
// =============================================================================

#[repr(C)]
pub struct WGPUComputePassDescriptor {
    /// Timestamp writes query set handle (0 = none).
    pub timestamp_writes_query_set: WGPUQuerySet,
    /// Query index for beginning timestamp.
    pub timestamp_writes_beginning: u32,
    /// Query index for end timestamp.
    pub timestamp_writes_end: u32,
    pub label: *const std::ffi::c_char,
}

// =============================================================================
// COMPUTE PIPELINE DESCRIPTOR
// =============================================================================

#[repr(C)]
pub struct WGPUComputePipelineDescriptor {
    pub layout: WGPUPipelineLayout,
    pub module: WGPUShaderModule,
    pub entry_point: *const std::ffi::c_char,
    /// Number of pipeline-overridable constants.
    pub constant_count: u32,
    /// Parallel array of constant key C-strings (length = constant_count).
    pub constant_keys: *const *const std::ffi::c_char,
    /// Parallel array of constant f64 values (length = constant_count).
    pub constant_values: *const f64,
    pub label: *const std::ffi::c_char,
}

// =============================================================================
// RENDER BUNDLE ENCODER DESCRIPTOR
// =============================================================================

#[repr(C)]
pub struct WGPURenderBundleEncoderDescriptor {
    pub color_formats: *const u32,
    pub color_format_count: u32,
    pub depth_stencil_format: u32,
    pub sample_count: u32,
    pub depth_read_only: u8,
    pub stencil_read_only: u8,
    pub label: *const std::ffi::c_char,
}

// =============================================================================
// ASYNC MAPPING AND FENCE TYPES
// =============================================================================

#[derive(Clone, Copy, PartialEq)]
pub enum BufferMapMode {
    Read = 0,
    Write = 1,
}

pub const MAP_STATUS_PENDING: i32 = 0;
pub const MAP_STATUS_READY: i32 = 1;
pub const MAP_STATUS_ERROR: i32 = -1;

pub enum MappedBuffer {
    Staging(wgpu::Buffer),
    Original(u64),
}

pub struct PendingMapping {
    pub buffer: MappedBuffer,
    pub mode: BufferMapMode,
    pub size: u64,
    pub status: Arc<AtomicI32>,
}

pub struct PendingFence {
    pub submission_index: wgpu::SubmissionIndex,
}

// =============================================================================
// DEVICE/ADAPTER/INSTANCE ENTRIES
// =============================================================================

pub(crate) struct AdapterEntry {
    pub adapter: wgpu::Adapter,
    /// Back-reference to parent instance (used on Android for surface creation chain).
    #[allow(dead_code)]
    pub instance_handle: u64,
    /// Cached adapter info strings (prevents unbounded CString leak on repeated calls).
    pub cached_info: std::sync::OnceLock<(std::ffi::CString, std::ffi::CString)>,
}

pub(crate) struct DeviceEntry {
    pub device: Arc<wgpu::Device>,
    pub queue: Arc<wgpu::Queue>,
    /// Back-reference to parent adapter (used on Android for surface creation chain).
    #[allow(dead_code)]
    pub adapter_handle: u64,
    pub errors: Arc<std::sync::Mutex<Vec<std::ffi::CString>>>,
}

// =============================================================================
// RENDER/COMPUTE PASS WRAPPERS
// =============================================================================

pub(crate) struct RenderPassWrapper {
    pub encoder_ptr: *mut wgpu::CommandEncoder,
    pub pass_ptr: *mut wgpu::RenderPass<'static>,
}

pub(crate) struct ComputePassWrapper {
    pub encoder_ptr: *mut wgpu::CommandEncoder,
    pub pass_ptr: *mut wgpu::ComputePass<'static>,
}
