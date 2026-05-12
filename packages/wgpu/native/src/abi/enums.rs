pub(crate) fn texture_format_from_u32(format: u32) -> wgpu::TextureFormat {
    match format {
        // 8-bit formats
        0 => wgpu::TextureFormat::R8Unorm,
        1 => wgpu::TextureFormat::R8Snorm,
        2 => wgpu::TextureFormat::R8Uint,
        3 => wgpu::TextureFormat::R8Sint,
        // 16-bit formats
        4 => wgpu::TextureFormat::R16Uint,
        5 => wgpu::TextureFormat::R16Sint,
        6 => wgpu::TextureFormat::R16Float,
        95 => wgpu::TextureFormat::R16Unorm,
        96 => wgpu::TextureFormat::R16Snorm,
        7 => wgpu::TextureFormat::Rg8Unorm,
        8 => wgpu::TextureFormat::Rg8Snorm,
        9 => wgpu::TextureFormat::Rg8Uint,
        10 => wgpu::TextureFormat::Rg8Sint,
        // 32-bit formats
        11 => wgpu::TextureFormat::R32Uint,
        12 => wgpu::TextureFormat::R32Sint,
        13 => wgpu::TextureFormat::R32Float,
        14 => wgpu::TextureFormat::Rg16Uint,
        15 => wgpu::TextureFormat::Rg16Sint,
        16 => wgpu::TextureFormat::Rg16Float,
        97 => wgpu::TextureFormat::Rg16Unorm,
        98 => wgpu::TextureFormat::Rg16Snorm,
        17 => wgpu::TextureFormat::Rgba8Unorm,
        18 => wgpu::TextureFormat::Rgba8UnormSrgb,
        19 => wgpu::TextureFormat::Rgba8Snorm,
        20 => wgpu::TextureFormat::Rgba8Uint,
        21 => wgpu::TextureFormat::Rgba8Sint,
        22 => wgpu::TextureFormat::Bgra8Unorm,
        23 => wgpu::TextureFormat::Bgra8UnormSrgb,
        // Packed 32-bit formats
        24 => wgpu::TextureFormat::Rgb9e5Ufloat,
        25 => wgpu::TextureFormat::Rgb10a2Uint,
        26 => wgpu::TextureFormat::Rgb10a2Unorm,
        27 => wgpu::TextureFormat::Rg11b10Ufloat,
        // 64-bit formats
        28 => wgpu::TextureFormat::Rg32Uint,
        29 => wgpu::TextureFormat::Rg32Sint,
        30 => wgpu::TextureFormat::Rg32Float,
        31 => wgpu::TextureFormat::Rgba16Uint,
        32 => wgpu::TextureFormat::Rgba16Sint,
        33 => wgpu::TextureFormat::Rgba16Float,
        99 => wgpu::TextureFormat::Rgba16Unorm,
        100 => wgpu::TextureFormat::Rgba16Snorm,
        // 128-bit formats
        34 => wgpu::TextureFormat::Rgba32Uint,
        35 => wgpu::TextureFormat::Rgba32Sint,
        36 => wgpu::TextureFormat::Rgba32Float,
        // Depth/stencil formats
        37 => wgpu::TextureFormat::Stencil8,
        38 => wgpu::TextureFormat::Depth16Unorm,
        39 => wgpu::TextureFormat::Depth24Plus,
        40 => wgpu::TextureFormat::Depth24PlusStencil8,
        41 => wgpu::TextureFormat::Depth32Float,
        42 => wgpu::TextureFormat::Depth32FloatStencil8,
        // BC compressed formats
        43 => wgpu::TextureFormat::Bc1RgbaUnorm,
        44 => wgpu::TextureFormat::Bc1RgbaUnormSrgb,
        45 => wgpu::TextureFormat::Bc2RgbaUnorm,
        46 => wgpu::TextureFormat::Bc2RgbaUnormSrgb,
        47 => wgpu::TextureFormat::Bc3RgbaUnorm,
        48 => wgpu::TextureFormat::Bc3RgbaUnormSrgb,
        49 => wgpu::TextureFormat::Bc4RUnorm,
        50 => wgpu::TextureFormat::Bc4RSnorm,
        51 => wgpu::TextureFormat::Bc5RgUnorm,
        52 => wgpu::TextureFormat::Bc5RgSnorm,
        53 => wgpu::TextureFormat::Bc6hRgbUfloat,
        54 => wgpu::TextureFormat::Bc6hRgbFloat,
        55 => wgpu::TextureFormat::Bc7RgbaUnorm,
        56 => wgpu::TextureFormat::Bc7RgbaUnormSrgb,
        // ETC2 compressed formats
        57 => wgpu::TextureFormat::Etc2Rgb8Unorm,
        58 => wgpu::TextureFormat::Etc2Rgb8UnormSrgb,
        59 => wgpu::TextureFormat::Etc2Rgb8A1Unorm,
        60 => wgpu::TextureFormat::Etc2Rgb8A1UnormSrgb,
        61 => wgpu::TextureFormat::Etc2Rgba8Unorm,
        62 => wgpu::TextureFormat::Etc2Rgba8UnormSrgb,
        63 => wgpu::TextureFormat::EacR11Unorm,
        64 => wgpu::TextureFormat::EacR11Snorm,
        65 => wgpu::TextureFormat::EacRg11Unorm,
        66 => wgpu::TextureFormat::EacRg11Snorm,
        // ASTC compressed formats
        67 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B4x4,
            channel: wgpu::AstcChannel::Unorm,
        },
        68 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B4x4,
            channel: wgpu::AstcChannel::UnormSrgb,
        },
        69 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B5x4,
            channel: wgpu::AstcChannel::Unorm,
        },
        70 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B5x4,
            channel: wgpu::AstcChannel::UnormSrgb,
        },
        71 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B5x5,
            channel: wgpu::AstcChannel::Unorm,
        },
        72 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B5x5,
            channel: wgpu::AstcChannel::UnormSrgb,
        },
        73 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B6x5,
            channel: wgpu::AstcChannel::Unorm,
        },
        74 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B6x5,
            channel: wgpu::AstcChannel::UnormSrgb,
        },
        75 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B6x6,
            channel: wgpu::AstcChannel::Unorm,
        },
        76 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B6x6,
            channel: wgpu::AstcChannel::UnormSrgb,
        },
        77 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B8x5,
            channel: wgpu::AstcChannel::Unorm,
        },
        78 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B8x5,
            channel: wgpu::AstcChannel::UnormSrgb,
        },
        79 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B8x6,
            channel: wgpu::AstcChannel::Unorm,
        },
        80 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B8x6,
            channel: wgpu::AstcChannel::UnormSrgb,
        },
        81 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B8x8,
            channel: wgpu::AstcChannel::Unorm,
        },
        82 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B8x8,
            channel: wgpu::AstcChannel::UnormSrgb,
        },
        83 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B10x5,
            channel: wgpu::AstcChannel::Unorm,
        },
        84 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B10x5,
            channel: wgpu::AstcChannel::UnormSrgb,
        },
        85 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B10x6,
            channel: wgpu::AstcChannel::Unorm,
        },
        86 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B10x6,
            channel: wgpu::AstcChannel::UnormSrgb,
        },
        87 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B10x8,
            channel: wgpu::AstcChannel::Unorm,
        },
        88 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B10x8,
            channel: wgpu::AstcChannel::UnormSrgb,
        },
        89 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B10x10,
            channel: wgpu::AstcChannel::Unorm,
        },
        90 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B10x10,
            channel: wgpu::AstcChannel::UnormSrgb,
        },
        91 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B12x10,
            channel: wgpu::AstcChannel::Unorm,
        },
        92 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B12x10,
            channel: wgpu::AstcChannel::UnormSrgb,
        },
        93 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B12x12,
            channel: wgpu::AstcChannel::Unorm,
        },
        94 => wgpu::TextureFormat::Astc {
            block: wgpu::AstcBlock::B12x12,
            channel: wgpu::AstcChannel::UnormSrgb,
        },
        _ => wgpu::TextureFormat::Rgba8Unorm,
    }
}

