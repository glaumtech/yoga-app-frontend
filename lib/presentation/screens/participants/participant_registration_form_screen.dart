import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/participant_controller.dart';
import '../../controllers/competition_controller.dart';
import '../../controllers/participant_registration_form_controller.dart';
import '../../controllers/school_controller.dart';
import '../../widgets/form_label_with_hint.dart';
import '../../widgets/form_title.dart';
import '../../widgets/buttons.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../core/utils/storage_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/permission_store.dart';
import '../../widgets/institution/institution_name_autocomplete_field.dart';
import '../../widgets/location/city_search_field.dart';
import '../../widgets/location/state_search_field.dart';
import '../schools/school_create_screen.dart';

String? _eventIdForRegistrationSave(
  ParticipantController participantController,
  CompetitionController competitionController,
) {
  final selectedId = participantController.selectedEventId.value;
  final fromList = competitionController.competitions.firstWhereOrNull(
    (c) => c.id == selectedId,
  );
  final idFromList = fromList?.id;
  if (idFromList != null && idFromList.isNotEmpty) {
    return idFromList;
  }
  if (selectedId.isNotEmpty) return selectedId;
  return null;
}

class ParticipantRegistrationFormScreen extends StatelessWidget {
  final String? initialCompetitionId;

  /// When false (e.g. public registration from a specific competition route),
  /// the competition selector is hidden; [initialCompetitionId] / [selectedEventId] is used.
  final bool showCompetitionDropdown;

  const ParticipantRegistrationFormScreen({
    super.key,
    this.initialCompetitionId,
    this.showCompetitionDropdown = true,
  });

