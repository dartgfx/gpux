use crate::abi::types::*;
use crate::bind_group::ops;
use crate::ffi_catch;
use crate::runtime::handle::*;
use crate::runtime::state::*;

#[export_name = "wgpun_DeviceCreateBindGroupLayout"]
pub extern "C" fn wgpuDeviceCreateBindGroupLayout(
    device: WGPUDevice,
    desc: *const WGPUBindGroupLayoutDescriptor,
) -> WGPUBindGroupLayout {
    if device == 0 || desc.is_null() {
        return 0;
    }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let desc = unsafe { &*desc };
        ops::device_create_bind_group_layout(&entry.device, desc)
    })
}

#[export_name = "wgpun_BindGroupLayoutRelease"]
pub extern "C" fn wgpuBindGroupLayoutRelease(layout: WGPUBindGroupLayout) {
    ffi_catch!((), {
        ops::bind_group_layout_release(layout);
    })
}

#[export_name = "wgpun_BindGroupLayoutRelease_p"]
pub extern "C" fn bind_group_layout_release_p(ptr: *mut std::ffi::c_void) {
    wgpuBindGroupLayoutRelease(ptr as u64);
}

// =============================================================================
// BIND GROUP
// =============================================================================

#[export_name = "wgpun_DeviceCreateBindGroup"]
pub extern "C" fn wgpuDeviceCreateBindGroup(
    device: WGPUDevice,
    desc: *const WGPUBindGroupDescriptor,
) -> WGPUBindGroup {
    if device == 0 || desc.is_null() {
        return 0;
    }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let desc = unsafe { &*desc };
        ops::device_create_bind_group(&entry.device, desc)
    })
}

#[export_name = "wgpun_BindGroupRelease"]
pub extern "C" fn wgpuBindGroupRelease(group: WGPUBindGroup) {
    ffi_catch!((), {
        ops::bind_group_release(group);
    })
}

#[export_name = "wgpun_BindGroupRelease_p"]
pub extern "C" fn bind_group_release_p(ptr: *mut std::ffi::c_void) {
    wgpuBindGroupRelease(ptr as u64);
}
