import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/registration_terms_and_conditions.dart';
import '../../core/theme/app_theme.dart';
import '../controllers/participant_controller.dart';
import 'pinned_scroll_views.dart';

class RegistrationTermsSection extends StatelessWidget {
  final ParticipantController controller;
  final bool isMobile;

  const RegistrationTermsSection({
    super.key,
    required this.controller,
    required this.isMobile,
  });

  static Future<void> showFullTermsDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final screenHeight = MediaQuery.sizeOf(dialogContext).height;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            RegistrationTermsAndConditions.title,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: screenHeight * 0.65,
            child: PinnedVerticalScrollView(
              alwaysShowScrollbar: true,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final paragraph
                        in RegistrationTermsAndConditions.fullTextParagraphs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          paragraph,
                          style: Theme.of(dialogContext).textTheme.bodyMedium,
                        ),
                      ),
                  ],
                ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: isMobile ? 14 : 15,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(RegistrationTermsAndConditions.title, style: labelStyle),
            const Text(
              ' *',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(
          () => CheckboxListTile(
            value: controller.termsAccepted.value,
            onChanged: (value) {
              controller.termsAccepted.value = value ?? false;
              if (controller.termsAccepted.value) {
                controller.showTermsError.value = false;
              }
              controller.validateRegistrationFormOnFieldChange();
            },
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppTheme.primaryColor,
            title: Text(
              RegistrationTermsAndConditions.agreementSummary,
              style: TextStyle(fontSize: isMobile ? 12 : 13),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: InkWell(
            onTap: () => showFullTermsDialog(context),
            child: Text(
              'click here',
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                color: AppTheme.primaryColor,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        Obx(() {
          if (!controller.showTermsError.value) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: 4, left: 16),
            child: Text(
              'Please accept the terms & conditions to continue',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: isMobile ? 11 : 12,
              ),
            ),
          );
        }),
      ],
    );
  }
}
