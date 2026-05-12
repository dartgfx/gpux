// Resource creation and release operations.

use super::enums::*;
use super::types::*;
use crate::handle::*;

/// Convert a nullable C string pointer to an Option<&str> for wgpu labels.
pub(crate) unsafe fn label_from_ptr(ptr: *const std::ffi::c_char) -> Option<&'static str> {
    if ptr.is_null() {
        return None;
    }
    std::ffi::CStr::from_ptr(ptr)
        .to_str()
        .ok()
        .filter(|s| !s.is_empty())
}

// =============================================================================
// BUFFER
// =============================================================================

pub fn device_create_buffer(device: &wgpu::Device, desc: &WGPUBufferDescriptor) -> WGPUBuffer {
    let buffer = device.create_buffer(&wgpu::BufferDescriptor {
        label: unsafe { label_from_ptr(desc.label) },
        size: desc.size,
        usage: wgpu::BufferUsages::from_bits_truncate(desc.usage),
        mapped_at_creation: desc.mapped_at_creation != 0,
    });
    into_handle(buffer)
}

pub fn buffer_release(buffer: WGPUBuffer) {
    if buffer == 0 {
        return;
    }
    unsafe {
        drop_handle::<wgpu::Buffer>(buffer);
    }
}

// =============================================================================
// TEXTURE
// =============================================================================

pub fn device_create_texture(device: &wgpu::Device, desc: &WGPUTextureDescriptor) -> WGPUTexture {
    let view_formats: Vec<wgpu::TextureFormat> =
        if desc.view_format_count > 0 && !desc.view_formats.is_null() {
            let slice = unsafe {
                std::slice::from_raw_parts(desc.view_formats, desc.view_format_count as usize)
            };
            slice.iter().map(|&f| texture_format_from_u32(f)).collect()
        } else {
            Vec::new()
        };

    let texture = device.create_texture(&wgpu::TextureDescriptor {
        label: unsafe { label_from_ptr(desc.label) },
        size: wgpu::Extent3d {
            width: desc.width,
            height: desc.height,
            depth_or_array_layers: desc.depth_or_array_layers,
        },
        mip_level_count: desc.mip_level_count,
        sample_count: desc.sample_count,
        dimension: texture_dimension_from_u32(desc.dimension),
        format: texture_format_from_u32(desc.format),
        usage: wgpu::TextureUsages::from_bits_truncate(desc.usage),
        view_formats: &view_formats,
    });
    into_handle(texture)
}

pub fn texture_create_view(
    texture_handle: WGPUTexture,
    desc: Option<&WGPUTextureViewDescriptor>,
) -> WGPUTextureView {
    if texture_handle == 0 {
        return 0;
    }
    let tex = unsafe { deref_handle::<wgpu::Texture>(texture_handle) };

    let view = match desc {
        Some(d) => tex.create_view(&wgpu::TextureViewDescriptor {
            label: unsafe { label_from_ptr(d.label) },
            format: Some(texture_format_from_u32(d.format)),
            dimension: Some(texture_view_dimension_from_u32(d.dimension)),
            usage: if d.usage == 0 {
                None
            } else {
                Some(wgpu::TextureUsages::from_bits_truncate(d.usage))
            },
            aspect: texture_aspect_from_u32(d.aspect),
            base_mip_level: d.base_mip_level,
            mip_level_count: if d.mip_level_count == 0 {
                None
            } else {
                Some(d.mip_level_count)
            },
            base_array_layer: d.base_array_layer,
            array_layer_count: if d.array_layer_count == 0 {
                None
            } else {
                Some(d.array_layer_count)
            },
        }),
        None => tex.create_view(&wgpu::TextureViewDescriptor::default()),
    };
    into_handle(view)
}

pub fn texture_release(texture: WGPUTexture) {
    if texture == 0 {
        return;
    }
    unsafe {
        drop_handle::<wgpu::Texture>(texture);
    }
}

pub fn texture_view_release(view: WGPUTextureView) {
    if view == 0 {
        return;
    }
    unsafe {
        drop_handle::<wgpu::TextureView>(view);
    }
}

// =============================================================================
// SAMPLER
// =============================================================================

