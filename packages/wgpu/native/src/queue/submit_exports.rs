use std::sync::Arc;

use crate::abi::types::*;
use crate::ffi_catch;
use crate::queue::ops;
use crate::runtime::handle::*;

// =============================================================================
// QUEUE SUBMIT
// =============================================================================

#[export_name = "wgpun_QueueSubmit"]
pub extern "C" fn wgpuQueueSubmit(
    queue: WGPUQueue,
    command_buffers: *const WGPUCommandBuffer,
    count: u32,
) {
    if queue == 0 || command_buffers.is_null() || count == 0 {
        return;
    }
    ffi_catch!((), {
        let queue_arc = unsafe { deref_handle::<Arc<wgpu::Queue>>(queue) };
        let buffers = unsafe { std::slice::from_raw_parts(command_buffers, count as usize) };
        ops::queue_submit(queue_arc, buffers);
    })
}
