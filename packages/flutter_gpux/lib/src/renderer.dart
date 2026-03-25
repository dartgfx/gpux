import 'package:flutter/foundation.dart';

import 'frame.dart';

/// GPU equivalent of [CustomPainter] — override [render] to encode
/// GPU commands into [GpuFrame.targetView].
///
/// Lifecycle: create resources lazily in [render], release in [dispose].
/// Pass [repaint] for continuous rendering, omit for render-once.
///
/// ```dart
/// class MyRenderer extends GpuRenderer {
///   MyRenderer({required super.repaint});
///
///   @override
///   bool render(GpuFrame frame) { /* encode commands */ return true; }
///
///   @override
///   bool shouldUpdate(covariant MyRenderer old) => false;
/// }
/// ```
abstract class GpuRenderer extends Listenable {
  /// Pass [repaint] to drive continuous rendering (e.g. an
  /// [AnimationController]). Without it, renders once.
  const GpuRenderer({
    Listenable? repaint,
  }) : _repaint = repaint;

  final Listenable? _repaint;

  @override
  void addListener(VoidCallback listener) => _repaint?.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _repaint?.removeListener(listener);

  /// Encode GPU commands for one frame.
  ///
  /// Return `true` if content was rendered, `false` to skip presentation.
  bool render(GpuFrame frame);

  /// If `true`, the next frame is skipped before texture acquisition.
  bool get shouldSkipNextFrame => false;

  /// Whether this renderer should replace [oldRenderer] on widget rebuild.
  ///
  /// Return `false` to keep the old renderer and avoid destroying
  /// GPU resources. Like [CustomPainter.shouldRepaint].
  bool shouldUpdate(covariant GpuRenderer oldRenderer);

  /// Release GPU resources (pipelines, buffers, textures).
  void dispose() {}
}
