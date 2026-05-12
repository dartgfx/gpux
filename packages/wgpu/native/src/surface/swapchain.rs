// Cross-platform swapchain surface for direct rendering (no Flutter interop)
//
// Creates a wgpu Surface from a native window handle for SDL, GLFW, etc.
// True zero-copy: GPU renders directly to the window's swapchain.
//
// Platform details:
// - Windows: HWND → Win32WindowHandle
// - macOS:   NSWindow → contentView → AppKitWindowHandle

use super::create_depth_texture;
use raw_window_handle::{RawDisplayHandle, RawWindowHandle};
use std::sync::Arc;

pub struct SwapchainSurface {
    pub device: Arc<wgpu::Device>,
    pub queue: Arc<wgpu::Queue>,
    pub surface: wgpu::Surface<'static>,
    pub config: wgpu::SurfaceConfiguration,
    pub width: u32,
    pub height: u32,
    pub depth_texture: wgpu::Texture,
    pub depth_view: wgpu::TextureView,
    pub current_frame: Option<wgpu::SurfaceTexture>,
}

impl SwapchainSurface {
    pub fn create(
        instance: &wgpu::Instance,
        adapter: &wgpu::Adapter,
        device: Arc<wgpu::Device>,
        queue: Arc<wgpu::Queue>,
        native_handle: isize,
        width: u32,
        height: u32,
    ) -> Result<Self, String> {
        if native_handle == 0 {
            return Err("Native window handle is null".to_string());
        }

        let (raw_window_handle, raw_display_handle) = create_raw_handles(native_handle)?;

        let surface = unsafe {
            instance
                .create_surface_unsafe(wgpu::SurfaceTargetUnsafe::RawHandle {
                    raw_display_handle: Some(raw_display_handle),
                    raw_window_handle,
                })
                .map_err(|e| format!("Failed to create surface: {}", e))?
        };

        let caps = surface.get_capabilities(adapter);
        if caps.formats.is_empty() {
            return Err("No supported surface formats".to_string());
        }

        // Prefer sRGB format, fallback to first available
        let format = caps
            .formats
            .iter()
            .find(|f| f.is_srgb())
            .copied()
            .unwrap_or(caps.formats[0]);

        log::info!(
            "Swapchain surface: {}x{}, format {:?}, present modes: {:?}",
            width,
            height,
            format,
            caps.present_modes
        );

        // Prefer Mailbox (low latency) > Fifo (vsync) > Immediate
        let present_mode = if caps.present_modes.contains(&wgpu::PresentMode::Mailbox) {
            wgpu::PresentMode::Mailbox
        } else if caps.present_modes.contains(&wgpu::PresentMode::Fifo) {
            wgpu::PresentMode::Fifo
        } else {
            caps.present_modes[0]
        };

        let config = wgpu::SurfaceConfiguration {
            usage: wgpu::TextureUsages::RENDER_ATTACHMENT,
            format,
            width,
            height,
            present_mode,
            alpha_mode: caps.alpha_modes[0],
            view_formats: vec![],
            desired_maximum_frame_latency: 2,
        };
        surface.configure(&device, &config);

        let (depth_texture, depth_view) = create_depth_texture(&device, width, height);

        Ok(SwapchainSurface {
            device,
            queue,
            surface,
            config,
            width,
            height,
            depth_texture,
            depth_view,
            current_frame: None,
        })
    }

    pub fn resize(&mut self, width: u32, height: u32) -> Result<(), String> {
        if width == 0 || height == 0 {
            return Err("Invalid size".to_string());
        }
        self.config.width = width;
        self.config.height = height;
        self.surface.configure(&self.device, &self.config);

        let (depth_texture, depth_view) = create_depth_texture(&self.device, width, height);
        self.depth_texture = depth_texture;
        self.depth_view = depth_view;
        self.width = width;
        self.height = height;
        Ok(())
    }

