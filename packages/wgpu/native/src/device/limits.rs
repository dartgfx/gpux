use crate::abi::types::WGPUDeviceLimits;

const FEATURE_MAP: &[(u32, wgpu::Features)] = &[
    // 0: coreFeaturesAndLimits — always supported, no wgpu flag
    (1, wgpu::Features::DEPTH_CLIP_CONTROL),
    (2, wgpu::Features::DEPTH32FLOAT_STENCIL8),
    (3, wgpu::Features::TEXTURE_COMPRESSION_BC),
    // 4: textureCompressionBcSliced3d — no wgpu equivalent
    (5, wgpu::Features::TEXTURE_COMPRESSION_ETC2),
    (6, wgpu::Features::TEXTURE_COMPRESSION_ASTC),
    // 7: textureCompressionAstcSliced3d — no wgpu equivalent
    (8, wgpu::Features::TIMESTAMP_QUERY),
    (9, wgpu::Features::INDIRECT_FIRST_INSTANCE),
    (10, wgpu::Features::SHADER_F16),
    (11, wgpu::Features::RG11B10UFLOAT_RENDERABLE),
    (12, wgpu::Features::BGRA8UNORM_STORAGE),
    (13, wgpu::Features::FLOAT32_FILTERABLE),
    // 14: float32Blendable — no wgpu equivalent
    // 15: clipDistances — no wgpu equivalent
    (16, wgpu::Features::DUAL_SOURCE_BLENDING),
    (17, wgpu::Features::SUBGROUP),
    // 18-21: textureFormatsTier1/2, primitiveIndex, textureComponentSwizzle — no wgpu equivalent
];

/// Convert a GpuFeatureName bitmask to wgpu Features flags.
pub(crate) fn features_from_bitmask(bits: u32) -> wgpu::Features {
    let mut features = wgpu::Features::empty();
    for &(bit, flag) in FEATURE_MAP {
        if bits & (1 << bit) != 0 {
            features |= flag;
        }
    }
    // timestampQuery also implies TIMESTAMP_QUERY_INSIDE_ENCODERS
    if bits & (1 << 8) != 0 {
        features |= wgpu::Features::TIMESTAMP_QUERY_INSIDE_ENCODERS;
    }
    features
}

/// Convert a WGPUDeviceLimits FFI struct to wgpu Limits.
pub(crate) fn limits_from_ffi(l: &WGPUDeviceLimits) -> wgpu::Limits {
    wgpu::Limits {
        max_texture_dimension_1d: l.max_texture_dimension_1d,
        max_texture_dimension_2d: l.max_texture_dimension_2d,
        max_texture_dimension_3d: l.max_texture_dimension_3d,
        max_texture_array_layers: l.max_texture_array_layers,
        max_bind_groups: l.max_bind_groups,
        max_bindings_per_bind_group: l.max_bindings_per_bind_group,
        max_dynamic_uniform_buffers_per_pipeline_layout: l
            .max_dynamic_uniform_buffers_per_pipeline_layout,
        max_dynamic_storage_buffers_per_pipeline_layout: l
            .max_dynamic_storage_buffers_per_pipeline_layout,
        max_sampled_textures_per_shader_stage: l.max_sampled_textures_per_shader_stage,
        max_samplers_per_shader_stage: l.max_samplers_per_shader_stage,
        max_storage_buffers_per_shader_stage: l.max_storage_buffers_per_shader_stage,
        max_storage_textures_per_shader_stage: l.max_storage_textures_per_shader_stage,
        max_uniform_buffers_per_shader_stage: l.max_uniform_buffers_per_shader_stage,
        max_uniform_buffer_binding_size: l.max_uniform_buffer_binding_size,
        max_storage_buffer_binding_size: l.max_storage_buffer_binding_size,
        min_uniform_buffer_offset_alignment: l.min_uniform_buffer_offset_alignment,
        min_storage_buffer_offset_alignment: l.min_storage_buffer_offset_alignment,
        max_vertex_buffers: l.max_vertex_buffers,
        max_buffer_size: l.max_buffer_size,
        max_vertex_attributes: l.max_vertex_attributes,
        max_vertex_buffer_array_stride: l.max_vertex_buffer_array_stride,
        max_inter_stage_shader_variables: l.max_inter_stage_shader_variables,
        max_color_attachments: l.max_color_attachments,
        max_color_attachment_bytes_per_sample: l.max_color_attachment_bytes_per_sample,
        max_compute_workgroup_storage_size: l.max_compute_workgroup_storage_size,
        max_compute_invocations_per_workgroup: l.max_compute_invocations_per_workgroup,
        max_compute_workgroup_size_x: l.max_compute_workgroup_size_x,
        max_compute_workgroup_size_y: l.max_compute_workgroup_size_y,
        max_compute_workgroup_size_z: l.max_compute_workgroup_size_z,
        max_compute_workgroups_per_dimension: l.max_compute_workgroups_per_dimension,
        max_immediate_size: l.max_immediate_size,
        ..wgpu::Limits::default()
    }
}

