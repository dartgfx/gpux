// Windows wgpu surface with D3D11 shared texture
//
// Zero-copy approach: wgpu renders -> GPU copy to D3D11 shared texture
// Falls back to CPU pixel buffer if D3D11 interop fails.
//
// Flow (optimized):
// 1. Create D3D11 shared texture with legacy shared handle
// 2. wgpu renders to its own texture
// 3. Copy wgpu texture -> D3D11 shared texture (GPU-only)
// 4. Consumer reads shared texture via handle
//
// Flow (fallback):
// 1. wgpu renders to its own texture
// 2. Copy texture -> staging buffer (GPU)
// 3. Map staging buffer -> CPU pixel buffer
// 4. Consumer reads pixel buffer directly

use super::windows_d3d11::D3D11SharedTexture;
use super::{create_depth_texture, WgpuSurface};
use std::sync::{Arc, Mutex};
use windows::Win32::Foundation::LUID;

pub struct WindowsSurface {
    shared_texture: Option<D3D11SharedTexture>,
    shared_handle: u64,

    pub pixel_buffer: Mutex<Vec<u8>>,
    pub pixel_buffer_ptr: *const u8,
    staging_buffer: wgpu::Buffer,
    staging_buffer_row_pitch: u32,
}

unsafe impl Send for WindowsSurface {}
unsafe impl Sync for WindowsSurface {}

impl WindowsSurface {
    pub fn create(
        device: Arc<wgpu::Device>,
        queue: Arc<wgpu::Queue>,
        width: u32,
        height: u32,
    ) -> Result<WgpuSurface, String> {
        // DISABLED: Flutter 3.41.1 bundles a stricter ANGLE that rejects
        // eglCreatePbufferFromClientBuffer with EGL_TEXTURE_FORMAT=RGBA because
        // no EGL config has EGL_BIND_TO_TEXTURE_RGBA. Both DxgiSharedHandle and
        // D3d11Texture2D paths fail. Using pixel buffer until Flutter fixes this.
        let shared_result: Result<(D3D11SharedTexture, u64), String> =
            Err("Disabled: ANGLE regression in Flutter 3.41.1".to_string());
        // let shared_result = Self::try_create_shared_texture(&device, width, height);

        let texture = device.create_texture(&wgpu::TextureDescriptor {
            label: Some("wgpu render texture"),
            size: wgpu::Extent3d {
                width,
                height,
                depth_or_array_layers: 1,
            },
            mip_level_count: 1,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format: wgpu::TextureFormat::Rgba8Unorm,
            usage: wgpu::TextureUsages::RENDER_ATTACHMENT
                | wgpu::TextureUsages::COPY_SRC
                | wgpu::TextureUsages::COPY_DST
                | wgpu::TextureUsages::TEXTURE_BINDING,
            view_formats: &[],
        });

        let (depth_texture, _depth_view) = create_depth_texture(&device, width, height);

        let bytes_per_row = width * 4;
        let padded_bytes_per_row = (bytes_per_row + 255) & !255;
        let buffer_size = (padded_bytes_per_row * height) as u64;

        let staging_buffer = device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("pixel buffer staging"),
            size: buffer_size,
            usage: wgpu::BufferUsages::COPY_DST | wgpu::BufferUsages::MAP_READ,
            mapped_at_creation: false,
        });

        let pixel_buffer_size = (bytes_per_row * height) as usize;
        let pixel_buffer = vec![0u8; pixel_buffer_size];
        let pixel_buffer_ptr = pixel_buffer.as_ptr();

        let (shared_texture, shared_handle) = match shared_result {
            Ok((tex, handle)) => {
                log::info!("D3D11 shared texture created, handle=0x{:x}", handle);
                (Some(tex), handle)
            }
            Err(e) => {
                log::warn!("D3D11 shared texture failed: {}", e);
                (None, 0)
            }
        };
        Ok(WgpuSurface {
            device,
            queue,
            width,
            height,
            format_ffi: 17, // rgba8Unorm
            texture,
            depth_texture,
            platform: WindowsSurface {
                shared_texture,
                shared_handle,
                pixel_buffer: Mutex::new(pixel_buffer),
                pixel_buffer_ptr,
                staging_buffer,
                staging_buffer_row_pitch: padded_bytes_per_row,
            },
        })
    }

    fn try_create_shared_texture(
        device: &wgpu::Device,
        width: u32,
        height: u32,
    ) -> Result<(D3D11SharedTexture, u64), String> {
        let luid = LUID {
            LowPart: 0,
            HighPart: 0,
        };

        let shared_tex: Option<Result<D3D11SharedTexture, String>> = unsafe {
            let hal_device = device.as_hal::<wgpu_hal::api::Dx12>();
            if let Some(dev) = hal_device {
                let dx12_device = dev.raw_device();
                let dx12_queue = dev.raw_queue();
                match D3D11SharedTexture::create_with_d3d11on12(
                    luid,
                    width,
                    height,
                    dx12_device,
                    dx12_queue,
                ) {
                    Ok(tex) => {
                        log::info!("Created D3D11on12 shared texture for GPU-GPU copy");
                        Some(Ok(tex))
                    }
                    Err(e) => {
                        log::warn!("D3D11on12 creation failed: {}", e);
                        Some(Err(e))
                    }
                }
            } else {
                log::warn!("DX12 HAL not available");
                None
            }
        };

        let shared_tex = match shared_tex {
            Some(Ok(tex)) => tex,
            Some(Err(_)) | None => {
                log::info!("Falling back to plain D3D11 (CPU staging)");
                D3D11SharedTexture::create(luid, width, height)?
            }
        };

        let handle = shared_tex.get_shared_handle().0 as u64;
        Ok((shared_tex, handle))
    }

    pub fn get_pixel_buffer_ptr(&self) -> *const u8 {
        self.pixel_buffer_ptr
    }

    pub fn get_shared_handle(&self) -> u64 {
        self.shared_handle
    }

    pub fn has_shared_texture(&self) -> bool {
        self.shared_texture.is_some()
    }
}

