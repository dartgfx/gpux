pub(crate) const SOURCE_WGSL: i32 = 0;
pub(crate) const SOURCE_GLSL: i32 = 1;
pub(crate) const SOURCE_SPIRV: i32 = 2;

pub(crate) const TARGET_WGSL: i32 = 0;
pub(crate) const TARGET_SPIRV: i32 = 1;
pub(crate) const TARGET_MSL: i32 = 2;
pub(crate) const TARGET_HLSL: i32 = 3;
pub(crate) const TARGET_GLSL: i32 = 4;

pub(crate) const STAGE_NONE: i32 = -1;
pub(crate) const STAGE_VERTEX: i32 = 0;
pub(crate) const STAGE_FRAGMENT: i32 = 1;
pub(crate) const STAGE_COMPUTE: i32 = 2;

pub(crate) const OUTPUT_NONE: u32 = 0;
pub(crate) const OUTPUT_TEXT: u32 = 1;
pub(crate) const OUTPUT_SPIRV: u32 = 2;

pub(crate) const STATUS_SUCCESS: u32 = 0;
pub(crate) const STATUS_FAILURE: u32 = 1;
