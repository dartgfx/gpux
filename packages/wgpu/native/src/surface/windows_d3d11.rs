// D3D11 Shared Texture with D3D11on12 GPU copy
//
// Creates D3D11 textures with legacy shared handles for cross-process sharing.
// Uses D3D11on12 to wrap wgpu's DX12 textures for GPU-GPU copy (no CPU staging).
//
// Flow:
// 1. Create D3D11 device + D3D11On12 device (sharing DX12 command queue)
// 2. Create D3D11 shared texture
// 3. Each frame: wrap wgpu DX12 texture → GPU copy → unwrap
// 4. Consumer reads shared texture via handle

use windows::{
    core::Interface,
    Win32::{
        Foundation::{HANDLE, HMODULE, LUID},
        Graphics::{
            Direct3D::D3D_DRIVER_TYPE_UNKNOWN,
            Direct3D11::{
                D3D11CreateDevice, ID3D11Device, ID3D11DeviceContext, ID3D11Resource,
                ID3D11Texture2D, D3D11_BIND_RENDER_TARGET, D3D11_BIND_SHADER_RESOURCE,
                D3D11_CREATE_DEVICE_BGRA_SUPPORT, D3D11_RESOURCE_MISC_SHARED, D3D11_SDK_VERSION,
                D3D11_TEXTURE2D_DESC, D3D11_USAGE_DEFAULT,
            },
            Direct3D11on12::{D3D11On12CreateDevice, ID3D11On12Device},
            Direct3D12::{ID3D12CommandQueue, ID3D12Resource},
            Dxgi::{
                Common::DXGI_FORMAT_B8G8R8A8_UNORM, CreateDXGIFactory1, IDXGIAdapter1,
                IDXGIFactory1, IDXGIResource,
            },
        },
    },
};

/// D3D11 shared texture with D3D11on12 for GPU-GPU copy from DX12.
pub struct D3D11SharedTexture {
    pub device: ID3D11Device,
    pub context: ID3D11DeviceContext,
    pub device_11on12: Option<ID3D11On12Device>,
    pub texture: ID3D11Texture2D,
    pub shared_handle: HANDLE,
    pub width: u32,
    pub height: u32,
    // Cached wrapped resource to avoid creating new one each frame
    cached_wrapped: std::sync::Mutex<Option<(usize, ID3D11Resource)>>, // (dx12_ptr, wrapped)
}

impl D3D11SharedTexture {
    /// Create a D3D11 shared texture (without D3D11on12 - for fallback).
    pub fn create(adapter_luid: LUID, width: u32, height: u32) -> Result<Self, String> {
        Self::create_internal(adapter_luid, width, height, None)
    }

    /// Create a D3D11 shared texture with D3D11on12 for GPU copy from DX12.
    pub fn create_with_d3d11on12(
        adapter_luid: LUID,
        width: u32,
        height: u32,
        dx12_device: &windows::Win32::Graphics::Direct3D12::ID3D12Device,
        dx12_queue: &ID3D12CommandQueue,
    ) -> Result<Self, String> {
        Self::create_internal(adapter_luid, width, height, Some((dx12_device, dx12_queue)))
    }

