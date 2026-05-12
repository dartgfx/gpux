use std::ffi::{c_char, CString};
use std::sync::{Arc, Mutex};

use crate::abi::types::*;
use crate::device::limits::{
    features_from_bitmask, features_to_bitmask, limits_from_ffi, limits_to_ffi, zero_limits,
};
use crate::runtime::handle::*;
use crate::runtime::label::label_from_ptr;
use crate::runtime::state::*;
use crate::{clear_error, ffi_catch, set_error, wgpu_get_last_error, LAST_ERROR};

/// Request a device from an adapter.
/// Returns device handle, or 0 on failure.
#[export_name = "wgpun_AdapterRequestDevice"]
pub extern "C" fn wgpun_AdapterRequestDevice(
    adapter: WGPUAdapter,
    descriptor: *const WGPUDeviceDescriptor,
) -> WGPUDevice {
    clear_error();

    if adapter == 0 {
        set_error("wgpu not initialized");
        return 0;
    }

    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<AdapterEntry>(adapter) };

        let (features, limits) = if descriptor.is_null() {
            (wgpu::Features::empty(), wgpu::Limits::default())
        } else {
            let desc = unsafe { &*descriptor };
            let mut features = features_from_bitmask(desc.required_features);
            if desc.bindless_textures != 0 {
                features |= wgpu::Features::TEXTURE_BINDING_ARRAY
                    | wgpu::Features::PARTIALLY_BOUND_BINDING_ARRAY
                    | wgpu::Features::SAMPLED_TEXTURE_AND_STORAGE_BUFFER_ARRAY_NON_UNIFORM_INDEXING;
            }
            if desc.immediates != 0 {
                features |= wgpu::Features::IMMEDIATES;
            }

            let mut limits = if desc.required_limits.is_null() {
                wgpu::Limits::default()
            } else {
                let l = unsafe { &*desc.required_limits };
                limits_from_ffi(l)
            };
            // When IMMEDIATES is requested but no limit was set, use adapter's limit.
            if desc.immediates != 0 && limits.max_immediate_size == 0 {
                limits.max_immediate_size = entry.adapter.limits().max_immediate_size;
            }
            // Binding arrays require a non-zero per-stage element limit.
            if desc.bindless_textures != 0
                && limits.max_binding_array_elements_per_shader_stage == 0
            {
                limits.max_binding_array_elements_per_shader_stage = entry
                    .adapter
                    .limits()
                    .max_binding_array_elements_per_shader_stage;
            }
            (features, limits)
        };

        let device_label = if !descriptor.is_null() {
            unsafe { label_from_ptr((*descriptor).label) }
        } else {
            None
        };

        let (device, queue) =
            match pollster::block_on(entry.adapter.request_device(&wgpu::DeviceDescriptor {
                label: device_label.or(Some("wgpu_native_device")),
                required_features: features,
                required_limits: limits,
                memory_hints: wgpu::MemoryHints::Performance,
                trace: wgpu::Trace::Off,
                experimental_features: wgpu::ExperimentalFeatures::default(),
            })) {
                Ok((d, q)) => (d, q),
                Err(e) => {
                    set_error(format!("Failed to request device: {}", e));
                    return 0;
                }
            };

        let errors = Arc::new(Mutex::new(Vec::<CString>::new()));
        let errors_clone = Arc::clone(&errors);
        device.on_uncaptured_error(Arc::new(move |error: wgpu::Error| {
            let msg = format!("{error}");
            log::error!("wgpu device error: {msg}");
            if let Ok(cstr) = CString::new(msg) {
                errors_clone.lock().unwrap().push(cstr);
            }
        }));

        into_handle(DeviceEntry {
            device: Arc::new(device),
            queue: Arc::new(queue),
            adapter_handle: adapter,
            errors,
        })
    })
}

/// Release a device.
#[export_name = "wgpun_DeviceRelease"]
pub extern "C" fn wgpun_DeviceRelease(device: WGPUDevice) {
    if device == 0 {
        return;
    }
    ffi_catch!((), {
        unsafe {
            drop_handle::<DeviceEntry>(device);
        }
    })
}

/// Get the queue for a device.
/// Returns queue handle (a heap-allocated Arc<Queue> clone).
#[export_name = "wgpun_DeviceGetQueue"]
pub extern "C" fn wgpun_DeviceGetQueue(device: WGPUDevice) -> WGPUQueue {
    if device == 0 {
        return 0;
    }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        into_handle(entry.queue.clone())
    })
}

