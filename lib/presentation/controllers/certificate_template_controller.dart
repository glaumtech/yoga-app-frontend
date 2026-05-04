import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/navigation/root_scaffold_messenger_key.dart';
import '../../data/models/certificate_template_model.dart';
import '../../data/repositories/certificate_template_repository.dart';

/// Preset keys sent to the server for PDF background / frame styling.
/// Matches “Test type” style dropdown on template creation screens.
const List<({String value, String label})> kCertificateTypes = [
  (value: 'prize_winner', label: 'Prize winner'),
  (value: 'participation', label: 'Participation'),
  (value: 'bonafide', label: 'Bonafide'),
  (value: 'custom', label: 'Custom'),
];

const List<({String value, String label})> kCertificateBackgroundPresets = [
  (value: 'DEFAULT', label: 'Default (built-in layout)'),
  (value: 'GRADIENT_GOLD', label: 'Gold gradient frame'),
  (value: 'GRADIENT_BLUE', label: 'Blue gradient frame'),
  (value: 'MINIMAL_WHITE', label: 'Minimal white'),
  (value: 'DARK_FRAME', label: 'Dark border frame'),
  (value: 'CUSTOM_IMAGE', label: 'Custom image (URL below)'),
];

class CertificateTemplateController extends GetxController {
  final CertificateTemplateRepository _repo = CertificateTemplateRepository();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString error = ''.obs;

  final RxBool includeStageInWinLine = true.obs;
  final RxBool showDedicatedStageLine = false.obs;

  final TextEditingController subtitle = TextEditingController();
  final TextEditingController organizedByLine = TextEditingController();
  final TextEditingController organizerAssociationLine =
      TextEditingController();
  final TextEditingController coordinatedIntro = TextEditingController();
  final TextEditingController coordinatedName = TextEditingController();
  final TextEditingController signatureLabel1 = TextEditingController();
  final TextEditingController signatureLabel2 = TextEditingController();
  final TextEditingController signatureLabel3 = TextEditingController();
  final TextEditingController signatureLabel4 = TextEditingController();
  final TextEditingController footerText = TextEditingController();

  final TextEditingController subjectPronounMale = TextEditingController();
  final TextEditingController subjectPronounFemale = TextEditingController();
  final TextEditingController subjectPronounOther = TextEditingController();
  final TextEditingController subjectPronounDefault = TextEditingController();

  final TextEditingController possessivePronounMale = TextEditingController();
  final TextEditingController possessivePronounFemale = TextEditingController();
  final TextEditingController possessivePronounOther = TextEditingController();
  final TextEditingController possessivePronounDefault =
      TextEditingController();

  final TextEditingController stageLinePrefix = TextEditingController();

  final TextEditingController backgroundImageUrl = TextEditingController();
  final TextEditingController accentColorHex = TextEditingController();
  final TextEditingController logoImageUrl = TextEditingController();

  final RxString backgroundPreset = 'DEFAULT'.obs;

