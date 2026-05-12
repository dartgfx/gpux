use std::sync::Arc;

use crate::abi::types::*;
use crate::ffi_catch;
use crate::runtime::handle::*;
use crate::runtime::state::*;
use crate::sync::ops;

#[export_name = "wgpun_QueueSubmitFenced"]
pub extern "C" fn wgpuQueueSubmitFenced(
    queue: WGPUQueue,
    command_buffers: *const WGPUCommandBuffer,
    count: u32,
) -> WGPUFence {
    if queue == 0 {
        return 0;
    }
    ffi_catch!(0, {
        let queue_arc = unsafe { deref_handle::<Arc<wgpu::Queue>>(queue) };
        let buffers = if count > 0 && !command_buffers.is_null() {
            unsafe { std::slice::from_raw_parts(command_buffers, count as usize) }
        } else {
            &[]
        };
        ops::queue_submit_fenced(queue_arc, buffers)
    })
}

#[export_name = "wgpun_FenceStatus"]
pub extern "C" fn wgpuFenceStatus(device: WGPUDevice, handle: WGPUFence) -> i32 {
    if device == 0 || handle == 0 {
        return 1;
    }
    ffi_catch!(1, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        ops::fence_status(&entry.device, handle)
    })
}

#[export_name = "wgpun_FenceWait"]
pub extern "C" fn wgpuFenceWait(device: WGPUDevice, handle: WGPUFence) -> u32 {
    if device == 0 || handle == 0 {
        return 0;
    }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        ops::fence_wait(&entry.device, handle)
    })
}

#[export_name = "wgpun_FenceRelease"]
pub extern "C" fn wgpuFenceRelease(handle: WGPUFence) {
    if handle == 0 {
        return;
    }
    ffi_catch!((), {
        ops::fence_release(handle);
    })
}

#[export_name = "wgpun_FenceRelease_p"]
pub extern "C" fn fence_release_p(ptr: *mut std::ffi::c_void) {
    wgpuFenceRelease(ptr as u64);
}
