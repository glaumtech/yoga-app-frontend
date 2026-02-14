import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/participant_controller.dart';
import '../../controllers/competition_controller.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/custom_loader.dart';
import '../../widgets/form_label_with_hint.dart';
import '../../widgets/form_title.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;

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

              // Submit Button
              Center(
                child: Obx(() {
                  if (participantController.isLoading.value) {
                    return const CustomLoader(
                      message: 'Creating participant...',
                    );
                  }
                  return PrimaryButton(
                    text: 'SUBMIT',
                    icon: Icons.save,
                    onPressed: () async {
                      // Get selected competition/event ID
                      final selectedCompetition = competitionController
                          .competitions
                          .firstWhereOrNull(
                            (c) =>
                                c.id ==
                                participantController.selectedEventId.value,
                          );
                      if (selectedCompetition == null) {
                        participantController.errorMessage.value =
                            'Please select a competition';
                        return;
                      }

                      final success = await participantController
                          .submitRegistrationForm(
                            eventId: selectedCompetition.id!,
                          );

                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Participant registered successfully',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                        participantController.resetForm();
                      }
                    },
                  );
                }),
              ),
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
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                })
                .toList(),
            onChanged: (value) {
              if (value != null) {
                controller.selectedEventId.value = value;
                // Clear category and group when competition changes
                controller.selectedCategories.clear();
                controller.standard.value = '';
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a competition';
              }
              return null;
            },
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
        TextFormField(
          controller: controller.nameController,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Participant name is required';
            }
            // Validate: Only period symbol for separating initial and name
            final namePattern = RegExp(r'^[A-Za-z\s.]+$');
            if (!namePattern.hasMatch(value.trim())) {
              return 'Name can only contain letters, spaces, and periods';
            }
            return null;
          },
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
        TextFormField(
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: Icon(Icons.calendar_today),
          ),
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: controller.dateOfBirth.value ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              controller.dateOfBirth.value = picked;
            }
          },
          validator: (value) {
            if (controller.dateOfBirth.value == null) {
              return 'Please select date of birth';
            }
            return null;
          },
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
            child: OutlinedButton.icon(
              onPressed: () => _pickPhoto(controller),
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
                  onChanged: (value) {
                    if (value != null) {
                      controller.gender.value = value;
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('FEMALE'),
                  value: 'FEMALE',
                  groupValue: controller.gender.value,
                  onChanged: (value) {
                    if (value != null) {
                      controller.gender.value = value;
                    }
                  },
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
            ),
            hint: const Text('Select Category'),
            items: availableCategories.map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                controller.selectedCategories.value = [value];
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a category';
              }
              return null;
            },
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

          // Get all groups from stageGroups map
          final allGroups = <String>[];
          if (selectedCompetition != null &&
              selectedCompetition.stageGroups != null) {
            selectedCompetition.stageGroups!.values.forEach((groupIds) {
              // Convert group IDs to names
              final groupNames = groupIds
                  .map((id) => competitionController.getGroupNameById(id))
                  .where((name) => name != null)
                  .cast<String>()
                  .toList();
              allGroups.addAll(groupNames);
            });
          }
          final uniqueGroups = allGroups.toSet().toList()..sort();

          return DropdownButtonFormField<String>(
            value: controller.standard.value.isNotEmpty
                ? controller.standard.value
                : null,
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
            items: uniqueGroups.map((group) {
              return DropdownMenuItem<String>(value: group, child: Text(group));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                controller.standard.value = value;
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
        TextFormField(
          controller: controller.yogaMasterNameController,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Yoga teacher name is required';
            }
            return null;
          },
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
        TextFormField(
          controller: controller.yogaMasterContactController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            counterText: '',
          ),
          validator: (value) {
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
            if (value.trim() == '9876543210' || value.trim() == '0123456789') {
              return 'Invalid cell number';
            }
            return null;
          },
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
        TextFormField(
          controller: controller.schoolNameController,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: Icon(Icons.search),
            hintText: 'Search or type institution name',
          ),
          // TODO: Add autocomplete functionality from schools/colleges list
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Institution name is required';
            }
            return null;
          },
        ),
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
            child: OutlinedButton.icon(
              onPressed: () => _pickBonafideCertificate(controller),
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
        Get.snackbar('Success', 'Bonafide certificate selected');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick certificate: ${e.toString()}');
    }
  }

  Widget _buildImagePreview(
    File? file,
    XFile? xFile,
    double width,
    double height, {
    IconData defaultIcon = Icons.image,
    String defaultText = 'No Image',
  }) {
    final hasImage = (xFile != null) || (file != null && file.existsSync());

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: hasImage
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
          Text(
            text,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
