use crate::abi::types::*;
use crate::runtime::handle::*;
use crate::sync::state::PendingFence;

pub fn queue_submit_fenced(
    queue: &wgpu::Queue,
    command_buffer_handles: &[WGPUCommandBuffer],
) -> WGPUFence {
    let buffers: Vec<wgpu::CommandBuffer> = command_buffer_handles
        .iter()
        .filter_map(|&handle| {
            if handle == 0 {
                return None;
            }
            Some(unsafe { drop_handle::<wgpu::CommandBuffer>(handle) })
        })
        .collect();

    if buffers.is_empty() && !command_buffer_handles.is_empty() {
        return 0;
    }

    let submission_index = queue.submit(buffers);

    into_handle(PendingFence { submission_index })
}

pub fn fence_status(device: &wgpu::Device, handle: WGPUFence) -> i32 {
    if handle == 0 {
        return 1;
    }
    let fence = unsafe { deref_handle::<PendingFence>(handle) };
    let result = device.poll(wgpu::PollType::Wait {
        submission_index: Some(fence.submission_index.clone()),
        timeout: Some(std::time::Duration::ZERO),
    });
    match result {
        Ok(_) => 1,
        Err(wgpu::PollError::Timeout) => 0,
        Err(_) => 1,
    }
}

pub fn fence_wait(device: &wgpu::Device, handle: WGPUFence) -> u32 {
    if handle == 0 {
        return 0;
    }
    let fence = unsafe { deref_handle::<PendingFence>(handle) };

    let mut iterations = 0u32;
    loop {
        iterations += 1;
        let result = device.poll(wgpu::PollType::Wait {
            submission_index: Some(fence.submission_index.clone()),
            timeout: Some(std::time::Duration::from_micros(100)),
        });
        match result {
            Ok(_) => break,
            Err(wgpu::PollError::Timeout) => continue,
            Err(_) => break,
        }
    }
    iterations
}

pub fn fence_release(handle: WGPUFence) {
    if handle == 0 {
        return;
    }
    unsafe { drop_handle::<PendingFence>(handle) };
}
