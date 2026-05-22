import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

/// Backend-generated registration QR PNG for a competition.
class CompetitionRegistrationQrImage extends StatelessWidget {
  final String competitionId;
  final double size;
  final BorderRadius? borderRadius;

  const CompetitionRegistrationQrImage({
    super.key,
    required this.competitionId,
    this.size = 100,
    this.borderRadius,
  });

  static String qrImageUrl(String competitionId) {
    return '${BaseUrl.baseUrl}${EndPoints.competitionRegistrationQr(competitionId)}';
  }

  @override
  Widget build(BuildContext context) {
    if (competitionId.isEmpty) {
      return SizedBox(width: size, height: size);
    }

    final radius = borderRadius ?? BorderRadius.circular(4);

    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        qrImageUrl(competitionId),
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: Icon(
            Icons.qr_code_2,
            size: size * 0.45,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}
