import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/participant_controller.dart';
import '../../controllers/competition_controller.dart';
import '../../controllers/participant_registration_form_controller.dart'
    show
        ParticipantRegistrationFormController,
        kParticipantRegistrationFormControllerTag;
import '../../controllers/school_controller.dart';
import '../../widgets/form_label_with_hint.dart';
import '../../widgets/form_title.dart';
import '../../widgets/buttons.dart';
import '../../../data/models/competition_model.dart';
import '../../../data/models/district_model.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/utils/storage_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/permission_store.dart';
import '../../widgets/institution/institution_name_autocomplete_field.dart';
import '../../widgets/location/district_search_field.dart';
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

CompetitionModel? _competitionForRegistration(
  ParticipantController participantController,
  CompetitionController competitionController,
) {
  final id = participantController.selectedEventId.value;
  if (id.isEmpty) return null;
  return competitionController.competitions.firstWhereOrNull((c) => c.id == id);
}

List<String> _categoriesForRegistration(
  ParticipantController participantController,
  CompetitionController competitionController,
) {
  final competition = _competitionForRegistration(
    participantController,
    competitionController,
  );
  if (competition?.categories != null && competition!.categories!.isNotEmpty) {
    return competition.categories!;
  }

  final id = participantController.selectedEventId.value;
  final home = competitionController.homeCompetitions.firstWhereOrNull(
    (c) => c.id?.toString() == id,
  );
  return home?.categories ?? const [];
}