    fn create_internal(
        adapter_luid: LUID,
        width: u32,
        height: u32,
        dx12_resources: Option<(
            &windows::Win32::Graphics::Direct3D12::ID3D12Device,
            &ID3D12CommandQueue,
        )>,
    ) -> Result<Self, String> {
        unsafe {
            let factory: IDXGIFactory1 = CreateDXGIFactory1()
                .map_err(|e| format!("Failed to create DXGI factory: {:?}", e))?;

            let adapter = find_adapter_by_luid(&factory, adapter_luid)?;

            let (device, context, device_11on12) =
                if let Some((dx12_device, dx12_queue)) = dx12_resources {
                    // Create D3D11on12 device wrapping the DX12 device and queue
                    let mut device: Option<ID3D11Device> = None;
                    let mut context: Option<ID3D11DeviceContext> = None;

                    let queues: [Option<windows::core::IUnknown>; 1] = [Some(
                        dx12_queue
                            .cast()
                            .map_err(|e| format!("Queue cast failed: {:?}", e))?,
                    )];

                    D3D11On12CreateDevice(
                        dx12_device, // DX12 device
                        D3D11_CREATE_DEVICE_BGRA_SUPPORT.0,
                        None,
                        Some(&queues),
                        0, // NodeMask
                        Some(&mut device as *mut _),
                        Some(&mut context as *mut _),
                        None,
                    )
                    .map_err(|e| format!("D3D11On12CreateDevice failed: {:?}", e))?;

                    let device = device.ok_or("D3D11on12 device is None")?;
                    let context = context.ok_or("D3D11on12 context is None")?;

                    let device_11on12: ID3D11On12Device = device
                        .cast()
                        .map_err(|e| format!("Failed to get ID3D11On12Device: {:?}", e))?;

                    log::info!("Created D3D11On12 device for GPU-GPU copy");
                    (device, context, Some(device_11on12))
                } else {
                    // Regular D3D11 device (fallback)
                    let mut device: Option<ID3D11Device> = None;
                    let mut context: Option<ID3D11DeviceContext> = None;

                    D3D11CreateDevice(
                        &adapter,
                        D3D_DRIVER_TYPE_UNKNOWN,
                        HMODULE::default(),
                        D3D11_CREATE_DEVICE_BGRA_SUPPORT,
                        None,
                        D3D11_SDK_VERSION,
                        Some(&mut device),
                        None,
                        Some(&mut context),
                    )
                    .map_err(|e| format!("D3D11CreateDevice failed: {:?}", e))?;

                    let device = device.ok_or("D3D11 device is None")?;
                    let context = context.ok_or("D3D11 context is None")?;
                    (device, context, None)
                };

            // Create shared texture
            let desc = D3D11_TEXTURE2D_DESC {
                Width: width,
                Height: height,
                MipLevels: 1,
                ArraySize: 1,
                Format: DXGI_FORMAT_B8G8R8A8_UNORM,
                SampleDesc: windows::Win32::Graphics::Dxgi::Common::DXGI_SAMPLE_DESC {
                    Count: 1,
                    Quality: 0,
                },
                Usage: D3D11_USAGE_DEFAULT,
                BindFlags: (D3D11_BIND_RENDER_TARGET.0 | D3D11_BIND_SHADER_RESOURCE.0) as u32,
                CPUAccessFlags: 0,
                MiscFlags: D3D11_RESOURCE_MISC_SHARED.0 as u32,
            };

            let mut texture: Option<ID3D11Texture2D> = None;
            device
                .CreateTexture2D(&desc, None, Some(&mut texture))
                .map_err(|e| format!("Failed to create shared texture: {:?}", e))?;

            let texture = texture.ok_or("Shared texture is None")?;

            // Get legacy shared handle
            let dxgi_resource: IDXGIResource = texture
                .cast()
                .map_err(|e| format!("Failed to get IDXGIResource: {:?}", e))?;

            let shared_handle = dxgi_resource
                .GetSharedHandle()
                .map_err(|e| format!("Failed to get shared handle: {:?}", e))?;

            if shared_handle.is_invalid() {
                return Err("Shared handle is invalid".to_string());
            }

            log::info!(
                "Created D3D11 shared texture: {}x{}, handle=0x{:x}, d3d11on12={}",
                width,
                height,
                shared_handle.0 as usize,
                device_11on12.is_some()
            );

            // Note: Don't initialize texture here - the D3D11on12 Flush can deadlock
            // with the consumer's thread. First frame from wgpu will fill it.
            Ok(Self {
                device,
                context,
                device_11on12,
                texture,
                shared_handle,
                width,
                height,
                cached_wrapped: std::sync::Mutex::new(None),
            })
        }
    }

