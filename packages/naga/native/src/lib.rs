// naga_native - WGSL validation via naga
//
// Standalone library for WGSL parsing and validation.
// No GPU initialization required.

use std::ffi::{c_char, CStr, CString};
use std::ptr;

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

/// Result of GLSL to WGSL translation.
#[repr(C)]
pub struct NagaTranslateResult {
    /// WGSL source code (null if translation failed)
    pub wgsl: *mut c_char,
    /// Number of errors (0 = valid)
    pub error_count: u32,
    /// Pointer to array of NagaError (null if error_count == 0)
    pub errors: *mut NagaError,
}

/// Validate WGSL source code.
///
/// Returns a NagaValidationResult with error_count=0 if valid,
/// or error_count>0 with error details if invalid.
///
/// The caller must call naga_free_validation_result() to free the result.
#[no_mangle]
pub extern "C" fn naga_validate_wgsl(
    source: *const c_char,
    _source_len: i32,
) -> NagaValidationResult {
    // Null check
    if source.is_null() {
        return make_single_error("null source pointer", -1, -1);
    }

    // Convert to Rust string
    let source_str = match unsafe { CStr::from_ptr(source) }.to_str() {
        Ok(s) => s,
        Err(_) => return make_single_error("invalid UTF-8 in source", -1, -1),
    };

    // Parse WGSL
    let module = match naga::front::wgsl::parse_str(source_str) {
        Ok(m) => m,
        Err(parse_error) => {
            return parse_error_to_result(&parse_error, source_str);
        }
    };

    // Validate the parsed module
    let mut validator = naga::valid::Validator::new(
        naga::valid::ValidationFlags::all(),
        naga::valid::Capabilities::all(),
    );

    match validator.validate(&module) {
        Ok(_) => NagaValidationResult {
            error_count: 0,
            errors: ptr::null_mut(),
        },
        Err(validation_error) => validation_error_to_result(&validation_error, source_str),
    }
}

/// Translate GLSL source code to WGSL.
///
/// stage: 0 = vertex, 1 = fragment, 2 = compute.
/// defines_json is a JSON object whose string keys and values become GLSL
/// preprocessor defines.
///
/// The caller must call naga_free_translate_result() to free the result.
#[no_mangle]
pub extern "C" fn naga_glsl_to_wgsl(
    source: *const c_char,
    stage: u32,
    defines_json: *const c_char,
) -> NagaTranslateResult {
    if source.is_null() {
        return make_single_translate_error("null source pointer", -1, -1);
    }

    let source_str = match unsafe { CStr::from_ptr(source) }.to_str() {
        Ok(s) => s,
        Err(_) => return make_single_translate_error("invalid UTF-8 in source", -1, -1),
    };

    let stage = match stage {
        0 => naga::ShaderStage::Vertex,
        1 => naga::ShaderStage::Fragment,
        2 => naga::ShaderStage::Compute,
        _ => return make_single_translate_error("invalid shader stage", -1, -1),
    };

    let defines = match parse_defines_json(defines_json) {
        Ok(defines) => defines,
        Err(message) => return make_single_translate_error(&message, -1, -1),
    };

    let options = naga::front::glsl::Options { stage, defines };
    let mut frontend = naga::front::glsl::Frontend::default();
    let module = match frontend.parse(&options, source_str) {
        Ok(module) => module,
        Err(parse_errors) => {
            return glsl_parse_errors_to_translate_result(&parse_errors, source_str)
        }
    };

    let mut validator = naga::valid::Validator::new(
        naga::valid::ValidationFlags::all(),
        naga::valid::Capabilities::all(),
    );

    let info = match validator.validate(&module) {
        Ok(info) => info,
        Err(validation_error) => {
            let validation = validation_error_to_result(&validation_error, source_str);
            return translate_result_from_validation_result(validation);
        }
    };

    match naga::back::wgsl::write_string(&module, &info, naga::back::wgsl::WriterFlags::empty()) {
        Ok(wgsl) => NagaTranslateResult {
            wgsl: CString::new(wgsl).unwrap_or_default().into_raw(),
            error_count: 0,
            errors: ptr::null_mut(),
        },
        Err(error) => make_single_translate_error(&format!("WGSL write error: {error}"), -1, -1),
    }
}

/// Free a validation result returned by naga_validate_wgsl.
#[no_mangle]
pub extern "C" fn naga_free_validation_result(result: NagaValidationResult) {
    free_error_array(result.errors, result.error_count);
}

/// Free a translation result returned by naga_glsl_to_wgsl.
#[no_mangle]
pub extern "C" fn naga_free_translate_result(result: NagaTranslateResult) {
    if !result.wgsl.is_null() {
        unsafe {
            drop(CString::from_raw(result.wgsl));
        }
    }
    free_error_array(result.errors, result.error_count);
}

