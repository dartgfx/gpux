// Linux wgpu surface with pixel buffer readback
//
// Flow:
// 1. wgpu renders to its own texture (Vulkan backend)
// 2. Copy texture -> staging buffer (GPU)
// 3. Map staging buffer -> CPU pixel buffer
// 4. Consumer reads pixel buffer directly

use super::{create_depth_texture, WgpuSurface};
use std::sync::{Arc, Mutex};

pub struct LinuxSurface {
    pub pixel_buffer: Mutex<Vec<u8>>,
    pub pixel_buffer_ptr: *const u8,
    staging_buffer: wgpu::Buffer,
    staging_buffer_row_pitch: u32,
}

unsafe impl Send for LinuxSurface {}
unsafe impl Sync for LinuxSurface {}

impl LinuxSurface {
    pub fn create(
        device: Arc<wgpu::Device>,
        queue: Arc<wgpu::Queue>,
        width: u32,
        height: u32,
    ) -> Result<WgpuSurface, String> {
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

        // wgpu requires buffer copy rows aligned to 256 bytes
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

        Ok(WgpuSurface {
            device,
            queue,
            width,
            height,
            format_ffi: 17, // rgba8Unorm
            texture,
            depth_texture,
            platform: LinuxSurface {
                pixel_buffer: Mutex::new(pixel_buffer),
                pixel_buffer_ptr,
                staging_buffer,
                staging_buffer_row_pitch: padded_bytes_per_row,
            },
        })
    }

    pub fn get_pixel_buffer_ptr(&self) -> *const u8 {
        self.pixel_buffer_ptr
    }
}

/// Copy wgpu render output to CPU pixel buffer.
pub fn copy_wgpu_to_pixel_buffer(surface: &mut WgpuSurface) {
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

    let _ = surface.device.poll(wgpu::PollType::wait_indefinitely());
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
