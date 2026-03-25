// Build script to extract wgpu version from Cargo.lock
// This avoids manual maintenance when upgrading wgpu.

use std::fs;

fn main() {
    // Re-run if Cargo.lock changes
    println!("cargo:rerun-if-changed=Cargo.lock");

    let version = extract_wgpu_version().unwrap_or_else(|| "unknown".to_string());
    println!("cargo:rustc-env=WGPU_VERSION={}", version);
}

fn extract_wgpu_version() -> Option<String> {
    let lock_content = fs::read_to_string("Cargo.lock").ok()?;

    // Parse Cargo.lock (TOML format) looking for wgpu package
    for line in lock_content.lines() {
        if line.starts_with("name = \"wgpu\"") {
            // Next line should be version
            continue;
        }
        if line.starts_with("version = ") && lock_content.contains("name = \"wgpu\"") {
            // This is fragile, let's use a better approach
        }
    }

    // Simple regex-free parsing: find [[package]] blocks
    let mut in_wgpu_block = false;
    for line in lock_content.lines() {
        let line = line.trim();
        if line == "[[package]]" {
            in_wgpu_block = false;
        } else if line == "name = \"wgpu\"" {
            in_wgpu_block = true;
        } else if in_wgpu_block && line.starts_with("version = ") {
            // Extract version from: version = "25.0.2"
            let version = line
                .strip_prefix("version = \"")?
                .strip_suffix('"')?;
            return Some(version.to_string());
        }
    }

    None
}
