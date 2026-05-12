use crate::abi::types::*;
use crate::ffi_catch;
use crate::runtime::handle::*;
use crate::surface::WgpuSurface;

/// Copy from a GpuTexture to surface.
#[no_mangle]
pub extern "C" fn wgpu_surface_copy_from_texture(surface_id: u64, src_texture: WGPUTexture) {
    if surface_id == 0 {
        return;
    }

    ffi_catch!((), {
        #[cfg(not(target_os = "android"))]
        {
            if src_texture == 0 {
                log::error!("Source texture handle is 0");
                return;
            }

            let surface = unsafe { deref_handle::<WgpuSurface>(surface_id) };
            let src = unsafe { deref_handle::<wgpu::Texture>(src_texture) };

            let mut encoder =
                surface
                    .device
                    .create_command_encoder(&wgpu::CommandEncoderDescriptor {
                        label: Some("surface copy"),
                    });

            encoder.copy_texture_to_texture(
                wgpu::TexelCopyTextureInfo {
                    texture: src,
                    mip_level: 0,
                    origin: wgpu::Origin3d::ZERO,
                    aspect: wgpu::TextureAspect::All,
                },
                wgpu::TexelCopyTextureInfo {
                    texture: &surface.texture,
                    mip_level: 0,
                    origin: wgpu::Origin3d::ZERO,
                    aspect: wgpu::TextureAspect::All,
                },
                wgpu::Extent3d {
                    width: surface.width,
                    height: surface.height,
                    depth_or_array_layers: 1,
                },
            );

            surface.queue.submit(std::iter::once(encoder.finish()));
        }

        #[cfg(target_os = "android")]
        {
            let _ = src_texture;
            log::warn!("wgpu_surface_copy_from_texture not supported on Android - use render APIs");
        }
    })
}

/// Signal frame is ready for display.
#[no_mangle]
#[allow(unused_variables)]
pub extern "C" fn wgpu_surface_present(surface_id: u64) {
    if surface_id == 0 {
        return;
    }

    ffi_catch!((), {
        #[cfg(target_os = "windows")]
        {
            let surface = unsafe { deref_handle_mut::<WgpuSurface>(surface_id) };
            crate::surface::platform::windows::copy_wgpu_to_pixel_buffer(surface);
        }

        #[cfg(target_os = "linux")]
        {
            let surface = unsafe { deref_handle_mut::<WgpuSurface>(surface_id) };
            crate::surface::platform::linux::copy_wgpu_to_pixel_buffer(surface);
        }

        #[cfg(target_os = "android")]
        {
            let surface = unsafe { deref_handle_mut::<WgpuSurface>(surface_id) };
            if let Some(frame) = surface.current_frame.take() {
                frame.present();
            }
        }

        #[cfg(all(
            not(target_os = "windows"),
            not(target_os = "linux"),
            not(target_os = "android")
        ))]
        {
            let _ = surface_id;
        }
    })
}
