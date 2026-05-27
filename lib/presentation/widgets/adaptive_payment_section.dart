import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/app_config.dart';
import '../../data/models/competition_model.dart';
import '../controllers/competition_controller.dart';
import '../controllers/participant_controller.dart';

/// Payment UI that adapts to organization payment model (Models 1–2 manual, Model 3 online).
class AdaptivePaymentSection extends StatelessWidget {
  final ParticipantController controller;
  final HomeCompetitionModel? homeCompetition;
  final CompetitionController? competitionController;
  final int? categoryId;
  final bool isMobile;

  const AdaptivePaymentSection({
    super.key,
    required this.controller,
    this.homeCompetition,
    this.competitionController,
    this.categoryId,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final model = homeCompetition?.paymentModel ?? 'ORG_SUBSCRIPTION';
    if (model == 'PAY_PER_PARTICIPANT') {
      return _buildOnlineSection(context);
    }
    return _buildManualSection(context);
  }

  Widget _buildManualSection(BuildContext context) {
    final fee = _resolveCategoryFee();
    final qrUrl = homeCompetition?.manualPaymentQrUrl;
    final upi = homeCompetition?.manualPaymentUpiId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        if (fee != null && fee > 0)
          Text(
            'Amount: ₹${fee.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        const SizedBox(height: 12),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('GPay (UPI/QR)'),
                  value: 'GPAY',
                  groupValue: controller.selectedPaymentMode.value,
                  onChanged: controller.isViewMode.value
                      ? null
                      : (v) => controller.selectedPaymentMode.value = v!,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Cash'),
                  value: 'CASH',
                  groupValue: controller.selectedPaymentMode.value,
                  onChanged: controller.isViewMode.value
                      ? null
                      : (v) => controller.selectedPaymentMode.value = v!,
                ),
              ),
            ],
          ),
        ),
        if (upi != null && upi.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('UPI ID: $upi'),
        ],
        if (qrUrl != null && qrUrl.isNotEmpty) ...[
          const SizedBox(height: 8),
          Image.network(
            '${AppConfig.baseUrl}$qrUrl',
            height: 160,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: controller.isViewMode.value
              ? null
              : () async {
                  final picker = ImagePicker();
                  final file =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (file != null) {
                    controller.paymentProofImage.value = file;
                  }
                },
          icon: const Icon(Icons.upload_file),
          label: Obx(
            () => Text(
              controller.paymentProofImage.value != null
                  ? 'Proof selected'
                  : 'Upload payment proof',
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Registration will remain pending until admin verifies your payment.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildOnlineSection(BuildContext context) {
    final fee = _resolveCategoryFee();
    final open = homeCompetition?.registrationOpen ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        if (!open)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Registration opens after the organizer pays the maintenance fee.',
            ),
          )
        else ...[
          if (fee != null && fee > 0)
            Text(
              'Amount: ₹${fee.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          const SizedBox(height: 8),
          const ListTile(
            leading: Icon(Icons.payment, color: Colors.green),
            title: Text('Online Payment (Razorpay)'),
            subtitle: Text('Pay after submitting the registration form'),
          ),
        ],
      ],
    );
  }

  double? _resolveCategoryFee() {
    if (categoryId != null && competitionController != null) {
      final amounts = competitionController!.categoryAmounts;
      return amounts[categoryId.toString()];
    }
    if (homeCompetition != null && categoryId != null) {
      return homeCompetition!.categoryAmounts[categoryId.toString()];
    }
    return null;
  }
}
