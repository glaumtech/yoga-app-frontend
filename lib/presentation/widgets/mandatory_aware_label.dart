import 'package:flutter/material.dart';

/// Reusable form label that highlights required marker `*`.
class MandatoryAwareLabel extends StatelessWidget {
  final String label;
  final TextStyle? style;
  final Color requiredColor;

  const MandatoryAwareLabel({
    super.key,
    required this.label,
    this.style,
    this.requiredColor = const Color(0xFFB00020),
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? Theme.of(context).textTheme.titleMedium;

    if (!label.contains('*')) {
      return Text(label, style: effectiveStyle);
    }

    final markerIndex = label.indexOf('*');
    final before = label.substring(0, markerIndex);
    final after = label.substring(markerIndex + 1);

    return RichText(
      text: TextSpan(
        style: effectiveStyle,
        children: [
          TextSpan(text: before),
          TextSpan(
            text: '*',
            style: effectiveStyle?.copyWith(color: requiredColor),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}
