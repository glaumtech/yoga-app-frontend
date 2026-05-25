import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Gallery (browse) and camera actions for profile / participant photo upload.
class PhotoSourceButtons extends StatelessWidget {
  const PhotoSourceButtons({
    super.key,
    required this.onPick,
    this.enabled = true,
    this.showCamera = true,
  });

  final Future<void> Function(ImageSource source) onPick;
  final bool enabled;
  final bool showCamera;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      minimumSize: const Size(0, 36),
    );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: enabled ? () => onPick(ImageSource.gallery) : null,
          icon: const Icon(Icons.upload_file, size: 16),
          label: const Text('BROWSE', style: TextStyle(fontSize: 12)),
          style: buttonStyle,
        ),
        if (showCamera)
          OutlinedButton.icon(
            onPressed: enabled ? () => onPick(ImageSource.camera) : null,
            icon: const Icon(Icons.camera_alt_outlined, size: 16),
            label: const Text('CAMERA', style: TextStyle(fontSize: 12)),
            style: buttonStyle,
          ),
      ],
    );
  }
}