pub(crate) fn texture_dimension_from_u32(dim: u32) -> wgpu::TextureDimension {
    match dim {
        0 => wgpu::TextureDimension::D1,
        1 => wgpu::TextureDimension::D2,
        2 => wgpu::TextureDimension::D3,
        _ => wgpu::TextureDimension::D2,
    }
}

pub(crate) fn texture_view_dimension_from_u32(dim: u32) -> wgpu::TextureViewDimension {
    match dim {
        0 => wgpu::TextureViewDimension::D1,
        1 => wgpu::TextureViewDimension::D2,
        2 => wgpu::TextureViewDimension::D2Array,
        3 => wgpu::TextureViewDimension::Cube,
        4 => wgpu::TextureViewDimension::CubeArray,
        5 => wgpu::TextureViewDimension::D3,
        _ => wgpu::TextureViewDimension::D2,
    }
}

pub(crate) fn address_mode_from_u32(mode: u32) -> wgpu::AddressMode {
    match mode {
        0 => wgpu::AddressMode::ClampToEdge,
        1 => wgpu::AddressMode::Repeat,
        2 => wgpu::AddressMode::MirrorRepeat,
        _ => wgpu::AddressMode::ClampToEdge,
    }
}

pub(crate) fn filter_mode_from_u32(mode: u32) -> wgpu::FilterMode {
    match mode {
        0 => wgpu::FilterMode::Nearest,
        1 => wgpu::FilterMode::Linear,
        _ => wgpu::FilterMode::Nearest,
    }
}

