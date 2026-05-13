use crate::abi::enums::texture_format_from_u32;
use crate::abi::types::*;
use crate::runtime::handle::*;
use crate::runtime::state::*;
#[cfg(target_os = "android")]
use crate::surface::platform::android::{
    acquire_ahardware_buffer, import_ahardware_buffer_to_wgpu, release_ahardware_buffer,
};
use crate::{ffi_catch, set_error};

#[cfg(target_os = "android")]
#[export_name = "wgpun_DeviceImportAHardwareBuffer"]
pub extern "C" fn wgpuDeviceImportAHardwareBuffer(
    device: WGPUDevice,
    ahb: *mut std::ffi::c_void,
    width: u32,
    height: u32,
    format: u32,
) -> WGPUTexture {
    if device == 0 || ahb.is_null() || width == 0 || height == 0 {
        return 0;
    }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        match import_ahardware_buffer_to_wgpu(
            &entry.device,
            ahb,
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

#[cfg(not(target_os = "android"))]
#[export_name = "wgpun_DeviceImportAHardwareBuffer"]
pub extern "C" fn wgpuDeviceImportAHardwareBuffer(
    _device: WGPUDevice,
    _ahb: *mut std::ffi::c_void,
    _width: u32,
    _height: u32,
    _format: u32,
) -> WGPUTexture {
    set_error("AHardwareBuffer import is only supported on Android");
    0
}

#[cfg(target_os = "android")]
#[export_name = "wgpun_AHardwareBufferAcquire"]
pub extern "C" fn ahardware_buffer_acquire(
    ahb: *mut std::ffi::c_void,
) -> *mut std::ffi::c_void {
    if ahb.is_null() {
        return std::ptr::null_mut();
    }
    ffi_catch!(std::ptr::null_mut(), {
        match acquire_ahardware_buffer(ahb) {
            Ok(acquired) => acquired,
            Err(error) => {
                set_error(error);
                std::ptr::null_mut()
            }
        }
    })
}

#[cfg(not(target_os = "android"))]
#[export_name = "wgpun_AHardwareBufferAcquire"]
pub extern "C" fn ahardware_buffer_acquire(
    _ahb: *mut std::ffi::c_void,
) -> *mut std::ffi::c_void {
    set_error("AHardwareBuffer acquire is only supported on Android");
    std::ptr::null_mut()
}

#[cfg(target_os = "android")]
#[export_name = "wgpun_AHardwareBufferRelease"]
pub extern "C" fn ahardware_buffer_release(ahb: *mut std::ffi::c_void) {
    ffi_catch!((), {
        release_ahardware_buffer(ahb);
    })
}

#[cfg(not(target_os = "android"))]
#[export_name = "wgpun_AHardwareBufferRelease"]
pub extern "C" fn ahardware_buffer_release(_ahb: *mut std::ffi::c_void) {}

#[export_name = "wgpun_AHardwareBufferRelease_p"]
pub extern "C" fn ahardware_buffer_release_p(ptr: *mut std::ffi::c_void) {
    ahardware_buffer_release(ptr);
}
