use crate::abi::types::*;
use crate::runtime::handle::*;
use crate::{clear_error, ffi_catch};

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
