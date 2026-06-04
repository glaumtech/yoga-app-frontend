import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// In-app webcam preview and capture for web and desktop platforms.
class WebcamCaptureDialog extends StatefulWidget {
  const WebcamCaptureDialog({super.key});

  static Future<XFile?> show(BuildContext context) {
    return showDialog<XFile?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const WebcamCaptureDialog(),
    );
  }

  @override
  State<WebcamCaptureDialog> createState() => _WebcamCaptureDialogState();
}

class _WebcamCaptureDialogState extends State<WebcamCaptureDialog> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _initializing = true;
  bool _capturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  int _preferredCameraIndex(List<CameraDescription> cameras) {
    final backIndex = cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );
    if (backIndex >= 0) return backIndex;
    return 0;
  }

  Future<void> _initCamera({int? cameraIndex}) async {
    setState(() {
      _initializing = true;
      _error = null;
    });

    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
      }
      if (_cameras.isEmpty) {
        setState(() {
          _error = 'No camera found on this device.';
          _initializing = false;
        });
        return;
      }

      _cameraIndex = cameraIndex ?? _preferredCameraIndex(_cameras);

      await _controller?.dispose();
      _controller = null;

      final controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error =
            'Could not access the camera. Allow camera permission in the browser or system settings.\n\n$e';
        _initializing = false;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _initializing || _capturing) return;
    final nextIndex = (_cameraIndex + 1) % _cameras.length;
    await _initCamera(cameraIndex: nextIndex);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) {
      return;
    }

    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(file);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _error = 'Failed to capture photo: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _buildPreview();

    return AlertDialog(
      title: const Text('Take photo'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(aspectRatio: 4 / 3, child: preview),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Colors.red[700], fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _capturing ? null : () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        FilledButton(
          onPressed:
              _controller != null &&
                  _controller!.value.isInitialized &&
                  !_capturing &&
                  _error == null
              ? _capture
              : null,
          child: _capturing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('CAPTURE'),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    if (_initializing) {
      return const DecoratedBox(
        decoration: BoxDecoration(color: Colors.black12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final controller = _controller;
    if (_error != null || controller == null || !controller.value.isInitialized) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(Icons.videocam_off, size: 48, color: Colors.grey[600]),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CameraPreview(controller),
        ),
        if (_cameras.length > 1)
          Positioned(
            right: 8,
            bottom: 8,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Switch camera',
                onPressed: _initializing || _capturing ? null : _switchCamera,
                icon: const Icon(Icons.cameraswitch, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
