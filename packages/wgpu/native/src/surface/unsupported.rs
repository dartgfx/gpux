#[cfg(not(any(
    target_vendor = "apple",
    target_os = "windows",
    target_os = "linux",
    target_os = "android"
)))]
pub struct WgpuSurface {
    pub device: Arc<wgpu::Device>,
    pub queue: Arc<wgpu::Queue>,
    pub width: u32,
    pub height: u32,
    pub format_ffi: u32,
    pub texture: wgpu::Texture,
    pub depth_texture: wgpu::Texture,
}

#[cfg(not(any(
    target_vendor = "apple",
    target_os = "windows",
    target_os = "linux",
    target_os = "android"
)))]
impl WgpuSurface {
    pub fn new(
        _device: Arc<wgpu::Device>,
        _queue: Arc<wgpu::Queue>,
        _width: u32,
        _height: u32,
    ) -> Result<Self, String> {
        Err("Unsupported platform".to_string())
    }

    pub fn resize(&mut self, _width: u32, _height: u32) -> Result<(), String> {
        Err("Unsupported platform".to_string())
    }

    pub fn platform_handle(&self) -> u64 {
        0
    }
}
use std::sync::Arc;
