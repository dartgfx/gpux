use crate::abi::types::*;
use crate::runtime::handle::*;
use crate::runtime::state::*;
use crate::surface::WgpuSurface;
use crate::{clear_error, ffi_catch, set_error};
/// Create a render surface with platform texture sharing.
/// Returns surface handle, or 0 on failure (check wgpu_get_last_error).
#[cfg(not(target_os = "android"))]
#[no_mangle]
pub extern "C" fn wgpu_create_surface(device_handle: WGPUDevice, width: u32, height: u32) -> u64 {
    clear_error();
    if device_handle == 0 {
        set_error("wgpu_create_surface: device handle is 0");
        return 0;
    }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device_handle) };

        match WgpuSurface::new(entry.device.clone(), entry.queue.clone(), width, height) {
            Ok(surface) => into_handle(surface),
            Err(e) => {
                set_error(format!("Failed to create surface: {}", e));
                0
            }
        }
    })
}

/// Create a render surface from a native window (Android only).
#[cfg(target_os = "android")]
#[no_mangle]
pub extern "C" fn wgpu_create_surface_from_window(
    device_handle: WGPUDevice,
    window_ptr: *mut std::ffi::c_void,
    width: u32,
    height: u32,
) -> u64 {
    clear_error();
    log::warn!(
        "wgpu_create_surface_from_window: ptr=0x{:x}, {}x{}",
        window_ptr as usize,
        width,
        height
    );

    if device_handle == 0 {
        set_error("wgpu_create_surface_from_window: device handle is 0");
        return 0;
    }

    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device_handle) };

        // Walk handle chain: DeviceEntry -> AdapterEntry -> Instance
        let adapter_entry = unsafe { deref_handle::<AdapterEntry>(entry.adapter_handle) };
        let instance = unsafe { deref_handle::<wgpu::Instance>(adapter_entry.instance_handle) };

        match WgpuSurface::new(
            instance,
            &adapter_entry.adapter,
            entry.device.clone(),
            entry.queue.clone(),
            window_ptr,
            width,
            height,
        ) {
            Ok(surface) => {
                let handle = into_handle(surface);
                log::warn!("Surface created successfully, handle={}", handle);
                handle
            }
            Err(e) => {
                set_error(format!("Failed to create surface: {}", e));
                0
            }
        }
    })
}

/// Stub for Android - use wgpu_create_surface_from_window instead
#[cfg(target_os = "android")]
#[no_mangle]
pub extern "C" fn wgpu_create_surface(
    _device_handle: WGPUDevice,
    _width: u32,
    _height: u32,
) -> u64 {
    set_error("On Android, use wgpu_create_surface_from_window");
    0
}

/// Stub for non-Android - use wgpu_create_surface instead
#[cfg(not(target_os = "android"))]
#[no_mangle]
pub extern "C" fn wgpu_create_surface_from_window(
    _device_handle: WGPUDevice,
    _window_ptr: *mut std::ffi::c_void,
    _width: u32,
    _height: u32,
) -> u64 {
    set_error("wgpu_create_surface_from_window is only available on Android");
    0
}

/// Get the platform-specific texture handle for sharing.
#[no_mangle]
pub extern "C" fn wgpu_get_surface_handle(surface_id: u64) -> u64 {
    #[cfg(target_os = "android")]
    {
        let _ = surface_id;
        0
    }

    #[cfg(not(target_os = "android"))]
    {
        if surface_id == 0 {
            return 0;
        }
        let surface = unsafe { deref_handle::<WgpuSurface>(surface_id) };
        surface.platform_handle()
    }
}

/// Get the pixel buffer pointer for a surface (Windows/Linux).
#[no_mangle]
pub extern "C" fn wgpu_get_pixel_buffer_ptr(surface_id: u64) -> *const u8 {
    #[cfg(any(target_os = "windows", target_os = "linux"))]
    {
        if surface_id == 0 {
            return std::ptr::null();
        }
        let surface = unsafe { deref_handle::<WgpuSurface>(surface_id) };
        surface.platform.get_pixel_buffer_ptr()
    }

    #[cfg(not(any(target_os = "windows", target_os = "linux")))]
    {
        let _ = surface_id;
        std::ptr::null()
    }
}

/// Get the D3D11 shared handle for a surface (Windows only).
#[no_mangle]
pub extern "C" fn wgpu_get_shared_handle(surface_id: u64) -> u64 {
    #[cfg(target_os = "windows")]
    {
        if surface_id == 0 {
            return 0;
        }
        let surface = unsafe { deref_handle::<WgpuSurface>(surface_id) };
        surface.platform.get_shared_handle()
    }

    #[cfg(not(target_os = "windows"))]
    {
        let _ = surface_id;
        0
    }
}

/// Get the texture format of a surface (returns FFI texture format value).
#[no_mangle]
pub extern "C" fn wgpu_get_surface_format(surface_id: u64) -> u32 {
    if surface_id == 0 {
        // Fallback before surface exists — matches most common platform defaults.
        #[cfg(target_vendor = "apple")]
        return 22; // bgra8Unorm
        #[cfg(not(target_vendor = "apple"))]
        return 18; // rgba8UnormSrgb
    }
    let surface = unsafe { deref_handle::<WgpuSurface>(surface_id) };
    surface.format_ffi
}

