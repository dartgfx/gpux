use crate::abi::types::*;
use crate::runtime::handle::*;
use crate::runtime::label::label_from_ptr;
use crate::runtime::state::*;

fn u32_option(v: u32) -> Option<u32> {
    if v == u32::MAX {
        None
    } else {
        Some(v)
    }
}

/// Begin a compute pass. Consumes the encoder handle, returns a ComputePassWrapper handle.
/// SAFETY: The compute pass borrows the encoder. The encoder is recovered via
/// compute_pass_end.
pub fn command_encoder_begin_compute_pass(
    encoder_handle: WGPUCommandEncoder,
    desc: Option<&WGPUComputePassDescriptor>,
) -> WGPUComputePassEncoder {
    let encoder = unsafe { drop_handle::<wgpu::CommandEncoder>(encoder_handle) };

    let timestamp_writes = match desc {
        Some(d) if d.timestamp_writes_query_set != 0 => {
            let qs = unsafe { deref_handle::<wgpu::QuerySet>(d.timestamp_writes_query_set) };
            Some(wgpu::ComputePassTimestampWrites {
                query_set: qs,
                beginning_of_pass_write_index: u32_option(d.timestamp_writes_beginning),
                end_of_pass_write_index: u32_option(d.timestamp_writes_end),
            })
        }
        _ => None,
    };

    let encoder_box = Box::new(encoder);
    let encoder_ptr = Box::into_raw(encoder_box);

    let compute_pass = unsafe {
        let pass_label = match desc {
            Some(d) => label_from_ptr(d.label),
            None => None,
        };
        (*encoder_ptr).begin_compute_pass(&wgpu::ComputePassDescriptor {
            label: pass_label,
            timestamp_writes,
        })
    };

    let pass_box = Box::new(compute_pass);
    let pass_ptr = Box::into_raw(pass_box);

    into_handle(ComputePassWrapper {
        encoder_ptr,
        pass_ptr,
    })
}

pub fn compute_pass_set_pipeline(
    pass_handle: WGPUComputePassEncoder,
    pipeline_handle: WGPUComputePipeline,
) {
    let wrapper = unsafe { deref_handle::<ComputePassWrapper>(pass_handle) };
    let pipeline = unsafe { deref_handle::<wgpu::ComputePipeline>(pipeline_handle) };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.set_pipeline(pipeline);
}

pub fn compute_pass_set_bind_group(
    pass_handle: WGPUComputePassEncoder,
    index: u32,
    bind_group_id: WGPUBindGroup,
    dynamic_offsets: &[u32],
) {
    let wrapper = unsafe { deref_handle::<ComputePassWrapper>(pass_handle) };

    if bind_group_id == 0 {
        let pass = unsafe { &mut *wrapper.pass_ptr };
        pass.set_bind_group(index, None, dynamic_offsets);
        return;
    }

    let bind_group = unsafe { deref_handle::<wgpu::BindGroup>(bind_group_id) };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.set_bind_group(index, Some(bind_group), dynamic_offsets);
}

pub fn compute_pass_dispatch_workgroups(
    pass_handle: WGPUComputePassEncoder,
    x: u32,
    y: u32,
    z: u32,
) {
    let wrapper = unsafe { deref_handle::<ComputePassWrapper>(pass_handle) };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.dispatch_workgroups(x, y, z);
}

pub fn compute_pass_dispatch_workgroups_indirect(
    pass_handle: WGPUComputePassEncoder,
    indirect_buffer: WGPUBuffer,
    indirect_offset: u64,
) {
    let wrapper = unsafe { deref_handle::<ComputePassWrapper>(pass_handle) };
    let buffer = unsafe { deref_handle::<wgpu::Buffer>(indirect_buffer) };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.dispatch_workgroups_indirect(buffer, indirect_offset);
}

pub fn compute_pass_push_debug_group(
    pass_handle: WGPUComputePassEncoder,
    label: *const std::ffi::c_char,
) {
    let wrapper = unsafe { deref_handle::<ComputePassWrapper>(pass_handle) };

    let label_str = if label.is_null() {
        ""
    } else {
        unsafe { std::ffi::CStr::from_ptr(label).to_str().unwrap_or("") }
    };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.push_debug_group(label_str);
}

pub fn compute_pass_pop_debug_group(pass_handle: WGPUComputePassEncoder) {
    let wrapper = unsafe { deref_handle::<ComputePassWrapper>(pass_handle) };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.pop_debug_group();
}

pub fn compute_pass_insert_debug_marker(
    pass_handle: WGPUComputePassEncoder,
    label: *const std::ffi::c_char,
) {
    let wrapper = unsafe { deref_handle::<ComputePassWrapper>(pass_handle) };

    let label_str = if label.is_null() {
        ""
    } else {
        unsafe { std::ffi::CStr::from_ptr(label).to_str().unwrap_or("") }
    };

    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.insert_debug_marker(label_str);
}

pub fn compute_pass_set_immediates(
    pass_handle: WGPUComputePassEncoder,
    offset: u32,
    data: *const u8,
    data_len: u32,
) {
    let wrapper = unsafe { deref_handle::<ComputePassWrapper>(pass_handle) };
    let slice = unsafe { std::slice::from_raw_parts(data, data_len as usize) };
    let pass = unsafe { &mut *wrapper.pass_ptr };
    pass.set_immediates(offset, slice);
}

pub fn compute_pass_end(pass_handle: WGPUComputePassEncoder) -> WGPUCommandEncoder {
    let wrapper = unsafe { drop_handle::<ComputePassWrapper>(pass_handle) };

    unsafe {
        let _pass = Box::from_raw(wrapper.pass_ptr);
        // pass drops here, ending the compute pass

        let encoder = *Box::from_raw(wrapper.encoder_ptr);
        into_handle(encoder)
    }
}
