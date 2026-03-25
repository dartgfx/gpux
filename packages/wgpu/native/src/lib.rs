// wgpu_native - Dart FFI bindings for wgpu
//
// Provides a handle-based API for GPU resources (buffers, textures, pipelines,
// shaders) with platform-specific surface support for texture sharing:
// - macOS/iOS: IOSurface
// - Windows: DXGI shared texture / pixel buffer
// - Android: Native window swapchain

// FFI functions take raw pointers and dereference in unsafe blocks.
// Clippy wants the functions themselves marked unsafe, but that's not
// idiomatic for extern "C" FFI - callers are already in unsafe territory.
#![allow(clippy::not_unsafe_ptr_arg_deref)]
// FFI functions use camelCase to match wgpu naming convention
#![allow(non_snake_case)]

use std::cell::RefCell;
use std::ffi::{c_char, CString};

// Internal modules
mod api;
mod ffi;
mod handle;
mod surface;

// =============================================================================
// LAST ERROR (thread-local for FFI error reporting)
// =============================================================================

thread_local! {
    static LAST_ERROR: RefCell<Option<CString>> = const { RefCell::new(None) };
}

fn set_error(msg: impl Into<String>) {
    let msg = msg.into();
    log::error!("{}", msg);
    LAST_ERROR.with(|e| {
        *e.borrow_mut() = CString::new(msg).ok();
    });
}

fn clear_error() {
    LAST_ERROR.with(|e| {
        *e.borrow_mut() = None;
    });
}

/// Catch panics at the FFI boundary so wgpu-core panics (e.g. stale handles)
/// produce an error instead of aborting the process.
///
/// Usage: `ffi_catch!(0, { ... })` for handle-returning functions,
///        `ffi_catch!((), { ... })` for void functions.
macro_rules! ffi_catch {
    ($default:expr, $body:expr) => {
        match std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| $body)) {
            Ok(v) => v,
            Err(e) => {
                let msg = if let Some(s) = e.downcast_ref::<&str>() {
                    s.to_string()
                } else if let Some(s) = e.downcast_ref::<String>() {
                    s.clone()
                } else {
                    "unknown panic".to_string()
                };
                $crate::set_error(format!("wgpu panic caught: {}", msg));
                $default
            }
        }
    };
}

pub(crate) use ffi_catch;

// =============================================================================
// FFI EXPORTS - Error
// =============================================================================

/// Get the last error message.
#[no_mangle]
pub extern "C" fn wgpu_get_last_error() -> *const c_char {
    LAST_ERROR.with(|e| {
        match e.borrow().as_ref() {
            Some(s) => s.as_ptr(),
            None => std::ptr::null(),
        }
    })
}
