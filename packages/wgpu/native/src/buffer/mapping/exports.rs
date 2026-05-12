use crate::abi::types::*;
use crate::buffer::mapping::ops;
use crate::ffi_catch;
use crate::runtime::handle::*;
use crate::runtime::state::*;

#[export_name = "wgpun_BufferMapStart"]
pub extern "C" fn wgpuBufferMapStart(
    device: WGPUDevice,
    buffer: WGPUBuffer,
    offset: u64,
    size: u64,
    mode: u32,
) -> WGPUBufferMapping {
    if device == 0 || buffer == 0 {
        return 0;
    }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        ops::buffer_map_start(&entry.device, &entry.queue, buffer, offset, size, mode)
    })
}

#[export_name = "wgpun_BufferMapStatus"]
pub extern "C" fn wgpuBufferMapStatus(handle: WGPUBufferMapping) -> i32 {
    if handle == 0 {
        return -1;
    }
    ffi_catch!(-1, { ops::buffer_map_status(handle) })
}

#[export_name = "wgpun_BufferMapGetPointer"]
pub extern "C" fn wgpuBufferMapGetPointer(handle: WGPUBufferMapping) -> *const u8 {
    if handle == 0 {
        return std::ptr::null();
    }
    ffi_catch!(std::ptr::null(), { ops::buffer_map_get_pointer(handle) })
}

#[export_name = "wgpun_BufferMapGetPointerMut"]
pub extern "C" fn wgpuBufferMapGetPointerMut(handle: WGPUBufferMapping) -> *mut u8 {
    if handle == 0 {
        return std::ptr::null_mut();
    }
    ffi_catch!(std::ptr::null_mut(), {
        ops::buffer_map_get_pointer_mut(handle)
    })
}

#[export_name = "wgpun_BufferMapGetSize"]
pub extern "C" fn wgpuBufferMapGetSize(handle: WGPUBufferMapping) -> u64 {
    if handle == 0 {
        return 0;
    }
    ffi_catch!(0, { ops::buffer_map_get_size(handle) })
}

#[export_name = "wgpun_BufferUnmap"]
pub extern "C" fn wgpuBufferUnmap(handle: WGPUBufferMapping, _original_buffer_id: WGPUBuffer) {
    if handle == 0 {
        return;
    }
    ffi_catch!((), {
        ops::buffer_unmap(handle);
    })
}

#[export_name = "wgpun_BufferMappingRelease_p"]
pub extern "C" fn buffer_mapping_release_p(ptr: *mut std::ffi::c_void) {
    let handle = ptr as u64;
    if handle == 0 {
        return;
    }
    ffi_catch!((), {
        ops::buffer_unmap(handle);
    })
}
