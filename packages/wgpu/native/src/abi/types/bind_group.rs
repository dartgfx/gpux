use super::handles::*;

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
