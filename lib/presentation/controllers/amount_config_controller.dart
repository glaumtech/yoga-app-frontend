import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/utils/snackbar_helper.dart';
import '../../data/repositories/payment_repository.dart';
import 'competition_controller.dart';

class AmountConfigController extends GetxController {
  final PaymentRepository _repo = PaymentRepository();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool extraFeeIncludedForCompetition = true.obs;

  final TextEditingController asanasFeeController = TextEditingController();
  final TextEditingController challengeFeeController = TextEditingController();
  final TextEditingController gatewayPercentController = TextEditingController();
  final TextEditingController platformPercentController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  @override
  void onClose() {
    // Do not dispose TextEditingControllers here — Settings TabBarView can delete
    // this controller while AmountConfig TextFields are still unmounting, which
    // triggers "TextEditingController was used after being disposed".
    super.onClose();
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  String _formatPercent(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  double? _parseAmount(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  void _applyResponse(Map<String, dynamic> data) {
    asanasFeeController.text =
        _formatAmount(_toDouble(data['asanasMaintenanceFee']));
    challengeFeeController.text =
        _formatAmount(_toDouble(data['challengeMaintenanceFee']));
    gatewayPercentController.text =
        _formatPercent(_toDouble(data['paymentGatewayFeePercent'], fallback: 3));
    platformPercentController.text =
        _formatPercent(_toDouble(data['platformFeePercent'], fallback: 3));
    extraFeeIncludedForCompetition.value =
        data['extraFeeIncludedForCompetition'] == true;
  }

  Future<void> loadSettings() async {
    if (isLoading.value) return;
    try {
      isLoading.value = true;
      final res = await _repo.getPaymentSettings();
      if (!res.success || res.data == null) {
        SnackbarHelper.showErrorMessage(
          res.message ?? 'Failed to load payment settings',
        );
        return;
      }
      _applyResponse(res.data!);
    } catch (e) {
      SnackbarHelper.showErrorMessage(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveSettings() async {
    if (isSaving.value) return;
    final asanas = _parseAmount(asanasFeeController.text);
    final challenge = _parseAmount(challengeFeeController.text);
    final gatewayPct = _parseAmount(gatewayPercentController.text);
    final platformPct = _parseAmount(platformPercentController.text);

    if (asanas == null || asanas <= 0) {
      SnackbarHelper.showErrorMessage('Asanas fee must be greater than zero');
      return;
    }
    if (challenge == null || challenge <= 0) {
      SnackbarHelper.showErrorMessage('Challenge fee must be greater than zero');
      return;
    }
    if (gatewayPct == null || gatewayPct < 0 || gatewayPct > 100) {
      SnackbarHelper.showErrorMessage(
        'Gateway fee percent must be between 0 and 100',
      );
      return;
    }
    if (platformPct == null || platformPct < 0 || platformPct > 100) {
      SnackbarHelper.showErrorMessage(
        'Platform fee percent must be between 0 and 100',
      );
      return;
    }

    try {
      isSaving.value = true;
      final res = await _repo.updatePaymentSettings(
        asanasMaintenanceFee: asanas,
        challengeMaintenanceFee: challenge,
        extraFeeIncludedForCompetition: extraFeeIncludedForCompetition.value,
        paymentGatewayFeePercent: gatewayPct,
        platformFeePercent: platformPct,
      );
      if (!res.success) {
        SnackbarHelper.showErrorMessage(
          res.message ?? 'Failed to save payment settings',
        );
        return;
      }
      if (res.data != null) {
        _applyResponse(res.data!);
      }
      if (Get.isRegistered<CompetitionController>()) {
        await Get.find<CompetitionController>().loadOnDemandContext();
      }
      SnackbarHelper.showSuccessMessage('Payment settings saved');
    } catch (e) {
      SnackbarHelper.showErrorMessage(e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }
}
