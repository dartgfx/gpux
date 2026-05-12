// FFI exports for instance/adapter/device/queue lifecycle.

use std::ffi::{c_char, CString};
use std::sync::{Arc, Mutex};

use crate::api::resources::label_from_ptr;
use crate::api::types::*;
use crate::handle::*;
use crate::{clear_error, ffi_catch, set_error, wgpu_get_last_error, LAST_ERROR};

// =============================================================================
// FEATURE BITMASK MAPPING
// =============================================================================
// Bit positions match GpuFeatureName enum order in Dart.

const FEATURE_MAP: &[(u32, wgpu::Features)] = &[
    // 0: coreFeaturesAndLimits — always supported, no wgpu flag
    (1, wgpu::Features::DEPTH_CLIP_CONTROL),
    (2, wgpu::Features::DEPTH32FLOAT_STENCIL8),
    (3, wgpu::Features::TEXTURE_COMPRESSION_BC),
    // 4: textureCompressionBcSliced3d — no wgpu equivalent
    (5, wgpu::Features::TEXTURE_COMPRESSION_ETC2),
    (6, wgpu::Features::TEXTURE_COMPRESSION_ASTC),
    // 7: textureCompressionAstcSliced3d — no wgpu equivalent
    (8, wgpu::Features::TIMESTAMP_QUERY),
    (9, wgpu::Features::INDIRECT_FIRST_INSTANCE),
    (10, wgpu::Features::SHADER_F16),
    (11, wgpu::Features::RG11B10UFLOAT_RENDERABLE),
    (12, wgpu::Features::BGRA8UNORM_STORAGE),
    (13, wgpu::Features::FLOAT32_FILTERABLE),
    // 14: float32Blendable — no wgpu equivalent
    // 15: clipDistances — no wgpu equivalent
    (16, wgpu::Features::DUAL_SOURCE_BLENDING),
    (17, wgpu::Features::SUBGROUP),
    // 18-21: textureFormatsTier1/2, primitiveIndex, textureComponentSwizzle — no wgpu equivalent
];

/// Convert a GpuFeatureName bitmask to wgpu Features flags.
fn features_from_bitmask(bits: u32) -> wgpu::Features {
    let mut features = wgpu::Features::empty();
    for &(bit, flag) in FEATURE_MAP {
        if bits & (1 << bit) != 0 {
            features |= flag;
        }
    }
    // timestampQuery also implies TIMESTAMP_QUERY_INSIDE_ENCODERS
    if bits & (1 << 8) != 0 {
        features |= wgpu::Features::TIMESTAMP_QUERY_INSIDE_ENCODERS;
    }
    features
}

/// Convert a WGPUDeviceLimits FFI struct to wgpu Limits.
fn limits_from_ffi(l: &WGPUDeviceLimits) -> wgpu::Limits {
    wgpu::Limits {
        max_texture_dimension_1d: l.max_texture_dimension_1d,
        max_texture_dimension_2d: l.max_texture_dimension_2d,
        max_texture_dimension_3d: l.max_texture_dimension_3d,
        max_texture_array_layers: l.max_texture_array_layers,
        max_bind_groups: l.max_bind_groups,
        max_bindings_per_bind_group: l.max_bindings_per_bind_group,
        max_dynamic_uniform_buffers_per_pipeline_layout: l
            .max_dynamic_uniform_buffers_per_pipeline_layout,
        max_dynamic_storage_buffers_per_pipeline_layout: l
            .max_dynamic_storage_buffers_per_pipeline_layout,
        max_sampled_textures_per_shader_stage: l.max_sampled_textures_per_shader_stage,
        max_samplers_per_shader_stage: l.max_samplers_per_shader_stage,
        max_storage_buffers_per_shader_stage: l.max_storage_buffers_per_shader_stage,
        max_storage_textures_per_shader_stage: l.max_storage_textures_per_shader_stage,
        max_uniform_buffers_per_shader_stage: l.max_uniform_buffers_per_shader_stage,
        max_uniform_buffer_binding_size: l.max_uniform_buffer_binding_size,
        max_storage_buffer_binding_size: l.max_storage_buffer_binding_size,
        min_uniform_buffer_offset_alignment: l.min_uniform_buffer_offset_alignment,
        min_storage_buffer_offset_alignment: l.min_storage_buffer_offset_alignment,
        max_vertex_buffers: l.max_vertex_buffers,
        max_buffer_size: l.max_buffer_size,
        max_vertex_attributes: l.max_vertex_attributes,
        max_vertex_buffer_array_stride: l.max_vertex_buffer_array_stride,
        max_inter_stage_shader_variables: l.max_inter_stage_shader_variables,
        max_color_attachments: l.max_color_attachments,
        max_color_attachment_bytes_per_sample: l.max_color_attachment_bytes_per_sample,
        max_compute_workgroup_storage_size: l.max_compute_workgroup_storage_size,
        max_compute_invocations_per_workgroup: l.max_compute_invocations_per_workgroup,
        max_compute_workgroup_size_x: l.max_compute_workgroup_size_x,
        max_compute_workgroup_size_y: l.max_compute_workgroup_size_y,
        max_compute_workgroup_size_z: l.max_compute_workgroup_size_z,
        max_compute_workgroups_per_dimension: l.max_compute_workgroups_per_dimension,
        max_immediate_size: l.max_immediate_size,
        ..wgpu::Limits::default()
    }
}

