import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:yoga_champ/services/api_service.dart';
import '../../../data/models/event_model.dart';

class EventBannerImage extends StatelessWidget {
  final EventModel event;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const EventBannerImage({
    super.key,
    required this.event,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: ImageStreamingService().getEventBannerUrl(
          int.parse(event.id!),
        ),
        width: width,
        height: height,
        fit: fit,
        httpHeaders: ImageStreamingService().getHeaders(),
        maxWidthDiskCache: 1920,
        maxHeightDiskCache: 1080,
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: borderRadius,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, color: Colors.grey, size: 48),
                const SizedBox(height: 8),
                Text(
                  'Image not available',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