    /// Copy from a DX12 resource to the shared texture (GPU-GPU copy).
    /// Returns true if successful, false if D3D11on12 not available.
    pub fn copy_from_dx12(&self, dx12_resource: &ID3D12Resource) -> Result<(), String> {
        let device_11on12 = self
            .device_11on12
            .as_ref()
            .ok_or("D3D11on12 not available")?;

        unsafe {
            // Get or create cached wrapped resource
            let dx12_ptr = dx12_resource as *const _ as usize;
            let mut cache = match self.cached_wrapped.lock() {
                Ok(guard) => guard,
                Err(poisoned) => poisoned.into_inner(),
            };

            let wrapped = if let Some((cached_ptr, ref cached_wrapped)) = *cache {
                if cached_ptr == dx12_ptr {
                    // Same resource, reuse cached wrapper
                    cached_wrapped.clone()
                } else {
                    // Different resource, need to create new wrapper
                    drop(cache.take()); // Release old wrapper
                    let new_wrapped = self.create_wrapped_resource(device_11on12, dx12_resource)?;
                    *cache = Some((dx12_ptr, new_wrapped.clone()));
                    new_wrapped
                }
            } else {
                // No cache, create new wrapper
                let new_wrapped = self.create_wrapped_resource(device_11on12, dx12_resource)?;
                *cache = Some((dx12_ptr, new_wrapped.clone()));
                new_wrapped
            };

            // Release lock before GPU operations
            drop(cache);

            // Acquire the wrapped resource for D3D11 use
            let resources: [Option<ID3D11Resource>; 1] = [Some(wrapped.clone())];
            device_11on12.AcquireWrappedResources(&resources);

            // Copy wrapped → shared texture
            let dst: ID3D11Resource = self
                .texture
                .cast()
                .map_err(|e| format!("Texture cast failed: {:?}", e))?;

            self.context.CopyResource(&dst, &wrapped);

            // Release the wrapped resource back to DX12
            device_11on12.ReleaseWrappedResources(&resources);

            // Flush to ensure copy is complete
            self.context.Flush();

            Ok(())
        }
    }

    unsafe fn create_wrapped_resource(
        &self,
        device_11on12: &ID3D11On12Device,
        dx12_resource: &ID3D12Resource,
    ) -> Result<ID3D11Resource, String> {
        let mut wrapped: Option<ID3D11Resource> = None;

        device_11on12
            .CreateWrappedResource(
                dx12_resource,
                &windows::Win32::Graphics::Direct3D11on12::D3D11_RESOURCE_FLAGS::default(),
                windows::Win32::Graphics::Direct3D12::D3D12_RESOURCE_STATE_COMMON,
                windows::Win32::Graphics::Direct3D12::D3D12_RESOURCE_STATE_COMMON,
                &mut wrapped,
            )
            .map_err(|e| format!("CreateWrappedResource failed: {:?}", e))?;

        wrapped.ok_or_else(|| "Wrapped resource is None".to_string())
    }

    pub fn get_shared_handle(&self) -> HANDLE {
        self.shared_handle
    }

    pub fn has_d3d11on12(&self) -> bool {
        self.device_11on12.is_some()
    }
}

fn find_adapter_by_luid(
    factory: &IDXGIFactory1,
    target_luid: LUID,
) -> Result<IDXGIAdapter1, String> {
    unsafe {
        if target_luid.LowPart == 0 && target_luid.HighPart == 0 {
            return factory
                .EnumAdapters1(0)
                .map_err(|e| format!("Failed to get default adapter: {:?}", e));
        }

        let mut i = 0;
        loop {
            let adapter = match factory.EnumAdapters1(i) {
                Ok(a) => a,
                Err(_) => break,
            };

            let desc = adapter
                .GetDesc1()
                .map_err(|e| format!("Failed to get adapter desc: {:?}", e))?;

            if desc.AdapterLuid.LowPart == target_luid.LowPart
                && desc.AdapterLuid.HighPart == target_luid.HighPart
            {
                return Ok(adapter);
            }

            i += 1;
        }

        Err(format!(
            "No adapter found matching LUID {:08x}{:08x}",
            target_luid.HighPart, target_luid.LowPart
        ))
    }
}
