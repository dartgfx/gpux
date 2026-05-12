use super::handles::*;

#[repr(C)]
pub struct WGPUPipelineLayoutDescriptor {
    pub bind_group_layouts: *const WGPUBindGroupLayout,
    pub bind_group_layout_count: u32,
    /// Size in bytes of immediate (push constant) data. 0 = none.
    pub immediate_size: u32,
    pub label: *const std::ffi::c_char,
}

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
