pub(crate) mod depth;
pub(crate) mod exports;
pub(crate) mod platform;
pub(crate) mod state;

#[cfg(not(any(
    target_vendor = "apple",
    target_os = "windows",
    target_os = "linux",
    target_os = "android"
)))]
pub(crate) mod unsupported;

#[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
pub mod swapchain;

pub use depth::create_depth_texture;
#[cfg(any(
    target_vendor = "apple",
    target_os = "windows",
    target_os = "linux",
    target_os = "android"
))]
pub use state::WgpuSurface;
#[cfg(not(any(
    target_vendor = "apple",
    target_os = "windows",
    target_os = "linux",
    target_os = "android"
)))]
pub use unsupported::WgpuSurface;