    pub fn get_texture_view(&mut self) -> Result<wgpu::TextureView, String> {
        if self.current_frame.is_none() {
            let frame = match self.surface.get_current_texture() {
                wgpu::CurrentSurfaceTexture::Success(tex)
                | wgpu::CurrentSurfaceTexture::Suboptimal(tex) => tex,
                wgpu::CurrentSurfaceTexture::Outdated | wgpu::CurrentSurfaceTexture::Lost => {
                    self.surface.configure(&self.device, &self.config);
                    match self.surface.get_current_texture() {
                        wgpu::CurrentSurfaceTexture::Success(tex)
                        | wgpu::CurrentSurfaceTexture::Suboptimal(tex) => tex,
                        other => {
                            return Err(format!(
                                "Failed to get swapchain texture after reconfigure: {:?}",
                                other
                            ))
                        }
                    }
                }
                other => return Err(format!("Failed to get swapchain texture: {:?}", other)),
            };
            self.current_frame = Some(frame);
        }

        let frame = self.current_frame.as_ref().unwrap();
        Ok(frame
            .texture
            .create_view(&wgpu::TextureViewDescriptor::default()))
    }

    pub fn present(&mut self) {
        if let Some(frame) = self.current_frame.take() {
            frame.present();
        }
    }

    pub fn format(&self) -> wgpu::TextureFormat {
        self.config.format
    }

    pub fn clear(&mut self, r: f64, g: f64, b: f64, a: f64) {
        let view = match self.get_texture_view() {
            Ok(v) => v,
            Err(e) => {
                log::error!("swapchain clear: {}", e);
                return;
            }
        };

        let mut encoder = self
            .device
            .create_command_encoder(&wgpu::CommandEncoderDescriptor {
                label: Some("swapchain clear"),
            });

        {
            let _pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                label: Some("clear pass"),
                color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                    view: &view,
                    resolve_target: None,
                    ops: wgpu::Operations {
                        load: wgpu::LoadOp::Clear(wgpu::Color { r, g, b, a }),
                        store: wgpu::StoreOp::Store,
                    },
                    depth_slice: None,
                })],
                depth_stencil_attachment: None,
                timestamp_writes: None,
                occlusion_query_set: None,
                multiview_mask: None,
            });
        }

        self.queue.submit(std::iter::once(encoder.finish()));
        self.present();
    }
}

// =============================================================================
// Platform-specific raw handle creation
// =============================================================================

#[cfg(target_os = "windows")]
fn create_raw_handles(hwnd: isize) -> Result<(RawWindowHandle, RawDisplayHandle), String> {
    use raw_window_handle::{Win32WindowHandle, WindowsDisplayHandle};
    use std::num::NonZeroIsize;

    let hwnd_nz = NonZeroIsize::new(hwnd).ok_or("Invalid HWND")?;
    let window_handle = Win32WindowHandle::new(hwnd_nz);
    let raw_window = RawWindowHandle::Win32(window_handle);

    let display_handle = WindowsDisplayHandle::new();
    let raw_display = RawDisplayHandle::Windows(display_handle);

    Ok((raw_window, raw_display))
}

#[cfg(target_os = "linux")]
fn create_raw_handles(window_handle: isize) -> Result<(RawWindowHandle, RawDisplayHandle), String> {
    use raw_window_handle::{XlibDisplayHandle, XlibWindowHandle};

    // Expect an X11 Window (XID) from the caller.
    // Wayland support can be added later when needed.
    let xlib_window = window_handle as u32;
    let window_handle = XlibWindowHandle::new(xlib_window.into());
    let raw_window = RawWindowHandle::Xlib(window_handle);

    // Display handle — None means wgpu will use the default display.
    let display_handle = XlibDisplayHandle::new(None, 0);
    let raw_display = RawDisplayHandle::Xlib(display_handle);

    Ok((raw_window, raw_display))
}

#[cfg(target_os = "macos")]
fn create_raw_handles(ns_window: isize) -> Result<(RawWindowHandle, RawDisplayHandle), String> {
    use objc2::msg_send;
    use raw_window_handle::{AppKitDisplayHandle, AppKitWindowHandle};
    use std::ptr::NonNull;

    // SDL gives us an NSWindow; wgpu needs the NSView (contentView).
    let ns_window_ptr = ns_window as *mut objc2::runtime::AnyObject;
    let ns_view: *mut objc2::runtime::AnyObject =
        unsafe { msg_send![&*ns_window_ptr, contentView] };
    if ns_view.is_null() {
        return Err("NSWindow contentView is null".to_string());
    }

    let view_nn =
        NonNull::new(ns_view as *mut std::ffi::c_void).ok_or("Failed to get non-null NSView")?;
    let window_handle = AppKitWindowHandle::new(view_nn);
    let raw_window = RawWindowHandle::AppKit(window_handle);

    let raw_display = RawDisplayHandle::AppKit(AppKitDisplayHandle::new());

    Ok((raw_window, raw_display))
}
