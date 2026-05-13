use std::ffi::{c_char, CString};
use std::ptr;

use crate::constants::{SOURCE_GLSL, SOURCE_WGSL, STAGE_NONE};
use crate::results::{
    free_errors, make_translation_error, make_translation_success, NagaGlslDefine,
    translation_failure_from_validation, NagaTranslationResult, NagaValidationResult,
};
use crate::source::{parse_source, read_entry_point, read_text};
use crate::translation::{target_capabilities, write_target};
use crate::validation::{validate_module, validate_module_info};

/// Validate WGSL source code.
///
/// Returns a NagaValidationResult with error_count=0 if valid,
/// or error_count>0 with error details if invalid.
///
/// The caller must call naga_free_validation_result() to free the result.
#[no_mangle]
pub extern "C" fn naga_validate_wgsl(
    source: *const c_char,
    source_len: i32,
) -> NagaValidationResult {
    naga_validate(
        source,
        source_len,
        ptr::null(),
        0,
        SOURCE_WGSL,
        STAGE_NONE,
        ptr::null(),
        0,
    )
}

/// Validate shader source code.
///
/// source_format: 0 = WGSL, 1 = GLSL, 2 = SPIR-V.
/// glsl_stage is required for GLSL sources: 0 = vertex, 1 = fragment, 2 = compute.
#[no_mangle]
pub extern "C" fn naga_validate(
    text_source: *const c_char,
    text_source_len: i32,
    spirv_words: *const u32,
    spirv_word_count: i32,
    source_format: i32,
    glsl_stage: i32,
    glsl_defines: *const NagaGlslDefine,
    glsl_define_count: i32,
) -> NagaValidationResult {
    let module = match parse_source(
        text_source,
        text_source_len,
        spirv_words,
        spirv_word_count,
        source_format,
        glsl_stage,
        glsl_defines,
        glsl_define_count,
    ) {
        Ok(m) => m,
        Err(result) => return result,
    };

    validate_module(&module, naga::valid::Capabilities::all(), "")
}

/// Translate shader source code.
///
/// source_format: 0 = WGSL, 1 = GLSL, 2 = SPIR-V.
/// target_format: 0 = WGSL, 1 = SPIR-V, 2 = MSL, 3 = HLSL, 4 = GLSL.
/// target_option_flags is interpreted by target_format.
/// target_option_value is interpreted by target_format.
/// entry_stage: -1 = no entry point, 0 = vertex, 1 = fragment, 2 = compute.
#[no_mangle]
pub extern "C" fn naga_translate(
    text_source: *const c_char,
    text_source_len: i32,
    spirv_words: *const u32,
    spirv_word_count: i32,
    source_format: i32,
    glsl_stage: i32,
    target_format: i32,
    target_option_flags: u32,
    target_option_value: i32,
    entry_stage: i32,
    entry_name: *const c_char,
    entry_name_len: i32,
    glsl_defines: *const NagaGlslDefine,
    glsl_define_count: i32,
) -> NagaTranslationResult {
    let source_text = if source_format == SOURCE_WGSL || source_format == SOURCE_GLSL {
        read_text(text_source, text_source_len).unwrap_or("")
    } else {
        ""
    };

    let module = match parse_source(
        text_source,
        text_source_len,
        spirv_words,
        spirv_word_count,
        source_format,
        glsl_stage,
        glsl_defines,
        glsl_define_count,
    ) {
        Ok(m) => m,
        Err(result) => return translation_failure_from_validation(result),
    };

    let capabilities = target_capabilities(target_format);
    let info = match validate_module_info(&module, capabilities, source_text) {
        Ok(info) => info,
        Err(result) => return translation_failure_from_validation(result),
    };

    let entry = match read_entry_point(entry_stage, entry_name, entry_name_len) {
        Ok(entry) => entry,
        Err(message) => return make_translation_error(&message, -1, -1),
    };

    match write_target(
        &module,
        &info,
        target_format,
        target_option_flags,
        target_option_value,
        entry,
    ) {
        Ok(output) => make_translation_success(output),
        Err(message) => make_translation_error(&message, -1, -1),
    }
}

/// Free a validation result returned by naga_validate_wgsl.
#[no_mangle]
pub extern "C" fn naga_free_validation_result(result: NagaValidationResult) {
    free_errors(result.errors, result.error_count);
}

/// Free a translation result returned by naga_translate.
#[no_mangle]
pub extern "C" fn naga_free_translation_result(result: NagaTranslationResult) {
    if !result.output_text.is_null() {
        unsafe {
            drop(CString::from_raw(result.output_text));
        }
    }

    if !result.output_words.is_null() && result.output_word_count > 0 {
        unsafe {
            drop(Vec::from_raw_parts(
                result.output_words,
                result.output_word_count as usize,
                result.output_word_count as usize,
            ));
        }
    }

    free_errors(result.diagnostics, result.diagnostic_count);
}
