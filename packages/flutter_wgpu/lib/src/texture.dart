import 'package:flutter/widgets.dart';

import 'texture_controller.dart';

/// Widget that displays a wgpu-rendered texture.
///
/// Automatically rebuilds when the controller's state changes
/// (e.g., texture becomes available, surface ready state changes).
///
/// Example:
/// ```dart
/// WgpuTextureWidget(
///   controller: myController,
///   placeholder: CircularProgressIndicator(),
/// )
/// ```
class WgpuTextureWidget extends StatelessWidget {
  const WgpuTextureWidget({
    super.key,
    required this.controller,
    this.placeholder,
  });

  /// The controller managing the GPU surface.
  final WgpuTextureController controller;

  /// Widget to show when texture is not yet available.
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final textureId = controller.textureId;
        if (textureId == null) {
          return placeholder ?? const SizedBox.shrink();
        }
        return Texture(textureId: textureId);
      },
    );
  }
}
