import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../controllers/reports_controller.dart';
import '../../controllers/reports_participants_list_preset.dart';
import '../../controllers/reports_registered_participants_tab_controller.dart';
import 'reports_registered_participants_tab.dart';

/// Popup dialog listing registered participants (opened from dashboard counts).
class ReportsRegisteredParticipantsPopup {
  ReportsRegisteredParticipantsPopup._();

  static Future<void> show(
    BuildContext context, {
    required String competitionId,
    required ReportsParticipantsListPreset preset,
  }) async {
    final reportsController = Get.isRegistered<ReportsController>()
        ? Get.find<ReportsController>()
        : Get.put(ReportsController(), permanent: false);

    final controllerTag =
        'reports_registered_popup_${DateTime.now().millisecondsSinceEpoch}';
    reportsController.pendingParticipantsPreset.value = preset;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _RegisteredParticipantsDialog(
          competitionId: competitionId,
          preset: preset,
          controllerTag: controllerTag,
          reportsController: reportsController,
        );
      },
    );

    if (Get.isRegistered<ReportsRegisteredParticipantsTabController>(
      tag: controllerTag,
    )) {
      Get.delete<ReportsRegisteredParticipantsTabController>(
        tag: controllerTag,
        force: true,
      );
    }
    reportsController.pendingParticipantsPreset.value = null;
  }
}

class _RegisteredParticipantsDialog extends StatelessWidget {
  const _RegisteredParticipantsDialog({
    required this.competitionId,
    required this.preset,
    required this.controllerTag,
    required this.reportsController,
  });

  final String competitionId;
  final ReportsParticipantsListPreset preset;
  final String controllerTag;
  final ReportsController reportsController;

  String? _competitionName() {
    for (final c in reportsController.competitions) {
      if (c.id == competitionId) return c.competitionName;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    final isMobile = mq.width < 600;
    final dialogWidth = math.min(isMobile ? mq.width - 24 : 1080.0, mq.width - 24);
    final dialogHeight = math.min(mq.height * 0.92, mq.height - 24);
    final competitionName = _competitionName();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: AppTheme.primaryColor,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 8 : 16,
                  10,
                  4,
                  10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preset.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          if (competitionName != null &&
                              competitionName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              competitionName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ReportsRegisteredParticipantsTab(
                controllerTag: controllerTag,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