/// Resize surface. Returns 1 on success, 0 on failure.
#[no_mangle]
pub extern "C" fn wgpu_resize_surface(surface_id: u64, width: u32, height: u32) -> i32 {
    if surface_id == 0 {
        return 0;
    }
    ffi_catch!(0, {
        let surface = unsafe { deref_handle_mut::<WgpuSurface>(surface_id) };
        if surface.resize(width, height).is_ok() {
            1
        } else {
            0
        }
    })
}

/// Destroy surface.
#[no_mangle]
pub extern "C" fn wgpu_destroy_surface(surface_id: u64) {
    if surface_id == 0 {
        return;
    }
    ffi_catch!((), {
        unsafe {
            drop_handle::<WgpuSurface>(surface_id);
        }
    })
}

// =============================================================================
// ANDROID JNI
// =============================================================================

#[cfg(target_os = "android")]
#[no_mangle]
pub extern "system" fn Java_dev_dartgfx_flutter_1wgpu_FlutterWgpuPlugin_nativeGetWindow(
    env: jni::JNIEnv,
    _class: jni::objects::JClass,
    surface: jni::objects::JObject,
) -> jni::sys::jlong {
    use ndk::native_window::NativeWindow;

    let native_window = unsafe { NativeWindow::from_surface(env.get_raw(), surface.as_raw()) };

    match native_window {
        Some(window) => {
            let ptr = window.ptr().as_ptr() as jni::sys::jlong;
            std::mem::forget(window);
            log::info!("Got ANativeWindow: 0x{:x}", ptr);
            ptr
        }
        None => {
            log::error!("Failed to get ANativeWindow from Surface");
            0
        }
    }
}

#[cfg(target_os = "android")]
#[no_mangle]
pub extern "system" fn Java_dev_dartgfx_flutter_1wgpu_FlutterWgpuPlugin_nativeReleaseWindow(
    _env: jni::JNIEnv,
    _class: jni::objects::JClass,
    window_ptr: jni::sys::jlong,
) {
    if window_ptr != 0 {
        unsafe {
            use ndk::native_window::NativeWindow;
            use std::ptr::NonNull;
            let ptr = NonNull::new(window_ptr as *mut std::ffi::c_void);
            if let Some(ptr) = ptr {
                let _ = NativeWindow::from_ptr(ptr.cast());
            }
        }
        log::info!("Released ANativeWindow: 0x{:x}", window_ptr);
    }
}

// =============================================================================
// FRAME NOTIFICATION (Apple only)
// =============================================================================

#[cfg(target_vendor = "apple")]
#[no_mangle]
pub extern "C" fn wgpu_mark_frame_available(engine_handle: i64, texture_id: i64) {
    use objc2::msg_send;

    unsafe {
        let class = match objc2::runtime::AnyClass::get(c"FlutterWgpuPlugin") {
            Some(c) => c,
            None => {
                log::error!("FlutterWgpuPlugin class not found");
                return;
            }
        };

        let _: () = msg_send![class, markFrameAvailable: engine_handle, textureId: texture_id];
    }
}

#[cfg(not(target_vendor = "apple"))]
#[no_mangle]
pub extern "C" fn wgpu_mark_frame_available(_engine_handle: i64, _texture_id: i64) {
    // No-op: Android uses swapchain, no markFrameAvailable needed
}

// =============================================================================
// SURFACE RENDERING
// =============================================================================

/// Get texture view for rendering to surface.
#[no_mangle]
pub extern "C" fn wgpu_surface_get_texture_view(surface_id: u64) -> WGPUTextureView {
    if surface_id == 0 {
        return 0;
    }

    ffi_catch!(0, {
        #[cfg(not(target_os = "android"))]
        {
            let surface = unsafe { deref_handle::<WgpuSurface>(surface_id) };
            let view = surface
                .texture
                .create_view(&wgpu::TextureViewDescriptor::default());
            into_handle(view)
        }

        #[cfg(target_os = "android")]
        {
            let surface = unsafe { deref_handle_mut::<WgpuSurface>(surface_id) };

            if surface.current_frame.is_none() {
                let frame = match surface.get_current_texture() {
                    wgpu::CurrentSurfaceTexture::Success(tex)
                    | wgpu::CurrentSurfaceTexture::Suboptimal(tex) => tex,
                    wgpu::CurrentSurfaceTexture::Outdated | wgpu::CurrentSurfaceTexture::Lost => {
                        surface
                            .platform
                            .resize(&surface.device, surface.width, surface.height);
                        match surface.get_current_texture() {
                            wgpu::CurrentSurfaceTexture::Success(tex)
                            | wgpu::CurrentSurfaceTexture::Suboptimal(tex) => tex,
                            other => {
                                log::error!(
                                    "Failed to get swapchain texture after reconfigure: {:?}",
                                    other
                                );
                                return 0;
                            }
                        }
                    }
                    other => {
                        log::error!("Failed to get swapchain texture: {:?}", other);
                        return 0;
                    }
                };
                surface.current_frame = Some(frame);
            }

            let frame = surface.current_frame.as_ref().unwrap();
            let view = frame
                .texture
                .create_view(&wgpu::TextureViewDescriptor::default());
            into_handle(view)
        }
    })
}
