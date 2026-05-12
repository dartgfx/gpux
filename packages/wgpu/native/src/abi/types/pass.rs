use super::handles::*;

#[repr(C)]
pub struct WGPURenderPassColorAttachment {
    pub view: WGPUTextureView,
    pub resolve_target: WGPUTextureView,
    pub load_op: u32,
    pub store_op: u32,
    pub clear_r: f64,
    pub clear_g: f64,
    pub clear_b: f64,
    pub clear_a: f64,
    /// Depth slice for 3D texture render targets (u32::MAX = None).
    pub depth_slice: u32,
}

#[repr(C)]
pub struct WGPURenderPassDepthStencilAttachment {
    pub view: WGPUTextureView,
    pub depth_load_op: u32,
    pub depth_store_op: u32,
    pub depth_clear_value: f32,
    pub depth_read_only: u8,
    pub stencil_load_op: u32,
    pub stencil_store_op: u32,
    pub stencil_clear_value: u32,
    pub stencil_read_only: u8,
}

#[repr(C)]
pub struct WGPURenderPassDescriptor {
    pub color_attachments: *const WGPURenderPassColorAttachment,
    pub color_attachment_count: u32,
    pub depth_stencil_attachment: *const WGPURenderPassDepthStencilAttachment,
    pub occlusion_query_set: WGPUQuerySet,
    /// Max draw calls (0 = use default 50_000_000).
    pub max_draw_count: u64,
    /// Timestamp writes query set handle (0 = none).
    pub timestamp_writes_query_set: WGPUQuerySet,
    /// Query index for beginning timestamp.
    pub timestamp_writes_beginning: u32,
    /// Query index for end timestamp.
    pub timestamp_writes_end: u32,
    pub label: *const std::ffi::c_char,
}
