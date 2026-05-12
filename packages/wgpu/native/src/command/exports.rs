use crate::abi::types::*;
use crate::command::ops;
use crate::ffi_catch;
use crate::runtime::handle::*;
use crate::runtime::label::label_from_ptr;
use crate::runtime::state::*;

#[export_name = "wgpun_DeviceCreateCommandEncoder"]
pub extern "C" fn wgpuDeviceCreateCommandEncoder(
    device: WGPUDevice,
    label: *const std::ffi::c_char,
) -> WGPUCommandEncoder {
    if device == 0 {
        return 0;
    }
    ffi_catch!(0, {
        let entry = unsafe { deref_handle::<DeviceEntry>(device) };
        let lbl = unsafe { label_from_ptr(label) };
        ops::device_create_command_encoder(&entry.device, lbl)
    })
}

#[export_name = "wgpun_CommandEncoderFinish"]
pub extern "C" fn wgpuCommandEncoderFinish(encoder: WGPUCommandEncoder) -> WGPUCommandBuffer {
    if encoder == 0 {
        return 0;
    }
    ffi_catch!(0, { ops::command_encoder_finish(encoder) })
}

#[export_name = "wgpun_CommandEncoderInsertDebugMarker"]
pub extern "C" fn wgpuCommandEncoderInsertDebugMarker(
    encoder: WGPUCommandEncoder,
    label: *const std::ffi::c_char,
) {
    if encoder == 0 {
        return;
    }
    ffi_catch!((), {
        ops::command_encoder_insert_debug_marker(encoder, label);
    })
}

#[export_name = "wgpun_CommandEncoderPushDebugGroup"]
pub extern "C" fn wgpuCommandEncoderPushDebugGroup(
    encoder: WGPUCommandEncoder,
    label: *const std::ffi::c_char,
) {
    if encoder == 0 {
        return;
    }
    ffi_catch!((), {
        ops::command_encoder_push_debug_group(encoder, label);
    })
}

#[export_name = "wgpun_CommandEncoderPopDebugGroup"]
pub extern "C" fn wgpuCommandEncoderPopDebugGroup(encoder: WGPUCommandEncoder) {
    if encoder == 0 {
        return;
    }
    ffi_catch!((), {
        ops::command_encoder_pop_debug_group(encoder);
    })
}

#[export_name = "wgpun_CommandEncoderCopyBufferToBuffer"]
pub extern "C" fn wgpuCommandEncoderCopyBufferToBuffer(
    encoder: WGPUCommandEncoder,
    source: WGPUBuffer,
    source_offset: u64,
    destination: WGPUBuffer,
    destination_offset: u64,
    size: u64,
) -> u8 {
    if encoder == 0 || source == 0 || destination == 0 {
        return 0;
    }
    ffi_catch!(0, {
        ops::command_encoder_copy_buffer_to_buffer(
            encoder,
            source,
            source_offset,
            destination,
            destination_offset,
            size,
        );
        1
    })
}

#[export_name = "wgpun_CommandEncoderClearBuffer"]
pub extern "C" fn wgpuCommandEncoderClearBuffer(
    encoder: WGPUCommandEncoder,
    buffer: WGPUBuffer,
    offset: u64,
    size: u64,
) -> u8 {
    if encoder == 0 || buffer == 0 {
        return 0;
    }
    ffi_catch!(0, {
        let size_opt = if size == 0 { None } else { Some(size) };
        ops::command_encoder_clear_buffer(encoder, buffer, offset, size_opt);
        1
    })
}

#[export_name = "wgpun_CommandEncoderCopyTextureToBuffer"]
pub extern "C" fn wgpuCommandEncoderCopyTextureToBuffer(
    encoder: WGPUCommandEncoder,
    texture: WGPUTexture,
    buffer: WGPUBuffer,
    bytes_per_row: u32,
    rows_per_image: u32,
    width: u32,
    height: u32,
    depth: u32,
    mip_level: u32,
    origin_x: u32,
    origin_y: u32,
    origin_z: u32,
) -> u8 {
    if encoder == 0 || texture == 0 || buffer == 0 {
        return 0;
    }
    ffi_catch!(0, {
        ops::command_encoder_copy_texture_to_buffer(
            encoder,
            texture,
            buffer,
            bytes_per_row,
            rows_per_image,
            width,
            height,
            depth,
            mip_level,
            origin_x,
            origin_y,
            origin_z,
        );
        1
    })
}

#[export_name = "wgpun_CommandEncoderCopyBufferToTexture"]
pub extern "C" fn wgpuCommandEncoderCopyBufferToTexture(
    encoder: WGPUCommandEncoder,
    buffer: WGPUBuffer,
    texture: WGPUTexture,
    bytes_per_row: u32,
    rows_per_image: u32,
    width: u32,
    height: u32,
    depth: u32,
    mip_level: u32,
    origin_x: u32,
    origin_y: u32,
    origin_z: u32,
) -> u8 {
    if encoder == 0 || buffer == 0 || texture == 0 {
        return 0;
    }
    ffi_catch!(0, {
        ops::command_encoder_copy_buffer_to_texture(
            encoder,
            buffer,
            texture,
            bytes_per_row,
            rows_per_image,
            width,
            height,
            depth,
            mip_level,
            origin_x,
            origin_y,
            origin_z,
        );
        1
    })
}

#[export_name = "wgpun_CommandEncoderCopyTextureToTexture"]
pub extern "C" fn wgpuCommandEncoderCopyTextureToTexture(
    encoder: WGPUCommandEncoder,
    src_texture: WGPUTexture,
    dst_texture: WGPUTexture,
    width: u32,
    height: u32,
    depth: u32,
    src_mip_level: u32,
    src_origin_x: u32,
    src_origin_y: u32,
    src_origin_z: u32,
    dst_mip_level: u32,
    dst_origin_x: u32,
    dst_origin_y: u32,
    dst_origin_z: u32,
) -> u8 {
    if encoder == 0 || src_texture == 0 || dst_texture == 0 {
        return 0;
    }
    ffi_catch!(0, {
        ops::command_encoder_copy_texture_to_texture(
            encoder,
            src_texture,
            dst_texture,
            width,
            height,
            depth,
            src_mip_level,
            src_origin_x,
            src_origin_y,
            src_origin_z,
            dst_mip_level,
            dst_origin_x,
            dst_origin_y,
            dst_origin_z,
        );
        1
    })
}