/// Copy wgpu render output to destination (uses surface's stored device/queue).
pub fn copy_wgpu_to_pixel_buffer(surface: &mut WgpuSurface) {
    if surface.platform.shared_texture.is_some() {
        if let Err(e) = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
            copy_to_d3d11_texture(surface);
        })) {
            eprintln!("[D3D11] PANIC in copy_to_d3d11_texture: {:?}", e);
            copy_to_pixel_buffer_impl(surface);
        }
    } else {
        copy_to_pixel_buffer_impl(surface);
    }
}

fn copy_to_d3d11_texture(surface: &mut WgpuSurface) {
    use std::time::Instant;

    static FRAME_COUNT: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
    static TOTAL_TIME: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
    static USE_GPU_COPY: std::sync::atomic::AtomicBool = std::sync::atomic::AtomicBool::new(true);

    let frame = FRAME_COUNT.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
    let t0 = Instant::now();

    if USE_GPU_COPY.load(std::sync::atomic::Ordering::Relaxed) {
        if let Some(ref shared_tex) = surface.platform.shared_texture {
            if shared_tex.has_d3d11on12() {
                let _ = surface.device.poll(wgpu::PollType::wait_indefinitely());

                let copy_result: Result<(), String> = unsafe {
                    let hal_tex = surface.texture.as_hal::<wgpu_hal::api::Dx12>();
                    if let Some(tex) = hal_tex {
                        let dx12_resource = tex.raw_resource();
                        shared_tex.copy_from_dx12(dx12_resource)
                    } else {
                        Err("No DX12 texture available".to_string())
                    }
                };

                match copy_result {
                    Ok(()) => {
                        let elapsed = t0.elapsed().as_micros() as u64;
                        TOTAL_TIME.fetch_add(elapsed, std::sync::atomic::Ordering::Relaxed);

                        if frame > 0 && frame % 60 == 0 {
                            let avg = TOTAL_TIME.load(std::sync::atomic::Ordering::Relaxed) as f64
                                / frame as f64;
                            eprintln!(
                                "[D3D11on12] avg/{}f: {:.0}us | frame={}us",
                                frame, avg, elapsed
                            );
                        }
                        return;
                    }
                    Err(e) => {
                        eprintln!("[D3D11on12] GPU copy failed at frame {}: {}", frame, e);
                        USE_GPU_COPY.store(false, std::sync::atomic::Ordering::Relaxed);
                        eprintln!("[D3D11on12] Switching to CPU staging permanently");
                    }
                }
            }
        }
    }

    copy_to_d3d11_texture_cpu(surface, frame, t0);
}