pub fn device_create_sampler(device: &wgpu::Device, desc: &WGPUSamplerDescriptor) -> WGPUSampler {
    let compare = if desc.compare == 0 {
        None
    } else {
        Some(compare_function_from_u32(desc.compare - 1))
    };

    let sampler = device.create_sampler(&wgpu::SamplerDescriptor {
        label: unsafe { label_from_ptr(desc.label) },
        address_mode_u: address_mode_from_u32(desc.address_mode_u),
        address_mode_v: address_mode_from_u32(desc.address_mode_v),
        address_mode_w: address_mode_from_u32(desc.address_mode_w),
        mag_filter: filter_mode_from_u32(desc.mag_filter),
        min_filter: filter_mode_from_u32(desc.min_filter),
        mipmap_filter: mipmap_filter_mode_from_u32(desc.mipmap_filter),
        lod_min_clamp: desc.lod_min_clamp,
        lod_max_clamp: desc.lod_max_clamp,
        compare,
        anisotropy_clamp: desc.max_anisotropy,
        border_color: None,
    });
    into_handle(sampler)
}

pub fn sampler_release(sampler: WGPUSampler) {
    if sampler == 0 {
        return;
    }
    unsafe {
        drop_handle::<wgpu::Sampler>(sampler);
    }
}

// =============================================================================
// SHADER MODULE
// =============================================================================

pub fn device_create_shader_module(
    device: &wgpu::Device,
    source: &str,
    label: Option<&str>,
) -> WGPUShaderModule {
    let module = device.create_shader_module(wgpu::ShaderModuleDescriptor {
        label,
        source: wgpu::ShaderSource::Wgsl(source.into()),
    });
    into_handle(module)
}

pub fn shader_module_get_compilation_info(module_handle: WGPUShaderModule) -> Option<String> {
    if module_handle == 0 {
        return None;
    }
    let module = unsafe { deref_handle::<wgpu::ShaderModule>(module_handle) };
    let info = pollster::block_on(module.get_compilation_info());

    if info.messages.is_empty() {
        return None;
    }

    let mut result = String::new();
    for msg in &info.messages {
        let type_char = match msg.message_type {
            wgpu::CompilationMessageType::Error => 'E',
            wgpu::CompilationMessageType::Warning => 'W',
            wgpu::CompilationMessageType::Info => 'I',
        };
        let line_num = msg.location.as_ref().map_or(0, |l| l.line_number);
        let line_pos = msg.location.as_ref().map_or(0, |l| l.line_position);
        if !result.is_empty() {
            result.push('\n');
        }
        result.push(type_char);
        result.push('\t');
        result.push_str(&line_num.to_string());
        result.push('\t');
        result.push_str(&line_pos.to_string());
        result.push('\t');
        result.push_str(&msg.message);
    }

    Some(result)
}

pub fn shader_module_release(module: WGPUShaderModule) {
    if module == 0 {
        return;
    }
    unsafe {
        drop_handle::<wgpu::ShaderModule>(module);
    }
}

// =============================================================================
// BIND GROUP LAYOUT
// =============================================================================

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

// =============================================================================
// BIND GROUP
// =============================================================================

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

// =============================================================================
// PIPELINE LAYOUT
// =============================================================================

pub fn device_create_pipeline_layout(
    device: &wgpu::Device,
    desc: &WGPUPipelineLayoutDescriptor,
) -> WGPUPipelineLayout {
    let layouts: Vec<Option<&wgpu::BindGroupLayout>> =
        if desc.bind_group_layout_count > 0 && !desc.bind_group_layouts.is_null() {
            let raw_layouts = unsafe {
                std::slice::from_raw_parts(
                    desc.bind_group_layouts,
                    desc.bind_group_layout_count as usize,
                )
            };
            raw_layouts
                .iter()
                .map(|&id| {
                    if id == 0 {
                        None
                    } else {
                        Some(unsafe { deref_handle::<wgpu::BindGroupLayout>(id) })
                    }
                })
                .collect()
        } else {
            vec![]
        };

    let pipeline_layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
        label: unsafe { label_from_ptr(desc.label) },
        bind_group_layouts: &layouts,
        immediate_size: desc.immediate_size,
    });
    into_handle(pipeline_layout)
}

