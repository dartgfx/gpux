use crate::constants::{TARGET_GLSL, TARGET_HLSL, TARGET_MSL, TARGET_SPIRV, TARGET_WGSL};

pub(crate) enum TranslationOutput {
    Text(String),
    Spirv(Vec<u32>),
}

pub(crate) fn target_capabilities(target_format: i32) -> naga::valid::Capabilities {
    match target_format {
        TARGET_WGSL => naga::back::wgsl::supported_capabilities(),
        TARGET_SPIRV => naga::back::spv::supported_capabilities(),
        TARGET_MSL => naga::back::msl::supported_capabilities(),
        TARGET_HLSL => naga::back::hlsl::supported_capabilities(),
        TARGET_GLSL => naga::back::glsl::supported_capabilities(),
        _ => naga::valid::Capabilities::all(),
    }
}

pub(crate) fn write_target(
    module: &naga::Module,
    info: &naga::valid::ModuleInfo,
    target_format: i32,
    option_flags: u32,
    option_value: i32,
    entry: Option<(naga::ShaderStage, String)>,
) -> Result<TranslationOutput, String> {
    match target_format {
        TARGET_WGSL => write_wgsl(module, info, option_flags),
        TARGET_SPIRV => write_spirv(module, info, option_flags, entry),
        TARGET_MSL => write_msl(module, info, option_flags, entry),
        TARGET_HLSL => write_hlsl(module, info, option_flags, option_value, entry),
        TARGET_GLSL => write_glsl(module, info, option_flags, entry),
        _ => Err("unknown target format".to_string()),
    }
}

fn write_wgsl(
    module: &naga::Module,
    info: &naga::valid::ModuleInfo,
    option_flags: u32,
) -> Result<TranslationOutput, String> {
    let mut flags = naga::back::wgsl::WriterFlags::empty();
    if has_flag(option_flags, 0) {
        flags |= naga::back::wgsl::WriterFlags::EXPLICIT_TYPES;
    }

    naga::back::wgsl::write_string(module, info, flags)
        .map(TranslationOutput::Text)
        .map_err(|error| format!("{}", error))
}

fn write_spirv(
    module: &naga::Module,
    info: &naga::valid::ModuleInfo,
    option_flags: u32,
    entry: Option<(naga::ShaderStage, String)>,
) -> Result<TranslationOutput, String> {
    let mut options = naga::back::spv::Options::default();
    options.flags = naga::back::spv::WriterFlags::empty();
    if has_flag(option_flags, 0) {
        options.flags |= naga::back::spv::WriterFlags::DEBUG;
    }
    if has_flag(option_flags, 1) {
        options.flags |= naga::back::spv::WriterFlags::ADJUST_COORDINATE_SPACE;
    }
    if has_flag(option_flags, 2) {
        options.flags |= naga::back::spv::WriterFlags::LABEL_VARYINGS;
    }
    if has_flag(option_flags, 3) {
        options.flags |= naga::back::spv::WriterFlags::FORCE_POINT_SIZE;
    }
    if has_flag(option_flags, 4) {
        options.flags |= naga::back::spv::WriterFlags::CLAMP_FRAG_DEPTH;
    }
    let pipeline_options =
        entry.map(
            |(shader_stage, entry_point)| naga::back::spv::PipelineOptions {
                shader_stage,
                entry_point,
            },
        );

    naga::back::spv::write_vec(module, info, &options, pipeline_options.as_ref())
        .map(TranslationOutput::Spirv)
        .map_err(|error| format!("{}", error))
}

fn write_msl(
    module: &naga::Module,
    info: &naga::valid::ModuleInfo,
    option_flags: u32,
    entry: Option<(naga::ShaderStage, String)>,
) -> Result<TranslationOutput, String> {
    let mut options = naga::back::msl::Options::default();
    options.spirv_cross_compatibility = has_flag(option_flags, 0);
    options.fake_missing_bindings = has_flag(option_flags, 1);
    options.zero_initialize_workgroup_memory = has_flag(option_flags, 2);
    options.force_loop_bounding = has_flag(option_flags, 3);
    let mut pipeline_options = naga::back::msl::PipelineOptions::default();
    pipeline_options.entry_point = entry;

    naga::back::msl::write_string(module, info, &options, &pipeline_options)
        .map(|(source, _)| TranslationOutput::Text(source))
        .map_err(|error| format!("{}", error))
}

