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
