import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/participant_receipt_image_download.dart';
import '../../data/models/participant_model.dart';
import '../controllers/participant_controller.dart';
import 'participant_payment_receipt_view.dart';

/// Post-registration confirmation styled as a payment success screen.
class RegistrationSuccessPanel extends StatefulWidget {
  static const Color _receiptBlue = Color(0xFF3B59F6);

  final ParticipantController participantController;
  final ParticipantModel? participant;
  final VoidCallback? onRegisterAnother;
  final String? registerAnotherLabel;

  const RegistrationSuccessPanel({
    super.key,
    required this.participantController,
    this.participant,
    this.onRegisterAnother,
    this.registerAnotherLabel,
  });

  @override
  State<RegistrationSuccessPanel> createState() =>
      _RegistrationSuccessPanelState();
}

class _RegistrationSuccessPanelState extends State<RegistrationSuccessPanel> {
  final GlobalKey _receiptCaptureKey = GlobalKey();

  ParticipantModel? get participant => widget.participant;

  @override
  Widget build(BuildContext context) {
    final hasParticipant = participant != null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            RepaintBoundary(
              key: _receiptCaptureKey,
              child: ParticipantPaymentReceiptView(
                participant: participant,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: _actionButton(
                label: 'Download Receipt',
                backgroundColor: RegistrationSuccessPanel._receiptBlue,
                onPressed: hasParticipant
                    ? () => downloadParticipantReceiptImage(
                        context,
                        _receiptCaptureKey,
                        registrationId: participant!.id,
                        registrationNo: participant!.registrationNo,
                      )
                    : null,
              ),
            ),
            if (widget.onRegisterAnother != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: widget.onRegisterAnother,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.person_add_outlined),
                label: Text(widget.registerAnotherLabel ?? 'Register Another'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color backgroundColor,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: onPressed == null
          ? backgroundColor.withValues(alpha: 0.45)
          : backgroundColor,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
