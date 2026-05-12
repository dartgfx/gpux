use crate::abi::types::*;
use crate::buffer::readback::ops;
use crate::ffi_catch;
use crate::runtime::handle::*;
use crate::runtime::state::*;

#[export_name = "wgpun_BufferReadSync"]
pub extern "C" fn wgpuBufferReadSync(
    device: WGPUDevice,
    buffer: WGPUBuffer,
    offset: u64,
    size: u64,
    output: *mut u8,
) -> u64 {
    if device == 0 || buffer == 0 || output.is_null() || size == 0 {
        return 0;
    }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let output_slice = unsafe { std::slice::from_raw_parts_mut(output, size as usize) };
        ops::buffer_read_sync(
            &entry.device,
            &entry.queue,
            buffer,
            offset,
            size,
            output_slice,
        )
    })
}
