import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/participant_registration_details_download.dart';
import '../../data/models/participant_model.dart';
import '../controllers/participant_controller.dart';

/// Post-registration confirmation styled as a payment success screen.
class RegistrationSuccessPanel extends StatelessWidget {
  static const Color _successGreen = Color(0xFF4CAF50);
  static const Color _contactOrange = Color(0xFFF27141);
  static const Color _receiptBlue = Color(0xFF3B59F6);
  static const String _contactEmail = 'praveen.sekar@glaum.in';

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
  Widget build(BuildContext context) {
    final hasParticipant = participant != null;
    final hasPayment = hasParticipant && _hasPaymentDetails(participant!);
    final timestamp = hasParticipant ? participant!.createdAt : DateTime.now();
    final dateFormat = DateFormat('dd-MM-yyyy');
    final timeFormat = DateFormat('HH:mm:ss');

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: _successGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 42),
            ),
            const SizedBox(height: 20),
            Text(
              hasPayment ? 'Payment successful!' : 'Registration successful!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _orderIdLabel(participant),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _detailRow('Date', dateFormat.format(timestamp)),
                  _detailRow('Time', timeFormat.format(timestamp)),
                  if (hasParticipant) ...[
                    if (_text(participant!.registrationNo).isNotEmpty)
                      _detailRow(
                        'Registration No',
                        _text(participant!.registrationNo),
                      ),
                    if (_text(participant!.competitionName).isNotEmpty)
                      _detailRow(
                        'Competition',
                        _text(participant!.competitionName),
                      ),
                    _detailRow('Participant', participant!.participantName),
                    if (hasPayment) ...[
                      if (_text(participant!.paymentMode).isNotEmpty)
                        _detailRow(
                          'Payment method',
                          _formatPaymentMode(participant!),
                        ),
                      if (_text(participant!.paymentStatus).isNotEmpty)
                        _detailRow(
                          'Status',
                          _formatPaymentStatus(participant!.paymentStatus!),
                        ),
                      if (participant!.amount != null)
                        _detailRow(
                          'Total amount',
                          '₹${participant!.amount!.toStringAsFixed(0)}',
                          emphasizeValue: true,
                        ),
                    ] else
                      _detailRow('Status', 'Registered'),
                  ] else
                    _detailRow('Status', 'Saved successfully'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    label: 'Need help? Contact Us!',
                    backgroundColor: _contactOrange,
                    onPressed: () => _showContactHelp(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(
                    label: 'Download Receipt',
                    backgroundColor: _receiptBlue,
                    onPressed: _canDownloadReceipt(participant)
                        ? () => downloadParticipantRegistrationDetailsPdf(
                            context,
                            participant!.id!,
                          )
                        : null,
                  ),
                ),
              ],
            ),
            if (onRegisterAnother != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRegisterAnother,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.person_add_outlined),
                label: Text(registerAnotherLabel ?? 'Register Another'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _text(String? value) => value?.trim() ?? '';

  String _orderIdLabel(ParticipantModel? p) {
    if (p == null) return 'Reference: —';
    final paymentId = _text(p.razorpayPaymentId);
    if (paymentId.isNotEmpty) return 'Order id: $paymentId';
    final orderId = _text(p.razorpayOrderId);
    if (orderId.isNotEmpty) return 'Order id: $orderId';
    final regNo = _text(p.registrationNo);
    if (regNo.isNotEmpty) return 'Registration no: $regNo';
    return 'Reference: —';
  }

  bool _hasPaymentDetails(ParticipantModel p) {
    return _text(p.paymentMode).isNotEmpty ||
        _text(p.paymentStatus).isNotEmpty ||
        p.amount != null ||
        _text(p.razorpayPaymentId).isNotEmpty;
  }

  bool _canDownloadReceipt(ParticipantModel? p) {
    return p != null && p.id != null && p.id!.trim().isNotEmpty;
  }

  String _formatPaymentMode(ParticipantModel p) {
    final mode = _text(p.paymentMode);
    switch (mode.toUpperCase()) {
      case 'ONLINE':
        return 'Online (Razorpay)';
      case 'GPAY':
        return 'GPay';
      case 'CASH':
        return 'Cash';
      default:
        return mode;
    }
  }

  String _formatPaymentStatus(String status) {
    final normalized = status.trim().toUpperCase();
    if (normalized == 'PAID' || normalized == 'SUCCESS' || normalized == 'SUCCESSFUL') {
      return 'Successful';
    }
    return status;
  }

  Future<void> _showContactHelp(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: _contactEmail);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open email app. Write to $_contactEmail'),
        ),
      );
    }
  }

  Widget _detailRow(
    String label,
    String value, {
    bool emphasizeValue = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: emphasizeValue ? FontWeight.bold : FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color backgroundColor,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: onPressed == null ? backgroundColor.withValues(alpha: 0.45) : backgroundColor,
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