  final TextEditingController templateName = TextEditingController();
  final RxString certificateType = 'prize_winner'.obs;
  final TextEditingController templateBody = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    subtitle.dispose();
    organizedByLine.dispose();
    organizerAssociationLine.dispose();
    coordinatedIntro.dispose();
    coordinatedName.dispose();
    signatureLabel1.dispose();
    signatureLabel2.dispose();
    signatureLabel3.dispose();
    signatureLabel4.dispose();
    footerText.dispose();
    subjectPronounMale.dispose();
    subjectPronounFemale.dispose();
    subjectPronounOther.dispose();
    subjectPronounDefault.dispose();
    possessivePronounMale.dispose();
    possessivePronounFemale.dispose();
    possessivePronounOther.dispose();
    possessivePronounDefault.dispose();
    stageLinePrefix.dispose();
    backgroundImageUrl.dispose();
    accentColorHex.dispose();
    logoImageUrl.dispose();
    templateName.dispose();
    templateBody.dispose();
    super.onClose();
  }

  void _toastError(String message) {
    final m = message.trim();
    if (m.isEmpty) return;
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(m),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.all(12),
        ),
      );
  }

  void _toastOk(String message) {
    final m = message.trim();
    if (m.isEmpty) return;
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(m),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(12),
        ),
      );
  }

  void _applyModel(CertificateTemplateModel m) {
    subtitle.text = m.subtitle;
    organizedByLine.text = m.organizedByLine;
    organizerAssociationLine.text = m.organizerAssociationLine;
    coordinatedIntro.text = m.coordinatedIntro;
    coordinatedName.text = m.coordinatedName;
    signatureLabel1.text = m.signatureLabel1;
    signatureLabel2.text = m.signatureLabel2;
    signatureLabel3.text = m.signatureLabel3;
    signatureLabel4.text = m.signatureLabel4;
    footerText.text = m.footerText;

    subjectPronounMale.text = m.subjectPronounMale;
    subjectPronounFemale.text = m.subjectPronounFemale;
    subjectPronounOther.text = m.subjectPronounOther;
    subjectPronounDefault.text = m.subjectPronounDefault;

    possessivePronounMale.text = m.possessivePronounMale;
    possessivePronounFemale.text = m.possessivePronounFemale;
    possessivePronounOther.text = m.possessivePronounOther;
    possessivePronounDefault.text = m.possessivePronounDefault;

    stageLinePrefix.text = m.stageLinePrefix;

    includeStageInWinLine.value = m.includeStageInWinLine;
    showDedicatedStageLine.value = m.showDedicatedStageLine;

    backgroundPreset.value = m.backgroundPreset;
    backgroundImageUrl.text = m.backgroundImageUrl;
    accentColorHex.text = m.accentColorHex;
    logoImageUrl.text = m.logoImageUrl;

    templateName.text = m.templateName;
    certificateType.value = kCertificateTypes.any((e) => e.value == m.certificateType)
        ? m.certificateType
        : 'prize_winner';
    templateBody.text = m.templateBody;
  }

  CertificateTemplateModel _readModel() {
    return CertificateTemplateModel(
      subtitle: subtitle.text.trim(),
      organizedByLine: organizedByLine.text.trim(),
      organizerAssociationLine: organizerAssociationLine.text.trim(),
      coordinatedIntro: coordinatedIntro.text.trim(),
      coordinatedName: coordinatedName.text.trim(),
      signatureLabel1: signatureLabel1.text.trim(),
      signatureLabel2: signatureLabel2.text.trim(),
      signatureLabel3: signatureLabel3.text.trim(),
      signatureLabel4: signatureLabel4.text.trim(),
      footerText: footerText.text.trim(),
      subjectPronounMale: subjectPronounMale.text.trim(),
      subjectPronounFemale: subjectPronounFemale.text.trim(),
      subjectPronounOther: subjectPronounOther.text.trim(),
      subjectPronounDefault: subjectPronounDefault.text.trim(),
      possessivePronounMale: possessivePronounMale.text.trim(),
      possessivePronounFemale: possessivePronounFemale.text.trim(),
      possessivePronounOther: possessivePronounOther.text.trim(),
      possessivePronounDefault: possessivePronounDefault.text.trim(),
      includeStageInWinLine: includeStageInWinLine.value,
      showDedicatedStageLine: showDedicatedStageLine.value,
      stageLinePrefix: stageLinePrefix.text.trim(),
      backgroundPreset: backgroundPreset.value,
      backgroundImageUrl: backgroundImageUrl.text.trim(),
      accentColorHex: accentColorHex.text.trim(),
      logoImageUrl: logoImageUrl.text.trim(),
      templateName: templateName.text.trim(),
      certificateType: certificateType.value,
      templateBody: templateBody.text,
    );
  }

  Future<void> load() async {
    if (isLoading.value) return;
    try {
      isLoading.value = true;
      error.value = '';
      final res = await _repo.getTemplate();
      if (!res.success || res.data == null) {
        final msg = res.message ?? 'Failed to load certificate template';
        error.value = msg;
        _toastError(msg);
        return;
      }
      _applyModel(res.data!);
    } catch (e) {
      final msg = e.toString();
      error.value = msg;
      _toastError(msg);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> save() async {
    if (isSaving.value) return;
    try {
      isSaving.value = true;
      error.value = '';
      final res = await _repo.saveTemplate(_readModel());
      if (!res.success) {
        final msg = res.message ?? 'Failed to save certificate template';
        error.value = msg;
        _toastError(msg);
        return;
      }
      if (res.data != null) {
        _applyModel(res.data!);
      }
      _toastOk('Certificate template saved.');
    } catch (e) {
      final msg = e.toString();
      error.value = msg;
      _toastError(msg);
    } finally {
      isSaving.value = false;
    }
  }
}
