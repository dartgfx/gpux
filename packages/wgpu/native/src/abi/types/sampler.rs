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
