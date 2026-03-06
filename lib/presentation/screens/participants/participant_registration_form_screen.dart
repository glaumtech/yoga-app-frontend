import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/participant_controller.dart';
import '../../controllers/competition_controller.dart';
import '../../controllers/school_controller.dart';
import '../../widgets/form_label_with_hint.dart';
import '../../widgets/form_title.dart';
import '../../widgets/buttons.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../core/utils/storage_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/school_model.dart';
import '../schools/school_create_screen.dart';

class ParticipantRegistrationFormScreen extends StatelessWidget {
  const ParticipantRegistrationFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final participantController = Get.find<ParticipantController>();
    // Initialize CompetitionController if not already initialized
    final competitionController = Get.put(CompetitionController());

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    // Load competitions if empty
    if (competitionController.competitions.isEmpty &&
        !competitionController.isLoading.value) {
      competitionController.loadCompetitions();
    }

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : (isTablet ? 20 : 24)),
        child: Form(
          key: participantController.formKey,
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
                        _buildCompetitionField(
                          context,
                          participantController,
                          competitionController,
                          isMobile,
                          isTablet,
                        ),
                        SizedBox(height: isMobile ? 20 : 24),
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
                        SizedBox(height: isMobile ? 20 : 24),
                        _buildInstitutionNameField(
                          context,
                          participantController,
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
                        _buildPaymentModeSection(context, isMobile, isTablet),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side: Fields in two columns
                        Expanded(
                          flex: 3,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Column 1
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildCompetitionField(
                                      context,
                                      participantController,
                                      competitionController,
                                      isMobile,
                                      isTablet,
                                    ),
                                    SizedBox(height: isMobile ? 20 : 24),
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
                                    _buildYogaTeacherNameField(
                                      context,
                                      participantController,
                                      isMobile,
                                      isTablet,
                                    ),
                                    SizedBox(height: isMobile ? 20 : 24),
                                    _buildInstitutionNameField(
                                      context,
                                      participantController,
                                      isMobile,
                                      isTablet,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: isTablet ? 12 : 16),
                              // Column 2
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildNameField(
                                      context,
                                      participantController,
                                      isMobile,
                                      isTablet,
                                    ),

                                    SizedBox(height: isMobile ? 20 : 24),
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
                                    _buildYogaTeacherCellField(
                                      context,
                                      participantController,
                                      isMobile,
                                      isTablet,
                                    ),
                                    SizedBox(height: isMobile ? 20 : 24),
                                    _buildPaymentModeSection(
                                      context,
                                      isMobile,
                                      isTablet,
                                    ),
                                  ],
                                ),
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
                            ],
                          ),
                        ),
                      ],
                    ),
              SizedBox(height: isMobile ? 24 : 32),

              // Error Message
              if (participantController.errorMessage.value.isNotEmpty)
                Container(
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
                ),

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

                                // Get selected competition/event ID
                                final selectedCompetition =
                                    competitionController.competitions
                                        .firstWhereOrNull(
                                          (c) =>
                                              c.id ==
                                              participantController
                                                  .selectedEventId
                                                  .value,
                                        );
                                if (selectedCompetition == null) {
                                  participantController.errorMessage.value =
                                      'Please select a competition';
                                  return;
                                }

                                final success = await participantController
                                    .submitRegistrationForm(
                                      eventId: selectedCompetition.id!,
                                      competitionController:
                                          competitionController,
                                    );

                                if (success && context.mounted) {
                                  // Clear error message on success
                                  participantController.errorMessage.value = '';
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
                                  participantController.errorMessage.value = '';

                                  // Get selected competition/event ID
                                  final selectedCompetition =
                                      competitionController.competitions
                                          .firstWhereOrNull(
                                            (c) =>
                                                c.id ==
                                                participantController
                                                    .selectedEventId
                                                    .value,
                                          );
                                  if (selectedCompetition == null) {
                                    participantController.errorMessage.value =
                                        'Please select a competition';
                                    return;
                                  }

                                  final success = await participantController
                                      .submitRegistrationForm(
                                        eventId: selectedCompetition.id!,
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
                                width: 200,
                              ),
                              const SizedBox(width: 16),
                              cancelButton(
                                onPressed: () {
                                  // Clear error message and reset form
                                  participantController.errorMessage.value = '';
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

                              // Get selected competition/event ID
                              final selectedCompetition = competitionController
                                  .competitions
                                  .firstWhereOrNull(
                                    (c) =>
                                        c.id ==
                                        participantController
                                            .selectedEventId
                                            .value,
                                  );
                              if (selectedCompetition == null) {
                                participantController.errorMessage.value =
                                    'Please select a competition';
                                return;
                              }

                              final success = await participantController
                                  .submitRegistrationForm(
                                    eventId: selectedCompetition.id!,
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

                                // Get selected competition/event ID
                                final selectedCompetition =
                                    competitionController.competitions
                                        .firstWhereOrNull(
                                          (c) =>
                                              c.id ==
                                              participantController
                                                  .selectedEventId
                                                  .value,
                                        );
                                if (selectedCompetition == null) {
                                  participantController.errorMessage.value =
                                      'Please select a competition';
                                  return;
                                }

                                final success = await participantController
                                    .submitRegistrationForm(
                                      eventId: selectedCompetition.id!,
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
          bottomSpacing: 8,
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
                    ? () => _pickPhoto(controller)
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
        FormLabelWithHint(label: 'Yoga Teacher Name :', bottomSpacing: 8),
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
          bottomSpacing: 8,
        ),
        Obx(
          () => TextFormField(
            controller: controller.yogaMasterContactController,
            readOnly: controller.isViewMode.value,
            keyboardType: TextInputType.phone,
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
          // Use formResetTrigger to force rebuild when form is reset
          final resetTrigger = controller.formResetTrigger.value;
          final isEdit = controller.isEditMode;
          final hasText = controller.schoolNameController.text.isNotEmpty;
          final participantId = controller.participantToEdit.value?.id ?? '';
          // Create a unique key that changes when form is reset
          final institutionKey = isEdit && hasText
              ? 'institution-edit-$participantId-${controller.schoolNameController.text}'
              : 'institution-new-$resetTrigger';

          return Autocomplete<SchoolModel>(
            key: ValueKey(institutionKey),
            displayStringForOption: (SchoolModel option) =>
                option.institutionName,
            optionsBuilder: (TextEditingValue textEditingValue) async {
              if (textEditingValue.text.isEmpty ||
                  textEditingValue.text.length < 3) {
                return const Iterable<SchoolModel>.empty();
              }
              // Store the search text for use in optionsViewBuilder
              final searchText = textEditingValue.text.trim();

              // Perform the search
              await controller.searchInstitutions(searchText);

              // Get the suggestions list
              final suggestions = controller.institutionSuggestions;

              // If no results and search has completed, return a placeholder item
              // This ensures the overlay is shown so we can display the "no results" message
              if (suggestions.isEmpty &&
                  !controller.isLoadingInstitutions.value &&
                  searchText.length >= 3) {
                // Return a placeholder SchoolModel with a special ID to indicate "no results"
                // We'll check for this in optionsViewBuilder and show the message instead
                return [
                  SchoolModel(
                    id: '__NO_RESULTS__',
                    institutionName: '__NO_RESULTS__',
                    address: '',
                    pincode: '',
                    institutionType: '__NO_RESULTS__',
                    stateId: 0,
                    cityId: 0,
                  ),
                ];
              }

              // Return the actual suggestions
              return suggestions;
            },
            onSelected: (SchoolModel institution) {
              controller.selectInstitution(institution);
            },
            fieldViewBuilder:
                (
                  BuildContext context,
                  TextEditingController textEditingController,
                  FocusNode focusNode,
                  VoidCallback onFieldSubmitted,
                ) {
                  // Sync the autocomplete controller with the form controller
                  // Update autocomplete controller when schoolNameController changes
                  void syncController() {
                    if (textEditingController.text !=
                        controller.schoolNameController.text) {
                      textEditingController.text =
                          controller.schoolNameController.text;
                    }
                  }

                  // Initial sync
                  syncController();

                  // Listen to changes in schoolNameController and update autocomplete controller
                  controller.schoolNameController.addListener(syncController);

                  // Listen to changes in autocomplete controller and update schoolNameController
                  textEditingController.addListener(() {
                    if (controller.schoolNameController.text !=
                        textEditingController.text) {
                      controller.schoolNameController.text =
                          textEditingController.text;
                    }
                  });

                  return Obx(() {
                    // Ensure sync when schoolNameController changes reactively
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      syncController();
                    });

                    return TextFormField(
                      controller: textEditingController,
                      readOnly: controller.isViewMode.value,
                      focusNode: focusNode,
                      onFieldSubmitted: (String value) {
                        onFieldSubmitted();
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixIcon: controller.isLoadingInstitutions.value
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : const Icon(Icons.search),
                        hintText: 'Search or type institution name',
                        filled: true,
                        fillColor: controller.isViewMode.value
                            ? Colors.grey[200]
                            : Colors.white,
                      ),
                      validator: !controller.isViewMode.value
                          ? (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Institution name is required';
                              }
                              return null;
                            }
                          : null,
                    );
                  });
                },
            optionsViewBuilder:
                (
                  BuildContext context,
                  AutocompleteOnSelected<SchoolModel> onSelected,
                  Iterable<SchoolModel> options,
                ) {
                  return Obx(() {
                    // Get current search text from the controller
                    final searchText = controller.schoolNameController.text
                        .trim();
                    final hasSearchText = searchText.length >= 3;
                    final isLoading = controller.isLoadingInstitutions.value;
                    final suggestions = controller.institutionSuggestions;

                    // Check if we have no results:
                    // - search text is at least 3 characters
                    // - not currently loading (search has completed)
                    // - institution suggestions list is empty (no results from API)
                    // - options contains the placeholder item (indicates no results)
                    final optionsList = options.toList();
                    final hasPlaceholder =
                        optionsList.isNotEmpty &&
                        optionsList.first.id == '__NO_RESULTS__';
                    final hasNoResults =
                        hasSearchText &&
                        !isLoading &&
                        suggestions.isEmpty &&
                        hasPlaceholder;

                    // Debug: Print to see what's happening (remove in production)
                    if (hasSearchText) {
                      print(
                        'DEBUG Autocomplete: hasNoResults=$hasNoResults, hasSearchText=$hasSearchText, isLoading=$isLoading, suggestions.length=${suggestions.length}, options.length=${optionsList.length}, searchText="$searchText"',
                      );
                    }

                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: hasNoResults
                              ? Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.school_outlined,
                                        size: 32,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No institution found',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'for "$searchText"',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          // Close the autocomplete overlay first
                                          FocusScope.of(context).unfocus();

                                          // Show dialog to create new institution
                                          _showAddInstitutionDialog(
                                            context,
                                            controller,
                                            searchText,
                                          );
                                        },
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text(
                                          'Add New Institution',
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.green[700],
                                          side: BorderSide(
                                            color: Colors.green[700]!,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : controller.isLoadingInstitutions.value
                              ? const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final optionsList = options.toList();
                                    final SchoolModel option =
                                        optionsList[index];

                                    // Skip the placeholder item - it's only used to show the overlay
                                    if (option.id == '__NO_RESULTS__') {
                                      return const SizedBox.shrink();
                                    }

                                    return InkWell(
                                      onTap: () => onSelected(option),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              option.institutionName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            if (option.address.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                option.address,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                            if (option.cityName != null ||
                                                option.stateName != null ||
                                                option.pincode.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                '${option.cityName ?? ''}${option.cityName != null && option.stateName != null ? ', ' : ''}${option.stateName ?? ''}${(option.cityName != null || option.stateName != null) && option.pincode.isNotEmpty ? ' - ' : ''}${option.pincode.isNotEmpty ? option.pincode : ''}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    );
                  });
                },
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
          child: Center(
            child: Obx(
              () => OutlinedButton.icon(
                onPressed: !controller.isViewMode.value
                    ? () => _pickBonafideCertificate(controller)
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

  Widget _buildPaymentModeSection(
    BuildContext context,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(label: 'Payment Mode :', bottomSpacing: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '//Here use your usual payment options',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '//Also, provide QR',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '//Payment Amount will be based on the category selected',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickPhoto(ParticipantController controller) async {
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
      Get.snackbar('Error', 'Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _pickBonafideCertificate(
    ParticipantController controller,
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
        Get.snackbar('Success', 'Bonafide certificate selected');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick certificate: ${e.toString()}');
    }
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