/// Convert wgpu Features flags to a GpuFeatureName bitmask.
fn features_to_bitmask(features: wgpu::Features) -> u32 {
    let mut bits: u32 = 1; // bit 0 = coreFeaturesAndLimits, always set
    for &(bit, flag) in FEATURE_MAP {
        if features.contains(flag) {
            bits |= 1 << bit;
        }
    }
    bits
}

/// Build a zeroed WGPUDeviceLimits (all fields 0).
fn zero_limits() -> WGPUDeviceLimits {
    WGPUDeviceLimits {
        max_texture_dimension_1d: 0,
        max_texture_dimension_2d: 0,
        max_texture_dimension_3d: 0,
        max_texture_array_layers: 0,
        max_bind_groups: 0,
        max_bind_groups_plus_vertex_buffers: 0,
        max_bindings_per_bind_group: 0,
        max_dynamic_uniform_buffers_per_pipeline_layout: 0,
        max_dynamic_storage_buffers_per_pipeline_layout: 0,
        max_sampled_textures_per_shader_stage: 0,
        max_samplers_per_shader_stage: 0,
        max_storage_buffers_per_shader_stage: 0,
        max_storage_textures_per_shader_stage: 0,
        max_uniform_buffers_per_shader_stage: 0,
        max_uniform_buffer_binding_size: 0,
        max_storage_buffer_binding_size: 0,
        min_uniform_buffer_offset_alignment: 0,
        min_storage_buffer_offset_alignment: 0,
        max_vertex_buffers: 0,
        max_buffer_size: 0,
        max_vertex_attributes: 0,
        max_vertex_buffer_array_stride: 0,
        max_inter_stage_shader_variables: 0,
        max_color_attachments: 0,
        max_color_attachment_bytes_per_sample: 0,
        max_compute_workgroup_storage_size: 0,
        max_compute_invocations_per_workgroup: 0,
        max_compute_workgroup_size_x: 0,
        max_compute_workgroup_size_y: 0,
        max_compute_workgroup_size_z: 0,
        max_compute_workgroups_per_dimension: 0,
        max_immediate_size: 0,
    }
}

/// Convert wgpu::Limits into WGPUDeviceLimits FFI struct.
fn limits_to_ffi(l: &wgpu::Limits) -> WGPUDeviceLimits {
    WGPUDeviceLimits {
        max_texture_dimension_1d: l.max_texture_dimension_1d,
        max_texture_dimension_2d: l.max_texture_dimension_2d,
        max_texture_dimension_3d: l.max_texture_dimension_3d,
        max_texture_array_layers: l.max_texture_array_layers,
        max_bind_groups: l.max_bind_groups,
        max_bind_groups_plus_vertex_buffers: l.max_bind_groups + l.max_vertex_buffers,
        max_bindings_per_bind_group: l.max_bindings_per_bind_group,
        max_dynamic_uniform_buffers_per_pipeline_layout: l
            .max_dynamic_uniform_buffers_per_pipeline_layout,
        max_dynamic_storage_buffers_per_pipeline_layout: l
            .max_dynamic_storage_buffers_per_pipeline_layout,
        max_sampled_textures_per_shader_stage: l.max_sampled_textures_per_shader_stage,
        max_samplers_per_shader_stage: l.max_samplers_per_shader_stage,
        max_storage_buffers_per_shader_stage: l.max_storage_buffers_per_shader_stage,
        max_storage_textures_per_shader_stage: l.max_storage_textures_per_shader_stage,
        max_uniform_buffers_per_shader_stage: l.max_uniform_buffers_per_shader_stage,
        max_uniform_buffer_binding_size: l.max_uniform_buffer_binding_size,
        max_storage_buffer_binding_size: l.max_storage_buffer_binding_size,
        min_uniform_buffer_offset_alignment: l.min_uniform_buffer_offset_alignment,
        min_storage_buffer_offset_alignment: l.min_storage_buffer_offset_alignment,
        max_vertex_buffers: l.max_vertex_buffers,
        max_buffer_size: l.max_buffer_size as u64,
        max_vertex_attributes: l.max_vertex_attributes,
        max_vertex_buffer_array_stride: l.max_vertex_buffer_array_stride,
        max_inter_stage_shader_variables: l.max_inter_stage_shader_variables,
        max_color_attachments: l.max_color_attachments,
        max_color_attachment_bytes_per_sample: l.max_color_attachment_bytes_per_sample,
        max_compute_workgroup_storage_size: l.max_compute_workgroup_storage_size,
        max_compute_invocations_per_workgroup: l.max_compute_invocations_per_workgroup,
        max_compute_workgroup_size_x: l.max_compute_workgroup_size_x,
        max_compute_workgroup_size_y: l.max_compute_workgroup_size_y,
        max_compute_workgroup_size_z: l.max_compute_workgroup_size_z,
        max_compute_workgroups_per_dimension: l.max_compute_workgroups_per_dimension,
        max_immediate_size: l.max_immediate_size,
    }
}

