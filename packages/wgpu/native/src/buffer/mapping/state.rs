use std::sync::atomic::AtomicI32;
use std::sync::Arc;

#[derive(Clone, Copy, PartialEq)]
pub enum BufferMapMode {
    Read = 0,
    Write = 1,
}

pub const MAP_STATUS_PENDING: i32 = 0;
pub const MAP_STATUS_READY: i32 = 1;
pub const MAP_STATUS_ERROR: i32 = -1;

pub enum MappedBuffer {
    Staging(wgpu::Buffer),
    Original(u64),
}

pub struct PendingMapping {
    pub buffer: MappedBuffer,
    pub mode: BufferMapMode,
    pub size: u64,
    pub status: Arc<AtomicI32>,
}
