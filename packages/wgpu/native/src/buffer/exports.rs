use crate::abi::types::*;
use crate::buffer::ops;
use crate::ffi_catch;
use crate::runtime::handle::*;
use crate::runtime::state::*;

#[export_name = "wgpun_DeviceCreateBuffer"]
pub extern "C" fn wgpuDeviceCreateBuffer(
    device: WGPUDevice,
    descriptor: *const WGPUBufferDescriptor,
) -> WGPUBuffer {
    if device == 0 || descriptor.is_null() {
        return 0;
    }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let desc = unsafe { &*descriptor };
        ops::device_create_buffer(&entry.device, desc)
    })
}

#[export_name = "wgpun_BufferRelease"]
pub extern "C" fn wgpuBufferRelease(buffer: WGPUBuffer) {
    ffi_catch!((), {
        ops::buffer_release(buffer);
    })
}

#[export_name = "wgpun_BufferRelease_p"]
pub extern "C" fn buffer_release_p(ptr: *mut std::ffi::c_void) {
    wgpuBufferRelease(ptr as u64);
}
