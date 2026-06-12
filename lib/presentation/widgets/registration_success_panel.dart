import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/participant_model.dart';
import '../controllers/participant_controller.dart';
import 'registration_event_venue_card.dart';

/// Post-registration confirmation with details and PDF download.
class RegistrationSuccessPanel extends StatelessWidget {
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Registration Successful',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                ),
              ),
              if (participant != null &&
                  participant!.id != null &&
                  participant!.id!.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.picture_as_pdf_outlined,
                    color: Colors.blue.shade800,
                  ),
                  tooltip: 'Download registration details (PDF)',
                  onPressed: () => participantController
                      .downloadParticipantRegistrationDetails(participant!.id!),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hasParticipant
                ? 'Your registration details are below.'
                : 'Saved successfully.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
          if (participant != null) ...[
            const SizedBox(height: 16),
            RegistrationEventVenueCard(
              competitionName: participant!.competitionName,
              eventDateDisplay: participant!.competitionEventDateDisplay,
              eventTimeDisplay: participant!.competitionEventTimeDisplay,
              venueAddress: participant!.competitionAddress,
              venueMapsUrl: participant!.venueMapsUrl,
              venueMapPreviewUrl: participant!.venueMapPreviewUrl,
              combineDateAndTime: true,
              compact: true,
            ),
            const SizedBox(height: 16),
            _infoRow('Registration No', participant!.registrationNo ?? 'N/A'),
            _infoRow('Participant Name', participant!.participantName),
            _infoRow('Gender', participant!.gender),
            _infoRow('Category', participant!.category),
            _infoRow('Standard/Group', participant!.standard),
            _infoRow('School', participant!.schoolName),
            _infoRow('Yoga Master', _displayYogaMaster(participant!)),
            if (participant!.yogaMasterContact.trim().isNotEmpty)
              _infoRow('Yoga Master Contact', participant!.yogaMasterContact),
            _infoRow(
              'Spot Registration',
              participant!.isSpotRegistration ? 'YES' : 'NO',
            ),
            if (_hasPaymentDetails(participant!)) ...[
              const SizedBox(height: 8),
              Text(
                'Payment',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              if (_text(participant!.paymentMode).isNotEmpty)
                _infoRow('Payment Mode', _formatPaymentMode(participant!)),
              if (_text(participant!.paymentStatus).isNotEmpty)
                _infoRow('Payment Status', _text(participant!.paymentStatus)),
              if (participant!.amount != null)
                _infoRow('Amount', '₹${participant!.amount!.toStringAsFixed(0)}'),
              if (_text(participant!.razorpayPaymentId).isNotEmpty)
                _infoRow(
                  'Transaction ID',
                  _text(participant!.razorpayPaymentId),
                ),
            ],
          ],
          if (onRegisterAnother != null) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRegisterAnother,
              icon: const Icon(Icons.person_add_outlined),
              label: Text(registerAnotherLabel ?? 'Register Another'),
            ),
          ],
        ],
      ),
    );
  }

  String _text(String? value) => value?.trim() ?? '';

  String _displayYogaMaster(ParticipantModel p) {
    final name = p.yogaMasterName.trim();
    if (name.isNotEmpty) return name;
    return 'N/A';
  }

  bool _hasPaymentDetails(ParticipantModel p) {
    return _text(p.paymentMode).isNotEmpty ||
        _text(p.paymentStatus).isNotEmpty ||
        p.amount != null ||
        _text(p.razorpayPaymentId).isNotEmpty;
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
