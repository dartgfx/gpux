use std::sync::Arc;

pub(crate) struct AdapterEntry {
    pub adapter: wgpu::Adapter,
    /// Back-reference to parent instance (used on Android for surface creation chain).
    #[allow(dead_code)]
    pub instance_handle: u64,
    /// Cached adapter info strings (prevents unbounded CString leak on repeated calls).
    pub cached_info: std::sync::OnceLock<(std::ffi::CString, std::ffi::CString)>,
}

pub(crate) struct DeviceEntry {
    pub device: Arc<wgpu::Device>,
    pub queue: Arc<wgpu::Queue>,
    /// Back-reference to parent adapter (used on Android for surface creation chain).
    #[allow(dead_code)]
    pub adapter_handle: u64,
    pub errors: Arc<std::sync::Mutex<Vec<std::ffi::CString>>>,
}

pub(crate) struct RenderPassWrapper {
    pub encoder_ptr: *mut wgpu::CommandEncoder,
    pub pass_ptr: *mut wgpu::RenderPass<'static>,
}

pub(crate) struct ComputePassWrapper {
    pub encoder_ptr: *mut wgpu::CommandEncoder,
    pub pass_ptr: *mut wgpu::ComputePass<'static>,
}
