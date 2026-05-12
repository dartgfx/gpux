use crate::surface::{create_depth_texture, WgpuSurface};
use core_foundation::base::TCFType;
use core_foundation::dictionary::CFDictionary;
use core_foundation::number::CFNumber;
use core_foundation::string::CFString;
use objc2::rc::Retained;
use objc2::runtime::ProtocolObject;
use objc2_metal::{
    MTLDevice, MTLPixelFormat, MTLStorageMode, MTLTexture, MTLTextureDescriptor, MTLTextureType,
    MTLTextureUsage,
};
use std::ffi::c_void;
use std::sync::Arc;

// IOSurface C API bindings
#[repr(C)]
pub struct __IOSurface(c_void);
pub type IOSurfaceRef = *mut __IOSurface;

#[link(name = "IOSurface", kind = "framework")]
extern "C" {
    fn IOSurfaceCreate(properties: *const c_void) -> IOSurfaceRef;
    fn IOSurfaceGetID(buffer: IOSurfaceRef) -> u32;

    static kIOSurfaceWidth: *const c_void;
    static kIOSurfaceHeight: *const c_void;
    static kIOSurfaceBytesPerElement: *const c_void;
    static kIOSurfaceBytesPerRow: *const c_void;
    static kIOSurfacePixelFormat: *const c_void;
}

#[link(name = "CoreFoundation", kind = "framework")]
extern "C" {
    fn CFRetain(cf: *const c_void) -> *const c_void;
    fn CFRelease(cf: *const c_void);
}

pub struct AppleSurface {
    // Kept alive - IOSurface is the backing store for the Metal texture
    #[allow(dead_code)]
    pub iosurface: IOSurfaceRef,
    pub iosurface_id: u32,
}

impl AppleSurface {
    pub fn create(
        device: Arc<wgpu::Device>,
        queue: Arc<wgpu::Queue>,
        width: u32,
        height: u32,
    ) -> Result<WgpuSurface, String> {
        let (iosurface, iosurface_id) = create_iosurface(width, height)?;

        log::info!(
            "Created IOSurface: id={}, {}x{} (zero-copy)",
            iosurface_id,
            width,
            height
        );

        let metal_device = get_metal_device(&device)?;
        let metal_texture =
            create_metal_texture_from_iosurface(&metal_device, iosurface, width, height)?;
        let texture = import_metal_texture_to_wgpu(&device, metal_texture, width, height)?;
        let (depth_texture, _depth_view) = create_depth_texture(&device, width, height);

        Ok(WgpuSurface {
            device,
            queue,
            width,
            height,
            format_ffi: 22, // bgra8Unorm
            texture,
            depth_texture,
            platform: AppleSurface {
                iosurface,
                iosurface_id,
            },
        })
    }
}

fn create_iosurface(width: u32, height: u32) -> Result<(IOSurfaceRef, u32), String> {
    let bytes_per_element = 4u32; // BGRA8
    let bytes_per_row = width * bytes_per_element;
    // Align to 16 bytes for Metal
    let bytes_per_row = (bytes_per_row + 15) & !15;

    let properties = unsafe {
        CFDictionary::from_CFType_pairs(&[
            (
                CFString::wrap_under_get_rule(kIOSurfaceWidth as *const _),
                CFNumber::from(width as i32).as_CFType(),
            ),
            (
                CFString::wrap_under_get_rule(kIOSurfaceHeight as *const _),
                CFNumber::from(height as i32).as_CFType(),
            ),
            (
                CFString::wrap_under_get_rule(kIOSurfaceBytesPerElement as *const _),
                CFNumber::from(bytes_per_element as i32).as_CFType(),
            ),
            (
                CFString::wrap_under_get_rule(kIOSurfaceBytesPerRow as *const _),
                CFNumber::from(bytes_per_row as i32).as_CFType(),
            ),
            (
                CFString::wrap_under_get_rule(kIOSurfacePixelFormat as *const _),
                // 'BGRA' as u32 = 0x42475241
                CFNumber::from(0x42475241i32).as_CFType(),
            ),
        ])
    };

    let surface = unsafe { IOSurfaceCreate(properties.as_concrete_TypeRef() as *const _) };
    if surface.is_null() {
        return Err("Failed to create IOSurface".to_string());
    }

    let id = unsafe { IOSurfaceGetID(surface) };

    Ok((surface, id))
}

fn get_metal_device(
    device: &wgpu::Device,
) -> Result<Retained<ProtocolObject<dyn MTLDevice>>, String> {
    unsafe {
        let hal_guard = device
            .as_hal::<wgpu::hal::api::Metal>()
            .ok_or_else(|| "Failed to get Metal device from wgpu".to_string())?;

        let raw_device = hal_guard.raw_device();
        Ok(raw_device.clone())
    }
}

fn create_metal_texture_from_iosurface(
    device: &ProtocolObject<dyn MTLDevice>,
    iosurface: IOSurfaceRef,
    width: u32,
    height: u32,
) -> Result<Retained<ProtocolObject<dyn MTLTexture>>, String> {
    create_metal_texture_from_iosurface_plane(
        device,
        iosurface,
        0,
        width,
        height,
        MTLPixelFormat::BGRA8Unorm,
        MTLTextureUsage::RenderTarget | MTLTextureUsage::ShaderRead,
    )
}

