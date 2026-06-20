import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/participant_model.dart';

/// Payment-success receipt card (matches post-registration confirmation UI).
class ParticipantPaymentReceiptView extends StatelessWidget {
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color pageBackground = Color(0xFF333333);

  final ParticipantModel? participant;
  final DateTime? timestamp;
  final bool includeOuterBackground;

  const ParticipantPaymentReceiptView({
    super.key,
    this.participant,
    this.timestamp,
    this.includeOuterBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final ts = timestamp ?? participant?.createdAt ?? DateTime.now();
    final dateFormat = DateFormat('dd-MM-yyyy');
    final timeFormat = DateFormat('HH:mm:ss');
    final hasParticipant = participant != null;
    final hasPayment =
        hasParticipant && _hasPaymentDetails(participant!);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: successGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 42),
        ),
        const SizedBox(height: 20),
        Text(
          hasPayment ? 'Payment successful!' : 'Registration successful!',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _orderIdLabel(participant),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              _detailRow('Date', dateFormat.format(ts)),
              _detailRow('Time', timeFormat.format(ts)),
              if (hasParticipant) ...[
                if (_text(participant!.registrationNo).isNotEmpty)
                  _detailRow(
                    'Registration No',
                    _text(participant!.registrationNo),
                    emphasizeValue: true,
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
      ],
    );

    if (!includeOuterBackground) {
      return content;
    }

    return ColoredBox(
      color: pageBackground,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
        child: content,
      ),
    );
  }

  static String _text(String? value) => value?.trim() ?? '';

  static String _orderIdLabel(ParticipantModel? p) {
    if (p == null) return 'Reference: —';
    final paymentId = _text(p.razorpayPaymentId);
    if (paymentId.isNotEmpty) return 'Order id: $paymentId';
    final orderId = _text(p.razorpayOrderId);
    if (orderId.isNotEmpty) return 'Order id: $orderId';
    final regNo = _text(p.registrationNo);
    if (regNo.isNotEmpty) return 'Registration no: $regNo';
    return 'Reference: —';
  }

  static bool _hasPaymentDetails(ParticipantModel p) {
    return _text(p.paymentMode).isNotEmpty ||
        _text(p.paymentStatus).isNotEmpty ||
        p.amount != null ||
        _text(p.razorpayPaymentId).isNotEmpty;
  }

  static String _formatPaymentMode(ParticipantModel p) {
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

  static String _formatPaymentStatus(String status) {
    final normalized = status.trim().toUpperCase();
    if (normalized == 'PAID' ||
        normalized == 'SUCCESS' ||
        normalized == 'SUCCESSFUL') {
      return 'Successful';
    }
    return status;
  }

  Widget _detailRow(
    String label,
    String value, {
    bool emphasizeValue = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
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
}
