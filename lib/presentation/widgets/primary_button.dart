import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Future<void> Function()? onPressedAsync;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double? width;
  final double? height;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.onPressedAsync,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: width,
      height: height ?? 48,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading
                  ? null
                  : (onPressedAsync != null
                        ? () async {
                            try {
                              await onPressedAsync!();
                            } catch (error) {
                              debugPrint('Error in onPressedAsync: $error');
                            }
                          }
                        : onPressed),
              child: _buildButtonContent(context),
            )
          : ElevatedButton(
              onPressed: isLoading
                  ? null
                  : (onPressedAsync != null
                        ? () async {
                            try {
                              await onPressedAsync!();
                            } catch (error) {
                              debugPrint('Error in onPressedAsync: $error');
                            }
                          }
                        : onPressed),
              child: _buildButtonContent(context),
            ),
    );

    return button;
  }

  Widget _buildButtonContent(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          if (text.trim().isNotEmpty) ...[const SizedBox(width: 8), Text(text)],
        ],
      );
    }

    return Text(text);
  }
}
