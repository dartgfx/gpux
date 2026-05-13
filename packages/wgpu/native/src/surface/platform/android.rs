use crate::surface::create_depth_texture;
use raw_window_handle::{
    AndroidDisplayHandle, AndroidNdkWindowHandle, RawDisplayHandle, RawWindowHandle,
};
use std::ptr::NonNull;

#[cfg(target_os = "android")]
use ash::{android::external_memory_android_hardware_buffer, vk};
#[cfg(target_os = "android")]
use ndk_sys::{
    AHardwareBuffer, AHardwareBuffer_Desc, AHardwareBuffer_Format, AHardwareBuffer_UsageFlags,
    AHardwareBuffer_acquire, AHardwareBuffer_describe, AHardwareBuffer_release,
};

pub struct AndroidSurface {
    pub surface: wgpu::Surface<'static>,
    pub config: wgpu::SurfaceConfiguration,
}

impl AndroidSurface {
    pub fn create(
        instance: &wgpu::Instance,
        adapter: &wgpu::Adapter,
        device: &wgpu::Device,
        window_ptr: *mut std::ffi::c_void,
        width: u32,
        height: u32,
    ) -> Result<(AndroidSurface, wgpu::Texture, wgpu::TextureView), String> {
        if window_ptr.is_null() {
            return Err("ANativeWindow pointer is null".to_string());
        }

        let ptr = NonNull::new(window_ptr).ok_or("Invalid window pointer")?;
        let window_handle = AndroidNdkWindowHandle::new(ptr);
        let raw_window_handle = RawWindowHandle::AndroidNdk(window_handle);

        let display_handle = AndroidDisplayHandle::new();
        let raw_display_handle = RawDisplayHandle::Android(display_handle);

        let surface = unsafe {
            instance
                .create_surface_unsafe(wgpu::SurfaceTargetUnsafe::RawHandle {
                    raw_display_handle: Some(raw_display_handle),
                    raw_window_handle,
                })
                .map_err(|e| format!("Failed to create surface: {}", e))?
        };

        let caps = surface.get_capabilities(adapter);
        let format = caps
            .formats
            .iter()
            .find(|f| f.is_srgb())
            .copied()
            .unwrap_or(caps.formats[0]);

        log::warn!(
            "Android surface created: {}x{}, format {:?}",
            width,
            height,
            format,
        );

        let config = wgpu::SurfaceConfiguration {
            usage: wgpu::TextureUsages::RENDER_ATTACHMENT,
            format,
            width,
            height,
            present_mode: wgpu::PresentMode::Fifo,
            alpha_mode: caps.alpha_modes[0],
            view_formats: vec![],
            desired_maximum_frame_latency: 2,
        };
        surface.configure(device, &config);

        let (depth_texture, depth_view) = create_depth_texture(device, width, height);

        Ok((
            AndroidSurface { surface, config },
            depth_texture,
            depth_view,
        ))
    }

    pub fn resize(&mut self, device: &wgpu::Device, width: u32, height: u32) {
        self.config.width = width;
        self.config.height = height;
        self.surface.configure(device, &self.config);
    }

    pub fn get_current_texture(&self) -> wgpu::CurrentSurfaceTexture {
        self.surface.get_current_texture()
    }
}

// =============================================================================
// AHardwareBuffer Vulkan import plumbing
// =============================================================================
//
// Mirrors the IOSurface import shape in `surface/platform/apple.rs`. Public
// helpers consumed by `texture/platform/android/exports.rs`.

#[cfg(target_os = "android")]
pub(crate) fn acquire_ahardware_buffer(
    ahb: *mut std::ffi::c_void,
) -> Result<*mut std::ffi::c_void, String> {
    if ahb.is_null() {
        return Err("AHardwareBuffer pointer is null".to_string());
    }
    unsafe { AHardwareBuffer_acquire(ahb.cast::<AHardwareBuffer>()) };
    Ok(ahb)
}

#[cfg(not(target_os = "android"))]
pub(crate) fn acquire_ahardware_buffer(
    _ahb: *mut std::ffi::c_void,
) -> Result<*mut std::ffi::c_void, String> {
    Err("AHardwareBuffer acquire is only supported on Android".to_string())
}

#[cfg(target_os = "android")]
pub(crate) fn release_ahardware_buffer(ahb: *mut std::ffi::c_void) {
    if ahb.is_null() {
        return;
    }
    unsafe { AHardwareBuffer_release(ahb.cast::<AHardwareBuffer>()) };
}

