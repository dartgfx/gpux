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
