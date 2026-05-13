use std::ffi::c_char;
use std::slice;
use std::str;

use crate::constants::{
    SOURCE_GLSL, SOURCE_SPIRV, SOURCE_WGSL, STAGE_COMPUTE, STAGE_FRAGMENT, STAGE_NONE, STAGE_VERTEX,
};
use crate::results::{make_single_error, NagaGlslDefine, NagaValidationResult};

pub(crate) fn read_text<'a>(
    source: *const c_char,
    source_len: i32,
) -> Result<&'a str, NagaValidationResult> {
    if source.is_null() {
        return Err(make_single_error("null source pointer", -1, -1));
    }
    if source_len < 0 {
        return Err(make_single_error("negative source length", -1, -1));
    }

    let bytes = unsafe { slice::from_raw_parts(source.cast::<u8>(), source_len as usize) };
    str::from_utf8(bytes).map_err(|_| make_single_error("invalid UTF-8 in source", -1, -1))
}

pub(crate) fn parse_source(
    text_source: *const c_char,
    text_source_len: i32,
    spirv_words: *const u32,
    spirv_word_count: i32,
    source_format: i32,
    glsl_stage: i32,
    glsl_defines: *const NagaGlslDefine,
    glsl_define_count: i32,
) -> Result<naga::Module, NagaValidationResult> {
    match source_format {
        SOURCE_WGSL => {
            let source = read_text(text_source, text_source_len)?;
            naga::front::wgsl::parse_str(source)
                .map_err(|error| parse_wgsl_error_to_result(&error, source))
        }
        SOURCE_GLSL => {
            let source = read_text(text_source, text_source_len)?;
            let stage = parse_stage(glsl_stage)
                .ok_or_else(|| make_single_error("GLSL source requires a shader stage", -1, -1))?;
            let mut frontend = naga::front::glsl::Frontend::default();
            let options = naga::front::glsl::Options {
                stage,
                defines: read_glsl_defines(glsl_defines, glsl_define_count)?,
            };
            frontend
                .parse(&options, source)
                .map_err(|error| make_single_error(&format!("{}", error), -1, -1))
        }
        SOURCE_SPIRV => {
            let words = read_spirv(spirv_words, spirv_word_count)?;
            let options = naga::front::spv::Options::default();
            naga::front::spv::Frontend::new(words.iter().copied(), &options)
                .parse()
                .map_err(|error| make_single_error(&format!("{}", error), -1, -1))
        }
        _ => Err(make_single_error("unknown source format", -1, -1)),
    }
}

fn read_glsl_defines(
    defines: *const NagaGlslDefine,
    define_count: i32,
) -> Result<naga::FastHashMap<String, String>, NagaValidationResult> {
    let mut result = naga::FastHashMap::default();
    if define_count == 0 {
        return Ok(result);
    }
    if define_count < 0 {
        return Err(make_single_error("negative GLSL define count", -1, -1));
    }
    if defines.is_null() {
        return Err(make_single_error("null GLSL defines pointer", -1, -1));
    }

    let defines = unsafe { slice::from_raw_parts(defines, define_count as usize) };
    for define in defines {
        let name = read_text(define.name, define.name_len)?.to_string();
        let value = read_text(define.value, define.value_len)?.to_string();
        result.insert(name, value);
    }
    Ok(result)
}

pub(crate) fn read_entry_point(
    entry_stage: i32,
    entry_name: *const c_char,
    entry_name_len: i32,
) -> Result<Option<(naga::ShaderStage, String)>, String> {
    if entry_stage == STAGE_NONE {
        return Ok(None);
    }

    let stage = parse_stage(entry_stage).ok_or_else(|| "unknown entry point stage".to_string())?;
    let name = read_text(entry_name, entry_name_len)
        .map_err(|_| "invalid entry point name".to_string())?
        .to_string();
    Ok(Some((stage, name)))
}

pub(crate) fn parse_stage(stage: i32) -> Option<naga::ShaderStage> {
    match stage {
        STAGE_VERTEX => Some(naga::ShaderStage::Vertex),
        STAGE_FRAGMENT => Some(naga::ShaderStage::Fragment),
        STAGE_COMPUTE => Some(naga::ShaderStage::Compute),
        _ => None,
    }
}

fn read_spirv<'a>(words: *const u32, word_count: i32) -> Result<&'a [u32], NagaValidationResult> {
    if words.is_null() {
        return Err(make_single_error("null SPIR-V words pointer", -1, -1));
    }
    if word_count < 0 {
        return Err(make_single_error("negative SPIR-V word count", -1, -1));
    }

    Ok(unsafe { slice::from_raw_parts(words, word_count as usize) })
}

fn parse_wgsl_error_to_result(
    error: &naga::front::wgsl::ParseError,
    source: &str,
) -> NagaValidationResult {
    let message = error.emit_to_string(source);
    let (offset, length) = error
        .location(source)
        .map(|loc| (loc.offset as i32, loc.length as i32))
        .unwrap_or((-1, -1));

    make_single_error(&message, offset, length)
}