#[cfg(not(target_os = "android"))]
pub(crate) fn release_ahardware_buffer(_ahb: *mut std::ffi::c_void) {}

#[cfg(target_os = "android")]
struct AcquiredAHardwareBuffer {
    ptr: *mut AHardwareBuffer,
}

#[cfg(target_os = "android")]
impl AcquiredAHardwareBuffer {
    fn into_ptr(self) -> *mut AHardwareBuffer {
        let ptr = self.ptr;
        std::mem::forget(self);
        ptr
    }
}

#[cfg(target_os = "android")]
impl Drop for AcquiredAHardwareBuffer {
    fn drop(&mut self) {
        unsafe { AHardwareBuffer_release(self.ptr) };
    }
}

#[cfg(target_os = "android")]
fn describe_ahardware_buffer(ahb: *const AHardwareBuffer) -> AHardwareBuffer_Desc {
    let mut desc = std::mem::MaybeUninit::<AHardwareBuffer_Desc>::zeroed();
    unsafe {
        AHardwareBuffer_describe(ahb, desc.as_mut_ptr());
        desc.assume_init()
    }
}

#[cfg(target_os = "android")]
fn ahardware_buffer_format_to_wgpu(format: u32) -> Result<wgpu::TextureFormat, String> {
    match format {
        f if f == AHardwareBuffer_Format::AHARDWAREBUFFER_FORMAT_R8G8B8A8_UNORM.0 => {
            Ok(wgpu::TextureFormat::Rgba8Unorm)
        }
        f if f == AHardwareBuffer_Format::AHARDWAREBUFFER_FORMAT_R8G8B8X8_UNORM.0 => {
            Ok(wgpu::TextureFormat::Rgba8Unorm)
        }
        f if f == AHardwareBuffer_Format::AHARDWAREBUFFER_FORMAT_R16G16B16A16_FLOAT.0 => {
            Ok(wgpu::TextureFormat::Rgba16Float)
        }
        f if f == AHardwareBuffer_Format::AHARDWAREBUFFER_FORMAT_Y8Cb8Cr8_420.0 => Err(
            "YUV AHardwareBuffer formats need VK_KHR_sampler_ycbcr_conversion and are not supported yet"
                .to_string(),
        ),
        other => Err(format!(
            "Unsupported AHardwareBuffer format {other:#x}; supported RGBA formats are R8G8B8A8_UNORM, R8G8B8X8_UNORM, and R16G16B16A16_FLOAT"
        )),
    }
}

#[cfg(target_os = "android")]
fn wgpu_format_to_vk_format(format: wgpu::TextureFormat) -> Result<vk::Format, String> {
    match format {
        wgpu::TextureFormat::Rgba8Unorm => Ok(vk::Format::R8G8B8A8_UNORM),
        wgpu::TextureFormat::Rgba16Float => Ok(vk::Format::R16G16B16A16_SFLOAT),
        other => Err(format!(
            "AHardwareBuffer import only supports RGBA8/RGBA16F wgpu formats, got {other:?}"
        )),
    }
}

#[cfg(target_os = "android")]
fn find_vulkan_memory_type_index(
    instance: &ash::Instance,
    physical_device: vk::PhysicalDevice,
    type_bits: u32,
    flags: vk::MemoryPropertyFlags,
) -> Option<u32> {
    let memory_properties =
        unsafe { instance.get_physical_device_memory_properties(physical_device) };
    memory_properties
        .memory_types_as_slice()
        .iter()
        .enumerate()
        .find_map(|(index, memory_type)| {
            let matches_type = type_bits & (1 << index) != 0;
            let matches_flags = memory_type.property_flags & flags == flags;
            if matches_type && matches_flags {
                Some(index as u32)
            } else {
                None
            }
        })
}

