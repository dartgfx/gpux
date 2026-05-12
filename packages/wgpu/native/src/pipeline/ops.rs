use crate::abi::enums::*;
use crate::abi::types::*;
use crate::runtime::handle::*;
use crate::runtime::label::label_from_ptr;

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