// =============================================================================
// INSTANCE
// =============================================================================

/// Create a wgpu instance.
/// Returns instance handle, or 0 on failure.
#[export_name = "wgpun_CreateInstance"]
pub extern "C" fn wgpun_CreateInstance(descriptor: *const WGPUInstanceDescriptor) -> WGPUInstance {
    #[cfg(target_os = "android")]
    {
        android_logger::init_once(
            android_logger::Config::default()
                .with_max_level(log::LevelFilter::Info)
                .with_tag("wgpu_native"),
        );
    }
    #[cfg(not(target_os = "android"))]
    {
        env_logger::try_init().ok();
    }
    clear_error();

    ffi_catch!(0, {
        let mut flags = wgpu::InstanceFlags::empty();
        let mut backends = wgpu::Backends::PRIMARY;
        if !descriptor.is_null() {
            let desc = unsafe { &*descriptor };
            if desc.validation != 0 {
                flags |= wgpu::InstanceFlags::VALIDATION;
            }
            if desc.gpu_based_validation != 0 {
                flags |= wgpu::InstanceFlags::GPU_BASED_VALIDATION;
            }
            if desc.backends != 0 {
                backends = wgpu::Backends::from_bits_truncate(desc.backends);
            }
        }

        log::info!(
            "Creating wgpu instance with backends: {:?}, flags: {:?}",
            backends,
            flags
        );

        let instance = wgpu::Instance::new(wgpu::InstanceDescriptor {
            backends,
            flags,
            ..wgpu::InstanceDescriptor::new_without_display_handle()
        });

        into_handle(instance)
    })
}

/// Release an instance.
#[export_name = "wgpun_InstanceRelease"]
pub extern "C" fn wgpun_InstanceRelease(instance: WGPUInstance) {
    if instance == 0 {
        return;
    }
    ffi_catch!((), {
        unsafe {
            drop_handle::<wgpu::Instance>(instance);
        }
    })
}

/// Get WGSL language features supported by this instance.
/// Returns a bitmask matching GpuWgslLanguageFeatureName enum order.
#[export_name = "wgpun_InstanceGetWGSLLanguageFeatures"]
pub extern "C" fn wgpun_InstanceGetWGSLLanguageFeatures(instance: WGPUInstance) -> u32 {
    if instance == 0 {
        return 0;
    }
    ffi_catch!(0, {
        let wgpu_instance = unsafe { deref_handle::<wgpu::Instance>(instance) };

        let features = wgpu_instance.wgsl_language_features();
        let mut bits: u32 = 0;
        if features.contains(wgpu::WgslLanguageFeatures::ReadOnlyAndReadWriteStorageTextures) {
            bits |= 1 << 0;
        }
        if features.contains(wgpu::WgslLanguageFeatures::Packed4x8IntegerDotProduct) {
            bits |= 1 << 1;
        }
        if features.contains(wgpu::WgslLanguageFeatures::UnrestrictedPointerParameters) {
            bits |= 1 << 2;
        }
        if features.contains(wgpu::WgslLanguageFeatures::PointerCompositeAccess) {
            bits |= 1 << 3;
        }
        bits
    })
}

// =============================================================================
// ADAPTER
// =============================================================================

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

// =============================================================================
// DEVICE
// =============================================================================

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

// =============================================================================
// DEVICE ERROR QUEUE
// =============================================================================

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

// =============================================================================
// ERROR SCOPES
// =============================================================================

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