pub(crate) fn mipmap_filter_mode_from_u32(mode: u32) -> wgpu::MipmapFilterMode {
    match mode {
        0 => wgpu::MipmapFilterMode::Nearest,
        1 => wgpu::MipmapFilterMode::Linear,
        _ => wgpu::MipmapFilterMode::Nearest,
    }
}

pub(crate) fn shader_stages_from_u32(visibility: u32) -> wgpu::ShaderStages {
    let mut stages = wgpu::ShaderStages::empty();
    if visibility & 1 != 0 {
        stages |= wgpu::ShaderStages::VERTEX;
    }
    if visibility & 2 != 0 {
        stages |= wgpu::ShaderStages::FRAGMENT;
    }
    if visibility & 4 != 0 {
        stages |= wgpu::ShaderStages::COMPUTE;
    }
    stages
}

pub(crate) fn buffer_binding_type_from_u32(buffer_type: u32) -> wgpu::BufferBindingType {
    match buffer_type {
        2 => wgpu::BufferBindingType::Uniform,
        3 => wgpu::BufferBindingType::Storage { read_only: false },
        4 => wgpu::BufferBindingType::Storage { read_only: true },
        _ => wgpu::BufferBindingType::Uniform,
    }
}

pub(crate) fn sampler_binding_type_from_u32(sampler_type: u32) -> wgpu::SamplerBindingType {
    match sampler_type {
        2 => wgpu::SamplerBindingType::Filtering,
        3 => wgpu::SamplerBindingType::NonFiltering,
        4 => wgpu::SamplerBindingType::Comparison,
        _ => wgpu::SamplerBindingType::Filtering,
    }
}

pub(crate) fn texture_sample_type_from_u32(sample_type: u32) -> wgpu::TextureSampleType {
    match sample_type {
        2 => wgpu::TextureSampleType::Float { filterable: true },
        3 => wgpu::TextureSampleType::Float { filterable: false },
        4 => wgpu::TextureSampleType::Depth,
        5 => wgpu::TextureSampleType::Sint,
        6 => wgpu::TextureSampleType::Uint,
        _ => wgpu::TextureSampleType::Float { filterable: true },
    }
}

pub(crate) fn storage_texture_access_from_u32(access: u32) -> wgpu::StorageTextureAccess {
    match access {
        2 => wgpu::StorageTextureAccess::WriteOnly,
        3 => wgpu::StorageTextureAccess::ReadOnly,
        4 => wgpu::StorageTextureAccess::ReadWrite,
        _ => wgpu::StorageTextureAccess::WriteOnly,
    }
}

