use std::ffi::CString;

use crate::abi::types::*;
use crate::device::limits::{features_to_bitmask, limits_to_ffi, zero_limits};
use crate::runtime::handle::*;
use crate::runtime::state::*;
use crate::{clear_error, ffi_catch, set_error};

/// Request an adapter from an instance.
/// Returns adapter handle, or 0 on failure.
#[export_name = "wgpun_InstanceRequestAdapter"]
pub extern "C" fn wgpun_InstanceRequestAdapter(
    instance: WGPUInstance,
    options: *const WGPURequestAdapterOptions,
) -> WGPUAdapter {
    clear_error();

    if instance == 0 {
        set_error("wgpu not initialized");
        return 0;
    }

    let wgpu_instance = unsafe { deref_handle::<wgpu::Instance>(instance) };

    let (power_preference, force_fallback) = if options.is_null() {
        (wgpu::PowerPreference::HighPerformance, false)
    } else {
        let opts = unsafe { &*options };
        let power = match opts.power_preference {
            1 => wgpu::PowerPreference::LowPower,
            2 => wgpu::PowerPreference::HighPerformance,
            _ => wgpu::PowerPreference::None,
        };
        (power, opts.force_fallback_adapter != 0)
    };

    ffi_catch!(0, {
        let adapter =
            match pollster::block_on(wgpu_instance.request_adapter(&wgpu::RequestAdapterOptions {
                power_preference,
                compatible_surface: None,
                force_fallback_adapter: force_fallback,
            })) {
                Ok(a) => a,
                Err(e) => {
                    set_error(format!("Failed to request adapter: {}", e));
                    return 0;
                }
            };

        log::info!("Adapter requested: {:?}", adapter.get_info());

        into_handle(AdapterEntry {
            adapter,
            instance_handle: instance,
            cached_info: std::sync::OnceLock::new(),
        })
    })
}

/// Release an adapter.
#[export_name = "wgpun_AdapterRelease"]
pub extern "C" fn wgpun_AdapterRelease(adapter: WGPUAdapter) {
    if adapter == 0 {
        return;
    }
    ffi_catch!((), {
        unsafe {
            drop_handle::<AdapterEntry>(adapter);
        }
    })
}

/// Get adapter info.
#[export_name = "wgpun_AdapterGetInfo"]
pub extern "C" fn wgpun_AdapterGetInfo(adapter: WGPUAdapter) -> WGPUAdapterInfo {
    use std::ptr;

    let empty = || WGPUAdapterInfo {
        vendor: ptr::null(),
        architecture: ptr::null(),
        device: ptr::null(),
        description: ptr::null(),
        backend_type: 0,
        adapter_type: 0,
        vendor_id: 0,
        device_id: 0,
        driver_api_version: 0,
    };

    if adapter == 0 {
        return empty();
    }

    ffi_catch!(empty(), {
        let entry = unsafe { deref_handle::<AdapterEntry>(adapter) };
        let info = entry.adapter.get_info();

        let backend_type = match info.backend {
            wgpu::Backend::Vulkan => 1,
            wgpu::Backend::Metal => 2,
            wgpu::Backend::Dx12 => 3,
            wgpu::Backend::Gl => 4,
            wgpu::Backend::BrowserWebGpu => 5,
            _ => 0,
        };

        let adapter_type = match info.device_type {
            wgpu::DeviceType::Other => 0,
            wgpu::DeviceType::IntegratedGpu => 1,
            wgpu::DeviceType::DiscreteGpu => 2,
            wgpu::DeviceType::VirtualGpu => 3,
            wgpu::DeviceType::Cpu => 4,
        };

        let (device_str, description_str) = entry.cached_info.get_or_init(|| {
            (
                CString::new(info.name.clone()).unwrap_or_default(),
                CString::new(info.driver_info.clone()).unwrap_or_default(),
            )
        });

        // Extract Vulkan API version from HAL physical device properties.
        let driver_api_version = if info.backend == wgpu::Backend::Vulkan {
            unsafe {
                entry
                    .adapter
                    .as_hal::<wgpu::hal::api::Vulkan>()
                    .map(|hal_adapter| {
                        hal_adapter
                            .physical_device_capabilities()
                            .properties()
                            .api_version
                    })
                    .unwrap_or(0)
            }
        } else {
            0
        };

        WGPUAdapterInfo {
            vendor: ptr::null(),
            architecture: ptr::null(),
            device: device_str.as_ptr() as *const _,
            description: description_str.as_ptr() as *const _,
            backend_type,
            adapter_type,
            vendor_id: info.vendor,
            device_id: info.device,
            driver_api_version,
        }
    })
}

/// Get adapter limits.
#[export_name = "wgpun_AdapterGetLimits"]
pub extern "C" fn wgpun_AdapterGetLimits(adapter: WGPUAdapter) -> WGPUDeviceLimits {
    if adapter == 0 {
        return zero_limits();
    }
    ffi_catch!(zero_limits(), {
        let entry = unsafe { deref_handle::<AdapterEntry>(adapter) };
        let l = entry.adapter.limits();
        limits_to_ffi(&l)
    })
}

/// Get adapter downlevel capability flags as a raw u64 bitmask.
#[export_name = "wgpun_AdapterGetDownlevelFlags"]
pub extern "C" fn wgpun_AdapterGetDownlevelFlags(adapter: WGPUAdapter) -> u64 {
    if adapter == 0 {
        return 0;
    }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<AdapterEntry>(adapter) };
        entry
            .adapter
            .get_downlevel_capabilities()
            .flags
            .bits()
            .into()
    })
}

/// Get adapter features as a bitmask.
/// Bit positions match GpuFeatureName enum order.
#[export_name = "wgpun_AdapterGetFeatures"]
pub extern "C" fn wgpun_AdapterGetFeatures(adapter: WGPUAdapter) -> u32 {
    if adapter == 0 {
        return 1;
    } // just coreFeaturesAndLimits
    ffi_catch!(1, {
        let entry = unsafe { deref_handle::<AdapterEntry>(adapter) };
        features_to_bitmask(entry.adapter.features())
    })
}
