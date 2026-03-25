import 'package:meta/meta.dart';
import 'package:wgpu/wgpu.dart';

import 'workarounds.dart';

/// Vendor IDs (PCI) for GPU manufacturers.
abstract final class _VendorId {
  static const qualcomm = {0x168C, 0x17CB, 0x1969, 0x5143};
  static const imgTec = {0x1010};
  static const huawei = {0x19E5};
  static const samsung = {0x144D};
  static const google = {0x1AE0}; // SwiftShader (CPU Vulkan on emulators)
}

/// Whether this Vulkan adapter should be rejected entirely.
///
/// Returns true if the GPU/driver is known to be fundamentally broken on
/// Vulkan. Caller should fall back to GLES.
///
/// Source: Flutter Impeller's `IsKnownBadDriver()` in driver_info_vk.cc,
bool isBlocklisted(WgpuAdapterInfo info) {
  if (info.backendType != WgpuBackendType.vulkan) return false;

  final vendorId = info.vendorId;
  final device = info.device;

  // Qualcomm Adreno ≤630: broken framebuffer fetch, command buffer timeouts.
  if (_VendorId.qualcomm.contains(vendorId)) {
    final version = parseAdrenoVersion(device);
    if (version != null && version <= 630) return true;
  }

  // Huawei Maleoon: all versions blocked.
  // https://github.com/flutter/flutter/issues/156623
  if (_VendorId.huawei.contains(vendorId)) return true;

  // Imagination PowerVR < BXE series.
  // https://github.com/flutter/flutter/issues/161122
  if (_VendorId.imgTec.contains(vendorId)) {
    if (isPowerVRPreBXE(device)) return true;
  }

  // SwiftShader (CPU Vulkan on Android emulators): always blocked.
  // GLES performs better than CPU-emulated Vulkan.
  if (_VendorId.google.contains(vendorId) &&
      info.adapterType == WgpuAdapterType.cpu) {
    return true;
  }

  // Samsung Xclipse: blocked if Vulkan API < 1.3.0.
  // All Xclipse GPUs report the same driver version, so we use the Vulkan
  // API version as a proxy — newer devices won't lower the supported level.
  // https://github.com/flutter/flutter/issues/161334
  if (_VendorId.samsung.contains(vendorId)) {
    if (!isVulkanAtLeast(info.driverApiVersion, 1, 3, 0)) return true;
  }

  return false;
}

/// Determine workarounds for a native adapter.
GpuWorkarounds workaroundsFor(WgpuAdapterInfo info) {
  if (!_VendorId.qualcomm.contains(info.vendorId)) {
    return GpuWorkarounds.none;
  }
  return const GpuWorkarounds(
    brokenMipmapGeneration: true, // all Adreno
  );
}

/// Check if a packed Vulkan API version is at least major.minor.patch.
@visibleForTesting
bool isVulkanAtLeast(int packed, int major, int minor, int patch) {
  if (packed == 0) return false;
  final vMajor = (packed >> 22) & 0x7F;
  final vMinor = (packed >> 12) & 0x3FF;
  final vPatch = packed & 0xFFF;
  if (vMajor != major) return vMajor > major;
  if (vMinor != minor) return vMinor > minor;
  return vPatch >= patch;
}

/// Parse Adreno version from device string like "Adreno (TM) 630".
@visibleForTesting
int? parseAdrenoVersion(String device) {
  final match = RegExp(r'Adreno.*?(\d+)').firstMatch(device);
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

/// Check if PowerVR device is pre-BXE generation (Rogue, AXE, AXM, AXT).
///
/// BXE and later (BXM, BXS, BXT, CXT, DXT) are allowed.
@visibleForTesting
bool isPowerVRPreBXE(String device) {
  // If device string contains a B-series or later identifier, it's allowed.
  if (RegExp(r'[BCD]X[EMST]').hasMatch(device)) return false;
  // Otherwise assume it's a pre-B Rogue/AX series — blocked.
  return true;
}
