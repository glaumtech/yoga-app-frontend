import 'package:flutter/material.dart';

/// A reusable widget for form labels with optional hint text
///
/// This widget displays a bold label text and optionally shows a hint text
/// below it with reduced line height for compact display.
class FormLabelWithHint extends StatelessWidget {
  /// The main label text (required)
  final String label;

  /// Optional hint text to display below the label
  final String? hintText;

  /// Custom label text style (optional)
  final TextStyle? labelStyle;

  /// Custom hint text style (optional)
  final TextStyle? hintStyle;

  /// Spacing between label and hint text
  final double? hintSpacing;

  /// Spacing after the entire label section
  final double? bottomSpacing;

  const FormLabelWithHint({
    super.key,
    required this.label,
    this.hintText,
    this.labelStyle,
    this.hintStyle,
    this.hintSpacing,
    this.bottomSpacing = 3,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              labelStyle ??
              Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 14 : 16,
                height: 1.2,
                color: Colors.grey[800],
              ),
        ),
        if (hintText != null && hintText!.isNotEmpty) ...[
          SizedBox(height: hintSpacing ?? (isMobile ? 4 : 3)),
          Text(
            hintText!,
            style:
                hintStyle ??
                TextStyle(
                  fontSize: isMobile ? 12 : 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                  height: isMobile ? 1.35 : 1.3,
                ),
          ),
        ],
        if (bottomSpacing != null) SizedBox(height: bottomSpacing),
      ],
    );
  }
}
