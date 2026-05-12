use super::handles::*;

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