fn free_error_array(errors_ptr: *mut NagaError, error_count: u32) {
    if errors_ptr.is_null() || error_count == 0 {
        return;
    }

    // Free each error's message
    let errors = unsafe { std::slice::from_raw_parts_mut(errors_ptr, error_count as usize) };
    for error in errors.iter() {
        if !error.message.is_null() {
            unsafe {
                drop(CString::from_raw(error.message));
            }
        }
    }

    // Free the array itself
    unsafe {
        drop(Vec::from_raw_parts(
            errors_ptr,
            error_count as usize,
            error_count as usize,
        ));
    }
}

// Helper: create result with a single error
fn make_single_error(message: &str, offset: i32, length: i32) -> NagaValidationResult {
    let (ptr, count) = make_error_array(vec![make_error(message, offset, length)]);

    NagaValidationResult {
        error_count: count,
        errors: ptr,
    }
}

fn make_single_translate_error(message: &str, offset: i32, length: i32) -> NagaTranslateResult {
    let (ptr, count) = make_error_array(vec![make_error(message, offset, length)]);

    NagaTranslateResult {
        wgsl: ptr::null_mut(),
        error_count: count,
        errors: ptr,
    }
}

fn make_error(message: &str, offset: i32, length: i32) -> NagaError {
    NagaError {
        message: CString::new(message).unwrap_or_default().into_raw(),
        offset,
        length,
    }
}

fn make_error_array(mut errors: Vec<NagaError>) -> (*mut NagaError, u32) {
    let count = errors.len() as u32;
    let ptr = errors.as_mut_ptr();
    std::mem::forget(errors);
    (ptr, count)
}

fn parse_defines_json(
    defines_json: *const c_char,
) -> Result<naga::FastHashMap<String, String>, String> {
    let mut defines = naga::FastHashMap::default();
    if defines_json.is_null() {
        return Ok(defines);
    }

    let defines_str = unsafe { CStr::from_ptr(defines_json) }
        .to_str()
        .map_err(|_| "invalid UTF-8 in defines_json".to_string())?;
    let trimmed = defines_str.trim();
    if trimmed.is_empty() || trimmed == "{}" {
        return Ok(defines);
    }

    for entry in trimmed
        .strip_prefix('{')
        .and_then(|s| s.strip_suffix('}'))
        .ok_or_else(|| "defines_json must be an object".to_string())?
        .split(',')
    {
        let entry = entry.trim();
        if entry.is_empty() {
            continue;
        }
        let Some((key, value)) = entry.split_once(':') else {
            return Err("defines_json entries must be key/value pairs".to_string());
        };
        defines.insert(unquote_json_string(key)?, unquote_json_string(value)?);
    }
    Ok(defines)
}

fn unquote_json_string(value: &str) -> Result<String, String> {
    let trimmed = value.trim();
    let unquoted = trimmed
        .strip_prefix('"')
        .and_then(|s| s.strip_suffix('"'))
        .ok_or_else(|| "defines_json keys and values must be strings".to_string())?;
    Ok(unquoted
        .replace("\\\"", "\"")
        .replace("\\\\", "\\")
        .replace("\\n", "\n")
        .replace("\\r", "\r")
        .replace("\\t", "\t"))
}

fn translate_result_from_validation_result(result: NagaValidationResult) -> NagaTranslateResult {
    NagaTranslateResult {
        wgsl: ptr::null_mut(),
        error_count: result.error_count,
        errors: result.errors,
    }
}

// Convert naga parse error to result
fn parse_error_to_result(
    error: &naga::front::wgsl::ParseError,
    source: &str,
) -> NagaValidationResult {
    let message = error.emit_to_string(source);

    // Extract location from the error (SourceLocation has offset and length)
    let (offset, length) = error
        .location(source)
        .map(|loc| (loc.offset as i32, loc.length as i32))
        .unwrap_or((-1, -1));

    make_single_error(&message, offset, length)
}

fn glsl_parse_errors_to_translate_result(
    errors: &naga::front::glsl::ParseErrors,
    source: &str,
) -> NagaTranslateResult {
    let message = errors.emit_to_string(source);
    let (offset, length) = errors
        .errors
        .first()
        .and_then(|error| error.location(source))
        .map(|loc| (loc.offset as i32, loc.length as i32))
        .unwrap_or((-1, -1));

    make_single_translate_error(&message, offset, length)
}

// Convert naga validation error to result
fn validation_error_to_result(
    error: &naga::WithSpan<naga::valid::ValidationError>,
    source: &str,
) -> NagaValidationResult {
    let message = format!("{}", error);

    // Get span if available, convert to location
    let (offset, length) = error
        .spans()
        .next()
        .map(|(span, _)| {
            let loc = span.location(source);
            (loc.offset as i32, loc.length as i32)
        })
        .unwrap_or((-1, -1));

    make_single_error(&message, offset, length)
}