/// Poll a device for completed work.
#[export_name = "wgpun_DevicePoll"]
pub extern "C" fn wgpun_DevicePoll(device: WGPUDevice, wait: u8) {
    if device == 0 {
        return;
    }
    ffi_catch!((), {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let poll_type = if wait != 0 {
            wgpu::PollType::wait_indefinitely()
        } else {
            wgpu::PollType::Poll
        };
        let _ = entry.device.poll(poll_type);
    })
}

/// Get device features as a bitmask.
/// Bit positions match GpuFeatureName enum order.
#[export_name = "wgpun_DeviceGetFeatures"]
pub extern "C" fn wgpun_DeviceGetFeatures(device: WGPUDevice) -> u32 {
    if device == 0 {
        return 1;
    }
    ffi_catch!(1, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        features_to_bitmask(entry.device.features())
    })
}

/// Get device limits.
#[export_name = "wgpun_DeviceGetLimits"]
pub extern "C" fn wgpun_DeviceGetLimits(device: WGPUDevice) -> WGPUDeviceLimits {
    if device == 0 {
        return zero_limits();
    }
    ffi_catch!(zero_limits(), {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let l = entry.device.limits();
        limits_to_ffi(&l)
    })
}

/// Pop one captured device error.
/// Returns null if the error queue is empty.
#[export_name = "wgpun_DevicePopError"]
pub extern "C" fn wgpun_DevicePopError(device: WGPUDevice) -> *const c_char {
    if device == 0 {
        return std::ptr::null();
    }
    ffi_catch!(std::ptr::null(), {
        let errors_arc = {
            let entry = unsafe { deref_handle::<DeviceEntry>(device) };
            Arc::clone(&entry.errors)
        };

        let mut errors = errors_arc.lock().unwrap();
        match errors.pop() {
            Some(cstr) => {
                LAST_ERROR.with(|e| *e.borrow_mut() = Some(cstr));
                wgpu_get_last_error()
            }
            None => std::ptr::null(),
        }
    })
}

thread_local! {
    static ERROR_SCOPE_STACK: std::cell::RefCell<Vec<wgpu::ErrorScopeGuard>> =
        std::cell::RefCell::new(Vec::new());
}

/// Push an error scope onto the device's error scope stack.
/// filter: 1 = Validation, 2 = OutOfMemory, 3 = Internal
#[export_name = "wgpun_DevicePushErrorScope"]
pub extern "C" fn wgpun_DevicePushErrorScope(device: WGPUDevice, filter: u32) {
    if device == 0 {
        return;
    }
    ffi_catch!((), {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let wgpu_filter = match filter {
            1 => wgpu::ErrorFilter::Validation,
            2 => wgpu::ErrorFilter::OutOfMemory,
            3 => wgpu::ErrorFilter::Internal,
            _ => return,
        };
        let guard = entry.device.push_error_scope(wgpu_filter);
        ERROR_SCOPE_STACK.with(|stack| stack.borrow_mut().push(guard));
    })
}

/// Pop the top error scope and return the error type + message.
/// Returns error type: 0 = no error, 1 = Validation, 2 = OutOfMemory, 3 = Internal.
/// If an error was captured, the message is available via wgpun_DevicePopScopeError.
#[export_name = "wgpun_DevicePopErrorScope"]
pub extern "C" fn wgpun_DevicePopErrorScope(device: WGPUDevice) -> u32 {
    if device == 0 {
        return 0;
    }
    ffi_catch!(0, {
        let guard = ERROR_SCOPE_STACK.with(|stack| stack.borrow_mut().pop());
        let guard = match guard {
            Some(g) => g,
            None => return 0,
        };

        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let error = pollster::block_on(guard.pop());
        let _ = entry.device.poll(wgpu::PollType::Poll);

        match error {
            None => 0,
            Some(wgpu::Error::Validation { description, .. }) => {
                if let Ok(cstr) = CString::new(description) {
                    LAST_ERROR.with(|e| *e.borrow_mut() = Some(cstr));
                }
                1
            }
            Some(wgpu::Error::OutOfMemory { .. }) => {
                if let Ok(cstr) = CString::new("Out of memory") {
                    LAST_ERROR.with(|e| *e.borrow_mut() = Some(cstr));
                }
                2
            }
            Some(wgpu::Error::Internal { description, .. }) => {
                if let Ok(cstr) = CString::new(description) {
                    LAST_ERROR.with(|e| *e.borrow_mut() = Some(cstr));
                }
                3
            }
        }
    })
}
