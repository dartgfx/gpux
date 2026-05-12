// Pointer-based handle helpers for FFI.
//
//
// Debug builds include a handle registry (like Vulkan validation layers)
// that catches use-after-free, double-free, and invalid handles.

#[cfg(debug_assertions)]
mod registry {
    use std::collections::HashSet;
    use std::sync::Mutex;

    static LIVE: Mutex<Option<HashSet<u64>>> = Mutex::new(None);

    fn with<R>(f: impl FnOnce(&mut HashSet<u64>) -> R) -> R {
        let mut guard = LIVE.lock().unwrap();
        let set = guard.get_or_insert_with(HashSet::new);
        f(set)
    }

    pub fn register(handle: u64) {
        let inserted = with(|s| s.insert(handle));
        assert!(inserted, "handle 0x{handle:x} already registered");
    }

    pub fn validate(handle: u64) {
        let exists = with(|s| s.contains(&handle));
        assert!(exists, "use-after-free or invalid handle: 0x{handle:x}");
    }

    pub fn unregister(handle: u64) {
        let removed = with(|s| s.remove(&handle));
        assert!(removed, "double-free on handle: 0x{handle:x}");
    }
}

pub fn into_handle<T>(value: T) -> u64 {
    let handle = Box::into_raw(Box::new(value)) as u64;
    #[cfg(debug_assertions)]
    registry::register(handle);
    handle
}

pub unsafe fn deref_handle<T>(handle: u64) -> &'static T {
    #[cfg(debug_assertions)]
    registry::validate(handle);
    &*(handle as *const T)
}

pub unsafe fn deref_handle_mut<T>(handle: u64) -> &'static mut T {
    #[cfg(debug_assertions)]
    registry::validate(handle);
    &mut *(handle as *mut T)
}

pub unsafe fn drop_handle<T>(handle: u64) -> T {
    #[cfg(debug_assertions)]
    registry::unregister(handle);
    *Box::from_raw(handle as *mut T)
}
