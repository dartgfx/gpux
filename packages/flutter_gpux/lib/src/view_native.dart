import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_wgpu/flutter_wgpu.dart';

import 'default.dart';
import 'frame.dart';
import 'controller.dart';
import 'renderer.dart';
import 'surface.dart';

/// Cross-platform GPU rendering widget (native implementation).
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
  GpuSurface? _surface;
  GpuRenderer? _renderer;
  GpuFrame? _frame;
  String? _error;
  bool _needsRender = true;
  bool _frameScheduled = false;
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

  Future<void> _init() async {
    try {
      // Use actual screen size so Android SurfaceProducer starts at the right
      // dimensions — wgpu's GL backend can't resize the framebuffer after creation.
      final dpr = MediaQuery.devicePixelRatioOf(context);
      final size = MediaQuery.sizeOf(context);
      final screenW = (size.width * dpr).round();
      final screenH = (size.height * dpr).round();
      final surface = await GpuSurface.create(
        device: _gpuController.device,
        width: screenW > 0 ? screenW : null,
        height: screenH > 0 ? screenH : null,
      );
      if (!mounted) {
        surface.dispose();
        return;
      }

      surface.onResized = _renderNow;

      _renderer = widget.renderer;
      _renderer!.addListener(_markNeedsRender);
      final format = surface.format;
      _frame = GpuFrame(
        device: _gpuController.device,
        format: format,
        targetView: surface.textureView,
        width: surface.width,
        height: surface.height,
      );

      setState(() => _surface = surface);
    } catch (e, st) {
      debugPrint('GpuView init error: $e\n$st');
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _markNeedsRender() {
    _needsRender = true;
    _scheduleFrame();
  }

  /// Render immediately — used after resize to fill the new texture
  /// before Flutter composites it.
  void _renderNow() {
    if (!mounted || _surface == null || _renderer == null) return;
    final surface = _surface!;
    final frame = _frame!
      ..targetView = surface.textureView
      ..width = surface.width
      ..height = surface.height;
    if (_renderer!.render(frame)) {
      surface.present();
    }
  }

  void _scheduleFrame() {
    if (_frameScheduled || _surface == null) return;
    _frameScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback(_onFrame);
  }

  void _onFrame(Duration timestamp) {
    _frameScheduled = false;
    if (!mounted || _surface == null || !_needsRender) return;
    _needsRender = false;

    try {
      final surface = _surface!;
      final frame = _frame!
        ..targetView = surface.textureView
        ..width = surface.width
        ..height = surface.height;
      final rendered = _renderer!.render(frame);

      if (rendered) {
        surface.present();
      }
    } catch (e, st) {
      debugPrint('GpuView render error: $e\n$st');
    }
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
        _markNeedsRender();
      }
    }
  }

  @override
  void dispose() {
    _renderer?.removeListener(_markNeedsRender);
    _renderer?.dispose();
    _surface?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text('GPU error: $_error'));
    }

    final surface = _surface;
    if (surface == null) {
      return widget.placeholder ?? const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final w = (constraints.biggest.width * dpr).round();
        final h = (constraints.biggest.height * dpr).round();
        surface.requestResize(w, h);
        return WgpuTextureWidget(
          controller: surface.controller,
          placeholder: widget.placeholder,
        );
      },
    );
  }
}
