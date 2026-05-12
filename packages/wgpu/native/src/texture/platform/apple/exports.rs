use crate::abi::enums::texture_format_from_u32;
use crate::abi::types::*;
use crate::runtime::handle::*;
use crate::runtime::state::*;
#[cfg(target_vendor = "apple")]
use crate::surface::platform::apple::{
    import_iosurface_plane_to_wgpu, release_iosurface, retain_iosurface, IOSurfaceRef,
};
use crate::{ffi_catch, set_error};

#[cfg(target_vendor = "apple")]
#[export_name = "wgpun_DeviceImportIOSurfacePlane"]
pub extern "C" fn wgpuDeviceImportIOSurfacePlane(
    device: WGPUDevice,
    iosurface: *mut std::ffi::c_void,
    plane: u32,
    width: u32,
    height: u32,
    format: u32,
) -> WGPUTexture {
    if device == 0 || iosurface.is_null() || width == 0 || height == 0 {
        return 0;
    }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        match import_iosurface_plane_to_wgpu(
            &entry.device,
            iosurface as IOSurfaceRef,
            plane as usize,
            width,
            height,
            texture_format_from_u32(format),
        ) {
            Ok(texture) => into_handle(texture),
            Err(error) => {
                set_error(error);
                0
            }
        }
    })
}

#[cfg(not(target_vendor = "apple"))]
#[export_name = "wgpun_DeviceImportIOSurfacePlane"]
pub extern "C" fn wgpuDeviceImportIOSurfacePlane(
    _device: WGPUDevice,
    _iosurface: *mut std::ffi::c_void,
    _plane: u32,
    _width: u32,
    _height: u32,
    _format: u32,
) -> WGPUTexture {
    set_error("IOSurface import is only supported by the Metal backend");
    0
}

#[cfg(target_vendor = "apple")]
#[export_name = "wgpun_IOSurfaceRetain"]
pub extern "C" fn iosurface_retain(iosurface: *mut std::ffi::c_void) -> *mut std::ffi::c_void {
    if iosurface.is_null() {
        return std::ptr::null_mut();
    }
    ffi_catch!(std::ptr::null_mut(), {
        match retain_iosurface(iosurface as IOSurfaceRef) {
            Ok(retained) => retained.cast(),
            Err(error) => {
                set_error(error);
                std::ptr::null_mut()
            }
        }
    })
}

#[cfg(not(target_vendor = "apple"))]
#[export_name = "wgpun_IOSurfaceRetain"]
pub extern "C" fn iosurface_retain(_iosurface: *mut std::ffi::c_void) -> *mut std::ffi::c_void {
    set_error("IOSurface retain is only supported on Apple platforms");
    std::ptr::null_mut()
}

#[cfg(target_vendor = "apple")]
#[export_name = "wgpun_IOSurfaceRelease"]
pub extern "C" fn iosurface_release(iosurface: *mut std::ffi::c_void) {
    ffi_catch!((), {
        release_iosurface(iosurface as IOSurfaceRef);
    })
}

#[cfg(not(target_vendor = "apple"))]
#[export_name = "wgpun_IOSurfaceRelease"]
pub extern "C" fn iosurface_release(_iosurface: *mut std::ffi::c_void) {}

#[export_name = "wgpun_IOSurfaceRelease_p"]
pub extern "C" fn iosurface_release_p(ptr: *mut std::ffi::c_void) {
    iosurface_release(ptr);
}