/// Convert wgpu Features flags to a GpuFeatureName bitmask.
pub(crate) fn features_to_bitmask(features: wgpu::Features) -> u32 {
    let mut bits: u32 = 1; // bit 0 = coreFeaturesAndLimits, always set
    for &(bit, flag) in FEATURE_MAP {
        if features.contains(flag) {
            bits |= 1 << bit;
        }
    }
    bits
}

/// Build a zeroed WGPUDeviceLimits (all fields 0).
pub(crate) fn zero_limits() -> WGPUDeviceLimits {
    WGPUDeviceLimits {
        max_texture_dimension_1d: 0,
        max_texture_dimension_2d: 0,
        max_texture_dimension_3d: 0,
        max_texture_array_layers: 0,
        max_bind_groups: 0,
        max_bind_groups_plus_vertex_buffers: 0,
        max_bindings_per_bind_group: 0,
        max_dynamic_uniform_buffers_per_pipeline_layout: 0,
        max_dynamic_storage_buffers_per_pipeline_layout: 0,
        max_sampled_textures_per_shader_stage: 0,
        max_samplers_per_shader_stage: 0,
        max_storage_buffers_per_shader_stage: 0,
        max_storage_textures_per_shader_stage: 0,
        max_uniform_buffers_per_shader_stage: 0,
        max_uniform_buffer_binding_size: 0,
        max_storage_buffer_binding_size: 0,
        min_uniform_buffer_offset_alignment: 0,
        min_storage_buffer_offset_alignment: 0,
        max_vertex_buffers: 0,
        max_buffer_size: 0,
        max_vertex_attributes: 0,
        max_vertex_buffer_array_stride: 0,
        max_inter_stage_shader_variables: 0,
        max_color_attachments: 0,
        max_color_attachment_bytes_per_sample: 0,
        max_compute_workgroup_storage_size: 0,
        max_compute_invocations_per_workgroup: 0,
        max_compute_workgroup_size_x: 0,
        max_compute_workgroup_size_y: 0,
        max_compute_workgroup_size_z: 0,
        max_compute_workgroups_per_dimension: 0,
        max_immediate_size: 0,
    }
}

/// Convert wgpu::Limits into WGPUDeviceLimits FFI struct.
pub(crate) fn limits_to_ffi(l: &wgpu::Limits) -> WGPUDeviceLimits {
    WGPUDeviceLimits {
        max_texture_dimension_1d: l.max_texture_dimension_1d,
        max_texture_dimension_2d: l.max_texture_dimension_2d,
        max_texture_dimension_3d: l.max_texture_dimension_3d,
        max_texture_array_layers: l.max_texture_array_layers,
        max_bind_groups: l.max_bind_groups,
        max_bind_groups_plus_vertex_buffers: l.max_bind_groups + l.max_vertex_buffers,
        max_bindings_per_bind_group: l.max_bindings_per_bind_group,
        max_dynamic_uniform_buffers_per_pipeline_layout: l
            .max_dynamic_uniform_buffers_per_pipeline_layout,
        max_dynamic_storage_buffers_per_pipeline_layout: l
            .max_dynamic_storage_buffers_per_pipeline_layout,
        max_sampled_textures_per_shader_stage: l.max_sampled_textures_per_shader_stage,
        max_samplers_per_shader_stage: l.max_samplers_per_shader_stage,
        max_storage_buffers_per_shader_stage: l.max_storage_buffers_per_shader_stage,
        max_storage_textures_per_shader_stage: l.max_storage_textures_per_shader_stage,
        max_uniform_buffers_per_shader_stage: l.max_uniform_buffers_per_shader_stage,
        max_uniform_buffer_binding_size: l.max_uniform_buffer_binding_size,
        max_storage_buffer_binding_size: l.max_storage_buffer_binding_size,
        min_uniform_buffer_offset_alignment: l.min_uniform_buffer_offset_alignment,
        min_storage_buffer_offset_alignment: l.min_storage_buffer_offset_alignment,
        max_vertex_buffers: l.max_vertex_buffers,
        max_buffer_size: l.max_buffer_size as u64,
        max_vertex_attributes: l.max_vertex_attributes,
        max_vertex_buffer_array_stride: l.max_vertex_buffer_array_stride,
        max_inter_stage_shader_variables: l.max_inter_stage_shader_variables,
        max_color_attachments: l.max_color_attachments,
        max_color_attachment_bytes_per_sample: l.max_color_attachment_bytes_per_sample,
        max_compute_workgroup_storage_size: l.max_compute_workgroup_storage_size,
        max_compute_invocations_per_workgroup: l.max_compute_invocations_per_workgroup,
        max_compute_workgroup_size_x: l.max_compute_workgroup_size_x,
        max_compute_workgroup_size_y: l.max_compute_workgroup_size_y,
        max_compute_workgroup_size_z: l.max_compute_workgroup_size_z,
        max_compute_workgroups_per_dimension: l.max_compute_workgroups_per_dimension,
        max_immediate_size: l.max_immediate_size,
    }
}