fn copy_to_d3d11_texture_cpu(surface: &mut WgpuSurface, frame: u64, t0: std::time::Instant) {
    use std::time::Instant;
    use windows::Win32::Graphics::Direct3D11::D3D11_BOX;

    static TOTAL_ENCODE: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
    static TOTAL_POLL: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
    static TOTAL_UPDATE: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);

    let width = surface.width;
    let height = surface.height;
    let bytes_per_row = width * 4;
    let padded_bytes_per_row = surface.platform.staging_buffer_row_pitch;
    let staging_buffer = &surface.platform.staging_buffer;

    let mut encoder = surface
        .device
        .create_command_encoder(&wgpu::CommandEncoderDescriptor {
            label: Some("d3d11 copy encoder"),
        });

    encoder.copy_texture_to_buffer(
        wgpu::TexelCopyTextureInfo {
            texture: &surface.texture,
            mip_level: 0,
            origin: wgpu::Origin3d::ZERO,
            aspect: wgpu::TextureAspect::All,
        },
        wgpu::TexelCopyBufferInfo {
            buffer: staging_buffer,
            layout: wgpu::TexelCopyBufferLayout {
                offset: 0,
                bytes_per_row: Some(padded_bytes_per_row),
                rows_per_image: Some(height),
            },
        },
        wgpu::Extent3d {
            width,
            height,
            depth_or_array_layers: 1,
        },
    );

    surface.queue.submit(std::iter::once(encoder.finish()));
    let t1 = Instant::now();

    let buffer_slice = staging_buffer.slice(..);
    let (tx, rx) = std::sync::mpsc::channel();
    buffer_slice.map_async(wgpu::MapMode::Read, move |result| {
        let _ = tx.send(result);
    });

    surface.device.poll(wgpu::PollType::wait_indefinitely());

    let map_result = match rx.recv() {
        Ok(result) => result,
        Err(_) => {
            log::error!("copy_to_d3d11_texture: channel recv failed");
            return;
        }
    };
    if let Err(e) = map_result {
        log::error!("copy_to_d3d11_texture: map failed: {:?}", e);
        return;
    }

    let data = buffer_slice.get_mapped_range();
    let t2 = Instant::now();

    if let Some(ref shared_tex) = surface.platform.shared_texture {
        unsafe {
            let dst_box = D3D11_BOX {
                left: 0,
                top: 0,
                front: 0,
                right: width,
                bottom: height,
                back: 1,
            };

            if padded_bytes_per_row == bytes_per_row {
                shared_tex.context.UpdateSubresource(
                    &shared_tex.texture,
                    0,
                    Some(&dst_box),
                    data.as_ptr() as *const _,
                    bytes_per_row,
                    0,
                );
            } else {
                let mut temp = vec![0u8; (bytes_per_row * height) as usize];
                for y in 0..height {
                    let src_offset = (y * padded_bytes_per_row) as usize;
                    let dst_offset = (y * bytes_per_row) as usize;
                    temp[dst_offset..dst_offset + bytes_per_row as usize]
                        .copy_from_slice(&data[src_offset..src_offset + bytes_per_row as usize]);
                }
                shared_tex.context.UpdateSubresource(
                    &shared_tex.texture,
                    0,
                    Some(&dst_box),
                    temp.as_ptr() as *const _,
                    bytes_per_row,
                    0,
                );
            }

            shared_tex.context.Flush();
        }
    }
    let t3 = Instant::now();

    drop(data);
    staging_buffer.unmap();

    TOTAL_ENCODE.fetch_add(
        (t1 - t0).as_micros() as u64,
        std::sync::atomic::Ordering::Relaxed,
    );
    TOTAL_POLL.fetch_add(
        (t2 - t1).as_micros() as u64,
        std::sync::atomic::Ordering::Relaxed,
    );
    TOTAL_UPDATE.fetch_add(
        (t3 - t2).as_micros() as u64,
        std::sync::atomic::Ordering::Relaxed,
    );

    if frame > 0 && frame % 60 == 0 {
        let n = frame as f64;
        let total = (t3 - t0).as_micros();
        eprintln!(
            "[D3D11] avg/{}f: encode={:.0}us poll={:.0}us update={:.0}us | frame={}us",
            frame,
            TOTAL_ENCODE.load(std::sync::atomic::Ordering::Relaxed) as f64 / n,
            TOTAL_POLL.load(std::sync::atomic::Ordering::Relaxed) as f64 / n,
            TOTAL_UPDATE.load(std::sync::atomic::Ordering::Relaxed) as f64 / n,
            total
        );
    }
}