pub fn pipeline_layout_release(layout: WGPUPipelineLayout) {
    if layout == 0 {
        return;
    }
    unsafe {
        drop_handle::<wgpu::PipelineLayout>(layout);
    }
}

// =============================================================================
// RENDER PIPELINE
// =============================================================================

pub fn device_create_render_pipeline(
    device: &wgpu::Device,
    desc: &WGPURenderPipelineDescriptor,
) -> WGPURenderPipeline {
    if desc.vertex.module == 0 {
        return 0;
    }
    let vertex_module = unsafe { deref_handle::<wgpu::ShaderModule>(desc.vertex.module) };

    let mut all_attributes: Vec<Vec<wgpu::VertexAttribute>> = vec![];
    if desc.vertex.buffer_count > 0 && !desc.vertex.buffers.is_null() {
        let raw_buffers = unsafe {
            std::slice::from_raw_parts(desc.vertex.buffers, desc.vertex.buffer_count as usize)
        };
        for b in raw_buffers {
            let attributes: Vec<wgpu::VertexAttribute> = if b.attribute_count > 0
                && !b.attributes.is_null()
            {
                let raw_attrs =
                    unsafe { std::slice::from_raw_parts(b.attributes, b.attribute_count as usize) };
                raw_attrs
                    .iter()
                    .map(|a| wgpu::VertexAttribute {
                        format: vertex_format_from_u32(a.format),
                        offset: a.offset,
                        shader_location: a.shader_location,
                    })
                    .collect()
            } else {
                vec![]
            };
            all_attributes.push(attributes);
        }
    }

    let vertex_buffer_layouts: Vec<wgpu::VertexBufferLayout> =
        if desc.vertex.buffer_count > 0 && !desc.vertex.buffers.is_null() {
            let raw_buffers = unsafe {
                std::slice::from_raw_parts(desc.vertex.buffers, desc.vertex.buffer_count as usize)
            };
            raw_buffers
                .iter()
                .enumerate()
                .map(|(i, b)| wgpu::VertexBufferLayout {
                    array_stride: b.array_stride,
                    step_mode: vertex_step_mode_from_u32(b.step_mode),
                    attributes: &all_attributes[i],
                })
                .collect()
        } else {
            vec![]
        };

    let vertex_entry_point = if !desc.vertex.entry_point.is_null() {
        unsafe {
            std::ffi::CStr::from_ptr(desc.vertex.entry_point)
                .to_str()
                .unwrap_or("main")
        }
    } else {
        "main"
    };

    let fragment_module = if desc.fragment.module != 0 {
        Some(unsafe { deref_handle::<wgpu::ShaderModule>(desc.fragment.module) })
    } else {
        None
    };

    let mut color_targets: Vec<Option<wgpu::ColorTargetState>> = vec![];
    if desc.fragment.target_count > 0 && !desc.fragment.targets.is_null() {
        let raw_targets = unsafe {
            std::slice::from_raw_parts(desc.fragment.targets, desc.fragment.target_count as usize)
        };
        for t in raw_targets {
            let blend = if t.blend_enabled != 0 {
                Some(wgpu::BlendState {
                    color: wgpu::BlendComponent {
                        src_factor: blend_factor_from_u32(t.blend_color.src_factor),
                        dst_factor: blend_factor_from_u32(t.blend_color.dst_factor),
                        operation: blend_operation_from_u32(t.blend_color.operation),
                    },
                    alpha: wgpu::BlendComponent {
                        src_factor: blend_factor_from_u32(t.blend_alpha.src_factor),
                        dst_factor: blend_factor_from_u32(t.blend_alpha.dst_factor),
                        operation: blend_operation_from_u32(t.blend_alpha.operation),
                    },
                })
            } else {
                None
            };
            color_targets.push(Some(wgpu::ColorTargetState {
                format: texture_format_from_u32(t.format),
                blend,
                write_mask: color_writes_from_u32(t.write_mask),
            }));
        }
    }

    let fragment_entry_point = if !desc.fragment.entry_point.is_null() {
        unsafe {
            std::ffi::CStr::from_ptr(desc.fragment.entry_point)
                .to_str()
                .unwrap_or("main")
        }
    } else {
        "main"
    };

    let depth_stencil = if desc.depth_stencil_enabled != 0 {
        Some(wgpu::DepthStencilState {
            format: texture_format_from_u32(desc.depth_stencil.format),
            depth_write_enabled: Some(desc.depth_stencil.depth_write_enabled != 0),
            depth_compare: Some(compare_function_from_u32(
                desc.depth_stencil.depth_compare - 1,
            )),
            stencil: wgpu::StencilState {
                front: wgpu::StencilFaceState {
                    compare: if desc.depth_stencil.stencil_front_compare == 0 {
                        wgpu::CompareFunction::Always
                    } else {
                        compare_function_from_u32(desc.depth_stencil.stencil_front_compare - 1)
                    },
                    fail_op: stencil_operation_from_u32(desc.depth_stencil.stencil_front_fail_op),
                    depth_fail_op: stencil_operation_from_u32(
                        desc.depth_stencil.stencil_front_depth_fail_op,
                    ),
                    pass_op: stencil_operation_from_u32(desc.depth_stencil.stencil_front_pass_op),
                },
                back: wgpu::StencilFaceState {
                    compare: if desc.depth_stencil.stencil_back_compare == 0 {
                        wgpu::CompareFunction::Always
                    } else {
                        compare_function_from_u32(desc.depth_stencil.stencil_back_compare - 1)
                    },
                    fail_op: stencil_operation_from_u32(desc.depth_stencil.stencil_back_fail_op),
                    depth_fail_op: stencil_operation_from_u32(
                        desc.depth_stencil.stencil_back_depth_fail_op,
                    ),
                    pass_op: stencil_operation_from_u32(desc.depth_stencil.stencil_back_pass_op),
                },
                read_mask: if desc.depth_stencil.stencil_read_mask == 0 {
                    0xFFFFFFFF
                } else {
                    desc.depth_stencil.stencil_read_mask
                },
                write_mask: if desc.depth_stencil.stencil_write_mask == 0 {
                    0xFFFFFFFF
                } else {
                    desc.depth_stencil.stencil_write_mask
                },
            },
            bias: wgpu::DepthBiasState {
                constant: desc.depth_stencil.depth_bias,
                slope_scale: desc.depth_stencil.depth_bias_slope_scale,
                clamp: desc.depth_stencil.depth_bias_clamp,
            },
        })
    } else {
        None
    };

    let layout = if desc.layout != 0 {
        Some(unsafe { deref_handle::<wgpu::PipelineLayout>(desc.layout) })
    } else {
        None
    };

    let owned_vertex_constants = parse_constants(
        desc.vertex.constant_count,
        desc.vertex.constant_keys,
        desc.vertex.constant_values,
    );
    let vertex_constants_refs: Vec<(&str, f64)> = owned_vertex_constants
        .iter()
        .map(|(k, v)| (k.as_str(), *v))
        .collect();
    let vertex_compilation = wgpu::PipelineCompilationOptions {
        constants: &vertex_constants_refs,
        zero_initialize_workgroup_memory: true,
    };

    let owned_fragment_constants = parse_constants(
        desc.fragment.constant_count,
        desc.fragment.constant_keys,
        desc.fragment.constant_values,
    );
    let fragment_constants_refs: Vec<(&str, f64)> = owned_fragment_constants
        .iter()
        .map(|(k, v)| (k.as_str(), *v))
        .collect();
    let fragment_compilation = wgpu::PipelineCompilationOptions {
        constants: &fragment_constants_refs,
        zero_initialize_workgroup_memory: true,
    };

    let fragment_state = fragment_module.map(|module| wgpu::FragmentState {
        module,
        entry_point: Some(fragment_entry_point),
        targets: &color_targets,
        compilation_options: fragment_compilation,
    });

    let pipeline = device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
        label: unsafe { label_from_ptr(desc.label) },
        layout,
        vertex: wgpu::VertexState {
            module: vertex_module,
            entry_point: Some(vertex_entry_point),
            buffers: &vertex_buffer_layouts,
            compilation_options: vertex_compilation,
        },
        primitive: wgpu::PrimitiveState {
            topology: primitive_topology_from_u32(desc.primitive_topology),
            strip_index_format: index_format_from_u32(desc.strip_index_format),
            front_face: front_face_from_u32(desc.front_face),
            cull_mode: cull_mode_from_u32(desc.cull_mode),
            unclipped_depth: desc.unclipped_depth != 0,
            polygon_mode: wgpu::PolygonMode::Fill,
            conservative: false,
        },
        depth_stencil,
        multisample: wgpu::MultisampleState {
            count: desc.multisample_count.max(1),
            mask: if desc.multisample_mask == 0 {
                !0
            } else {
                desc.multisample_mask as u64
            },
            alpha_to_coverage_enabled: desc.alpha_to_coverage_enabled != 0,
        },
        fragment: fragment_state,
        multiview_mask: None,
        cache: None,
    });
    into_handle(pipeline)
}