pub(crate) fn vertex_format_from_u32(format: u32) -> wgpu::VertexFormat {
    match format {
        0 => wgpu::VertexFormat::Uint8,
        1 => wgpu::VertexFormat::Uint8x2,
        2 => wgpu::VertexFormat::Uint8x4,
        3 => wgpu::VertexFormat::Sint8,
        4 => wgpu::VertexFormat::Sint8x2,
        5 => wgpu::VertexFormat::Sint8x4,
        6 => wgpu::VertexFormat::Unorm8,
        7 => wgpu::VertexFormat::Unorm8x2,
        8 => wgpu::VertexFormat::Unorm8x4,
        9 => wgpu::VertexFormat::Snorm8,
        10 => wgpu::VertexFormat::Snorm8x2,
        11 => wgpu::VertexFormat::Snorm8x4,
        12 => wgpu::VertexFormat::Uint16,
        13 => wgpu::VertexFormat::Uint16x2,
        14 => wgpu::VertexFormat::Uint16x4,
        15 => wgpu::VertexFormat::Sint16,
        16 => wgpu::VertexFormat::Sint16x2,
        17 => wgpu::VertexFormat::Sint16x4,
        18 => wgpu::VertexFormat::Unorm16,
        19 => wgpu::VertexFormat::Unorm16x2,
        20 => wgpu::VertexFormat::Unorm16x4,
        21 => wgpu::VertexFormat::Snorm16,
        22 => wgpu::VertexFormat::Snorm16x2,
        23 => wgpu::VertexFormat::Snorm16x4,
        24 => wgpu::VertexFormat::Float16,
        25 => wgpu::VertexFormat::Float16x2,
        26 => wgpu::VertexFormat::Float16x4,
        27 => wgpu::VertexFormat::Float32,
        28 => wgpu::VertexFormat::Float32x2,
        29 => wgpu::VertexFormat::Float32x3,
        30 => wgpu::VertexFormat::Float32x4,
        31 => wgpu::VertexFormat::Uint32,
        32 => wgpu::VertexFormat::Uint32x2,
        33 => wgpu::VertexFormat::Uint32x3,
        34 => wgpu::VertexFormat::Uint32x4,
        35 => wgpu::VertexFormat::Sint32,
        36 => wgpu::VertexFormat::Sint32x2,
        37 => wgpu::VertexFormat::Sint32x3,
        38 => wgpu::VertexFormat::Sint32x4,
        39 => wgpu::VertexFormat::Unorm10_10_10_2,
        40 => wgpu::VertexFormat::Unorm8x4Bgra,
        _ => wgpu::VertexFormat::Float32,
    }
}

pub(crate) fn index_format_from_u32(format: u32) -> Option<wgpu::IndexFormat> {
    match format {
        0 => Some(wgpu::IndexFormat::Uint16),
        1 => Some(wgpu::IndexFormat::Uint32),
        _ => None,
    }
}

pub(crate) fn vertex_step_mode_from_u32(mode: u32) -> wgpu::VertexStepMode {
    match mode {
        0 => wgpu::VertexStepMode::Vertex,
        1 => wgpu::VertexStepMode::Instance,
        _ => wgpu::VertexStepMode::Vertex,
    }
}

pub(crate) fn primitive_topology_from_u32(topology: u32) -> wgpu::PrimitiveTopology {
    match topology {
        0 => wgpu::PrimitiveTopology::PointList,
        1 => wgpu::PrimitiveTopology::LineList,
        2 => wgpu::PrimitiveTopology::LineStrip,
        3 => wgpu::PrimitiveTopology::TriangleList,
        4 => wgpu::PrimitiveTopology::TriangleStrip,
        _ => wgpu::PrimitiveTopology::TriangleList,
    }
}

pub(crate) fn front_face_from_u32(front_face: u32) -> wgpu::FrontFace {
    match front_face {
        0 => wgpu::FrontFace::Ccw,
        1 => wgpu::FrontFace::Cw,
        _ => wgpu::FrontFace::Ccw,
    }
}

pub(crate) fn cull_mode_from_u32(cull_mode: u32) -> Option<wgpu::Face> {
    match cull_mode {
        0 => None,
        1 => Some(wgpu::Face::Front),
        2 => Some(wgpu::Face::Back),
        _ => None,
    }
}

