import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_theme.dart';

/// Streams an uploaded MP4 from [url] inside a dialog. The server supports
/// HTTP Range, so playback starts after the first few seconds are buffered
/// and seeking fetches only the needed part.
class SavedVideoPreviewDialog extends StatefulWidget {
  final String url;
  final String title;
  final VoidCallback? onDownload;

  const SavedVideoPreviewDialog({
    super.key,
    required this.url,
    required this.title,
    this.onDownload,
  });

  static Future<void> show(
    BuildContext context, {
    required String url,
    required String title,
    VoidCallback? onDownload,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => SavedVideoPreviewDialog(
        url: url,
        title: title,
        onDownload: onDownload,
      ),
    );
  }

  @override
  State<SavedVideoPreviewDialog> createState() =>
      _SavedVideoPreviewDialogState();
}

class _SavedVideoPreviewDialogState extends State<SavedVideoPreviewDialog> {
  late final VideoPlayerController _player;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..addListener(_onTick);
    _init();
  }

  Future<void> _init() async {
    try {
      await _player.initialize();
      if (!mounted) return;
      setState(() {});
      await _player.play();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'This video cannot be played here. Use Download to watch it '
              'on your device.',
        );
      }
    }
  }

  void _onTick() {
    if (!mounted) return;
    final err = _player.value.errorDescription;
    if (err != null && _error == null) {
      _error =
          'This video cannot be played here. Use Download to watch it on '
          'your device.';
    }
    setState(() {});
  }

  @override
  void dispose() {
    _player.removeListener(_onTick);
    _player.dispose();
    super.dispose();
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final value = _player.value;
    final ready = value.isInitialized && _error == null;
    final screen = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: screen.height * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                fit: FlexFit.loose,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildBody(screen),
                ),
              ),
              if (ready) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: value.isPlaying ? 'Pause' : 'Play',
                        onPressed: () =>
                            value.isPlaying ? _player.pause() : _player.play(),
                        icon: Icon(
                          value.isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_fill,
                          color: AppTheme.primaryColor,
                          size: 32,
                        ),
                      ),
                      Expanded(
                        child: VideoProgressIndicator(
                          _player,
                          allowScrubbing: true,
                          colors: VideoProgressColors(
                            playedColor: AppTheme.primaryColor,
                            bufferedColor: Colors.white24,
                            backgroundColor: Colors.white10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${_fmt(value.position)} / ${_fmt(value.duration)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (widget.onDownload != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: widget.onDownload,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                      ),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(Size screen) {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
      );
    }
    final value = _player.value;
    if (!value.isInitialized) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'Loading video...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }
    final aspect = value.aspectRatio;
    return ConstrainedBox(
      // Portrait videos would otherwise overflow the screen height.
      constraints: BoxConstraints(maxHeight: screen.height * 0.65),
      child: Center(
        child: AspectRatio(
          aspectRatio: aspect > 0 ? aspect : 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: () =>
                      value.isPlaying ? _player.pause() : _player.play(),
                  child: VideoPlayer(_player),
                ),
                if (value.isBuffering)
                  const CircularProgressIndicator(strokeWidth: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