pub fn render_pipeline_get_bind_group_layout(
    pipeline_handle: WGPURenderPipeline,
    index: u32,
) -> WGPUBindGroupLayout {
    if pipeline_handle == 0 {
        return 0;
    }
    let pipeline = unsafe { deref_handle::<wgpu::RenderPipeline>(pipeline_handle) };
    let layout = pipeline.get_bind_group_layout(index);
    into_handle(layout)
}

pub fn render_pipeline_release(pipeline: WGPURenderPipeline) {
    if pipeline == 0 {
        return;
    }
    unsafe {
        drop_handle::<wgpu::RenderPipeline>(pipeline);
    }
}

// =============================================================================
// COMPUTE PIPELINE
// =============================================================================

fn parse_constants(
    count: u32,
    keys: *const *const std::ffi::c_char,
    values: *const f64,
) -> Vec<(String, f64)> {
    let mut constants = Vec::new();
    if count > 0 && !keys.is_null() && !values.is_null() {
        let key_ptrs = unsafe { std::slice::from_raw_parts(keys, count as usize) };
        let vals = unsafe { std::slice::from_raw_parts(values, count as usize) };
        for i in 0..count as usize {
            if !key_ptrs[i].is_null() {
                if let Ok(key) = unsafe { std::ffi::CStr::from_ptr(key_ptrs[i]).to_str() } {
                    constants.push((key.to_string(), vals[i]));
                }
            }
        }
    }
    constants
}

