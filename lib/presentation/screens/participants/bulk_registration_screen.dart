import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../controllers/participant_controller.dart';
import '../../controllers/competition_controller.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/custom_loader.dart';
import '../../widgets/form_title.dart';
import '../../../core/theme/app_theme.dart';
import '../../models/bulk_registration_row.dart';

class BulkRegistrationScreen extends StatelessWidget {
  const BulkRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final participantController = Get.find<ParticipantController>();
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                FormTitle(
                  text: 'BULK REGISTRATION',
                  isMobile: isMobile,
                  isTablet: isTablet,
                ),

                // Common Fields Section
                _buildCommonFieldsSection(
                  context,
                  participantController,
                  competitionController,
                  isMobile,
                  isTablet,
                ),
                SizedBox(height: isMobile ? 24 : 32),

                // Participants Table
                _buildParticipantsTable(
                  context,
                  participantController,
                  competitionController,
                  isMobile,
                  isTablet,
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
                        const Icon(Icons.error_outline, color: Colors.red),
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
                  child: Obx(
                    () => participantController.isLoading.value
                        ? const CustomLoader()
                        : PrimaryButton(
                            text: 'SAVE',
                            onPressed: () async {
                              if (participantController
                                  .selectedEventId
                                  .value
                                  .isEmpty) {
                                participantController.errorMessage.value =
                                    'Please select a competition';
                                return;
                              }
                              await participantController
                                  .submitBulkRegistration();
                            },
                            width: isMobile ? double.infinity : 200,
                          ),
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 24),
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
        Text(
          'COMPETITION :',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        const SizedBox(height: 8),
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
                controller.bulkCategory.value = '';
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

  Widget _buildCommonFieldsSection(
    BuildContext context,
    ParticipantController controller,
    CompetitionController competitionController,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Competition, Category, and Institution Name in same row
        isMobile
            ? Column(
                children: [
                  _buildCompetitionField(
                    context,
                    controller,
                    competitionController,
                    isMobile,
                    isTablet,
                  ),
                  SizedBox(height: isMobile ? 20 : 24),
                  _buildCategoryField(
                    context,
                    controller,
                    competitionController,
                    isMobile,
                    isTablet,
                  ),
                  SizedBox(height: isMobile ? 20 : 24),
                  _buildInstitutionField(
                    context,
                    controller,
                    isMobile,
                    isTablet,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildCompetitionField(
                      context,
                      controller,
                      competitionController,
                      isMobile,
                      isTablet,
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 20),
                  Expanded(
                    child: _buildCategoryField(
                      context,
                      controller,
                      competitionController,
                      isMobile,
                      isTablet,
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 20),
                  Expanded(
                    child: _buildInstitutionField(
                      context,
                      controller,
                      isMobile,
                      isTablet,
                    ),
                  ),
                ],
              ),
        SizedBox(height: isMobile ? 20 : 24),

        // Yoga Teacher Name and Yoga Teacher Cell in same row (3 columns)
        isMobile
            ? Column(
                children: [
                  _buildTextField(
                    context,
                    label: 'Yoga Teacher Name :',
                    controller: controller.bulkYogaTeacherNameController,
                    isRequired: true,
                    isMobile: isMobile,
                    isTablet: isTablet,
                  ),
                  SizedBox(height: isMobile ? 20 : 24),
                  _buildYogaTeacherCellField(
                    context,
                    controller,
                    isMobile,
                    isTablet,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      context,
                      label: 'Yoga Teacher Name :',
                      controller: controller.bulkYogaTeacherNameController,
                      isRequired: true,
                      isMobile: isMobile,
                      isTablet: isTablet,
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 20),
                  Expanded(
                    child: _buildYogaTeacherCellField(
                      context,
                      controller,
                      isMobile,
                      isTablet,
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 20),
                  Expanded(
                    child: SizedBox.shrink(), // Empty third column
                  ),
                ],
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
        Text(
          'Yoga Teacher Cell :',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '(Without +91)',
          style: TextStyle(
            fontSize: isMobile ? 11 : 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller.bulkYogaTeacherCellController,
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
            if (value.trim().length != 10) {
              return 'Cell number must be 10 digits';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
    bool isMobile = false,
    bool isTablet = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildInstitutionField(
    BuildContext context,
    ParticipantController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Institution Name :',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller.bulkInstitutionNameController,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: const Icon(Icons.arrow_drop_down),
            hintText: 'Search or type institution name',
          ),
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
        Text(
          'Category :',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          final selectedCompetition = competitionController.competitions
              .firstWhereOrNull(
                (c) => c.id == controller.selectedEventId.value,
              );

          final categories = selectedCompetition?.categories ?? [];

          return DropdownButtonFormField<String>(
            value: controller.bulkCategory.value.isNotEmpty
                ? controller.bulkCategory.value
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
            items: categories.map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                controller.bulkCategory.value = value;
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

  Widget _buildParticipantsTable(
    BuildContext context,
    ParticipantController controller,
    CompetitionController competitionController,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table Header
        if (!isMobile)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'NAME',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Expanded(
                  child: Text(
                    'D.O.B',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Expanded(
                  child: Text(
                    'SEX',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Expanded(
                  child: Text(
                    'GROUP',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Expanded(
                  child: Text(
                    'PHOTO',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        // Table Rows
        Obx(
          () => Column(
            children: [
              ...controller.bulkRegistrationRows.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                return _buildTableRow(
                  context,
                  controller,
                  competitionController,
                  index,
                  row,
                  isMobile,
                  isTablet,
                );
              }).toList(),
            ],
          ),
        ),
        // Add More Button
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => controller.addBulkRegistrationRow(),
              icon: const Icon(Icons.add),
              label: const Text('Add More'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableRow(
    BuildContext context,
    ParticipantController controller,
    CompetitionController competitionController,
    int index,
    BulkRegistrationRow row,
    bool isMobile,
    bool isTablet,
  ) {
    if (isMobile) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMobileField(
                'NAME',
                TextFormField(
                  controller: row.nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildMobileField(
                'D.O.B',
                InkWell(
                  onTap: () => _selectDate(context, row),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                      isDense: true,
                    ),
                    child: Obx(
                      () => Text(
                        row.dateOfBirth.value != null
                            ? DateFormat(
                                'yyyy-MM-dd',
                              ).format(row.dateOfBirth.value!)
                            : 'Select date',
                        style: TextStyle(
                          color: row.dateOfBirth.value != null
                              ? Colors.black
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildMobileField(
                'SEX',
                Obx(
                  () => DropdownButtonFormField<String>(
                    value: row.gender.value.isNotEmpty
                        ? row.gender.value
                        : null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: ['Male', 'Female'].map((gender) {
                      return DropdownMenuItem<String>(
                        value: gender,
                        child: Text(gender),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        row.gender.value = value;
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildMobileField(
                'GROUP',
                _buildGroupDropdown(
                  context,
                  controller,
                  competitionController,
                  row,
                  isMobile,
                ),
              ),
              const SizedBox(height: 12),
              _buildMobileField(
                'PHOTO',
                _buildPhotoField(context, controller, row, isMobile),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          // NAME
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: row.nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // D.O.B
          Expanded(
            child: InkWell(
              onTap: () => _selectDate(context, row),
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
                child: Obx(
                  () => Text(
                    row.dateOfBirth.value != null
                        ? DateFormat(
                            'dd/MM/yyyy',
                          ).format(row.dateOfBirth.value!)
                        : 'Select',
                    style: TextStyle(
                      fontSize: 12,
                      color: row.dateOfBirth.value != null
                          ? Colors.black
                          : Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // SEX
          Expanded(
            child: Obx(
              () => DropdownButtonFormField<String>(
                value: row.gender.value.isNotEmpty ? row.gender.value : null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
                items: ['Male', 'Female'].map((gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender, style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    row.gender.value = value;
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // GROUP
          Expanded(
            child: _buildGroupDropdown(
              context,
              controller,
              competitionController,
              row,
              isMobile,
            ),
          ),
          const SizedBox(width: 8),
          // PHOTO
          Expanded(child: _buildPhotoField(context, controller, row, isMobile)),
        ],
      ),
    );
  }

  Widget _buildMobileField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 4),
        field,
      ],
    );
  }

  Widget _buildGroupDropdown(
    BuildContext context,
    ParticipantController controller,
    CompetitionController competitionController,
    BulkRegistrationRow row,
    bool isMobile,
  ) {
    return Obx(() {
      final selectedCompetition = competitionController.competitions
          .firstWhereOrNull((c) => c.id == controller.selectedEventId.value);

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
        value: row.group.value.isNotEmpty ? row.group.value : null,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 8,
            vertical: 8,
          ),
          isDense: true,
        ),
        hint: Text('Select', style: TextStyle(fontSize: isMobile ? 12 : 12)),
        items: uniqueGroups.map((group) {
          return DropdownMenuItem<String>(
            value: group,
            child: Text(group, style: TextStyle(fontSize: isMobile ? 12 : 12)),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            row.group.value = value;
          }
        },
      );
    });
  }

  Widget _buildPhotoField(
    BuildContext context,
    ParticipantController controller,
    BulkRegistrationRow row,
    bool isMobile,
  ) {
    return Obx(
      () => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            onPressed: () => _pickPhoto(context, controller, row),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 12,
                vertical: isMobile ? 6 : 8,
              ),
              minimumSize: const Size(0, 32),
            ),
            child: const Text('BROWSE', style: TextStyle(fontSize: 12)),
          ),
          if (row.photoFile.value != null ||
              row.photoXFile.value != null ||
              row.photoBytes.value != null) ...[
            const SizedBox(height: 4),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: kIsWeb
                    ? (row.photoBytes.value != null
                          ? Image.memory(
                              row.photoBytes.value!,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.image, size: 20))
                    : (row.photoFile.value != null &&
                              row.photoFile.value!.existsSync()
                          ? Image.file(row.photoFile.value!, fit: BoxFit.cover)
                          : const Icon(Icons.image, size: 20)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    BulkRegistrationRow row,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: row.dateOfBirth.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      row.dateOfBirth.value = picked;
      row.dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _pickPhoto(
    BuildContext context,
    ParticipantController controller,
    BulkRegistrationRow row,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        row.photoXFile.value = image;
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          row.photoBytes.value = bytes;
        } else {
          row.photoFile.value = File(image.path);
        }
      }
    } catch (e) {
      controller.errorMessage.value = 'Error picking image: ${e.toString()}';
    }
  }
}