  @override
  Widget build(BuildContext context) {
    // Keep screen Stateless: init work happens in controller.onReady()
    Get.put(
      ParticipantRegistrationFormController(
        initialCompetitionId: initialCompetitionId,
      ),
    );

    // Public registration screen can be opened after logout.
    // Ensure ParticipantController exists even if it was deleted on signOut().
    final participantController = Get.isRegistered<ParticipantController>()
        ? Get.find<ParticipantController>()
        : Get.put(ParticipantController());
    // Initialize CompetitionController if not already initialized
    final competitionController = Get.put(CompetitionController());

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : (isTablet ? 20 : 24)),
        child: Form(
          key: participantController.formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                FormTitle(
                  text: 'REGISTRATION',
                  isMobile: isMobile,
                  isTablet: isTablet,
                ),

                // Main content: Left side (fields in columns) and Right side (Photo & Certificate)
                isMobile
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showCompetitionDropdown) ...[
                            _buildCompetitionField(
                              context,
                              participantController,
                              competitionController,
                              isMobile,
                              isTablet,
                            ),
                            SizedBox(height: isMobile ? 20 : 24),
                          ],
                          _buildNameField(
                            context,
                            participantController,
                            isMobile,
                            isTablet,
                          ),
                          SizedBox(height: isMobile ? 20 : 24),
                          _buildDateOfBirthField(
                            context,
                            participantController,
                            isMobile,
                            isTablet,
                          ),
                          SizedBox(height: isMobile ? 20 : 24),
                          _buildAgeField(
                            context,
                            participantController,
                            isMobile,
                          ),
                          SizedBox(height: isMobile ? 20 : 24),
                          _buildGenderField(
                            context,
                            participantController,
                            isMobile,
                            isTablet,
                          ),
                          SizedBox(height: isMobile ? 20 : 24),
                          _buildCategoryField(
                            context,
                            participantController,
                            competitionController,
                            isMobile,
                            isTablet,
                          ),
                          SizedBox(height: isMobile ? 20 : 24),
                          _buildGroupField(
                            context,
                            participantController,
                            competitionController,
                            isMobile,
                            isTablet,
                          ),
                          SizedBox(height: isMobile ? 20 : 24),
                          _buildPhotoField(
                            context,
                            participantController,
                            isMobile,
                            isTablet,
                          ),
                          SizedBox(height: isMobile ? 20 : 24),
                          _buildBonafideCertificateField(
                            context,
                            participantController,
                            isMobile,
                            isTablet,
                          ),
                          SizedBox(height: isMobile ? 20 : 24),
                          _buildEcoCertificateOptInField(
                            context,
                            participantController,
                            isMobile,
                          ),
                          SizedBox(height: isMobile ? 20 : 24),
                          Builder(
                            builder: (context) {
                              final permissionStore =
                                  Get.isRegistered<PermissionStore>()
                                  ? Get.find<PermissionStore>()
                                  : Get.put(PermissionStore());
                              final showSpot = permissionStore.has(
                                'SHOW_SPOT_REGISTRATION_OPTION',
                              );
                              if (!showSpot) return const SizedBox.shrink();
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildSpotRegistrationField(
                                    context,
                                    participantController,
                                    isMobile,
                                    isTablet,
                                  ),
                                  SizedBox(height: isMobile ? 20 : 24),
                                ],
                              );
                            },
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left side: Fields in two columns
                          Expanded(
                            flex: 3,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showCompetitionDropdown) ...[
                                  _buildCompetitionField(
                                    context,
                                    participantController,
                                    competitionController,
                                    isMobile,
                                    isTablet,
                                  ),
                                  SizedBox(height: isMobile ? 20 : 24),
                                ],
                                _buildNameField(
                                  context,
                                  participantController,
                                  isMobile,
                                  isTablet,
                                ),
                                SizedBox(height: isMobile ? 20 : 24),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Column 1
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            spacing: 12,
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: _buildDateOfBirthField(
                                                  context,
                                                  participantController,
                                                  isMobile,
                                                  isTablet,
                                                ),
                                              ),
                                              Expanded(
                                                child: _buildAgeField(
                                                  context,
                                                  participantController,
                                                  isMobile,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: isMobile ? 20 : 24),
                                          _buildCategoryField(
                                            context,
                                            participantController,
                                            competitionController,
                                            isMobile,
                                            isTablet,
                                          ),
                                          SizedBox(height: isMobile ? 20 : 24),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: isTablet ? 12 : 16),
                                    // Column 2
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildGenderField(
                                            context,
                                            participantController,
                                            isMobile,
                                            isTablet,
                                          ),
                                          SizedBox(height: isMobile ? 20 : 24),
                                          _buildGroupField(
                                            context,
                                            participantController,
                                            competitionController,
                                            isMobile,
                                            isTablet,
                                          ),
                                          SizedBox(height: isMobile ? 20 : 24),
                                          Builder(
                                            builder: (context) {
                                              final permissionStore =
                                                  Get.isRegistered<
                                                    PermissionStore
                                                  >()
                                                  ? Get.find<PermissionStore>()
                                                  : Get.put(PermissionStore());
                                              final showSpot = permissionStore.has(
                                                'SHOW_SPOT_REGISTRATION_OPTION',
                                              );
                                              if (!showSpot) {
                                                return const SizedBox.shrink();
                                              }
                                              return const SizedBox.shrink();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                // SizedBox(height: isMobile ? 20 : 10),
                                _buildInstitutionSection(
                                  context,
                                  participantController,
                                  isMobile,
                                  isTablet,
                                ),
                                SizedBox(height: isMobile ? 20 : 24),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _buildYogaTeacherNameField(
                                        context,
                                        participantController,
                                        isMobile,
                                        isTablet,
                                      ),
                                    ),
                                    SizedBox(width: isTablet ? 12 : 16),
                                    Expanded(
                                      child: _buildYogaTeacherCellField(
                                        context,
                                        participantController,
                                        isMobile,
                                        isTablet,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: isTablet ? 16 : 24),
                          // Right side: Photo and Bonafide Certificate
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPhotoField(
                                  context,
                                  participantController,
                                  isMobile,
                                  isTablet,
                                ),
                                SizedBox(height: isMobile ? 20 : 24),
                                _buildBonafideCertificateField(
                                  context,
                                  participantController,
                                  isMobile,
                                  isTablet,
                                ),
                                SizedBox(height: isMobile ? 20 : 24),
                                _buildEcoCertificateOptInField(
                                  context,
                                  participantController,
                                  isMobile,
                                ),
                                SizedBox(height: isMobile ? 20 : 24),
                                Builder(
                                  builder: (context) {
                                    final permissionStore =
                                        Get.isRegistered<PermissionStore>()
                                        ? Get.find<PermissionStore>()
                                        : Get.put(PermissionStore());
                                    final showSpot = permissionStore.has(
                                      'SHOW_SPOT_REGISTRATION_OPTION',
                                    );
                                    if (!showSpot)
                                      return const SizedBox.shrink();
                                    return _buildSpotRegistrationField(
                                      context,
                                      participantController,
                                      isMobile,
                                      isTablet,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                if (isMobile) ...[
                  // SizedBox(height: isMobile ? 20 : 10),
                  _buildInstitutionSection(
                    context,
                    participantController,
                    isMobile,
                    isTablet,
                  ),
                  SizedBox(height: isMobile ? 20 : 24),
                  _buildYogaTeacherNameField(
                    context,
                    participantController,
                    isMobile,
                    isTablet,
                  ),
                  SizedBox(height: isMobile ? 20 : 24),
                  _buildYogaTeacherCellField(
                    context,
                    participantController,
                    isMobile,
                    isTablet,
                  ),
                ],
                SizedBox(height: isMobile ? 24 : 32),

                // Error Message (only show when not in list view)
                Obx(() {
                  if (participantController.isListView.value) {
                    return const SizedBox.shrink();
                  }
                  if (participantController.errorMessage.value.isNotEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              participantController.errorMessage.value,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),

                // Action Buttons (Save and Cancel)
                Obx(() {
                  // Show cancel button in view mode, hide save button
                  if (participantController.isViewMode.value) {
                    return Center(
                      child: cancelButton(
                        onPressed: () {
                          // Clear error message, reset form and redirect to list view
                          participantController.errorMessage.value = '';
                          participantController.resetForm();
                          participantController.toggleViewMode(true);
                        },
                        width: isMobile ? null : 200,
                        isFullWidth: isMobile,
                      ),
                    );
                  }

                  // Hide buttons if not in edit mode (create mode shows buttons)
                  if (!participantController.isEditMode) {
                    return isMobile
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              saveButton(
                                onPressed: () async {
                                  // Clear any previous error messages
                                  participantController.errorMessage.value = '';

                                  final eventId = _eventIdForRegistrationSave(
                                    participantController,
                                    competitionController,
                                  );
                                  if (eventId == null || eventId.isEmpty) {
                                    participantController.errorMessage.value =
                                        'Please select a competition';
                                    return;
                                  }

                                  final success = await participantController
                                      .submitRegistrationForm(
                                        eventId: eventId,
                                        competitionController:
                                            competitionController,
                                      );

                                  if (success && context.mounted) {
                                    // Clear error message on success
                                    participantController.errorMessage.value =
                                        '';
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Participant registered successfully',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    // Form is already reset in submitRegistrationForm method
                                  }
                                },
                                isLoading: participantController.isLoading,
                                text: 'SAVE',
                                isFullWidth: true,
                              ),
                              const SizedBox(height: 12),
                              cancelButton(
                                onPressed: () {
                                  // Clear error message and reset form
                                  participantController.errorMessage.value = '';
                                  participantController.resetForm();
                                },
                                isFullWidth: true,
                              ),
                            ],
                          )
                        : Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                saveButton(
                                  onPressed: () async {
                                    // Clear any previous error messages
                                    participantController.errorMessage.value =
                                        '';

                                    final eventId = _eventIdForRegistrationSave(
                                      participantController,
                                      competitionController,
                                    );
                                    if (eventId == null || eventId.isEmpty) {
                                      participantController.errorMessage.value =
                                          'Please select a competition';
                                      return;
                                    }

                                    final success = await participantController
                                        .submitRegistrationForm(
                                          eventId: eventId,
                                          competitionController:
                                              competitionController,
                                        );

                                    if (success && context.mounted) {
                                      // Clear error message on success
                                      participantController.errorMessage.value =
                                          '';
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Participant registered successfully',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      // Form is already reset in submitRegistrationForm method
                                    }
                                  },
                                  isLoading: participantController.isLoading,
                                  text: 'SAVE',
                                  width: 200,
                                ),
                                const SizedBox(width: 16),
                                cancelButton(
                                  onPressed: () {
                                    // Clear error message and reset form
                                    participantController.errorMessage.value =
                                        '';
                                    participantController.resetForm();
                                  },
                                  width: 200,
                                ),
                              ],
                            ),
                          );
                  }

                  // Edit mode: show both save and cancel buttons
                  return isMobile
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            saveButton(
                              onPressed: () async {
                                // Clear any previous error messages
                                participantController.errorMessage.value = '';

                                final eventId = _eventIdForRegistrationSave(
                                  participantController,
                                  competitionController,
                                );
                                if (eventId == null || eventId.isEmpty) {
                                  participantController.errorMessage.value =
                                      'Please select a competition';
                                  return;
                                }

                                final success = await participantController
                                    .submitRegistrationForm(
                                      eventId: eventId,
                                      competitionController:
                                          competitionController,
                                    );

                                if (success && context.mounted) {
                                  // Clear error message on success
                                  participantController.errorMessage.value = '';
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Participant updated successfully',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  // Redirect to list view after successful update
                                  participantController.resetForm();
                                  participantController.toggleViewMode(true);
                                }
                              },
                              isLoading: participantController.isLoading,
                              text: 'UPDATE',
                              isFullWidth: true,
                            ),
                            const SizedBox(height: 12),
                            cancelButton(
                              onPressed: () {
                                // Clear error message, reset form and redirect to list view
                                participantController.errorMessage.value = '';
                                participantController.resetForm();
                                participantController.toggleViewMode(true);
                              },
                              isFullWidth: true,
                            ),
                          ],
                        )
                      : Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              saveButton(
                                onPressed: () async {
                                  // Clear any previous error messages
                                  participantController.errorMessage.value = '';

                                  final eventId = _eventIdForRegistrationSave(
                                    participantController,
                                    competitionController,
                                  );
                                  if (eventId == null || eventId.isEmpty) {
                                    participantController.errorMessage.value =
                                        'Please select a competition';
                                    return;
                                  }

                                  final success = await participantController
                                      .submitRegistrationForm(
                                        eventId: eventId,
                                        competitionController:
                                            competitionController,
                                      );

                                  if (success && context.mounted) {
                                    // Clear error message on success
                                    participantController.errorMessage.value =
                                        '';
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Participant updated successfully',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    // Redirect to list view after successful update
                                    participantController.resetForm();
                                    participantController.toggleViewMode(true);
                                  }
                                },
                                isLoading: participantController.isLoading,
                                text: 'UPDATE',
                                width: 200,
                              ),
                              const SizedBox(width: 16),
                              cancelButton(
                                onPressed: () {
                                  // Clear error message, reset form and redirect to list view
                                  participantController.errorMessage.value = '';
                                  participantController.resetForm();
                                  participantController.toggleViewMode(true);
                                },
                                width: 200,
                              ),
                            ],
                          ),
                        );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompetitionField(
    BuildContext context,
    ParticipantController controller,
    CompetitionController competitionController,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(label: 'COMPETITION :', bottomSpacing: 12),
        Obx(
          () => DropdownButtonFormField<String>(
            value: controller.selectedEventId.value.isNotEmpty
                ? controller.selectedEventId.value
                : null,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: 12,
              ),
              isDense: isMobile,
              filled: true,
              fillColor: controller.isViewMode.value
                  ? Colors.grey[200]
                  : Colors.white,
            ),
            hint: Text(
              'Select Competition',
              style: TextStyle(fontSize: isMobile ? 14 : 16),
            ),
            style: TextStyle(fontSize: isMobile ? 14 : 16),
            items: competitionController.competitions
                .where((c) => c.id != null)
                .map((competition) {
                  return DropdownMenuItem<String>(
                    value: competition.id,
                    child: Text(
                      competition.competitionName,
                      style: TextStyle(fontSize: isMobile ? 14 : 16),
                    ),
                  );
                })
                .toList(),
            onChanged: !controller.isViewMode.value
                ? (value) {
                    if (value != null) {
                      controller.selectedEventId.value = value;
                      // Clear category, stage and group when competition changes
                      controller.selectedCategories.clear();
                      controller.selectedStage.value = '';
                      controller.standard.value = '';
                    }
                  }
                : null,
            validator: !controller.isViewMode.value
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a competition';
                    }
                    return null;
                  }
                : null,
            isExpanded: true,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField(
    BuildContext context,
    ParticipantController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(
          label: "Participant's Name :",
          hintText: '(This will reflect in your E-Certificate)',
          bottomSpacing: 6,
        ),
        Obx(
          () => TextFormField(
            controller: controller.nameController,
            readOnly: controller.isViewMode.value,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              filled: true,
              fillColor: controller.isViewMode.value
                  ? Colors.grey[200]
                  : Colors.white,
            ),
            validator: !controller.isViewMode.value
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Participant name is required';
                    }
                    // Validate: Only period symbol for separating initial and name
                    final namePattern = RegExp(r'^[A-Za-z\s.]+$');
                    if (!namePattern.hasMatch(value.trim())) {
                      return 'Name can only contain letters, spaces, and periods';
                    }
                    return null;
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDateOfBirthField(
    BuildContext context,
    ParticipantController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(label: 'Date of Birth :', bottomSpacing: 8),
        Obx(
          () => TextFormField(
            readOnly: true,
            controller: TextEditingController(
              text: controller.dateOfBirth.value != null
                  ? app_date_utils.AppDateUtils.formatDate(
                      controller.dateOfBirth.value!,
                    )
                  : '',
            ),
            decoration: InputDecoration(
              hintText: 'DD/MM/YYYY',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              suffixIcon: Icon(Icons.calendar_today),
              filled: true,
              fillColor: controller.isViewMode.value
                  ? Colors.grey[200]
                  : Colors.white,
            ),
            onTap: !controller.isViewMode.value
                ? () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate:
                          controller.dateOfBirth.value ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      controller.dateOfBirth.value = picked;
                    }
                  }
                : null,
            validator: !controller.isViewMode.value
                ? (value) {
                    if (controller.dateOfBirth.value == null) {
                      return 'Please select date of birth';
                    }
                    return null;
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildAgeField(
    BuildContext context,
    ParticipantController controller,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(label: 'Age :', bottomSpacing: 8),
        Obx(
          () => TextFormField(
            readOnly: true,
            controller: TextEditingController(
              text: controller.dateOfBirth.value != null
                  ? app_date_utils.AppDateUtils.calculateAge(
                      controller.dateOfBirth.value!,
                    ).toString()
                  : '',
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoField(
    BuildContext context,
    ParticipantController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(label: "Participant's Photo :", bottomSpacing: 8),
        Center(
          child: Obx(
            () => _buildImagePreview(
              controller.photoFile.value,
              controller.selectedImage.value,
              controller.existingPhotoUrl.value,
              isMobile ? 150 : 200,
              isMobile ? 150 : 200,
              defaultIcon: Icons.person,
              defaultText: 'No Photo',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Center(
            child: Obx(
              () => OutlinedButton.icon(
                onPressed: !controller.isViewMode.value
                    ? () => _pickPhoto(controller, context)
                    : null,
                icon: const Icon(Icons.upload_file, size: 16),
                label: const Text('BROWSE', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 36),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderField(
    BuildContext context,
    ParticipantController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(label: 'Sex :', bottomSpacing: 8),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('MALE'),
                  value: 'MALE',
                  groupValue: controller.gender.value,
                  onChanged: !controller.isViewMode.value
                      ? (value) {
                          if (value != null) {
                            controller.gender.value = value;
                          }
                        }
                      : null,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('FEMALE'),
                  value: 'FEMALE',
                  groupValue: controller.gender.value,
                  onChanged: !controller.isViewMode.value
                      ? (value) {
                          if (value != null) {
                            controller.gender.value = value;
                          }
                        }
                      : null,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpotRegistrationField(
    BuildContext context,
    ParticipantController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(label: 'Spot Registration :', bottomSpacing: 8),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('No'),
                  value: false,
                  groupValue: controller.isSpotRegistration.value,
                  onChanged: !controller.isViewMode.value
                      ? (value) {
                          if (value != null) {
                            controller.isSpotRegistration.value = value;
                          }
                        }
                      : null,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Yes'),
                  value: true,
                  groupValue: controller.isSpotRegistration.value,
                  onChanged: !controller.isViewMode.value
                      ? (value) {
                          if (value != null) {
                            controller.isSpotRegistration.value = value;
                          }
                        }
                      : null,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEcoCertificateOptInField(
    BuildContext context,
    ParticipantController controller,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(label: 'E-Certificate :', bottomSpacing: 8),
        Obx(
          () => IgnorePointer(
            ignoring: controller.isViewMode.value,
            child: CheckboxListTile(
              value: controller.optForECertificate.value,
              onChanged: (value) {
                controller.optForECertificate.value = value ?? false;
              },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Colors.green,
              title: Text(
                'Save Trees. Go Green. Opt for a Downloadable E-Certificate',
                style: TextStyle(fontSize: isMobile ? 12 : 13),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryField(
    BuildContext context,
    ParticipantController controller,
    CompetitionController competitionController,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(label: 'Category :', bottomSpacing: 12),
        Obx(() {
          final selectedCompetition = competitionController.competitions
              .firstWhereOrNull(
                (c) => c.id == controller.selectedEventId.value,
              );
          final availableCategories =
              selectedCompetition?.categories ?? <String>[];

          return DropdownButtonFormField<String>(
            value: controller.selectedCategories.isNotEmpty
                ? controller.selectedCategories.first
                : null,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              filled: true,
              fillColor: controller.isViewMode.value
                  ? Colors.grey[200]
                  : Colors.white,
            ),
            hint: const Text('Select Category'),
            items: availableCategories.map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: !controller.isViewMode.value
                ? (value) {
                    if (value != null) {
                      controller.selectedCategories.value = [value];
                    }
                  }
                : null,
            validator: !controller.isViewMode.value
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  }
                : null,
            isExpanded: true,
          );
        }),
      ],
    );
  }

  Widget _buildGroupField(
    BuildContext context,
    ParticipantController controller,
    CompetitionController competitionController,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(label: 'Select Group :', bottomSpacing: 8),
        Obx(() {
          final selectedCompetition = competitionController.competitions
              .firstWhereOrNull(
                (c) => c.id == controller.selectedEventId.value,
              );

          // Get all groups from all stages with their stage information
          final allGroupsWithStage = <String>[];
          if (selectedCompetition != null &&
              selectedCompetition.stageGroups != null) {
            selectedCompetition.stageGroups!.forEach((stageIdStr, groupIds) {
              final stageId = int.tryParse(stageIdStr);
              if (stageId != null) {
                final stageName = competitionController.getStageNameById(
                  stageId,
                );
                if (stageName != null) {
                  // Convert group IDs to names and format as "GroupName (GROUP StageName)"
                  groupIds.forEach((groupId) {
                    final groupName = competitionController.getGroupNameById(
                      groupId,
                    );
                    if (groupName != null) {
                      // Format: "II (GROUP A)" or "II (GROUP StageName)"
                      allGroupsWithStage.add('$groupName (GROUP $stageName)');
                    }
                  });
                }
              }
            });
          }
          // Sort by group name (extract before " (GROUP")
          allGroupsWithStage.sort((a, b) {
            final groupA = a.split(' (GROUP').first;
            final groupB = b.split(' (GROUP').first;
            return groupA.compareTo(groupB);
          });

          // Find current value - match by formatted string or group name
          String? currentValue;
          if (controller.standard.value.isNotEmpty) {
            // First try to find exact match with formatted string
            final match = allGroupsWithStage.firstWhereOrNull(
              (formatted) =>
                  formatted.startsWith('${controller.standard.value} (GROUP'),
            );
            if (match != null) {
              currentValue = match;
            } else {
              // If not found, try to match with just the group name
              final matchByName = allGroupsWithStage.firstWhereOrNull(
                (formatted) =>
                    formatted.split(' (GROUP').first.trim() ==
                    controller.standard.value,
              );
              currentValue = matchByName;
            }
          }

          return DropdownButtonFormField<String>(
            value: currentValue,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            hint: const Text('Select Group'),
            items: allGroupsWithStage.map((formattedGroup) {
              return DropdownMenuItem<String>(
                value: formattedGroup,
                child: Text(formattedGroup),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                // Extract just the group name (before " (GROUP")
                final groupName = value.split(' (GROUP').first.trim();
                // Extract stage name (between "GROUP " and ")"
                final stagePart = value
                    .split('GROUP ')
                    .last
                    .replaceAll(')', '');
                controller.standard.value = groupName;
                controller.selectedStage.value = stagePart;
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a group';
              }
              return null;
            },
            isExpanded: true,
          );
        }),
      ],
    );
  }

  Widget _buildYogaTeacherNameField(
    BuildContext context,
    ParticipantController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(label: 'Yoga Teacher Name :', bottomSpacing: 10),
        Obx(
          () => TextFormField(
            controller: controller.yogaMasterNameController,
            readOnly: controller.isViewMode.value,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              filled: true,
              fillColor: controller.isViewMode.value
                  ? Colors.grey[200]
                  : Colors.white,
            ),
            validator: !controller.isViewMode.value
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Yoga teacher name is required';
                    }
                    return null;
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildYogaTeacherCellField(
    BuildContext context,
    ParticipantController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(
          label: 'Yoga Teacher Cell :',
          hintText: '(Without +91)',
          bottomSpacing: 5,
        ),
        Obx(
          () => TextFormField(
            controller: controller.yogaMasterContactController,
            readOnly: controller.isViewMode.value,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 10,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              counterText: '',
              filled: true,
              fillColor: controller.isViewMode.value
                  ? Colors.grey[200]
                  : Colors.white,
            ),
            validator: !controller.isViewMode.value
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Yoga teacher cell is required';
                    }
                    // Validate 10 digits
                    if (value.trim().length != 10) {
                      return 'Cell number must be exactly 10 digits';
                    }
                    // Check for fake numbers (all same digit or reverse sequence)
                    if (RegExp(r'^(\d)\1{9}$').hasMatch(value.trim())) {
                      return 'Invalid cell number';
                    }
                    if (value.trim() == '9876543210' ||
                        value.trim() == '0123456789') {
                      return 'Invalid cell number';
                    }
                    return null;
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildInstitutionSection(
    BuildContext context,
    ParticipantController controller,
    bool isMobile,
    bool isTablet,
  ) {
    final theme = Theme.of(context);
    final headingStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      letterSpacing: 0.6,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('INSTITUTION', style: headingStyle),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInstitutionSearchFilters(
                context,
                controller,
                isMobile,
                isTablet,
              ),
              SizedBox(height: isMobile ? 12 : 16),
              _buildInstitutionNameField(
                context,
                controller,
                isMobile,
                isTablet,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstitutionSearchFilters(
    BuildContext context,
    ParticipantController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Obx(() {
      if (controller.isViewMode.value) {
        return const SizedBox.shrink();
      }
      controller.ensureInstitutionSearchFiltersLoaded();

      InputDecoration filterDecoration({Widget? suffixIcon}) {
        return InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: suffixIcon,
        );
      }

      final loadingLocations =
          controller.isLoadingInstitutionSearchLocations.value;
      final stateId = controller.institutionSearchFilterStateId.value;
      final loadingCities = controller.isLoadingInstitutionSearchCities.value;

      final stateField = loadingLocations
          ? TextFormField(
              readOnly: true,
              style: TextStyle(fontSize: isMobile ? 14 : 15),
              decoration: filterDecoration(
                suffixIcon: const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ).copyWith(hintText: 'Loading states...'),
            )
          : StateSearchField(
              textEditingController:
                  controller.institutionFilterStateTextController,
              focusNode: controller.institutionFilterStateFocusNode,
              states: List.from(controller.institutionSearchStates),
              decorationBuilder: filterDecoration,
              isMobile: isMobile,
              onStateId: controller.setInstitutionSearchFilterState,
            );

      final cityField = loadingCities
          ? TextFormField(
              readOnly: true,
              style: TextStyle(fontSize: isMobile ? 14 : 15),
              decoration: filterDecoration(
                suffixIcon: const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ).copyWith(hintText: 'Loading cities...'),
            )
          : (stateId <= 0
                ? TextFormField(
                    readOnly: true,
                    style: TextStyle(fontSize: isMobile ? 14 : 15),
                    decoration: filterDecoration().copyWith(
                      hintText: 'Select state first',
                    ),
                  )
                : CitySearchField(
                    textEditingController:
                        controller.institutionFilterCityTextController,
                    focusNode: controller.institutionFilterCityFocusNode,
                    cities: List.from(controller.institutionSearchCities),
                    decorationBuilder: filterDecoration,
                    isMobile: isMobile,
                    onCityId: controller.setInstitutionSearchFilterCity,
                  ));

      final typeField = DropdownButtonFormField<int?>(
        value: controller.institutionSearchFilterTypeId.value > 0
            ? controller.institutionSearchFilterTypeId.value
            : null,
        decoration: filterDecoration(),
        hint: const Text('Institution type (optional)'),
        isExpanded: true,
        menuMaxHeight: 280,
        style: TextStyle(fontSize: isMobile ? 14 : 15),
        items: [
          const DropdownMenuItem<int?>(value: null, child: Text('Any type')),
          ...controller.institutionSearchTypes.map(
            (t) => DropdownMenuItem<int?>(
              value: t.id,
              child: Text(t.displayName, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: loadingLocations
            ? null
            : (v) {
                controller.setInstitutionSearchFilterType(v ?? 0);
              },
      );

      final filterChildren = isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                stateField,
                const SizedBox(height: 12),
                cityField,
                const SizedBox(height: 12),
                typeField,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: stateField),
                SizedBox(width: isTablet ? 10 : 12),
                Expanded(child: cityField),
                SizedBox(width: isTablet ? 10 : 12),
                Expanded(child: typeField),
              ],
            );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormLabelWithHint(
            label: 'Narrow search (optional)',
            hintText:
                'Search state & city by typing; pick institution type below',
            bottomSpacing: 8,
          ),
          filterChildren,
        ],
      );
    });
  }

  Widget _buildInstitutionNameField(
    BuildContext context,
    ParticipantController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(label: 'Institution Name :', bottomSpacing: 8),
        Obx(() {
          final resetTrigger = controller.formResetTrigger.value;
          final isEdit = controller.isEditMode;
          final hasText = controller.schoolNameController.text.isNotEmpty;
          final participantId = controller.participantToEdit.value?.id ?? '';
          final institutionKey = isEdit && hasText
              ? 'institution-edit-$participantId-${controller.schoolNameController.text}'
              : 'institution-new-$resetTrigger';

          return InstitutionNameAutocompleteField(
            autocompleteKey: institutionKey,
            formTextController: controller.schoolNameController,
            onSearch: (q) => controller.searchInstitutions(q),
            suggestions: controller.institutionSuggestions,
            isLoading: controller.isLoadingInstitutions,
            onInstitutionSelected: controller.selectInstitution,
            onClear: () {
              controller.selectedInstitutionId.value = null;
              controller.participantInstitutionId.value = null;
            },
            isViewMode: controller.isViewMode,
            validator: !controller.isViewMode.value
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Institution name is required';
                    }
                    return null;
                  }
                : null,
            onAddNewInstitution: (ctx, searchText) =>
                _showAddInstitutionDialog(ctx, controller, searchText),
          );
        }),
      ],
    );
  }

  Widget _buildBonafideCertificateField(
    BuildContext context,
    ParticipantController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(
          label: 'Bonafied Certificate :',
          hintText: '(Applicable only for Govt / Govt Aided)',
          bottomSpacing: 8,
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            return Obx(
              () => _buildImagePreview(
                controller.bonafideFile.value,
                controller.bonafideImage.value,
                controller.existingCertificateUrl.value,
                constraints.maxWidth,
                isMobile ? 150 : 200,
                defaultIcon: Icons.description,
                defaultText: 'No Certificate',
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Obx(() {
            final hasCertificate =
                controller.bonafideFile.value != null ||
                controller.bonafideImage.value != null ||
                (controller.existingCertificateUrl.value.isNotEmpty);

            return Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: !controller.isViewMode.value
                        ? () => _pickBonafideCertificate(controller, context)
                        : null,
                    icon: const Icon(Icons.upload_file, size: 16),
                    label: const Text('BROWSE', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                  if (hasCertificate && !controller.isViewMode.value) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _removeBonafideCertificate(controller),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text(
                        'REMOVE',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 36),
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Future<void> _pickPhoto(
    ParticipantController controller,
    BuildContext context,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (file != null) {
        controller.selectedImage.value = file;
        if (!kIsWeb) {
          controller.photoFile.value = File(file.path);
        }
        // Clear existing photo URL when a new image is selected
        // This ensures the newly selected local image is shown instead of the old URL
        controller.existingPhotoUrl.value = '';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickBonafideCertificate(
    ParticipantController controller,
    BuildContext context,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (file != null) {
        controller.bonafideImage.value = file;
        if (!kIsWeb) {
          controller.bonafideFile.value = File(file.path);
        }
        // Clear existing certificate URL when a new certificate is selected
        // This ensures the newly selected local image is shown instead of the old URL
        controller.existingCertificateUrl.value = '';
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bonafide certificate selected'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick certificate: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeBonafideCertificate(ParticipantController controller) {
    controller.bonafideFile.value = null;
    controller.bonafideImage.value = null;
    controller.existingCertificateUrl.value = '';
  }

  Widget _buildImagePreview(
    File? file,
    XFile? xFile,
    String? imageUrl,
    double width,
    double height, {
    IconData defaultIcon = Icons.image,
    String defaultText = 'No Image',
  }) {
    final hasLocalImage =
        (xFile != null) || (file != null && file.existsSync());
    final hasUrlImage = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: hasLocalImage
            ? (kIsWeb
                  ? (xFile != null
                        ? FutureBuilder<Uint8List>(
                            future: xFile.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                );
                              }
                              return _buildDefaultPreview(
                                defaultIcon,
                                defaultText,
                              );
                            },
                          )
                        : _buildDefaultPreview(defaultIcon, defaultText))
                  : (file != null && file.existsSync()
                        ? Image.file(file, fit: BoxFit.cover)
                        : _buildDefaultPreview(defaultIcon, defaultText)))
            : hasUrlImage
            ? _buildNetworkImage(imageUrl, defaultIcon, defaultText)
            : _buildDefaultPreview(defaultIcon, defaultText),
      ),
    );
  }

  Widget _buildDefaultPreview(IconData icon, String text) {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey[400], size: 40),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildNetworkImage(
    String imageUrl,
    IconData defaultIcon,
    String defaultText,
  ) {
    // Create headers with authentication token
    final headers = <String, String>{};
    try {
      final token = StorageService.getString(AppConstants.tokenKey);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      // If token retrieval fails, continue without auth header
    }

    // Use imageUrl as key to force reload when URL changes (including cache-busting parameter)
    return Image.network(
      imageUrl,
      key: ValueKey(imageUrl), // Force rebuild when URL changes
      fit: BoxFit.cover,
      headers: headers,
      cacheWidth: null, // Don't cache width
      cacheHeight: null, // Don't cache height
      errorBuilder: (context, error, stackTrace) {
        return _buildDefaultPreview(defaultIcon, defaultText);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
    );
  }

  void _showAddInstitutionDialog(
    BuildContext context,
    ParticipantController participantController,
    String institutionName,
  ) {
    final schoolController = Get.put(SchoolController());

    // Pre-fill the institution name
    schoolController.institutionNameController.text = institutionName;
    schoolController.isListView.value = false; // Show create form

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        // Use Builder to ensure we have access to MediaQuery from the dialog's context
        return Builder(
          builder: (builderContext) {
            // Safely get MediaQuery - use dialogContext if available, otherwise use builderContext
            final mediaQuery =
                MediaQuery.maybeOf(dialogContext) ??
                MediaQuery.maybeOf(builderContext) ??
                MediaQuery.of(context);

            final screenWidth = mediaQuery.size.width;
            final screenHeight = mediaQuery.size.height;
            final isMobile = screenWidth < 600;
            final isTablet = screenWidth >= 600 && screenWidth < 1024;

            // Calculate responsive width
            double dialogWidth;
            if (isMobile) {
              dialogWidth = screenWidth - 32; // Full width minus padding
            } else if (isTablet) {
              dialogWidth = screenWidth * 0.85; // 85% of screen width
            } else {
              dialogWidth =
                  1200; // Fixed width for desktop (increased from 800)
            }

            return Dialog(
              insetPadding: EdgeInsets.all(16),
              child: Container(
                width: dialogWidth,
                constraints: BoxConstraints(
                  maxHeight: screenHeight * (isMobile ? 0.95 : 0.9),
                  maxWidth: screenWidth - (isMobile ? 32 : 48),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green[700],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Add New Institution',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              // Clear the pre-filled name when dialog is closed
                              schoolController.institutionNameController
                                  .clear();
                            },
                          ),
                        ],
                      ),
                    ),
                    // Form content
                    Expanded(
                      child: SingleChildScrollView(
                        child: const SchoolCreateScreen(hideButtons: true),
                      ),
                    ),
                    // Action buttons
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Obx(
                        () => Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                // Clear the pre-filled name when dialog is closed
                                schoolController.institutionNameController
                                    .clear();
                              },
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: schoolController.isLoading.value
                                  ? null
                                  : () async {
                                      await schoolController.submitSchool();
                                      if (schoolController
                                              .errorMessage
                                              .value
                                              .isEmpty &&
                                          !schoolController.isLoading.value) {
                                        // Success - close dialog and refresh institution search
                                        Navigator.pop(dialogContext);

                                        // Refresh the institution search with the new institution
                                        await participantController
                                            .searchInstitutions(
                                              institutionName,
                                              useInstitutionSearchFilters:
                                                  false,
                                            );

                                        // Select the newly created institution if found
                                        final newInstitution =
                                            participantController
                                                .institutionSuggestions
                                                .firstWhereOrNull(
                                                  (inst) =>
                                                      inst.institutionName
                                                          .toLowerCase()
                                                          .trim() ==
                                                      institutionName
                                                          .toLowerCase()
                                                          .trim(),
                                                );
                                        if (newInstitution != null) {
                                          participantController
                                              .selectInstitution(
                                                newInstitution,
                                              );
                                        }

                                        // Clear the school controller form
                                        schoolController.resetForm();
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                              ),
                              child: schoolController.isLoading.value
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text('Save'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