pub fn device_create_compute_pipeline(
    device: &wgpu::Device,
    desc: &WGPUComputePipelineDescriptor,
) -> WGPUComputePipeline {
    if desc.module == 0 {
        return 0;
    }
    let module = unsafe { deref_handle::<wgpu::ShaderModule>(desc.module) };

    let entry_point = if !desc.entry_point.is_null() {
        unsafe {
            std::ffi::CStr::from_ptr(desc.entry_point)
                .to_str()
                .unwrap_or("main")
        }
    } else {
        "main"
    };

    let layout = if desc.layout != 0 {
        Some(unsafe { deref_handle::<wgpu::PipelineLayout>(desc.layout) })
    } else {
        None
    };

    let owned_constants = parse_constants(
        desc.constant_count,
        desc.constant_keys,
        desc.constant_values,
    );
    let constants_refs: Vec<(&str, f64)> = owned_constants
        .iter()
        .map(|(k, v)| (k.as_str(), *v))
        .collect();
    let compilation_options = wgpu::PipelineCompilationOptions {
        constants: &constants_refs,
        zero_initialize_workgroup_memory: true,
    };

    let pipeline = device.create_compute_pipeline(&wgpu::ComputePipelineDescriptor {
        label: unsafe { label_from_ptr(desc.label) },
        layout,
        module,
        entry_point: Some(entry_point),
        compilation_options,
        cache: None,
    });
    into_handle(pipeline)
}

pub fn compute_pipeline_get_bind_group_layout(
    pipeline_handle: WGPUComputePipeline,
    index: u32,
) -> WGPUBindGroupLayout {
    if pipeline_handle == 0 {
        return 0;
    }
    let pipeline = unsafe { deref_handle::<wgpu::ComputePipeline>(pipeline_handle) };
    let layout = pipeline.get_bind_group_layout(index);
    into_handle(layout)
}

pub fn compute_pipeline_release(pipeline: WGPUComputePipeline) {
    if pipeline == 0 {
        return;
    }
    unsafe {
        drop_handle::<wgpu::ComputePipeline>(pipeline);
    }
}
