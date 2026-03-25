/// GPU workarounds for known driver bugs.
///
/// Workarounds are boolean flags that renderers check to avoid broken code
/// paths on specific GPU/driver combinations. Determined at adapter creation
/// time based on vendor ID and device string.
///
/// ```dart
/// // Via GpuController (typical usage):
/// if (!controller.workarounds.brokenMipmapGeneration) {
///   generateMipmaps(texture);
/// }
/// ```
class GpuWorkarounds {
  const GpuWorkarounds({
    this.brokenMipmapGeneration = false,
  });

  /// No workarounds needed (web, or capable native GPU).
  static const none = GpuWorkarounds();

  /// GPU mipmap generation produces corrupt results.
  ///
  /// Affected: All Qualcomm Adreno GPUs.
  /// Mitigation: Use CPU-side mipmap generation instead of GPU compute/blit.
  final bool brokenMipmapGeneration;

  @override
  String toString() => brokenMipmapGeneration
      ? 'GpuWorkarounds(brokenMipmapGeneration)'
      : 'GpuWorkarounds.none';
}
