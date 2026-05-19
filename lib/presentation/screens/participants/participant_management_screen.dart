import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/participant_controller.dart';
import '../../widgets/admin_sidebar_layout.dart';
import '../../widgets/toggle_button_group.dart';
import 'participants_list_screen.dart';
import 'participant_registration_form_screen.dart';
import 'bulk_registration_screen.dart';

class ParticipantManagementScreen extends StatefulWidget {
  const ParticipantManagementScreen({super.key});

  @override
  State<ParticipantManagementScreen> createState() =>
      _ParticipantManagementScreenState();
}

class _ParticipantManagementScreenState
    extends State<ParticipantManagementScreen> {
  late final ParticipantController participantController;

  @override
  void initState() {
    super.initState();
    participantController = Get.put(ParticipantController());
  }

  @override
  void dispose() {
    if (Get.isRegistered<ParticipantController>()) {
      participantController.resetBulkRegistrationForm();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return AdminSidebarLayout(
      title: 'PARTICIPANTS',
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.05),
              Colors.white,
              AppTheme.secondaryColor.withOpacity(0.03),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: isMobile ? 8 : 10,
                  bottom: 0,
                  left: isMobile ? 16 : 24,
                  right: isMobile ? 16 : 24,
                ),
                child: Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Obx(
                        () => ToggleButtonGroup(
                          options: [
                            ToggleButtonOption(
                              label: participantController.isViewMode.value
                                  ? '+ VIEW'
                                  : participantController.isEditMode
                                  ? '+ EDIT'
                                  : '+ CREATE',
                            ),
                            const ToggleButtonOption(label: '≡ LIST'),
                          ],
                          selectedIndex: participantController.isListView.value
                              ? 1
                              : 0,
                          onTap: (index) {
                            if (index == 1) {
                              // Switching to list view - reset forms
                              if (participantController.isEditMode ||
                                  participantController.isViewMode.value) {
                                participantController.resetForm();
                              }
                              participantController.resetBulkRegistrationForm();
                            } else {
                              // Switching to create view - always reset form to ensure clean state
                              participantController.resetForm();
                            }
                            participantController.toggleViewMode(index == 1);
                          },
                        ),
                      ),
                      // Single/Bulk toggle — create only (not edit/view)
                      if (!participantController.isListView.value &&
                          !participantController.isEditMode &&
                          !participantController.isViewMode.value)
                        ToggleButtonGroup(
                          options: const [
                            ToggleButtonOption(label: 'SINGLE'),
                            ToggleButtonOption(label: 'BULK'),
                          ],
                          selectedIndex: participantController.isBulkMode.value
                              ? 1
                              : 0,
                          onTap: (index) =>
                              participantController.isBulkMode.value =
                                  index == 1,
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Obx(
                  () => participantController.isListView.value
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: const ParticipantsListScreen(),
                        )
                      : SingleChildScrollView(
                          padding: EdgeInsets.all(isMobile ? 16 : 16),
                          child:
                              !participantController.isEditMode &&
                                  !participantController.isViewMode.value &&
                                  participantController.isBulkMode.value
                              ? const BulkRegistrationScreen()
                              : const ParticipantRegistrationFormScreen(),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
