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
