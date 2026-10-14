import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

/// Standard notice that payments are accepted in Indian Rupees only.
class PaymentInrOnlyNotice extends StatelessWidget {
  const PaymentInrOnlyNotice({
    super.key,
    this.margin = const EdgeInsets.only(top: 10),
  });

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 18,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppConstants.paymentInrOnlyMessage,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
