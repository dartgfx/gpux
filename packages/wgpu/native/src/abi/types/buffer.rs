#[repr(C)]
pub struct WGPUBufferDescriptor {
    pub size: u64,
    pub usage: u32,
    pub mapped_at_creation: u8,
    pub label: *const std::ffi::c_char,
}
