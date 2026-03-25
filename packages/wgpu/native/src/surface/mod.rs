// wgpu render surface with platform texture sharing
//
// Platform differences:
// - Apple/Windows: We create and own the texture, share via IOSurface/DXGI
// - Android: Swapchain-based rendering to native window

#[cfg(target_vendor = "apple")]
mod apple;

#[cfg(target_os = "windows")]
pub(crate) mod windows;

#[cfg(target_os = "windows")]
mod windows_d3d11;

#[cfg(target_os = "linux")]
pub(crate) mod linux;

#[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
pub mod swapchain;

#[cfg(target_os = "android")]
pub(crate) mod android;

use std::sync::Arc;

// =============================================================================
// Apple/Windows: Texture-based surface (we own the texture)
// =============================================================================

#[cfg(any(target_vendor = "apple", target_os = "windows", target_os = "linux"))]
pub struct WgpuSurface {
    pub device: Arc<wgpu::Device>,
    pub queue: Arc<wgpu::Queue>,
    pub width: u32,
    pub height: u32,
    pub format_ffi: u32,
    pub texture: wgpu::Texture,
    #[allow(dead_code)]
    pub depth_texture: wgpu::Texture,

    #[cfg(target_vendor = "apple")]
    pub platform: self::apple::AppleSurface,

    #[cfg(target_os = "windows")]
    pub platform: self::windows::WindowsSurface,

    #[cfg(target_os = "linux")]
    pub platform: self::linux::LinuxSurface,
}

#[cfg(any(target_vendor = "apple", target_os = "windows", target_os = "linux"))]
impl WgpuSurface {
    pub fn new(
        device: Arc<wgpu::Device>,
        queue: Arc<wgpu::Queue>,
        width: u32,
        height: u32,
    ) -> Result<Self, String> {
        #[cfg(target_vendor = "apple")]
        {
            self::apple::AppleSurface::create(device, queue, width, height)
        }

        #[cfg(target_os = "windows")]
        {
            self::windows::WindowsSurface::create(device, queue, width, height)
        }

        #[cfg(target_os = "linux")]
        {
            self::linux::LinuxSurface::create(device, queue, width, height)
        }
    }

    pub fn resize(&mut self, width: u32, height: u32) -> Result<(), String> {
        if width == self.width && height == self.height {
            return Ok(());
        }

        #[cfg(target_vendor = "apple")]
        {
            *self = self::apple::AppleSurface::create(
                self.device.clone(), self.queue.clone(), width, height,
            )?;
        }

        #[cfg(target_os = "windows")]
        {
            *self = self::windows::WindowsSurface::create(
                self.device.clone(), self.queue.clone(), width, height,
            )?;
        }

        #[cfg(target_os = "linux")]
        {
            *self = self::linux::LinuxSurface::create(
                self.device.clone(), self.queue.clone(), width, height,
            )?;
        }

        Ok(())
    }

    pub fn platform_handle(&self) -> u64 {
        #[cfg(target_vendor = "apple")]
        {
            self.platform.iosurface_id as u64
        }

        #[cfg(target_os = "windows")]
        {
            0
        }

        #[cfg(target_os = "linux")]
        {
            0
        }
    }
}

// =============================================================================
// Android: Swapchain-based surface
// =============================================================================

#[cfg(target_os = "android")]
pub struct WgpuSurface {
    pub device: Arc<wgpu::Device>,
    pub queue: Arc<wgpu::Queue>,
    pub width: u32,
    pub height: u32,
    pub format_ffi: u32,
    #[allow(dead_code)]
    pub depth_texture: wgpu::Texture,
    pub platform: self::android::AndroidSurface,
    pub current_frame: Option<wgpu::SurfaceTexture>,
}

#[cfg(target_os = "android")]
impl WgpuSurface {
    pub fn new(
        instance: &wgpu::Instance,
        adapter: &wgpu::Adapter,
        device: Arc<wgpu::Device>,
        queue: Arc<wgpu::Queue>,
        window_ptr: *mut std::ffi::c_void,
        width: u32,
        height: u32,
    ) -> Result<Self, String> {
        let (platform, depth_texture, _depth_view) =
            self::android::AndroidSurface::create(
                instance, adapter, &device, window_ptr, width, height,
            )?;

        let format_ffi = match platform.config.format {
            wgpu::TextureFormat::Rgba8Unorm => 17,
            wgpu::TextureFormat::Rgba8UnormSrgb => 18,
            _ => 18,
        };

        Ok(WgpuSurface {
            device,
            queue,
            width,
            height,
            format_ffi,
            depth_texture,
            platform,
            current_frame: None,
        })
    }

    pub fn resize(&mut self, width: u32, height: u32) -> Result<(), String> {
        if width == self.width && height == self.height {
            return Ok(());
        }

        // Drop any outstanding SurfaceTexture before reconfiguring —
        // wgpu requires all SurfaceOutputs to be dropped first.
        self.current_frame.take();

        self.platform.resize(&self.device, width, height);
        let (depth_texture, _depth_view) = create_depth_texture(&self.device, width, height);
        self.depth_texture = depth_texture;
        self.width = width;
        self.height = height;

        Ok(())
    }

    pub fn get_current_texture(&self) -> wgpu::CurrentSurfaceTexture {
        self.platform.get_current_texture()
    }
}

// =============================================================================
// Unsupported platforms
// =============================================================================

#[cfg(not(any(target_vendor = "apple", target_os = "windows", target_os = "linux", target_os = "android")))]
pub struct WgpuSurface {
    pub device: Arc<wgpu::Device>,
    pub queue: Arc<wgpu::Queue>,
    pub width: u32,
    pub height: u32,
    pub format_ffi: u32,
    pub texture: wgpu::Texture,
    pub depth_texture: wgpu::Texture,
}

#[cfg(not(any(target_vendor = "apple", target_os = "windows", target_os = "linux", target_os = "android")))]
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

// =============================================================================
// Shared utilities
// =============================================================================

pub fn create_depth_texture(
    device: &wgpu::Device,
    width: u32,
    height: u32,
) -> (wgpu::Texture, wgpu::TextureView) {
    let texture = device.create_texture(&wgpu::TextureDescriptor {
        label: Some("Depth Texture"),
        size: wgpu::Extent3d {
            width,
            height,
            depth_or_array_layers: 1,
        },
        mip_level_count: 1,
        sample_count: 1,
        dimension: wgpu::TextureDimension::D2,
        format: wgpu::TextureFormat::Depth32Float,
        usage: wgpu::TextureUsages::RENDER_ATTACHMENT,
        view_formats: &[],
    });

    let view = texture.create_view(&wgpu::TextureViewDescriptor::default());

    (texture, view)
}
