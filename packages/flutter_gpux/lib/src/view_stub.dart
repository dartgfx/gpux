import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'renderer.dart';

/// Cross-platform GPU rendering widget (unsupported platform stub).
class GpuView extends StatelessWidget {
  const GpuView({
    super.key,
    this.controller,
    required this.renderer,
    this.placeholder,
  });

  final GpuController? controller;
  final GpuRenderer renderer;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    throw UnsupportedError('GPU rendering is not supported on this platform.');
  }
}
