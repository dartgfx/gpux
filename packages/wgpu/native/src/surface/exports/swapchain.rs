use crate::abi::types::*;
use crate::runtime::handle::*;
use crate::runtime::state::*;
use crate::{clear_error, ffi_catch, set_error};

// =============================================================================
// SWAPCHAIN SURFACE (native window, no Flutter)
// =============================================================================

/// Create a swapchain surface from a native window handle.
/// - Windows: pass HWND
/// - macOS: pass NSWindow pointer (contentView is extracted internally)
/// Returns surface handle, or 0 on failure (check wgpu_get_last_error).
#[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
#[no_mangle]
pub extern "C" fn wgpu_create_swapchain_surface(
    device_handle: WGPUDevice,
    native_handle: isize,
    width: u32,
    height: u32,
) -> u64 {
    use crate::surface::swapchain::SwapchainSurface;

    clear_error();
    if device_handle == 0 {
        set_error("wgpu_create_swapchain_surface: device handle is 0");
        return 0;
    }

    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device_handle) };
        let adapter_entry = unsafe { deref_handle::<AdapterEntry>(entry.adapter_handle) };
        let instance = unsafe { deref_handle::<wgpu::Instance>(adapter_entry.instance_handle) };

        match SwapchainSurface::create(
            instance,
            &adapter_entry.adapter,
            entry.device.clone(),
            entry.queue.clone(),
            native_handle,
            width,
            height,
        ) {
            Ok(surface) => into_handle(surface),
            Err(e) => {
                set_error(format!("Failed to create swapchain surface: {}", e));
                0
            }
        }
    })
}

/// Stub for unsupported platforms.
#[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
#[no_mangle]
pub extern "C" fn wgpu_create_swapchain_surface(
    _device_handle: WGPUDevice,
    _native_handle: isize,
    _width: u32,
    _height: u32,
) -> u64 {
    set_error("Swapchain surfaces require Windows or macOS");
    0
}

/// Get the texture format of a swapchain surface.
/// Returns format enum value matching GpuTextureFormat index.
#[no_mangle]
pub extern "C" fn wgpu_swapchain_get_format(surface_id: u64) -> u32 {
    #[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
    {
        use crate::surface::swapchain::SwapchainSurface;

        if surface_id == 0 {
            return 0;
        }
        let surface = unsafe { deref_handle::<SwapchainSurface>(surface_id) };
        match surface.format() {
            wgpu::TextureFormat::Bgra8Unorm => 26,
            wgpu::TextureFormat::Bgra8UnormSrgb => 27,
            wgpu::TextureFormat::Rgba8Unorm => 21,
            wgpu::TextureFormat::Rgba8UnormSrgb => 22,
            wgpu::TextureFormat::Rgba16Float => 37,
            other => {
                log::warn!("Unexpected swapchain format: {:?}", other);
                26 // fallback to Bgra8Unorm
            }
        }
    }

    #[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
    {
        let _ = surface_id;
        0
    }
}

/// Acquire the next swapchain texture for rendering.
/// Returns texture view handle, or 0 if failed.
#[no_mangle]
pub extern "C" fn wgpu_swapchain_get_texture_view(surface_id: u64) -> WGPUTextureView {
    #[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
    {
        use crate::surface::swapchain::SwapchainSurface;

        if surface_id == 0 {
            return 0;
        }
        ffi_catch!(0, {
            let surface = unsafe { deref_handle_mut::<SwapchainSurface>(surface_id) };
            match surface.get_texture_view() {
                Ok(view) => into_handle(view),
                Err(e) => {
                    set_error(format!("swapchain get_texture_view: {}", e));
                    0
                }
            }
        })
    }

    #[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
    {
        let _ = surface_id;
        0
    }
}

/// Get the depth texture view for a swapchain surface.
#[no_mangle]
pub extern "C" fn wgpu_swapchain_get_depth_view(surface_id: u64) -> WGPUTextureView {
    #[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
    {
        use crate::surface::swapchain::SwapchainSurface;

        if surface_id == 0 {
            return 0;
        }
        ffi_catch!(0, {
            let surface = unsafe { deref_handle::<SwapchainSurface>(surface_id) };
            let view = surface
                .depth_texture
                .create_view(&wgpu::TextureViewDescriptor::default());
            into_handle(view)
        })
    }

    #[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
    {
        let _ = surface_id;
        0
    }
}

/// Present the current swapchain frame.
#[no_mangle]
pub extern "C" fn wgpu_swapchain_present(surface_id: u64) {
    #[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
    {
        use crate::surface::swapchain::SwapchainSurface;

        if surface_id == 0 {
            return;
        }
        ffi_catch!((), {
            let surface = unsafe { deref_handle_mut::<SwapchainSurface>(surface_id) };
            surface.present();
        })
    }

    #[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
    {
        let _ = surface_id;
    }
}

/// Resize a swapchain surface.
/// Returns 1 on success, 0 on failure.
#[no_mangle]
pub extern "C" fn wgpu_swapchain_resize(surface_id: u64, width: u32, height: u32) -> u32 {
    #[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
    {
        use crate::surface::swapchain::SwapchainSurface;

        if surface_id == 0 {
            return 0;
        }
        ffi_catch!(0, {
            let surface = unsafe { deref_handle_mut::<SwapchainSurface>(surface_id) };
            match surface.resize(width, height) {
                Ok(()) => 1,
                Err(e) => {
                    set_error(format!("swapchain resize: {}", e));
                    0
                }
            }
        })
    }

    #[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
    {
        let _ = (surface_id, width, height);
        0
    }
}

/// Clear the swapchain to a solid color and present.
#[no_mangle]
pub extern "C" fn wgpu_swapchain_clear(surface_id: u64, r: f64, g: f64, b: f64, a: f64) {
    #[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
    {
        use crate::surface::swapchain::SwapchainSurface;

        if surface_id == 0 {
            return;
        }
        ffi_catch!((), {
            let surface = unsafe { deref_handle_mut::<SwapchainSurface>(surface_id) };
            surface.clear(r, g, b, a);
        })
    }

    #[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
    {
        let _ = (surface_id, r, g, b, a);
    }
}

/// Destroy a swapchain surface.
#[no_mangle]
pub extern "C" fn wgpu_swapchain_destroy(surface_id: u64) {
    #[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
    {
        use crate::surface::swapchain::SwapchainSurface;

        if surface_id == 0 {
            return;
        }
        ffi_catch!((), {
            unsafe {
                drop_handle::<SwapchainSurface>(surface_id);
            }
        })
    }

    #[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
    {
        let _ = surface_id;
    }
}
