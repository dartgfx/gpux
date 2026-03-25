import 'package:flutter/widgets.dart';
import 'package:gpux/gpux.dart';

import 'controller.dart';

/// Provides a shared [GpuController] to descendant widgets.
///
/// Wrapping a subtree with `DefaultGpu` ensures all [GpuView] widgets
/// share a single GPU device instead of each creating their own.
///
/// ```dart
/// DefaultGpu(
///   child: Column(children: [
///     GpuView(renderer: sceneRenderer),
///     GpuView(renderer: minimapRenderer), // shares the same device
///   ]),
/// )
/// ```
class DefaultGpu extends StatefulWidget {
  const DefaultGpu({
    super.key,
    this.features = const {},
    this.instance,
    required this.child,
  });

  /// GPU features to request during device initialization.
  final Set<GpuFeatureName> features;

  /// Custom GPU instance (e.g., a debug-enabled backend).
  ///
  /// If omitted, uses the cross-platform default.
  final GpuInstance? instance;

  /// The widget below this in the tree.
  final Widget child;

  /// Returns the [GpuController] from the nearest [DefaultGpu] ancestor.
  ///
  /// Throws if no [DefaultGpu] exists above [context].
  static GpuController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'No DefaultGpu found in the widget tree.');
    return controller!;
  }

  /// Returns the [GpuController] from the nearest [DefaultGpu] ancestor,
  /// or `null` if none exists.
  static GpuController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_DefaultGpuScope>()
        ?.controller;
  }

  @override
  State<DefaultGpu> createState() => _DefaultGpuState();
}

class _DefaultGpuState extends State<DefaultGpu> {
  GpuController? _controller;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller = GpuController(instance: widget.instance);
    await controller.initialize(features: widget.features);
    if (!mounted) {
      controller.dispose();
      return;
    }
    setState(() => _controller = controller);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }
    return _DefaultGpuScope(
      controller: controller,
      child: widget.child,
    );
  }
}

class _DefaultGpuScope extends InheritedWidget {
  const _DefaultGpuScope({
    required this.controller,
    required super.child,
  });

  final GpuController controller;

  @override
  bool updateShouldNotify(_DefaultGpuScope oldWidget) =>
      controller != oldWidget.controller;
}
