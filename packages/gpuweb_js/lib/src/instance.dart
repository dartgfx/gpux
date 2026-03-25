import 'dart:js_interop';

import 'package:gpuweb/gpuweb.dart';

import 'convert.dart';
import 'js/webgpu.dart';
import 'adapter.dart';

export 'canvas.dart' show GpuCanvasAlphaMode;

/// Web implementation of [GpuInstance].
///
/// On the web, `navigator.gpu` is the entry point:
///
/// ```dart
/// final instance = WebGpu();
/// final adapter = await instance.requestAdapter();
/// ```
class WebGpu implements GpuInstance {
  WebGpu() : _js = jsNavigator.gpu {
    if (_js == null) {
      throw UnsupportedError('WebGPU is not supported in this browser.');
    }
  }

  final JsGpu? _js;

  @override
  GpuTextureFormat get preferredCanvasFormat =>
      textureFormatFromJs(_js!.getPreferredCanvasFormat());

  @override
  Set<GpuWgslLanguageFeatureName> get wgslLanguageFeatures {
    final jsFeatures = JsSetLike(_js!.wgslLanguageFeatures);
    final result = <GpuWgslLanguageFeatureName>{};
    for (final f in GpuWgslLanguageFeatureName.values) {
      if (jsFeatures.has(wgslFeatureToJs(f))) {
        result.add(f);
      }
    }
    return result;
  }

  @override
  Future<WebGpuAdapter> requestAdapter([
    GpuRequestAdapterOptions options = const GpuRequestAdapterOptions(),
  ]) async {
    final jsOptions = <String, Object?>{};
    if (options.powerPreference != null) {
      jsOptions['powerPreference'] = powerPreferenceToJs(
        options.powerPreference!,
      );
    }
    if (options.forceFallbackAdapter) {
      jsOptions['forceFallbackAdapter'] = true;
    }
    if (options.featureLevel != 'core') {
      jsOptions['featureLevel'] = options.featureLevel;
    }

    final jsOpts = jsOptions.isEmpty ? null : jsOptions.jsify() as JSObject;
    final jsAdapter = await _js!.requestAdapter(jsOpts).toDart;
    if (jsAdapter == null) {
      throw StateError('No GPU adapter available.');
    }
    return WebGpuAdapter(jsAdapter);
  }
}
