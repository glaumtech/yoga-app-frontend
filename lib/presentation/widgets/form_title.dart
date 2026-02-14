import 'package:flutter/material.dart';

/// Reusable form title widget with consistent styling
/// Matches the style used in bulk registration, user management, and competition screens
class FormTitle extends StatelessWidget {
  final String text;
  final bool isMobile;
  final bool isTablet;

  const FormTitle({
    super.key,
    required this.text,
    required this.isMobile,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Text(
            text,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        SizedBox(height: isMobile ? 24 : 32),
      ],
    );
  }
}
