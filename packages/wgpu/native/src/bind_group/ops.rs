use crate::abi::enums::*;
use crate::abi::types::*;
use crate::runtime::handle::*;
use crate::runtime::label::label_from_ptr;

pub fn device_create_bind_group_layout(
    device: &wgpu::Device,
    desc: &WGPUBindGroupLayoutDescriptor,
) -> WGPUBindGroupLayout {
    let entries: Vec<wgpu::BindGroupLayoutEntry> = if desc.entry_count > 0
        && !desc.entries.is_null()
    {
        let raw_entries =
            unsafe { std::slice::from_raw_parts(desc.entries, desc.entry_count as usize) };
        raw_entries
            .iter()
            .map(|e| {
                let binding_type = match e.binding_type {
                    BINDING_TYPE_BUFFER => wgpu::BindingType::Buffer {
                        ty: buffer_binding_type_from_u32(e.buffer_type),
                        has_dynamic_offset: e.has_dynamic_offset != 0,
                        min_binding_size: if e.min_binding_size > 0 {
                            std::num::NonZeroU64::new(e.min_binding_size)
                        } else {
                            None
                        },
                    },
                    BINDING_TYPE_SAMPLER => {
                        wgpu::BindingType::Sampler(sampler_binding_type_from_u32(e.sampler_type))
                    }
                    BINDING_TYPE_TEXTURE => wgpu::BindingType::Texture {
                        sample_type: texture_sample_type_from_u32(e.texture_sample_type),
                        view_dimension: texture_view_dimension_from_u32(e.texture_view_dimension),
                        multisampled: e.texture_multisampled != 0,
                    },
                    BINDING_TYPE_STORAGE_TEXTURE => wgpu::BindingType::StorageTexture {
                        access: storage_texture_access_from_u32(e.buffer_type),
                        format: texture_format_from_u32(e.texture_sample_type),
                        view_dimension: texture_view_dimension_from_u32(e.texture_view_dimension),
                    },
                    _ => wgpu::BindingType::Buffer {
                        ty: wgpu::BufferBindingType::Uniform,
                        has_dynamic_offset: false,
                        min_binding_size: None,
                    },
                };
                wgpu::BindGroupLayoutEntry {
                    binding: e.binding,
                    visibility: shader_stages_from_u32(e.visibility),
                    ty: binding_type,
                    count: if e.count > 0 {
                        std::num::NonZeroU32::new(e.count)
                    } else {
                        None
                    },
                }
            })
            .collect()
    } else {
        vec![]
    };

    let layout = device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
        label: unsafe { label_from_ptr(desc.label) },
        entries: &entries,
    });
    into_handle(layout)
}

pub fn bind_group_layout_release(layout: WGPUBindGroupLayout) {
    if layout == 0 {
        return;
    }
    unsafe {
        drop_handle::<wgpu::BindGroupLayout>(layout);
    }
}

pub fn device_create_bind_group(
    device: &wgpu::Device,
    desc: &WGPUBindGroupDescriptor,
) -> WGPUBindGroup {
    if desc.layout == 0 {
        return 0;
    }
    let layout = unsafe { deref_handle::<wgpu::BindGroupLayout>(desc.layout) };

    if desc.entry_count == 0 || desc.entries.is_null() {
        let bind_group = device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: unsafe { label_from_ptr(desc.label) },
            layout,
            entries: &[],
        });
        return into_handle(bind_group);
    }

    let raw_entries =
        unsafe { std::slice::from_raw_parts(desc.entries, desc.entry_count as usize) };

    // Pre-collect texture view arrays so they outlive the BindGroupEntry references
    let view_arrays: Vec<Option<Vec<&wgpu::TextureView>>> = raw_entries
        .iter()
        .map(|e| {
            if e.resource_type == 4 {
                let count = e.size as usize;
                let handles_ptr = e.resource as *const u64;
                let handle_slice = unsafe { std::slice::from_raw_parts(handles_ptr, count) };
                Some(
                    handle_slice
                        .iter()
                        .filter(|&&h| h != 0)
                        .map(|&h| unsafe { deref_handle::<wgpu::TextureView>(h) })
                        .collect(),
                )
            } else {
                None
            }
        })
        .collect();

    let entries: Vec<wgpu::BindGroupEntry> = raw_entries
        .iter()
        .enumerate()
        .filter_map(|(i, e)| {
            let resource = match e.resource_type {
                0 => {
                    if e.resource == 0 {
                        return None;
                    }
                    let buffer = unsafe { deref_handle::<wgpu::Buffer>(e.resource) };
                    let size = if e.size > 0 {
                        std::num::NonZeroU64::new(e.size)
                    } else {
                        None
                    };
                    wgpu::BindingResource::Buffer(wgpu::BufferBinding {
                        buffer,
                        offset: e.offset,
                        size,
                    })
                }
                1 => {
                    if e.resource == 0 {
                        return None;
                    }
                    let sampler = unsafe { deref_handle::<wgpu::Sampler>(e.resource) };
                    wgpu::BindingResource::Sampler(sampler)
                }
                2 => {
                    if e.resource == 0 {
                        return None;
                    }
                    let view = unsafe { deref_handle::<wgpu::TextureView>(e.resource) };
                    wgpu::BindingResource::TextureView(view)
                }
                4 => {
                    let views = view_arrays[i].as_ref()?;
                    wgpu::BindingResource::TextureViewArray(views)
                }
                _ => return None,
            };
            Some(wgpu::BindGroupEntry {
                binding: e.binding,
                resource,
            })
        })
        .collect();

    let bind_group = device.create_bind_group(&wgpu::BindGroupDescriptor {
        label: unsafe { label_from_ptr(desc.label) },
        layout,
        entries: &entries,
    });
    into_handle(bind_group)
}

pub fn bind_group_release(group: WGPUBindGroup) {
    if group == 0 {
        return;
    }
    unsafe {
        drop_handle::<wgpu::BindGroup>(group);
    }
}
