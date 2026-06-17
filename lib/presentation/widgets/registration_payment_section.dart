import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/competition_model.dart';
import '../controllers/competition_controller.dart';
import '../controllers/participant_controller.dart';

/// Online registration fee summary for On Demand (pay-per-participant) competitions.
class RegistrationPaymentSection extends StatelessWidget {
  final ParticipantController participantController;
  final HomeCompetitionModel? homeCompetition;
  final CompetitionController? competitionController;
  final int? categoryId;
  final bool isMobile;

  const RegistrationPaymentSection({
    super.key,
    required this.participantController,
    this.homeCompetition,
    this.competitionController,
    this.categoryId,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!_hasCategoryFee()) {
      return const SizedBox.shrink();
    }

    final open = homeCompetition?.registrationOpen ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Registration fee',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (!open)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Registration opens after the organizer pays the maintenance fee.',
            ),
          )
        else ...[
          Obx(() {
            final fee = _resolveCategoryFee();
            if (fee == null || fee <= 0) return const SizedBox.shrink();
            final total = _resolveTotalPayable(fee);
            return Text(
              'Total payable: ₹${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            );
          }),
          const SizedBox(height: 8),
          const Text(
            'Payment is collected online when you click Pay & Register Now.',
            style: TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ],
    );
  }

  double _resolveTotalPayable(double baseFee) {
    final comp = competitionController;
    if (comp != null) {
      // Touch observables so Obx rebuilds when on-demand fee settings load.
      comp.onDemandExtraFeeForParticipantReg.value;
      comp.onDemandPaymentGatewayFeePercent.value;
      comp.onDemandPlatformFeePercent.value;
      return comp.calculateOnDemandTotalWithFees(
        baseFee,
        forParticipantRegistration: true,
      );
    }
    return baseFee;
  }

  bool _hasCategoryFee() {
    final fee = _resolveCategoryFee();
    return fee != null && fee > 0;
  }

  double? _resolveCategoryFee() {
    if (categoryId == null) return null;
    final compController = competitionController;
    final eventId = participantController.selectedEventId.value;
    if (compController != null && eventId.isNotEmpty) {
      final fee = compController.resolveCategoryFeeRupees(eventId, categoryId!);
      return fee > 0 ? fee : null;
    }
    if (homeCompetition != null) {
      final byId = homeCompetition!.categoryAmounts[categoryId.toString()];
      if (byId != null && byId > 0) return byId;
    }
    return null;
  }
}