List<({String groupName, String stageName})> _groupStageEntriesForRegistration(
  CompetitionModel? competition,
  CompetitionController competitionController,
) {
  if (competition == null) return const [];

  final entries = <({String groupName, String stageName})>[];

  if (competition.stageGroups != null && competition.stageGroups!.isNotEmpty) {
    final sortedStageIds =
        competition.stageGroups!.keys
            .map((id) => int.tryParse(id))
            .whereType<int>()
            .toList()
          ..sort((a, b) {
            final stageA =
                competitionController.getStageNameById(a)?.toLowerCase() ?? '';
            final stageB =
                competitionController.getStageNameById(b)?.toLowerCase() ?? '';
            return stageA.compareTo(stageB);
          });

    for (final stageId in sortedStageIds) {
      final stageName = competitionController.getStageNameById(stageId);
      if (stageName == null) continue;

      final groupIds =
          List<int>.from(
            competition.stageGroups![stageId.toString()] ?? const [],
          )..sort((a, b) {
            final groupA =
                competitionController.getGroupNameById(a)?.toLowerCase() ?? '';
            final groupB =
                competitionController.getGroupNameById(b)?.toLowerCase() ?? '';
            return groupA.compareTo(groupB);
          });

      for (final groupId in groupIds) {
        final groupName = competitionController.getGroupNameById(groupId);
        if (groupName != null) {
          entries.add((groupName: groupName, stageName: stageName));
        }
      }
    }
  }

  if (entries.isEmpty && competition.stageGroupLabels != null) {
    final sortedStages = competition.stageGroupLabels!.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    for (final stageName in sortedStages) {
      final groups = List<String>.from(
        competition.stageGroupLabels![stageName] ?? const [],
      )..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      for (final groupName in groups) {
        entries.add((groupName: groupName, stageName: stageName));
      }
    }
  }

  return entries;
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
    // Fresh controller each visit (e.g. after logout) so competition data reloads.
    if (Get.isRegistered<ParticipantRegistrationFormController>(
      tag: kParticipantRegistrationFormControllerTag,
    )) {
      Get.delete<ParticipantRegistrationFormController>(
        tag: kParticipantRegistrationFormControllerTag,
        force: true,
      );
    }
    Get.put(
      ParticipantRegistrationFormController(
        initialCompetitionId: initialCompetitionId,
      ),
      tag: kParticipantRegistrationFormControllerTag,
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
          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                          _buildSpotRegistrationSection(
                            context,
                            participantController,
                            competitionController,
                            isMobile,
                            isTablet,
                            includeBottomSpacing: true,
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
                                _buildSpotRegistrationSection(
                                  context,
                                  participantController,
                                  competitionController,
                                  isMobile,
                                  isTablet,
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
                                    SnackbarHelper.showSuccess(
                                      context,
                                      'Participant registered successfully',
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
                                      SnackbarHelper.showSuccess(
                                        context,
                                        'Participant registered successfully',
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
                                    SnackbarHelper.showSuccess(
                                      context,
                                      'Participant updated successfully',
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
                      controller.applySpotRegistrationRulesForSelectedEvent();
                      controller.validateRegistrationFormOnFieldChange();
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
            onChanged: controller.isViewMode.value
                ? null
                : (_) => controller.validateRegistrationFormOnFieldChange(),
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
                      controller.validateRegistrationFormOnFieldChange();
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
                            controller.validateRegistrationFormOnFieldChange();
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
                            controller.validateRegistrationFormOnFieldChange();
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

  bool _isSpotRegistrationOptionVisible(
    PermissionStore permissionStore,
    ParticipantController participantController,
    CompetitionController competitionController,
  ) {
    if (!permissionStore.has('SHOW_SPOT_REGISTRATION_OPTION')) {
      return false;
    }
    if (competitionController.competitions.isEmpty) {
      return false;
    }
    return participantController.isSpotRegistrationOptionVisible;
  }

  Widget _buildSpotRegistrationSection(
    BuildContext context,
    ParticipantController participantController,
    CompetitionController competitionController,
    bool isMobile,
    bool isTablet, {
    bool includeBottomSpacing = false,
  }) {
    return Obx(() {
      final permissionStore = Get.isRegistered<PermissionStore>()
          ? Get.find<PermissionStore>()
          : Get.put(PermissionStore());
      final _ = competitionController.competitions.length;
      final visible = _isSpotRegistrationOptionVisible(
        permissionStore,
        participantController,
        competitionController,
      );
      if (!visible) {
        return const SizedBox.shrink();
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSpotRegistrationField(
            context,
            participantController,
            isMobile,
            isTablet,
          ),
          if (includeBottomSpacing) SizedBox(height: isMobile ? 20 : 24),
        ],
      );
    });
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
                            controller.validateRegistrationFormOnFieldChange();
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
                            controller.validateRegistrationFormOnFieldChange();
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
                controller.validateRegistrationFormOnFieldChange();
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
          final _ = competitionController.competitions.length;
          if (competitionController.isLoadingRegistrationCompetition.value) {
            return const LinearProgressIndicator(minHeight: 2);
          }

          final availableCategories = _categoriesForRegistration(
            controller,
            competitionController,
          );

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
                      controller.validateRegistrationFormOnFieldChange();
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
          final _ = competitionController.competitions.length;
          if (competitionController.isLoadingRegistrationCompetition.value) {
            return const LinearProgressIndicator(minHeight: 2);
          }

          final selectedCompetition = _competitionForRegistration(
            controller,
            competitionController,
          );

          final groupStageEntries = _groupStageEntriesForRegistration(
            selectedCompetition,
            competitionController,
          );

          final allGroupsWithStage = groupStageEntries
              .map((e) => '${e.groupName} (GROUP ${e.stageName})')
              .toList();

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
                controller.validateRegistrationFormOnFieldChange();
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
            onChanged: controller.isViewMode.value
                ? null
                : (_) => controller.validateRegistrationFormOnFieldChange(),
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
            onChanged: controller.isViewMode.value
                ? null
                : (_) => controller.validateRegistrationFormOnFieldChange(),
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
      final loadingDistricts =
          controller.isLoadingInstitutionSearchDistricts.value;
      // Rebuild when cities for the state load (district list is derived).
      final districtListVersion = controller.institutionSearchDistricts.length;
      if (controller.institutionSearchFilterTypeId.value > 0) {
        controller.setInstitutionSearchFilterType(0);
      }

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

      final districtField = loadingDistricts
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
              ).copyWith(hintText: 'Loading districts...'),
            )
          : (stateId <= 0
                ? TextFormField(
                    readOnly: true,
                    style: TextStyle(fontSize: isMobile ? 14 : 15),
                    decoration: filterDecoration().copyWith(
                      hintText: 'Select state first',
                    ),
                  )
                : DistrictSearchField(
                    key: ValueKey(
                      'inst_search_district_${stateId}_$districtListVersion',
                    ),
                    textEditingController:
                        controller.institutionFilterDistrictTextController,
                    focusNode: controller.institutionFilterDistrictFocusNode,
                    districts: List<DistrictModel>.from(
                      controller.institutionSearchDistricts,
                    ),
                    decorationBuilder: filterDecoration,
                    isMobile: isMobile,
                  ));

      final filterChildren = isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [stateField, const SizedBox(height: 12), districtField],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: stateField),
                SizedBox(width: isTablet ? 10 : 12),
                Expanded(child: districtField),
              ],
            );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormLabelWithHint(
            label: 'Narrow search (optional)',
            hintText: 'Search state & district by typing',
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
              controller.validateRegistrationFormOnFieldChange();
            },
            onValueChanged: controller.validateRegistrationFormOnFieldChange,
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
    return Obx(() {
      if (!controller.isBonafideCertificateApplicable) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormLabelWithHint(
            label: 'Bonafied Certificate :',
            hintText: '(Applicable only for Govt / Govt Aided School)',
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
                  memoryBytes: controller.bonafideBytes.value,
                  previewKey:
                      controller.bonafideImage.value?.path ??
                      controller.bonafideFileName.value,
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Obx(() {
              final hasCertificate = controller.hasBonafideCertificateSelected;

              if (controller.isViewMode.value) {
                return const SizedBox.shrink();
              }

              return Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          _pickBonafideCertificate(controller, context),
                      icon: const Icon(Icons.upload_file, size: 16),
                      label: const Text(
                        'BROWSE',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 36),
                      ),
                    ),
                    if (hasCertificate) ...[
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
    });
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
        SnackbarHelper.showError(
          context,
          'Failed to pick image: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _pickBonafideCertificate(
    ParticipantController controller,
    BuildContext context,
  ) async {
    final picked = await controller.pickBonafideCertificate();
    if (!context.mounted) return;

    if (picked) {
      SnackbarHelper.showSuccess(context, 'Bonafide certificate selected');
    } else if (controller.errorMessage.value.isNotEmpty) {
      SnackbarHelper.showError(context, controller.errorMessage.value);
    }
  }

  void _removeBonafideCertificate(ParticipantController controller) {
    controller.bonafideFile.value = null;
    controller.bonafideImage.value = null;
    controller.bonafideBytes.value = null;
    controller.bonafideFileName.value = '';
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
    Uint8List? memoryBytes,
    Object? previewKey,
  }) {
    final hasMemoryImage = memoryBytes != null && memoryBytes.isNotEmpty;
    final hasLocalImage =
        hasMemoryImage ||
        (xFile != null) ||
        (file != null && file.existsSync());
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
            ? (hasMemoryImage
                  ? Image.memory(
                      memoryBytes,
                      key: ValueKey(previewKey ?? memoryBytes.hashCode),
                      fit: BoxFit.cover,
                      width: width,
                      height: height,
                    )
                  : _buildLocalImagePreview(
                      file: file,
                      xFile: xFile,
                      defaultIcon: defaultIcon,
                      defaultText: defaultText,
                      previewKey: previewKey,
                    ))
            : hasUrlImage
            ? _buildNetworkImage(imageUrl, defaultIcon, defaultText)
            : _buildDefaultPreview(defaultIcon, defaultText),
      ),
    );
  }

  Widget _buildLocalImagePreview({
    required File? file,
    required XFile? xFile,
    required IconData defaultIcon,
    required String defaultText,
    Object? previewKey,
  }) {
    if (file != null && file.existsSync()) {
      return Image.file(
        file,
        key: ValueKey(previewKey ?? file.path),
        fit: BoxFit.cover,
      );
    }

    if (xFile != null) {
      return FutureBuilder<Uint8List>(
        key: ValueKey(previewKey ?? xFile.path),
        future: xFile.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return Image.memory(snapshot.data!, fit: BoxFit.cover);
          }
          return _buildDefaultPreview(defaultIcon, defaultText);
        },
      );
    }

    return _buildDefaultPreview(defaultIcon, defaultText);
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