pub(crate) fn compare_function_from_u32(compare: u32) -> wgpu::CompareFunction {
    match compare {
        0 => wgpu::CompareFunction::Never,
        1 => wgpu::CompareFunction::Less,
        2 => wgpu::CompareFunction::Equal,
        3 => wgpu::CompareFunction::LessEqual,
        4 => wgpu::CompareFunction::Greater,
        5 => wgpu::CompareFunction::NotEqual,
        6 => wgpu::CompareFunction::GreaterEqual,
        7 => wgpu::CompareFunction::Always,
        _ => wgpu::CompareFunction::Less,
    }
}

pub(crate) fn blend_operation_from_u32(op: u32) -> wgpu::BlendOperation {
    match op {
        0 => wgpu::BlendOperation::Add,
        1 => wgpu::BlendOperation::Subtract,
        2 => wgpu::BlendOperation::ReverseSubtract,
        3 => wgpu::BlendOperation::Min,
        4 => wgpu::BlendOperation::Max,
        _ => wgpu::BlendOperation::Add,
    }
}

pub(crate) fn blend_factor_from_u32(factor: u32) -> wgpu::BlendFactor {
    match factor {
        0 => wgpu::BlendFactor::Zero,
        1 => wgpu::BlendFactor::One,
        2 => wgpu::BlendFactor::Src,
        3 => wgpu::BlendFactor::OneMinusSrc,
        4 => wgpu::BlendFactor::SrcAlpha,
        5 => wgpu::BlendFactor::OneMinusSrcAlpha,
        6 => wgpu::BlendFactor::Dst,
        7 => wgpu::BlendFactor::OneMinusDst,
        8 => wgpu::BlendFactor::DstAlpha,
        9 => wgpu::BlendFactor::OneMinusDstAlpha,
        10 => wgpu::BlendFactor::SrcAlphaSaturated,
        11 => wgpu::BlendFactor::Constant,
        12 => wgpu::BlendFactor::OneMinusConstant,
        13 => wgpu::BlendFactor::Src1,
        14 => wgpu::BlendFactor::OneMinusSrc1,
        15 => wgpu::BlendFactor::Src1Alpha,
        16 => wgpu::BlendFactor::OneMinusSrc1Alpha,
        _ => wgpu::BlendFactor::One,
    }
}

pub(crate) fn color_writes_from_u32(mask: u32) -> wgpu::ColorWrites {
    wgpu::ColorWrites::from_bits_truncate(mask)
}

pub(crate) fn stencil_operation_from_u32(op: u32) -> wgpu::StencilOperation {
    match op {
        0 => wgpu::StencilOperation::Keep,
        1 => wgpu::StencilOperation::Zero,
        2 => wgpu::StencilOperation::Replace,
        3 => wgpu::StencilOperation::IncrementClamp,
        4 => wgpu::StencilOperation::DecrementClamp,
        5 => wgpu::StencilOperation::Invert,
        6 => wgpu::StencilOperation::IncrementWrap,
        7 => wgpu::StencilOperation::DecrementWrap,
        _ => wgpu::StencilOperation::Keep,
    }
}

pub(crate) fn texture_aspect_from_u32(aspect: u32) -> wgpu::TextureAspect {
    match aspect {
        1 => wgpu::TextureAspect::All,
        2 => wgpu::TextureAspect::StencilOnly,
        3 => wgpu::TextureAspect::DepthOnly,
        _ => wgpu::TextureAspect::All,
    }
}

pub(crate) fn load_op_from_u32<V: Default>(op: u32, clear_value: V) -> wgpu::LoadOp<V> {
    match op {
        0 => wgpu::LoadOp::Clear(clear_value),
        1 => wgpu::LoadOp::Load,
        _ => wgpu::LoadOp::Clear(clear_value),
    }
}

pub(crate) fn store_op_from_u32(op: u32) -> wgpu::StoreOp {
    match op {
        0 => wgpu::StoreOp::Store,
        1 => wgpu::StoreOp::Discard,
        _ => wgpu::StoreOp::Store,
    }
}
