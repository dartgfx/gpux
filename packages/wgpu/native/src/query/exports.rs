use std::sync::Arc;

use crate::abi::types::*;
use crate::ffi_catch;
use crate::query::ops;
use crate::queue::ops as queue_ops;
use crate::runtime::handle::*;
use crate::runtime::label::label_from_ptr;
use crate::runtime::state::*;

#[export_name = "wgpun_DeviceCreateQuerySet"]
pub extern "C" fn wgpuDeviceCreateQuerySet(
    device: WGPUDevice,
    query_type: u32,
    count: u32,
    label: *const std::ffi::c_char,
) -> WGPUQuerySet {
    if device == 0 {
        return 0;
    }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let lbl = unsafe { label_from_ptr(label) };
        ops::device_create_query_set(&entry.device, query_type, count, lbl)
    })
}

#[export_name = "wgpun_QuerySetRelease"]
pub extern "C" fn wgpuQuerySetRelease(query_set: WGPUQuerySet) {
    if query_set == 0 {
        return;
    }
    ffi_catch!((), {
        ops::query_set_release(query_set);
    })
}

#[export_name = "wgpun_QuerySetRelease_p"]
pub extern "C" fn query_set_release_p(ptr: *mut std::ffi::c_void) {
    wgpuQuerySetRelease(ptr as u64);
}

#[export_name = "wgpun_CommandEncoderWriteTimestamp"]
pub extern "C" fn wgpuCommandEncoderWriteTimestamp(
    encoder: WGPUCommandEncoder,
    query_set: WGPUQuerySet,
    query_index: u32,
) -> u8 {
    if encoder == 0 || query_set == 0 {
        return 0;
    }
    ffi_catch!(0, {
        ops::command_encoder_write_timestamp(encoder, query_set, query_index);
        1
    })
}

#[export_name = "wgpun_CommandEncoderResolveQuerySet"]
pub extern "C" fn wgpuCommandEncoderResolveQuerySet(
    encoder: WGPUCommandEncoder,
    query_set: WGPUQuerySet,
    first_query: u32,
    query_count: u32,
    destination: WGPUBuffer,
    destination_offset: u64,
) -> u8 {
    if encoder == 0 || query_set == 0 || destination == 0 {
        return 0;
    }
    ffi_catch!(0, {
        ops::command_encoder_resolve_query_set(
            encoder,
            query_set,
            first_query,
            query_count,
            destination,
            destination_offset,
        );
        1
    })
}

#[export_name = "wgpun_QueueGetTimestampPeriod"]
pub extern "C" fn wgpuQueueGetTimestampPeriod(queue: WGPUQueue) -> f32 {
    if queue == 0 {
        return 0.0;
    }
    ffi_catch!(0.0, {
        let queue_arc = unsafe { deref_handle::<Arc<wgpu::Queue>>(queue) };
        queue_ops::queue_get_timestamp_period(queue_arc)
    })
}
