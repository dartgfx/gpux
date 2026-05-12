use crate::abi::enums::*;
use crate::abi::types::*;
use crate::runtime::handle::*;
use crate::runtime::label::label_from_ptr;

pub fn device_create_sampler(device: &wgpu::Device, desc: &WGPUSamplerDescriptor) -> WGPUSampler {
    let compare = if desc.compare == 0 {
        None
    } else {
        Some(compare_function_from_u32(desc.compare - 1))
    };

    let sampler = device.create_sampler(&wgpu::SamplerDescriptor {
        label: unsafe { label_from_ptr(desc.label) },
        address_mode_u: address_mode_from_u32(desc.address_mode_u),
        address_mode_v: address_mode_from_u32(desc.address_mode_v),
        address_mode_w: address_mode_from_u32(desc.address_mode_w),
        mag_filter: filter_mode_from_u32(desc.mag_filter),
        min_filter: filter_mode_from_u32(desc.min_filter),
        mipmap_filter: mipmap_filter_mode_from_u32(desc.mipmap_filter),
        lod_min_clamp: desc.lod_min_clamp,
        lod_max_clamp: desc.lod_max_clamp,
        compare,
        anisotropy_clamp: desc.max_anisotropy,
        border_color: None,
    });
    into_handle(sampler)
}

pub fn sampler_release(sampler: WGPUSampler) {
    if sampler == 0 {
        return;
    }
    unsafe {
        drop_handle::<wgpu::Sampler>(sampler);
    }
}
