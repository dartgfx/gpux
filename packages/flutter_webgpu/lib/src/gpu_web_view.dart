import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:gpuweb_js/gpuweb_js.dart';

/// Callback for rendering a frame.
typedef GpuWebRenderCallback =
    void Function(WebGpuCanvasContext context, int width, int height);

/// A Flutter widget that displays WebGPU-rendered content via an HTML canvas.
class GpuWebView extends StatefulWidget {
  const GpuWebView({
    super.key,
    required this.device,
    required this.onRender,
    required this.format,
    this.onCreated,
    this.alphaMode = GpuCanvasAlphaMode.opaque,
  });

  /// The WebGPU device for rendering.
  final WebGpuDevice device;

  /// Texture format for the canvas surface.
  final GpuTextureFormat format;

  /// Called each frame to render content.
  final GpuWebRenderCallback onRender;

  /// Called once when the canvas context is created and configured.
  final GpuWebRenderCallback? onCreated;

  /// Alpha compositing mode for the canvas.
  final GpuCanvasAlphaMode alphaMode;

  @override
  State<GpuWebView> createState() => _GpuWebViewState();
}

class _GpuWebViewState extends State<GpuWebView>
    with SingleTickerProviderStateMixin {
  late final String _viewType;
  WebGpuCanvasContext? _context;
  Ticker? _ticker;
  _JsCanvas? _canvas;
  int _width = 0;
  int _height = 0;
  bool _needsOnCreated = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'gpu-web-view-${identityHashCode(this)}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final canvas = _JsCanvas(_createElement('canvas'));
      canvas.style.width = '100%';
      canvas.style.height = '100%';
      _canvas = canvas;
      return canvas as JSObject;
    });
  }

  void _ensureContext() {
    if (_context != null || _canvas == null) return;

    _context = WebGpuCanvasContext.fromCanvas(_canvas!);
    _configureContext();
    _needsOnCreated = widget.onCreated != null;

    _ticker = createTicker(_onTick)..start();
  }

  void _configureContext() {
    _context!.configure(
      device: widget.device,
      format: widget.format,
      alphaMode: widget.alphaMode,
    );
  }

  @override
  void didUpdateWidget(GpuWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_context == null) return;

    if (oldWidget.device != widget.device ||
        oldWidget.format != widget.format ||
        oldWidget.alphaMode != widget.alphaMode) {
      _configureContext();
    }
  }

  void _onTick(Duration elapsed) {
    final ctx = _context;
    if (ctx == null) return;

    // Resize canvas backing store to match CSS layout size.
    final canvas = _canvas!;
    final dpr =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final w = (canvas.clientWidth * dpr).round();
    final h = (canvas.clientHeight * dpr).round();
    if (w != _width || h != _height) {
      _width = w;
      _height = h;
      canvas.width = w;
      canvas.height = h;
    }

    if (_width > 0 && _height > 0) {
      if (_needsOnCreated) {
        _needsOnCreated = false;
        widget.onCreated!(ctx, _width, _height);
      }
      widget.onRender(ctx, _width, _height);
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _context?.unconfigure();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      viewType: _viewType,
      onPlatformViewCreated: (_) => _ensureContext(),
    );
  }
}

// ---------------------------------------------------------------------------
// Minimal DOM bindings
// ---------------------------------------------------------------------------

@JS('document.createElement')
external JSObject _createElement(String tag);

extension type _JsCanvas(JSObject _) implements JSObject {
  external set width(int value);
  external set height(int value);
  external int get clientWidth;
  external int get clientHeight;
  external _JsStyle get style;
}

extension type _JsStyle._(JSObject _) implements JSObject {
  external set width(String value);
  external set height(String value);
}
