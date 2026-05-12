use crate::abi::types::*;
use crate::runtime::handle::*;

pub fn device_create_shader_module(
    device: &wgpu::Device,
    source: &str,
    label: Option<&str>,
) -> WGPUShaderModule {
    let module = device.create_shader_module(wgpu::ShaderModuleDescriptor {
        label,
        source: wgpu::ShaderSource::Wgsl(source.into()),
    });
    into_handle(module)
}

pub fn shader_module_get_compilation_info(module_handle: WGPUShaderModule) -> Option<String> {
    if module_handle == 0 {
        return None;
    }
    let module = unsafe { deref_handle::<wgpu::ShaderModule>(module_handle) };
    let info = pollster::block_on(module.get_compilation_info());

    if info.messages.is_empty() {
        return None;
    }

    let mut result = String::new();
    for msg in &info.messages {
        let type_char = match msg.message_type {
            wgpu::CompilationMessageType::Error => 'E',
            wgpu::CompilationMessageType::Warning => 'W',
            wgpu::CompilationMessageType::Info => 'I',
        };
        let line_num = msg.location.as_ref().map_or(0, |l| l.line_number);
        let line_pos = msg.location.as_ref().map_or(0, |l| l.line_position);
        if !result.is_empty() {
            result.push('\n');
        }
        result.push(type_char);
        result.push('\t');
        result.push_str(&line_num.to_string());
        result.push('\t');
        result.push_str(&line_pos.to_string());
        result.push('\t');
        result.push_str(&msg.message);
    }

    Some(result)
}

pub fn shader_module_release(module: WGPUShaderModule) {
    if module == 0 {
        return;
    }
    unsafe {
        drop_handle::<wgpu::ShaderModule>(module);
    }
}
