use std::sync::Arc;

#[cfg(target_os = "android")]
use crate::surface::create_depth_texture;

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
    pub platform: crate::surface::platform::apple::AppleSurface,

    #[cfg(target_os = "windows")]
    pub platform: crate::surface::platform::windows::WindowsSurface,

    #[cfg(target_os = "linux")]
    pub platform: crate::surface::platform::linux::LinuxSurface,
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
            crate::surface::platform::apple::AppleSurface::create(device, queue, width, height)
        }

        #[cfg(target_os = "windows")]
        {
            crate::surface::platform::windows::WindowsSurface::create(device, queue, width, height)
        }

        #[cfg(target_os = "linux")]
        {
            crate::surface::platform::linux::LinuxSurface::create(device, queue, width, height)
        }
    }

    pub fn resize(&mut self, width: u32, height: u32) -> Result<(), String> {
        if width == self.width && height == self.height {
            return Ok(());
        }

        #[cfg(target_vendor = "apple")]
        {
            *self = crate::surface::platform::apple::AppleSurface::create(
                self.device.clone(),
                self.queue.clone(),
                width,
                height,
            )?;
        }

        #[cfg(target_os = "windows")]
        {
            *self = crate::surface::platform::windows::WindowsSurface::create(
                self.device.clone(),
                self.queue.clone(),
                width,
                height,
            )?;
        }

        #[cfg(target_os = "linux")]
        {
            *self = crate::surface::platform::linux::LinuxSurface::create(
                self.device.clone(),
                self.queue.clone(),
                width,
                height,
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

#[cfg(target_os = "android")]
pub struct WgpuSurface {
    pub device: Arc<wgpu::Device>,
    pub queue: Arc<wgpu::Queue>,
    pub width: u32,
    pub height: u32,
    pub format_ffi: u32,
    #[allow(dead_code)]
    pub depth_texture: wgpu::Texture,
    pub platform: crate::surface::platform::android::AndroidSurface,
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
            crate::surface::platform::android::AndroidSurface::create(
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