#[cfg(target_os = "android")]
pub(crate) fn import_ahardware_buffer_to_wgpu(
    device: &wgpu::Device,
    ahb: *mut std::ffi::c_void,
    width: u32,
    height: u32,
    format: wgpu::TextureFormat,
) -> Result<wgpu::Texture, String> {
    if ahb.is_null() {
        return Err("AHardwareBuffer pointer is null".to_string());
    }
    if width == 0 || height == 0 {
        return Err("texture width and height must be positive".to_string());
    }

    let ahb = ahb.cast::<AHardwareBuffer>();
    unsafe { AHardwareBuffer_acquire(ahb) };
    let acquired = AcquiredAHardwareBuffer { ptr: ahb };

    let ahb_desc = describe_ahardware_buffer(acquired.ptr);
    if ahb_desc.width != width || ahb_desc.height != height {
        return Err(format!(
            "AHardwareBuffer dimensions {}x{} do not match requested texture {}x{}",
            ahb_desc.width, ahb_desc.height, width, height
        ));
    }
    if ahb_desc.layers != 1 {
        return Err(format!(
            "AHardwareBuffer import only supports single-layer images, got {} layers",
            ahb_desc.layers
        ));
    }
    if ahb_desc.usage
        & AHardwareBuffer_UsageFlags::AHARDWAREBUFFER_USAGE_GPU_SAMPLED_IMAGE.0 as u64
        == 0
    {
        return Err(
            "AHardwareBuffer must include AHARDWAREBUFFER_USAGE_GPU_SAMPLED_IMAGE".to_string(),
        );
    }

    let ahb_format = ahardware_buffer_format_to_wgpu(ahb_desc.format)?;
    if format != ahb_format {
        return Err(format!(
            "AHardwareBuffer format {:#x} maps to {ahb_format:?}, but caller requested {format:?}",
            ahb_desc.format
        ));
    }

    let hal_device = unsafe {
        device
            .as_hal::<wgpu::hal::api::Vulkan>()
            .ok_or_else(|| "Failed to get Vulkan device from wgpu".to_string())?
    };

    if !hal_device
        .enabled_device_extensions()
        .contains(&external_memory_android_hardware_buffer::NAME)
    {
        return Err(
            "Vulkan device was not created with VK_ANDROID_external_memory_android_hardware_buffer"
                .to_string(),
        );
    }

    let raw_device = hal_device.raw_device().clone();
    let raw_instance = hal_device.shared_instance().raw_instance();
    let physical_device = hal_device.raw_physical_device();
    let vk_format = wgpu_format_to_vk_format(format)?;
    let ahb_ext =
        external_memory_android_hardware_buffer::Device::new(raw_instance, hal_device.raw_device());

    let mut format_properties = vk::AndroidHardwareBufferFormatPropertiesANDROID::default();
    let mut properties = vk::AndroidHardwareBufferPropertiesANDROID::default();
    properties.p_next = (&mut format_properties as *mut _) as *mut std::ffi::c_void;
    unsafe {
        ahb_ext
            .get_android_hardware_buffer_properties(
                acquired.ptr.cast::<vk::AHardwareBuffer>(),
                &mut properties,
            )
            .map_err(|error| {
                format!("vkGetAndroidHardwareBufferPropertiesANDROID failed: {error:?}")
            })?;
    }

    if properties.allocation_size == 0 {
        return Err("AHardwareBuffer reports zero allocation size".to_string());
    }
    if format_properties.format == vk::Format::UNDEFINED {
        return Err(
            "AHardwareBuffer uses an external/YUV-only Vulkan format; YUV import is deferred"
                .to_string(),
        );
    }
    if format_properties.format != vk_format {
        return Err(format!(
            "AHardwareBuffer Vulkan format {:?} does not match expected {:?}",
            format_properties.format, vk_format
        ));
    }
    if !format_properties
        .format_features
        .contains(vk::FormatFeatureFlags::SAMPLED_IMAGE)
    {
        return Err(format!(
            "AHardwareBuffer format {:?} is not sampleable by Vulkan",
            format_properties.format
        ));
    }
    if !format_properties
        .format_features
        .contains(vk::FormatFeatureFlags::TRANSFER_SRC)
    {
        return Err(format!(
            "AHardwareBuffer format {:?} cannot be exposed as COPY_SRC",
            format_properties.format
        ));
    }

    let mut external_memory_info = vk::ExternalMemoryImageCreateInfo::default()
        .handle_types(vk::ExternalMemoryHandleTypeFlags::ANDROID_HARDWARE_BUFFER_ANDROID);
    let image_info = vk::ImageCreateInfo::default()
        .image_type(vk::ImageType::TYPE_2D)
        .format(vk_format)
        .extent(vk::Extent3D {
            width,
            height,
            depth: 1,
        })
        .mip_levels(1)
        .array_layers(1)
        .samples(vk::SampleCountFlags::TYPE_1)
        .tiling(vk::ImageTiling::OPTIMAL)
        .usage(vk::ImageUsageFlags::SAMPLED | vk::ImageUsageFlags::TRANSFER_SRC)
        .sharing_mode(vk::SharingMode::EXCLUSIVE)
        .initial_layout(vk::ImageLayout::UNDEFINED)
        .push_next(&mut external_memory_info);

    let image = unsafe { raw_device.create_image(&image_info, None) }
        .map_err(|error| format!("vkCreateImage for AHardwareBuffer failed: {error:?}"))?;
    let memory_requirements = unsafe { raw_device.get_image_memory_requirements(image) };
    let memory_type_bits = memory_requirements.memory_type_bits & properties.memory_type_bits;
    let memory_type_index = find_vulkan_memory_type_index(
        raw_instance,
        physical_device,
        memory_type_bits,
        vk::MemoryPropertyFlags::DEVICE_LOCAL,
    )
    .ok_or_else(|| {
        unsafe { raw_device.destroy_image(image, None) };
        format!(
            "No DEVICE_LOCAL memory type matches AHardwareBuffer memory bits {memory_type_bits:#x}"
        )
    })?;

    let mut dedicated_info = vk::MemoryDedicatedAllocateInfo::default().image(image);
    let mut import_info =
        vk::ImportAndroidHardwareBufferInfoANDROID::default().buffer(acquired.ptr.cast());
    let allocate_info = vk::MemoryAllocateInfo::default()
        .allocation_size(properties.allocation_size)
        .memory_type_index(memory_type_index)
        .push_next(&mut dedicated_info)
        .push_next(&mut import_info);

    let memory = match unsafe { raw_device.allocate_memory(&allocate_info, None) } {
        Ok(memory) => memory,
        Err(error) => {
            unsafe { raw_device.destroy_image(image, None) };
            return Err(format!(
                "vkAllocateMemory importing AHardwareBuffer failed: {error:?}"
            ));
        }
    };

    if let Err(error) = unsafe { raw_device.bind_image_memory(image, memory, 0) } {
        unsafe {
            raw_device.free_memory(memory, None);
            raw_device.destroy_image(image, None);
        }
        return Err(format!(
            "vkBindImageMemory for imported AHardwareBuffer failed: {error:?}"
        ));
    }

    let public_desc = wgpu::TextureDescriptor {
        label: Some("External AHardwareBuffer texture"),
        size: wgpu::Extent3d {
            width,
            height,
            depth_or_array_layers: 1,
        },
        mip_level_count: 1,
        sample_count: 1,
        dimension: wgpu::TextureDimension::D2,
        format,
        usage: wgpu::TextureUsages::TEXTURE_BINDING | wgpu::TextureUsages::COPY_SRC,
        view_formats: &[],
    };
    let hal_desc = wgpu::hal::TextureDescriptor {
        label: Some("External AHardwareBuffer texture"),
        size: public_desc.size,
        mip_level_count: public_desc.mip_level_count,
        sample_count: public_desc.sample_count,
        dimension: public_desc.dimension,
        format,
        usage: wgpu::TextureUses::RESOURCE | wgpu::TextureUses::COPY_SRC,
        memory_flags: wgpu::hal::MemoryFlags::empty(),
        view_formats: vec![],
    };

    let drop_device = raw_device.clone();
    let ahb_for_drop = acquired.into_ptr() as usize;
    let drop_callback: wgpu::hal::DropCallback = Box::new(move || unsafe {
        drop_device.destroy_image(image, None);
        drop_device.free_memory(memory, None);
        AHardwareBuffer_release(ahb_for_drop as *mut AHardwareBuffer);
    });

    let hal_texture = unsafe {
        hal_device.texture_from_raw(
            image,
            &hal_desc,
            Some(drop_callback),
            wgpu::hal::vulkan::TextureMemory::External,
        )
    };

    Ok(unsafe {
        device.create_texture_from_hal::<wgpu::hal::api::Vulkan>(hal_texture, &public_desc)
    })
}

#[cfg(not(target_os = "android"))]
pub(crate) fn import_ahardware_buffer_to_wgpu(
    _device: &wgpu::Device,
    _ahb: *mut std::ffi::c_void,
    _width: u32,
    _height: u32,
    _format: wgpu::TextureFormat,
) -> Result<wgpu::Texture, String> {
    Err("AHardwareBuffer texture import is only available on Android".to_string())
}