fn create_metal_texture_from_iosurface_plane(
    device: &ProtocolObject<dyn MTLDevice>,
    iosurface: IOSurfaceRef,
    plane: usize,
    width: u32,
    height: u32,
    pixel_format: MTLPixelFormat,
    usage: MTLTextureUsage,
) -> Result<Retained<ProtocolObject<dyn MTLTexture>>, String> {
    use objc2::msg_send;
    use objc2::runtime::AnyObject;

    let desc = MTLTextureDescriptor::new();
    unsafe {
        desc.setTextureType(MTLTextureType::Type2D);
        desc.setPixelFormat(pixel_format);
        desc.setWidth(width as usize);
        desc.setHeight(height as usize);
        desc.setDepth(1);
        desc.setMipmapLevelCount(1);
        desc.setSampleCount(1);
        desc.setArrayLength(1);
        desc.setStorageMode(MTLStorageMode::Shared);
        desc.setUsage(usage);
    }

    let iosurface_ptr = iosurface as *mut AnyObject;

    let texture_ptr: *mut AnyObject = unsafe {
        let device_ptr = (device as *const _ as *mut AnyObject).as_ref().unwrap();
        let desc_ptr = (&*desc as *const _ as *mut AnyObject).as_ref().unwrap();
        msg_send![device_ptr, newTextureWithDescriptor: desc_ptr, iosurface: iosurface_ptr, plane: plane]
    };

    if texture_ptr.is_null() {
        return Err(format!(
            "Failed to create Metal texture from IOSurface plane {}",
            plane
        ));
    }

    // SAFETY: newTextureWithDescriptor:iosurface:plane: returns a +1 retained MTLTexture.
    // We wrap it in Retained to take ownership.
    let texture: Retained<ProtocolObject<dyn MTLTexture>> = unsafe {
        Retained::from_raw(texture_ptr as *mut ProtocolObject<dyn MTLTexture>)
            .ok_or_else(|| "Failed to retain Metal texture".to_string())?
    };

    log::info!("Created Metal texture backed by IOSurface plane {}", plane);
    Ok(texture)
}

fn import_metal_texture_to_wgpu(
    device: &wgpu::Device,
    metal_texture: Retained<ProtocolObject<dyn MTLTexture>>,
    width: u32,
    height: u32,
) -> Result<wgpu::Texture, String> {
    let desc = wgpu::TextureDescriptor {
        label: Some("IOSurface Texture (zero-copy)"),
        size: wgpu::Extent3d {
            width,
            height,
            depth_or_array_layers: 1,
        },
        mip_level_count: 1,
        sample_count: 1,
        dimension: wgpu::TextureDimension::D2,
        format: wgpu::TextureFormat::Bgra8Unorm,
        usage: wgpu::TextureUsages::RENDER_ATTACHMENT
            | wgpu::TextureUsages::TEXTURE_BINDING
            | wgpu::TextureUsages::COPY_DST,
        view_formats: &[],
    };

    unsafe {
        let hal_texture = wgpu::hal::metal::Device::texture_from_raw(
            metal_texture,
            wgpu::TextureFormat::Bgra8Unorm,
            MTLTextureType::Type2D,
            1,
            1,
            wgpu::hal::CopyExtent {
                width,
                height,
                depth: 1,
            },
        );

        Ok(device.create_texture_from_hal::<wgpu::hal::api::Metal>(hal_texture, &desc))
    }
}

pub fn import_iosurface_plane_to_wgpu(
    device: &wgpu::Device,
    iosurface: IOSurfaceRef,
    plane: usize,
    width: u32,
    height: u32,
    format: wgpu::TextureFormat,
) -> Result<wgpu::Texture, String> {
    if iosurface.is_null() {
        return Err("IOSurface pointer is null".to_string());
    }
    let metal_format = match format {
        wgpu::TextureFormat::R8Unorm => MTLPixelFormat::R8Unorm,
        wgpu::TextureFormat::Rg8Unorm => MTLPixelFormat::RG8Unorm,
        wgpu::TextureFormat::Bgra8Unorm => MTLPixelFormat::BGRA8Unorm,
        other => {
            return Err(format!(
                "Unsupported IOSurface import texture format {:?}",
                other
            ));
        }
    };
    let metal_device = get_metal_device(device)?;
    let metal_texture = create_metal_texture_from_iosurface_plane(
        &metal_device,
        iosurface,
        plane,
        width,
        height,
        metal_format,
        MTLTextureUsage::ShaderRead,
    )?;
    let desc = wgpu::TextureDescriptor {
        label: Some("Imported IOSurface Plane"),
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

    unsafe {
        let hal_texture = wgpu::hal::metal::Device::texture_from_raw(
            metal_texture,
            format,
            MTLTextureType::Type2D,
            1,
            1,
            wgpu::hal::CopyExtent {
                width,
                height,
                depth: 1,
            },
        );

        Ok(device.create_texture_from_hal::<wgpu::hal::api::Metal>(hal_texture, &desc))
    }
}

pub fn retain_iosurface(iosurface: IOSurfaceRef) -> Result<IOSurfaceRef, String> {
    if iosurface.is_null() {
        return Err("IOSurface pointer is null".to_string());
    }
    let retained = unsafe { CFRetain(iosurface.cast_const().cast()) as IOSurfaceRef };
    if retained.is_null() {
        return Err("Failed to retain IOSurface".to_string());
    }
    Ok(retained)
}

pub fn release_iosurface(iosurface: IOSurfaceRef) {
    if iosurface.is_null() {
        return;
    }
    unsafe {
        CFRelease(iosurface.cast_const().cast());
    }
}
