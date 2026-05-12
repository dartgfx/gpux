use crate::abi::types::*;
use crate::ffi_catch;
use crate::runtime::handle::*;
use crate::runtime::state::*;
use crate::sampler::ops;

#[export_name = "wgpun_DeviceCreateSampler"]
pub extern "C" fn wgpuDeviceCreateSampler(
    device: WGPUDevice,
    descriptor: *const WGPUSamplerDescriptor,
) -> WGPUSampler {
    if device == 0 || descriptor.is_null() {
        return 0;
    }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let desc = unsafe { &*descriptor };
        ops::device_create_sampler(&entry.device, desc)
    })
}

#[export_name = "wgpun_SamplerRelease"]
pub extern "C" fn wgpuSamplerRelease(sampler: WGPUSampler) {
    ffi_catch!((), {
        ops::sampler_release(sampler);
    })
}

#[export_name = "wgpun_SamplerRelease_p"]
pub extern "C" fn sampler_release_p(ptr: *mut std::ffi::c_void) {
    wgpuSamplerRelease(ptr as u64);
}
