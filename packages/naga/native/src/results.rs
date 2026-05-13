use std::ffi::{c_char, CString};
use std::ptr;
use std::slice;

use crate::constants::{OUTPUT_NONE, OUTPUT_SPIRV, OUTPUT_TEXT, STATUS_FAILURE, STATUS_SUCCESS};
use crate::translation::TranslationOutput;

/// Result of WGSL validation.
#[repr(C)]
pub struct NagaValidationResult {
    /// Number of errors (0 = valid)
    pub error_count: u32,
    /// Pointer to array of NagaError (null if error_count == 0)
    pub errors: *mut NagaError,
}

/// A single validation error.
#[repr(C)]
pub struct NagaError {
    /// Error message (null-terminated UTF-8)
    pub message: *mut c_char,
    /// Byte offset into source (-1 if not available)
    pub offset: i32,
    /// Length of error span (-1 if not available)
    pub length: i32,
}

/// A GLSL preprocessor definition.
#[repr(C)]
pub struct NagaGlslDefine {
    /// Definition name.
    pub name: *const c_char,
    /// Definition name byte length.
    pub name_len: i32,
    /// Definition value.
    pub value: *const c_char,
    /// Definition value byte length.
    pub value_len: i32,
}

/// Result of shader translation.
#[repr(C)]
pub struct NagaTranslationResult {
    /// 0 = success, 1 = failure
    pub status: u32,
    /// 0 = none, 1 = UTF-8 text, 2 = SPIR-V words
    pub output_kind: u32,
    /// Text output pointer. Null unless output_kind == 1.
    pub output_text: *mut c_char,
    /// SPIR-V output pointer. Null unless output_kind == 2.
    pub output_words: *mut u32,
    /// Number of SPIR-V words.
    pub output_word_count: u32,
    /// Number of diagnostics.
    pub diagnostic_count: u32,
    /// Pointer to array of NagaError.
    pub diagnostics: *mut NagaError,
}

pub(crate) fn make_single_error(message: &str, offset: i32, length: i32) -> NagaValidationResult {
    let c_message = CString::new(message).unwrap_or_default().into_raw();

    let error = NagaError {
        message: c_message,
        offset,
        length,
    };

    let mut errors = vec![error];
    let ptr = errors.as_mut_ptr();
    std::mem::forget(errors);

    NagaValidationResult {
        error_count: 1,
        errors: ptr,
    }
}

pub(crate) fn make_ok_validation() -> NagaValidationResult {
    NagaValidationResult {
        error_count: 0,
        errors: ptr::null_mut(),
    }
}

pub(crate) fn free_errors(errors_ptr: *mut NagaError, error_count: u32) {
    if errors_ptr.is_null() || error_count == 0 {
        return;
    }

    let errors = unsafe { slice::from_raw_parts_mut(errors_ptr, error_count as usize) };
    for error in errors.iter() {
        if !error.message.is_null() {
            unsafe {
                drop(CString::from_raw(error.message));
            }
        }
    }

    unsafe {
        drop(Vec::from_raw_parts(
            errors_ptr,
            error_count as usize,
            error_count as usize,
        ));
    }
}

pub(crate) fn translation_failure_from_validation(
    result: NagaValidationResult,
) -> NagaTranslationResult {
    NagaTranslationResult {
        status: STATUS_FAILURE,
        output_kind: OUTPUT_NONE,
        output_text: ptr::null_mut(),
        output_words: ptr::null_mut(),
        output_word_count: 0,
        diagnostic_count: result.error_count,
        diagnostics: result.errors,
    }
}

pub(crate) fn make_translation_error(
    message: &str,
    offset: i32,
    length: i32,
) -> NagaTranslationResult {
    let result = make_single_error(message, offset, length);
    translation_failure_from_validation(result)
}

pub(crate) fn make_translation_success(output: TranslationOutput) -> NagaTranslationResult {
    match output {
        TranslationOutput::Text(text) => make_translation_text(text),
        TranslationOutput::Spirv(words) => make_translation_spirv(words),
    }
}

fn make_translation_text(text: String) -> NagaTranslationResult {
    NagaTranslationResult {
        status: STATUS_SUCCESS,
        output_kind: OUTPUT_TEXT,
        output_text: CString::new(text).unwrap_or_default().into_raw(),
        output_words: ptr::null_mut(),
        output_word_count: 0,
        diagnostic_count: 0,
        diagnostics: ptr::null_mut(),
    }
}

fn make_translation_spirv(mut words: Vec<u32>) -> NagaTranslationResult {
    let output_words = words.as_mut_ptr();
    let output_word_count = words.len() as u32;
    std::mem::forget(words);

    NagaTranslationResult {
        status: STATUS_SUCCESS,
        output_kind: OUTPUT_SPIRV,
        output_text: ptr::null_mut(),
        output_words,
        output_word_count,
        diagnostic_count: 0,
        diagnostics: ptr::null_mut(),
    }
}
