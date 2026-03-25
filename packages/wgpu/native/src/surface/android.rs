// Android platform surface integration for wgpu
//
// Creates a wgpu Surface from an ANativeWindow.
// Uses swapchain-based rendering directly to the native window.

use super::create_depth_texture;
use raw_window_handle::{
    AndroidDisplayHandle, AndroidNdkWindowHandle, RawDisplayHandle, RawWindowHandle,
};
use std::ptr::NonNull;

pub struct AndroidSurface {
    pub surface: wgpu::Surface<'static>,
    pub config: wgpu::SurfaceConfiguration,
}

impl AndroidSurface {
    pub fn create(
        instance: &wgpu::Instance,
        adapter: &wgpu::Adapter,
        device: &wgpu::Device,
        window_ptr: *mut std::ffi::c_void,
        width: u32,
        height: u32,
    ) -> Result<(AndroidSurface, wgpu::Texture, wgpu::TextureView), String> {
        if window_ptr.is_null() {
            return Err("ANativeWindow pointer is null".to_string());
        }

        let ptr = NonNull::new(window_ptr).ok_or("Invalid window pointer")?;
        let window_handle = AndroidNdkWindowHandle::new(ptr);
        let raw_window_handle = RawWindowHandle::AndroidNdk(window_handle);

        let display_handle = AndroidDisplayHandle::new();
        let raw_display_handle = RawDisplayHandle::Android(display_handle);

        let surface = unsafe {
            instance
                .create_surface_unsafe(wgpu::SurfaceTargetUnsafe::RawHandle {
                    raw_display_handle: Some(raw_display_handle),
                    raw_window_handle,
                })
                .map_err(|e| format!("Failed to create surface: {}", e))?
        };

        let caps = surface.get_capabilities(adapter);
        let format = caps
            .formats
            .iter()
            .find(|f| f.is_srgb())
            .copied()
            .unwrap_or(caps.formats[0]);

        log::warn!(
            "Android surface created: {}x{}, format {:?}",
            width,
            height,
            format,
        );

        let config = wgpu::SurfaceConfiguration {
            usage: wgpu::TextureUsages::RENDER_ATTACHMENT,
            format,
            width,
            height,
            present_mode: wgpu::PresentMode::Fifo,
            alpha_mode: caps.alpha_modes[0],
            view_formats: vec![],
            desired_maximum_frame_latency: 2,
        };
        surface.configure(device, &config);

        let (depth_texture, depth_view) = create_depth_texture(device, width, height);

        Ok((
            AndroidSurface { surface, config },
            depth_texture,
            depth_view,
        ))
    }

    pub fn resize(&mut self, device: &wgpu::Device, width: u32, height: u32) {
        self.config.width = width;
        self.config.height = height;
        self.surface.configure(device, &self.config);
    }

    pub fn get_current_texture(&self) -> wgpu::CurrentSurfaceTexture {
        self.surface.get_current_texture()
    }
}
