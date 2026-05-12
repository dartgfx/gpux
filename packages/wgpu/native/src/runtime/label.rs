pub(crate) unsafe fn label_from_ptr(ptr: *const std::ffi::c_char) -> Option<&'static str> {
    if ptr.is_null() {
        return None;
    }
    std::ffi::CStr::from_ptr(ptr)
        .to_str()
        .ok()
        .filter(|s| !s.is_empty())
}
