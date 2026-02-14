import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'primary_button.dart';
import 'custom_loader.dart';

Widget saveButton({
  required VoidCallback onPressed,
  RxBool? isLoading,
  String text = 'SAVE',
  double? width,
  double? height,
  bool isFullWidth = false,
}) {
  return Builder(
    builder: (context) {
      final screenWidth = MediaQuery.of(context).size.width;
      final isMobile = screenWidth < 600;

      final defaultWidth = isFullWidth
          ? double.infinity
          : (isMobile ? double.infinity : (width ?? 200));
      final defaultHeight = height ?? 48;

      if (isLoading != null) {
        return Obx(
          () => isLoading.value == true
              ? SizedBox(
                  width: defaultWidth,
                  height: defaultHeight,
                  child: const Center(child: CustomLoader()),
                )
              : PrimaryButton(
                  text: text,
                  onPressed: onPressed,
                  width: defaultWidth,
                  height: defaultHeight,
                ),
        );
      } else {
        return PrimaryButton(
          text: text,
          onPressed: onPressed,
          width: defaultWidth,
          height: defaultHeight,
        );
      }
    },
  );
}

Widget cancelButton({
  required VoidCallback onPressed,
  String text = 'CANCEL',
  double? width,
  double? height,
  bool isFullWidth = false,
}) {
  return Builder(
    builder: (context) {
      final screenWidth = MediaQuery.of(context).size.width;
      final isMobile = screenWidth < 600;

      final defaultWidth = isFullWidth
          ? double.infinity
          : (isMobile ? double.infinity : (width ?? 200));
      final defaultHeight = height ?? 48;

      return SizedBox(
        width: defaultWidth,
        height: defaultHeight,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey[700],
            side: BorderSide(color: Colors.grey[400]!),
            padding: EdgeInsets.symmetric(vertical: (defaultHeight - 24) / 2),
          ),
          child: Text(text),
        ),
      );
    },
  );
}
