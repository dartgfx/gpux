use crate::abi::types::*;
use crate::runtime::handle::*;

pub fn device_create_query_set(
    device: &wgpu::Device,
    query_type: u32,
    count: u32,
    label: Option<&str>,
) -> WGPUQuerySet {
    let ty = match query_type {
        1 => wgpu::QueryType::Occlusion,
        _ => wgpu::QueryType::Timestamp,
    };
    let query_set = device.create_query_set(&wgpu::QuerySetDescriptor { label, ty, count });

    into_handle(query_set)
}

pub fn query_set_release(query_set_handle: WGPUQuerySet) {
    unsafe { drop_handle::<wgpu::QuerySet>(query_set_handle) };
}

pub fn command_encoder_write_timestamp(
    encoder_handle: WGPUCommandEncoder,
    query_set_handle: WGPUQuerySet,
    query_index: u32,
) {
    let encoder = unsafe { deref_handle_mut::<wgpu::CommandEncoder>(encoder_handle) };
    let qs = unsafe { deref_handle::<wgpu::QuerySet>(query_set_handle) };

    encoder.write_timestamp(qs, query_index);
}

pub fn command_encoder_resolve_query_set(
    encoder_handle: WGPUCommandEncoder,
    query_set_handle: WGPUQuerySet,
    first_query: u32,
    query_count: u32,
    destination: WGPUBuffer,
    destination_offset: u64,
) {
    let encoder = unsafe { deref_handle_mut::<wgpu::CommandEncoder>(encoder_handle) };
    let qs = unsafe { deref_handle::<wgpu::QuerySet>(query_set_handle) };
    let dst_buffer = unsafe { deref_handle::<wgpu::Buffer>(destination) };

    encoder.resolve_query_set(
        qs,
        first_query..first_query + query_count,
        dst_buffer,
        destination_offset,
    );
}
