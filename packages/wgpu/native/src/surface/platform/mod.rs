#[cfg(target_vendor = "apple")]
pub(crate) mod apple;

#[cfg(target_os = "windows")]
pub(crate) mod windows;

#[cfg(target_os = "windows")]
mod windows_d3d11;

#[cfg(target_os = "linux")]
pub(crate) mod linux;

#[cfg(target_os = "android")]
pub(crate) mod android;
