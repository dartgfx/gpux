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

/// Free a validation result returned by naga_validate_wgsl.
#[no_mangle]
pub extern "C" fn naga_free_validation_result(result: NagaValidationResult) {
    if result.errors.is_null() || result.error_count == 0 {
        return;
    }

    // Free each error's message
    let errors = unsafe {
        std::slice::from_raw_parts_mut(result.errors, result.error_count as usize)
    };
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
            result.errors,
            result.error_count as usize,
            result.error_count as usize,
        ));
    }
}

// Helper: create result with a single error
fn make_single_error(message: &str, offset: i32, length: i32) -> NagaValidationResult {
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
