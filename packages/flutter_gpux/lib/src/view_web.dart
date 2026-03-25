import 'package:flutter/widgets.dart';
import 'package:flutter_webgpu/flutter_webgpu.dart';

import 'default.dart';
import 'frame.dart';
import 'controller.dart';
import 'renderer.dart';

/// Cross-platform GPU rendering widget (web implementation).
///
/// Only re-renders when the renderer signals via its [Listenable]
/// or when [GpuRenderer.shouldUpdate] returns true on widget rebuild.
///
/// Requires either an explicit [controller] or a [DefaultGpu] ancestor.
///
/// ```dart
/// DefaultGpu(
///   child: GpuView(renderer: MyRenderer()),
/// )
/// ```
class GpuView extends StatefulWidget {
  const GpuView({
    super.key,
    this.controller,
    required this.renderer,
    this.placeholder,
  });

  /// GPU controller providing device and format.
  ///
  /// If omitted, uses the controller from [DefaultGpu] ancestor.
  final GpuController? controller;

  /// Renderer that owns GPU resources and render logic.
  final GpuRenderer renderer;

  /// Widget to show while initializing.
  final Widget? placeholder;

  @override
  State<GpuView> createState() => _GpuViewState();
}

class _GpuViewState extends State<GpuView> {
  GpuRenderer? _renderer;
  GpuFrame? _frame;
  bool _needsRender = true;
  bool _ready = false;
  bool _initCalled = false;

  GpuController get _gpuController =>
      widget.controller ?? DefaultGpu.of(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initCalled) {
      _initCalled = true;
      _init();
    }
  }

  void _init() {
    _renderer = widget.renderer;
    _renderer!.addListener(_markNeedsRender);
    setState(() => _ready = true);
  }

  void _markNeedsRender() {
    _needsRender = true;
  }

  @override
  void didUpdateWidget(GpuView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.renderer != oldWidget.renderer && _renderer != null) {
      if (widget.renderer.shouldUpdate(_renderer!)) {
        _renderer!.removeListener(_markNeedsRender);
        _renderer!.dispose();
        _renderer = widget.renderer;
        _renderer!.addListener(_markNeedsRender);
        _needsRender = true;
      }
    }
  }

  @override
  void dispose() {
    _renderer?.removeListener(_markNeedsRender);
    _renderer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return widget.placeholder ?? const SizedBox.shrink();
    }

    return GpuWebView(
      device: _gpuController.device as WebGpuDevice,
      format: _gpuController.format,
      onRender: (canvasContext, width, height) {
        if (!_needsRender) return;
        if (_renderer!.shouldSkipNextFrame) return;
        _needsRender = false;
        final texture = canvasContext.getCurrentTexture();
        final targetView = texture.createView();
        final frame = _frame ??= GpuFrame(
          device: _gpuController.device,
          format: _gpuController.format,
          targetView: targetView,
          width: width,
          height: height,
        );
        frame
          ..targetView = targetView
          ..width = width
          ..height = height;
        _renderer!.render(frame);
      },
    );
  }
}
