import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CustomLoader extends StatelessWidget {
  final String? message;
  final Color? color;

  /// When set, shows only a small spinner (no message column). Use inside
  /// tight layouts (e.g. inline button loading) to avoid RenderFlex overflow.
  final double? size;

  const CustomLoader({super.key, this.message, this.color, this.size});

  @override
  Widget build(BuildContext context) {
    final indicatorColor = color ?? AppTheme.primaryColor;

    if (size != null) {
      return Center(
        child: SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class FullScreenLoader extends StatelessWidget {
  final String? message;

  const FullScreenLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.3),
      body: CustomLoader(message: message),
    );
  }
}
