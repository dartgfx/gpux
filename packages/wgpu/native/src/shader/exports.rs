use crate::abi::types::*;
use crate::runtime::handle::*;
use crate::runtime::label::label_from_ptr;
use crate::runtime::state::*;
use crate::shader::ops;
use crate::{ffi_catch, LAST_ERROR};

#[export_name = "wgpun_DeviceCreateShaderModule"]
pub extern "C" fn wgpuDeviceCreateShaderModule(
    device: WGPUDevice,
    source: *const u8,
    source_len: u32,
    label: *const std::ffi::c_char,
) -> WGPUShaderModule {
    if device == 0 || source.is_null() || source_len == 0 {
        return 0;
    }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let source = unsafe {
            let bytes = std::slice::from_raw_parts(source, source_len as usize);
            match std::str::from_utf8(bytes) {
                Ok(s) => s,
                Err(_) => return 0,
            }
        };
        let lbl = unsafe { label_from_ptr(label) };
        ops::device_create_shader_module(&entry.device, source, lbl)
    })
}

#[export_name = "wgpun_ShaderModuleGetCompilationInfo"]
pub extern "C" fn wgpuShaderModuleGetCompilationInfo(
    module: WGPUShaderModule,
) -> *const std::ffi::c_char {
    if module == 0 {
        return std::ptr::null();
    }
    ffi_catch!(std::ptr::null(), {
        match ops::shader_module_get_compilation_info(module) {
            Some(info) => LAST_ERROR.with(|e| {
                let cstr = std::ffi::CString::new(info).unwrap_or_default();
                let ptr = cstr.as_ptr();
                *e.borrow_mut() = Some(cstr);
                ptr
            }),
            None => std::ptr::null(),
        }
    })
}

#[export_name = "wgpun_ShaderModuleRelease"]
pub extern "C" fn wgpuShaderModuleRelease(module: WGPUShaderModule) {
    ffi_catch!((), {
        ops::shader_module_release(module);
    })
}

#[export_name = "wgpun_ShaderModuleRelease_p"]
pub extern "C" fn shader_module_release_p(ptr: *mut std::ffi::c_void) {
    wgpuShaderModuleRelease(ptr as u64);
}