fn copy_to_pixel_buffer_impl(surface: &mut WgpuSurface) {
    use std::time::Instant;

    static FRAME_COUNT: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
    static TOTAL_ENCODE_COPY: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
    static TOTAL_SUBMIT: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
    static TOTAL_POLL_WAIT: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
    static TOTAL_MAP_RECV: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
    static TOTAL_MEMCPY: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);

    let frame = FRAME_COUNT.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
    let t_start = Instant::now();

    let width = surface.width;
    let height = surface.height;
    let bytes_per_row = width * 4;
    let padded_bytes_per_row = surface.platform.staging_buffer_row_pitch;

    let staging_buffer = &surface.platform.staging_buffer;

    let mut encoder = surface
        .device
        .create_command_encoder(&wgpu::CommandEncoderDescriptor {
            label: Some("pixel buffer copy encoder"),
        });

    encoder.copy_texture_to_buffer(
        wgpu::TexelCopyTextureInfo {
            texture: &surface.texture,
            mip_level: 0,
            origin: wgpu::Origin3d::ZERO,
            aspect: wgpu::TextureAspect::All,
        },
        wgpu::TexelCopyBufferInfo {
            buffer: staging_buffer,
            layout: wgpu::TexelCopyBufferLayout {
                offset: 0,
                bytes_per_row: Some(padded_bytes_per_row),
                rows_per_image: Some(height),
            },
        },
        wgpu::Extent3d {
            width,
            height,
            depth_or_array_layers: 1,
        },
    );
    let t1 = Instant::now();

    surface.queue.submit(std::iter::once(encoder.finish()));
    let t2 = Instant::now();

    let buffer_slice = staging_buffer.slice(..);
    let (tx, rx) = std::sync::mpsc::channel();
    buffer_slice.map_async(wgpu::MapMode::Read, move |result| {
        let _ = tx.send(result);
    });

    surface.device.poll(wgpu::PollType::wait_indefinitely());
    let t3 = Instant::now();

    let map_result = match rx.recv() {
        Ok(result) => result,
        Err(_) => {
            log::error!("copy_wgpu_to_pixel_buffer: channel recv failed");
            return;
        }
    };
    if let Err(e) = map_result {
        log::error!("copy_wgpu_to_pixel_buffer: map failed: {:?}", e);
        return;
    }

    let data = buffer_slice.get_mapped_range();
    let t4 = Instant::now();

    {
        let mut pixel_buffer = match surface.platform.pixel_buffer.lock() {
            Ok(guard) => guard,
            Err(poisoned) => poisoned.into_inner(),
        };

        let buf_len = pixel_buffer.len();
        if padded_bytes_per_row == bytes_per_row {
            pixel_buffer.copy_from_slice(&data[..buf_len]);
        } else {
            for y in 0..height {
                let src_offset = (y * padded_bytes_per_row) as usize;
                let dst_offset = (y * bytes_per_row) as usize;
                pixel_buffer[dst_offset..dst_offset + bytes_per_row as usize]
                    .copy_from_slice(&data[src_offset..src_offset + bytes_per_row as usize]);
            }
        }
    }
    let t5 = Instant::now();

    drop(data);
    staging_buffer.unmap();

    TOTAL_ENCODE_COPY.fetch_add(
        (t1 - t_start).as_micros() as u64,
        std::sync::atomic::Ordering::Relaxed,
    );
    TOTAL_SUBMIT.fetch_add(
        (t2 - t1).as_micros() as u64,
        std::sync::atomic::Ordering::Relaxed,
    );
    TOTAL_POLL_WAIT.fetch_add(
        (t3 - t2).as_micros() as u64,
        std::sync::atomic::Ordering::Relaxed,
    );
    TOTAL_MAP_RECV.fetch_add(
        (t4 - t3).as_micros() as u64,
        std::sync::atomic::Ordering::Relaxed,
    );
    TOTAL_MEMCPY.fetch_add(
        (t5 - t4).as_micros() as u64,
        std::sync::atomic::Ordering::Relaxed,
    );

    if frame > 0 && frame % 60 == 0 {
        let n = frame as f64;
        let total = (t5 - t_start).as_micros();
        eprintln!(
            "[wgpu] copy_pixbuf avg/{}f: enc={:.0}us sub={:.0}us poll={:.0}us map={:.0}us memcpy={:.0}us | frame={}us",
            frame,
            TOTAL_ENCODE_COPY.load(std::sync::atomic::Ordering::Relaxed) as f64 / n,
            TOTAL_SUBMIT.load(std::sync::atomic::Ordering::Relaxed) as f64 / n,
            TOTAL_POLL_WAIT.load(std::sync::atomic::Ordering::Relaxed) as f64 / n,
            TOTAL_MAP_RECV.load(std::sync::atomic::Ordering::Relaxed) as f64 / n,
            TOTAL_MEMCPY.load(std::sync::atomic::Ordering::Relaxed) as f64 / n,
            total
        );
    }
}
