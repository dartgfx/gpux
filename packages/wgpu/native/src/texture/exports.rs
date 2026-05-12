use crate::abi::types::*;
use crate::ffi_catch;
use crate::runtime::handle::*;
use crate::runtime::state::*;
use crate::texture::ops;

// =============================================================================
// TEXTURE
// =============================================================================

#[export_name = "wgpun_DeviceCreateTexture"]
pub extern "C" fn wgpuDeviceCreateTexture(
    device: WGPUDevice,
    descriptor: *const WGPUTextureDescriptor,
) -> WGPUTexture {
    if device == 0 || descriptor.is_null() {
        return 0;
    }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let desc = unsafe { &*descriptor };
        ops::device_create_texture(&entry.device, desc)
    })
}

#[export_name = "wgpun_TextureCreateView"]
pub extern "C" fn wgpuTextureCreateView(
    texture: WGPUTexture,
    descriptor: *const WGPUTextureViewDescriptor,
) -> WGPUTextureView {
    if texture == 0 {
        return 0;
    }
    ffi_catch!(0, {
        let desc = if descriptor.is_null() {
            None
        } else {
            Some(unsafe { &*descriptor })
        };
        ops::texture_create_view(texture, desc)
    })
}

#[export_name = "wgpun_TextureRelease"]
pub extern "C" fn wgpuTextureRelease(texture: WGPUTexture) {
    ffi_catch!((), {
        ops::texture_release(texture);
    })
}

#[export_name = "wgpun_TextureRelease_p"]
pub extern "C" fn texture_release_p(ptr: *mut std::ffi::c_void) {
    wgpuTextureRelease(ptr as u64);
}

#[export_name = "wgpun_TextureViewRelease"]
pub extern "C" fn wgpuTextureViewRelease(view: WGPUTextureView) {
    ffi_catch!((), {
        ops::texture_view_release(view);
    })
}

#[export_name = "wgpun_TextureViewRelease_p"]
pub extern "C" fn texture_view_release_p(ptr: *mut std::ffi::c_void) {
    wgpuTextureViewRelease(ptr as u64);
}