fn write_hlsl(
    module: &naga::Module,
    info: &naga::valid::ModuleInfo,
    option_flags: u32,
    option_value: i32,
    entry: Option<(naga::ShaderStage, String)>,
) -> Result<TranslationOutput, String> {
    let mut options = naga::back::hlsl::Options::default();
    options.shader_model = hlsl_shader_model(option_value);
    options.fake_missing_bindings = has_flag(option_flags, 0);
    options.zero_initialize_workgroup_memory = has_flag(option_flags, 1);
    options.restrict_indexing = has_flag(option_flags, 2);
    options.force_loop_bounding = has_flag(option_flags, 3);
    options.ray_query_initialization_tracking = has_flag(option_flags, 4);
    let mut pipeline_options = naga::back::hlsl::PipelineOptions::default();
    pipeline_options.entry_point = entry;
    let mut source = String::new();
    let mut writer = naga::back::hlsl::Writer::new(&mut source, &options, &pipeline_options);

    writer
        .write(module, info, None)
        .map(|_| TranslationOutput::Text(source))
        .map_err(|error| format!("{}", error))
}

fn write_glsl(
    module: &naga::Module,
    info: &naga::valid::ModuleInfo,
    option_flags: u32,
    entry: Option<(naga::ShaderStage, String)>,
) -> Result<TranslationOutput, String> {
    let Some((shader_stage, entry_point)) = entry else {
        return Err("GLSL translation requires an entry point".to_string());
    };

    let mut options = naga::back::glsl::Options::default();
    options.writer_flags = naga::back::glsl::WriterFlags::empty();
    if has_flag(option_flags, 0) {
        options.writer_flags |= naga::back::glsl::WriterFlags::ADJUST_COORDINATE_SPACE;
    }
    if has_flag(option_flags, 1) {
        options.writer_flags |= naga::back::glsl::WriterFlags::TEXTURE_SHADOW_LOD;
    }
    if has_flag(option_flags, 2) {
        options.writer_flags |= naga::back::glsl::WriterFlags::DRAW_PARAMETERS;
    }
    if has_flag(option_flags, 3) {
        options.writer_flags |= naga::back::glsl::WriterFlags::INCLUDE_UNUSED_ITEMS;
    }
    if has_flag(option_flags, 4) {
        options.writer_flags |= naga::back::glsl::WriterFlags::FORCE_POINT_SIZE;
    }
    options.zero_initialize_workgroup_memory = has_flag(option_flags, 5);
    let pipeline_options = naga::back::glsl::PipelineOptions {
        shader_stage,
        entry_point,
        multiview: None,
    };
    let mut source = String::new();
    let mut writer = naga::back::glsl::Writer::new(
        &mut source,
        module,
        info,
        &options,
        &pipeline_options,
        naga::proc::BoundsCheckPolicies::default(),
    )
    .map_err(|error| format!("{}", error))?;

    writer
        .write()
        .map(|_| TranslationOutput::Text(source))
        .map_err(|error| format!("{}", error))
}

fn has_flag(flags: u32, bit: u32) -> bool {
    (flags & (1 << bit)) != 0
}

fn hlsl_shader_model(value: i32) -> naga::back::hlsl::ShaderModel {
    match value {
        0 => naga::back::hlsl::ShaderModel::V5_0,
        1 => naga::back::hlsl::ShaderModel::V5_1,
        2 => naga::back::hlsl::ShaderModel::V6_0,
        3 => naga::back::hlsl::ShaderModel::V6_1,
        4 => naga::back::hlsl::ShaderModel::V6_2,
        5 => naga::back::hlsl::ShaderModel::V6_3,
        6 => naga::back::hlsl::ShaderModel::V6_4,
        7 => naga::back::hlsl::ShaderModel::V6_5,
        8 => naga::back::hlsl::ShaderModel::V6_6,
        9 => naga::back::hlsl::ShaderModel::V6_7,
        10 => naga::back::hlsl::ShaderModel::V6_8,
        11 => naga::back::hlsl::ShaderModel::V6_9,
        _ => naga::back::hlsl::ShaderModel::V5_1,
    }
}
