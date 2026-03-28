import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../config/app_config.dart';
import '../../../core/utils/storage_service.dart';
import '../../controllers/competition_controller.dart';
import '../../widgets/admin_sidebar_layout.dart';
import '../../widgets/form_title.dart';
import '../../widgets/toggle_button_group.dart';
import '../../widgets/buttons.dart';
import '../../widgets/form_label_with_hint.dart';
import 'competitions_list_screen.dart';

class CreateCompetitionScreen extends StatelessWidget {
  const CreateCompetitionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CompetitionController());

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    // Clear form when switching to create view (if not in edit mode)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.isListView.value && !controller.isEditMode.value) {
        // Check if form has values that shouldn't be there
        if (controller.competitionNameController.text.isNotEmpty ||
            controller.descriptionController.text.isNotEmpty ||
            controller.addressController.text.isNotEmpty) {
          controller.clearForm();
        }
      }
    });

    return AdminSidebarLayout(
      title: 'COMPETITIONS',
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
              // Toggle Buttons
              Padding(
                padding: EdgeInsets.only(
                  top: isMobile ? 8 : 10,
                  bottom: 0,
                  left: isMobile ? 16 : 24,
                  right: isMobile ? 16 : 24,
                ),
                child: Obx(
                  () => ToggleButtonGroup(
                    options: [
                      ToggleButtonOption(
                        label: controller.isViewMode.value
                            ? ' VIEW'
                            : controller.isEditMode.value
                            ? ' EDIT'
                            : ' CREATE',
                        icon: controller.isViewMode.value
                            ? Icons.visibility
                            : controller.isEditMode.value
                            ? Icons.edit
                            : Icons.add,
                      ),
                      const ToggleButtonOption(label: '≡ LIST'),
                    ],
                    selectedIndex: controller.isListView.value ? 1 : 0,
                    onTap: (index) => controller.toggleViewMode(index == 1),
                  ),
                ),
              ),
              // Content (Create Form or List View)
              Expanded(
                child: Obx(
                  () => controller.isListView.value
                      ? const CompetitionsListScreen()
                      : SingleChildScrollView(
                          padding: EdgeInsets.all(isMobile ? 16 : 10),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: double.infinity,
                              ),
                              child: _buildForm(
                                context,
                                controller,
                                isMobile,
                                isTablet,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : (isTablet ? 20 : 24)),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Obx(
                () => FormTitle(
                  text: controller.isViewMode.value
                      ? 'VIEW COMPETITION'
                      : controller.isEditMode.value
                      ? 'EDIT COMPETITION'
                      : 'CREATE COMPETITION',
                  isMobile: isMobile,
                  isTablet: isTablet,
                ),
              ),

              // Competition Name, Description, Address (right aligned) | Brochure Upload (right side)
              isMobile
                  ? Column(
                      children: [
                        // Upload Brochure (top on mobile)
                        _buildBrochureUpload(
                          context,
                          controller,
                          isMobile,
                          isTablet,
                        ),
                        SizedBox(height: isMobile ? 20 : 24),
                        // Competition Name (right aligned)
                        _buildTextField(
                          context,
                          controller,
                          label: 'COMPETITION NAME :',
                          textController: controller.competitionNameController,
                          isRequired: true,
                          isMobile: isMobile,
                          isTablet: isTablet,
                          textAlign: TextAlign.left,
                        ),
                        SizedBox(height: isMobile ? 20 : 24),
                        // Description (right aligned)
                        _buildTextField(
                          context,
                          controller,
                          label: 'DESCRIPTION :',
                          textController: controller.descriptionController,
                          isRequired: true,
                          maxLines: 2,
                          isMobile: isMobile,
                          isTablet: isTablet,
                          textAlign: TextAlign.left,
                        ),
                        SizedBox(height: isMobile ? 20 : 24),
                        // Address (right aligned)
                        _buildTextField(
                          context,
                          controller,
                          label: 'ADDRESS :',
                          textController: controller.addressController,
                          isRequired: true,
                          maxLines: 2,
                          isMobile: isMobile,
                          isTablet: isTablet,
                          textAlign: TextAlign.left,
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side: Competition Name, Description, Address (right aligned)
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              // Competition Name (right aligned)
                              _buildTextField(
                                context,
                                controller,
                                label: 'COMPETITION NAME :',
                                textController:
                                    controller.competitionNameController,
                                isRequired: true,
                                isMobile: isMobile,
                                isTablet: isTablet,
                                textAlign: TextAlign.left,
                              ),
                              SizedBox(height: isMobile ? 20 : 24),
                              // Description (right aligned)
                              _buildTextField(
                                context,
                                controller,
                                label: 'DESCRIPTION :',
                                textController:
                                    controller.descriptionController,
                                isRequired: true,
                                maxLines: 2,
                                isMobile: isMobile,
                                isTablet: isTablet,
                                textAlign: TextAlign.left,
                              ),
                              SizedBox(height: isMobile ? 20 : 24),
                              // Address (right aligned)
                              _buildTextField(
                                context,
                                controller,
                                label: 'ADDRESS :',
                                textController: controller.addressController,
                                isRequired: true,
                                maxLines: 2,
                                isMobile: isMobile,
                                isTablet: isTablet,
                                textAlign: TextAlign.left,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 24),
                        // Right side: Upload Brochure
                        Expanded(
                          flex: 1,
                          child: _buildBrochureUpload(
                            context,
                            controller,
                            isMobile,
                            isTablet,
                          ),
                        ),
                      ],
                    ),
              SizedBox(height: isMobile ? 20 : 24),

              // Event Start, End, and Display Ad From in same line
              isMobile
                  ? Column(
                      children: [
                        _buildDateField(
                          context,
                          controller,
                          label: 'EVENT START DATE :',
                          isStartDate: true,
                          isDisplayAd: false,
                          isMobile: isMobile,
                          isTablet: isTablet,
                        ),
                        SizedBox(height: isMobile ? 20 : 24),
                        _buildDateField(
                          context,
                          controller,
                          label: 'EVENT END DATE :',
                          isStartDate: false,
                          isDisplayAd: false,
                          isMobile: isMobile,
                          isTablet: isTablet,
                        ),
                        SizedBox(height: isMobile ? 20 : 24),
                        _buildDateField(
                          context,
                          controller,
                          label: 'DISPLAY AD FROM :',
                          isStartDate: false,
                          isDisplayAd: true,
                          isRequired: true,
                          isMobile: isMobile,
                          isTablet: isTablet,
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildDateField(
                            context,
                            controller,
                            label: 'EVENT START DATE :',
                            isStartDate: true,
                            isDisplayAd: false,
                            isMobile: isMobile,
                            isTablet: isTablet,
                          ),
                        ),
                        SizedBox(width: isTablet ? 12 : 16),
                        Expanded(
                          child: _buildDateField(
                            context,
                            controller,
                            label: 'EVENT END DATE :',
                            isStartDate: false,
                            isDisplayAd: false,
                            isMobile: isMobile,
                            isTablet: isTablet,
                          ),
                        ),
                        SizedBox(width: isTablet ? 12 : 16),
                        Expanded(
                          child: _buildDateField(
                            context,
                            controller,
                            label: 'DISPLAY AD FROM :',
                            isStartDate: false,
                            isDisplayAd: true,
                            isRequired: true,
                            isMobile: isMobile,
                            isTablet: isTablet,
                          ),
                        ),
                      ],
                    ),
              SizedBox(height: isMobile ? 20 : 24),

              // Participants Per Stage and Marks in same line (desktop)
              isMobile
                  ? Column(
                      children: [
                        _buildParticipantsPerStageField(
                          context,
                          controller,
                          isMobile,
                          isTablet,
                        ),
                        SizedBox(height: isMobile ? 20 : 24),

                        _buildMarksField(
                          context,
                          controller,
                          isMobile,
                          isTablet,
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildParticipantsPerStageField(
                            context,
                            controller,
                            isMobile,
                            isTablet,
                          ),
                        ),
                        SizedBox(width: isTablet ? 12 : 16),

                        Expanded(
                          flex: 2,
                          child: _buildMarksField(
                            context,
                            controller,
                            isMobile,
                            isTablet,
                          ),
                        ),
                      ],
                    ),
              SizedBox(height: isMobile ? 20 : 24),

              // Prizes and Categories in same line (desktop)
              isMobile
                  ? Column(
                      children: [
                        _buildPrizesField(
                          context,
                          controller,
                          isMobile,
                          isTablet,
                        ),
                        SizedBox(height: isMobile ? 20 : 24),
                        _buildCategoriesField(
                          context,
                          controller,
                          isMobile,
                          isTablet,
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildPrizesField(
                            context,
                            controller,
                            isMobile,
                            isTablet,
                          ),
                        ),
                        SizedBox(width: isTablet ? 12 : 16),
                        Expanded(
                          child: _buildCategoriesField(
                            context,
                            controller,
                            isMobile,
                            isTablet,
                          ),
                        ),
                      ],
                    ),
              SizedBox(height: isMobile ? 20 : 24),

              // Category Amounts
              Obx(
                () => controller.selectedCategories.isNotEmpty
                    ? Column(
                        children: [
                          _buildCategoryAmountsField(
                            context,
                            controller,
                            isMobile,
                            isTablet,
                          ),
                          SizedBox(height: isMobile ? 20 : 24),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),

              // Stages
              _buildStagesField(context, controller, isMobile, isTablet),
              SizedBox(height: isMobile ? 20 : 24),

              // Show mapped groups for selected stages
              Obx(
                () => controller.selectedStages.isNotEmpty
                    ? Column(
                        children: [
                          _buildStageGroupsDisplay(
                            context,
                            controller,
                            isMobile,
                            isTablet,
                          ),
                          SizedBox(height: isMobile ? 20 : 24),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),

              // Error Message
              if (controller.errorMessage.value.isNotEmpty)
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
                          controller.errorMessage.value,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),

              // Submit and Cancel Buttons
              Obx(
                () => controller.isEditMode.value
                    ? SizedBox(height: isMobile ? 24 : 32)
                    : SizedBox(height: isMobile ? 24 : 32),
              ),
              Obx(
                () => controller.isViewMode.value
                    ? (isMobile
                          ? Column(
                              children: [
                                cancelButton(
                                  onPressed: () {
                                    controller.clearForm();
                                    controller.toggleViewMode(true);
                                  },
                                  isFullWidth: true,
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                cancelButton(
                                  onPressed: () {
                                    controller.clearForm();
                                    controller.toggleViewMode(true);
                                  },
                                  width: 200,
                                ),
                              ],
                            ))
                    : controller.isEditMode.value
                    ? (isMobile
                          ? Column(
                              children: [
                                saveButton(
                                  onPressed: () async {
                                    await controller.updateCompetition();
                                  },
                                  isLoading: controller.isLoading,
                                  text: 'UPDATE',
                                  isFullWidth: true,
                                ),
                                const SizedBox(height: 12),
                                cancelButton(
                                  onPressed: () {
                                    controller.clearForm();
                                    controller.toggleViewMode(true);
                                  },
                                  isFullWidth: true,
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                saveButton(
                                  onPressed: () async {
                                    await controller.updateCompetition();
                                  },
                                  isLoading: controller.isLoading,
                                  text: 'UPDATE',
                                  width: 200,
                                ),
                                const SizedBox(width: 16),
                                cancelButton(
                                  onPressed: () {
                                    controller.clearForm();
                                    controller.toggleViewMode(true);
                                  },
                                  width: 200,
                                ),
                              ],
                            ))
                    : (isMobile
                          ? Column(
                              children: [
                                saveButton(
                                  onPressed: () async {
                                    await controller.createCompetition();
                                  },
                                  isLoading: controller.isLoading,
                                  isFullWidth: true,
                                ),
                                const SizedBox(height: 12),
                                cancelButton(
                                  onPressed: () {
                                    controller.clearForm();
                                    controller.toggleViewMode(true);
                                  },
                                  isFullWidth: true,
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                saveButton(
                                  onPressed: () async {
                                    await controller.createCompetition();
                                  },
                                  isLoading: controller.isLoading,
                                  width: 200,
                                ),
                                const SizedBox(width: 16),
                                cancelButton(
                                  onPressed: () {
                                    controller.clearForm();
                                    controller.toggleViewMode(true);
                                  },
                                  width: 200,
                                ),
                              ],
                            )),
              ),
              SizedBox(height: isMobile ? 16 : 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context,
    CompetitionController competitionController, {
    required String label,
    required TextEditingController textController,
    bool isRequired = false,
    int maxLines = 1,
    bool isMobile = false,
    bool isTablet = false,
    TextAlign textAlign = TextAlign.left,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(label: label),
        Obx(
          () => TextFormField(
            controller: textController,
            maxLines: maxLines,
            textAlign: textAlign,
            readOnly: competitionController.isViewMode.value,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: competitionController.isViewMode.value
                  ? Colors.grey[200]
                  : Colors.grey[50],
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: isMobile ? 12 : 16,
              ),
              isDense: isMobile,
            ),
            validator: isRequired && !competitionController.isViewMode.value
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'This field is required';
                    }
                    return null;
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildBrochureUpload(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(label: 'UPLOAD BROCHURE :'),
        FormField<bool>(
          initialValue:
              controller.brochureFile.value != null ||
              controller.brochureFileLocal.value != null ||
              controller.brochureBytes.value != null ||
              (controller.isEditMode.value &&
                  controller.competitionToEdit.value?.id != null),
          validator: (value) {
            // In edit mode, if there's already a brochure URL, it's valid
            if (controller.isEditMode.value &&
                controller.competitionToEdit.value?.id != null) {
              return null; // Brochure is optional for updates if one already exists
            }
            // For create mode, check if local file is uploaded
            final hasBrochure =
                controller.brochureFile.value != null ||
                controller.brochureFileLocal.value != null ||
                controller.brochureBytes.value != null;
            if (!hasBrochure) {
              return 'Please upload a brochure';
            }
            return null;
          },
          builder: (FormFieldState<bool> field) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBrochurePreview(context, controller, isMobile, isTablet),
                Obx(
                  () => controller.isViewMode.value
                      ? const SizedBox.shrink()
                      : const SizedBox(height: 8),
                ),
                Obx(
                  () => controller.isViewMode.value
                      ? const SizedBox.shrink()
                      : Center(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await controller.pickBrochure();
                              // Update form field value after picking
                              final hasBrochure =
                                  controller.brochureFile.value != null ||
                                  controller.brochureFileLocal.value != null ||
                                  controller.brochureBytes.value != null;
                              field.didChange(hasBrochure);
                              field.validate();
                            },
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: const Text('BROWSE'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: BorderSide(color: AppTheme.primaryColor),
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 16,
                                vertical: isMobile ? 10 : 12,
                              ),
                            ),
                          ),
                        ),
                ),
                Obx(() {
                  // Don't show error in edit mode if brochure already exists
                  final shouldShowError =
                      controller.hasAttemptedSubmit.value &&
                      field.errorText != null &&
                      !(controller.isEditMode.value &&
                          controller.competitionToEdit.value?.id != null);
                  return shouldShowError
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8, left: 12),
                          child: Text(
                            field.errorText!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 12,
                            ),
                          ),
                        )
                      : const SizedBox.shrink();
                }),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildBrochurePreview(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Obx(() {
      // Check if we have a local file (for create mode)
      final hasLocalFile =
          controller.brochureFile.value != null ||
          controller.brochureFileLocal.value != null ||
          controller.brochureBytes.value != null;

      // Check if we have a competition ID (for view/edit mode)
      final hasApiBrochure =
          (controller.isEditMode.value || controller.isViewMode.value) &&
          controller.competitionToEdit.value?.id != null;

      final hasBrochure = hasLocalFile || hasApiBrochure;

      return GestureDetector(
        onTap: hasBrochure
            ? () => _showBrochurePreviewDialog(context, controller)
            : null,
        child: Container(
          width: double.infinity,
          height: isMobile ? 200 : 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
            color: Colors.grey[100],
          ),
          child: hasBrochure
              ? Stack(
                  children: [
                    // Preview banner image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Obx(() => _buildPreviewImage(controller)),
                    ),
                    // Preview overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.black.withOpacity(0.2),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.visibility,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : _buildDefaultBrochurePreview(),
        ),
      );
    });
  }

  Widget _buildDefaultBrochurePreview() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description, color: Colors.grey[400], size: 60),
          const SizedBox(height: 12),
          Text(
            'No Brochure',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewImage(CompetitionController controller) {
    // Priority 1: Check if a new local file has been uploaded (for both create and edit modes)
    // This takes precedence over API brochure in edit mode
    // Access reactive values to ensure this widget rebuilds when they change
    final brochureBytes = controller.brochureBytes.value;
    final brochureFileLocal = controller.brochureFileLocal.value;
    final isEditMode = controller.isEditMode.value;
    final isViewMode = controller.isViewMode.value;
    final competitionId = controller.competitionToEdit.value?.id;
    final updateTimestamp = controller.brochureUpdateTimestamp.value;

    if (brochureBytes != null) {
      // Web: Use Image.memory
      return Image.memory(
        brochureBytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultBrochurePreview();
        },
      );
    } else if (brochureFileLocal != null && brochureFileLocal.existsSync()) {
      // Mobile/Desktop: Use Image.file
      return Image.file(
        brochureFileLocal,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultBrochurePreview();
        },
      );
    }
    // Priority 2: If no local file, check if we're in edit/view mode and have a competition ID
    // Use API URL for brochure (existing brochure from server)
    else if ((isEditMode || isViewMode) && competitionId != null) {
      // Use API URL for brochure with cache-busting parameter only when brochure is updated
      // Use stable timestamp based on competition ID to prevent excessive API calls
      // Only add timestamp parameter if brochure was recently updated
      final brochureUrl = updateTimestamp > 0
          ? '${AppConfig.baseUrl}${EndPoints.competitionBrochure(competitionId)}?t=$updateTimestamp'
          : '${AppConfig.baseUrl}${EndPoints.competitionBrochure(competitionId)}';

      return Image.network(
        brochureUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        headers: _getImageHeaders(),
        cacheWidth: null, // Allow full resolution
        cacheHeight: null,
        // Add a key that includes timestamp only when brochure is updated to force rebuild
        key: ValueKey(
          updateTimestamp > 0
              ? 'brochure_${competitionId}_$updateTimestamp'
              : 'brochure_$competitionId',
        ),
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
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultBrochurePreview();
        },
      );
    } else {
      return _buildDefaultBrochurePreview();
    }
  }

  Map<String, String> _getImageHeaders() {
    try {
      final token = StorageService.getString(AppConstants.tokenKey);
      if (token != null && token.isNotEmpty) {
        return {'Authorization': 'Bearer $token'};
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  void _showBrochurePreviewDialog(
    BuildContext context,
    CompetitionController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.preview, color: Colors.white),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Brochure Preview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Preview content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Center(child: _buildPreviewImage(controller)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context,
    CompetitionController controller, {
    required String label,
    required bool isStartDate,
    required bool isDisplayAd,
    bool isRequired = true,
    bool isMobile = false,
    bool isTablet = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(label: label),
        FormField<DateTime>(
          initialValue: isStartDate
              ? controller.eventStartDate.value
              : isDisplayAd
              ? controller.displayAdFrom.value
              : controller.eventEndDate.value,
          validator: isRequired
              ? (value) {
                  if (value == null) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
          builder: (FormFieldState<DateTime> field) {
            return Obx(() {
              final currentDate = isStartDate
                  ? controller.eventStartDate.value
                  : isDisplayAd
                  ? controller.displayAdFrom.value
                  : controller.eventEndDate.value;

              // Update field value when date changes
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (field.value != currentDate) {
                  field.didChange(currentDate);
                  field.validate();
                }
              });

              return InkWell(
                onTap: controller.isViewMode.value
                    ? null
                    : () async {
                        await _selectDate(
                          context,
                          controller,
                          isStartDate: isStartDate,
                          isDisplayAd: isDisplayAd,
                        );
                        // Trigger validation after date selection
                        Future.delayed(const Duration(milliseconds: 100), () {
                          final updatedDate = isStartDate
                              ? controller.eventStartDate.value
                              : isDisplayAd
                              ? controller.displayAdFrom.value
                              : controller.eventEndDate.value;
                          field.didChange(updatedDate);
                          field.validate();
                        });
                      },
                child: Obx(
                  () => InputDecorator(
                    decoration: InputDecoration(
                      hintText: 'Select date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: controller.isViewMode.value
                          ? Colors.grey[200]
                          : Colors.grey[50],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: isMobile ? 12 : 16,
                      ),
                      isDense: isMobile,
                      suffixIcon: controller.isViewMode.value
                          ? null
                          : const Icon(Icons.calendar_today),
                      errorText: controller.hasAttemptedSubmit.value
                          ? field.errorText
                          : null,
                    ),
                    child: Text(
                      currentDate != null
                          ? DateFormat('yyyy-MM-dd').format(currentDate)
                          : '',
                      style: TextStyle(
                        color: currentDate != null
                            ? Colors.black
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              );
            });
          },
        ),
      ],
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    CompetitionController controller, {
    bool isStartDate = false,
    bool isDisplayAd = false,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? controller.eventStartDate.value ?? DateTime.now()
          : isDisplayAd
          ? controller.displayAdFrom.value ?? DateTime.now()
          : controller.eventEndDate.value ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      if (isStartDate) {
        controller.eventStartDate.value = picked;
      } else if (isDisplayAd) {
        controller.displayAdFrom.value = picked;
      } else {
        controller.eventEndDate.value = picked;
      }
    }
  }

  Widget _buildMarksField(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(label: 'MARKS :'),
        Row(
          children: [
            Expanded(
              child: Obx(
                () => DropdownButtonFormField<int>(
                  value: controller.minimumMarks.value > 0
                      ? controller.minimumMarks.value
                      : null,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: controller.isViewMode.value
                        ? Colors.grey[200]
                        : Colors.grey[50],
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: isMobile ? 12 : 16,
                    ),
                    isDense: isMobile,
                    hint: Text(
                      'Min',
                      style: TextStyle(fontSize: isMobile ? 13 : 14),
                    ),
                  ),
                  items: CompetitionController.marksOptions
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: controller.isViewMode.value
                      ? null
                      : (value) => controller.minimumMarks.value = value ?? 0,
                ),
              ),
            ),
            SizedBox(width: isMobile ? 8 : 12),
            Expanded(
              child: Obx(
                () => DropdownButtonFormField<int>(
                  value: controller.maximumMarks.value > 0
                      ? controller.maximumMarks.value
                      : null,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: controller.isViewMode.value
                        ? Colors.grey[200]
                        : Colors.grey[50],
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: isMobile ? 12 : 16,
                    ),
                    isDense: isMobile,
                    hint: Text(
                      'Max',
                      style: TextStyle(fontSize: isMobile ? 13 : 14),
                    ),
                  ),
                  items: CompetitionController.marksOptions
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: controller.isViewMode.value
                      ? null
                      : (value) => controller.maximumMarks.value = value ?? 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParticipantsPerStageField(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(label: 'PARTICIPANTS PER STAGE :'),
        Obx(
          () => DropdownButtonFormField<int>(
            value: controller.participantsPerStage.value > 0
                ? controller.participantsPerStage.value
                : null,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: controller.isViewMode.value
                  ? Colors.grey[200]
                  : Colors.grey[50],
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: isMobile ? 12 : 16,
              ),
              isDense: isMobile,
            ),
            items: CompetitionController.participantsPerStageOptions
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value.toString()),
                  ),
                )
                .toList(),
            onChanged: controller.isViewMode.value
                ? null
                : (value) => controller.participantsPerStage.value = value ?? 0,
            hint: const Text('Select participants per stage'),
            validator: controller.isViewMode.value
                ? null
                : (value) {
                    if (value == null || value <= 0) {
                      return 'This field is required';
                    }
                    return null;
                  },
          ),
        ),
      ],
    );
  }

  /// Groups checkboxes + "Add More" so each section is visually distinct.
  Widget _optionSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.22),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildPrizesField(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(label: 'PRIZES :'),
        const SizedBox(height: 8),
        _optionSectionCard(
          child: FormField<List<String>>(
            initialValue: controller.selectedPrizes.toList(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select at least one prize';
              }
              return null;
            },
            builder: (FormFieldState<List<String>> field) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return Obx(() {
                    // Update field value when prizes change
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (field.value != controller.selectedPrizes.toList()) {
                        field.didChange(controller.selectedPrizes.toList());
                        field.validate();
                      }
                    });

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Wrap(
                                spacing: isMobile ? 8 : 16,
                                runSpacing: 8,
                                children: [
                                  ...controller.prizeOptionNames.map((prize) {
                                    final isSelected = controller.selectedPrizes
                                        .contains(prize);
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Checkbox(
                                          value: isSelected,
                                          onChanged: controller.isViewMode.value
                                              ? null
                                              : (value) {
                                                  controller.togglePrize(prize);
                                                  field.didChange(
                                                    controller.selectedPrizes
                                                        .toList(),
                                                  );
                                                  field.validate();
                                                },
                                          activeColor: AppTheme.primaryColor,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        Text(prize),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                            if (!controller.isViewMode.value) ...[
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _showAddPrizeDialog(context, controller),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add More'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryColor,
                                  side: BorderSide(
                                    color: AppTheme.primaryColor,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 12 : 16,
                                    vertical: isMobile ? 8 : 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Obx(
                          () =>
                              controller.hasAttemptedSubmit.value &&
                                  field.errorText != null
                              ? Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    left: 12,
                                  ),
                                  child: Text(
                                    field.errorText!,
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    );
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesField(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(label: 'CATEGORIES :'),
        const SizedBox(height: 8),
        _optionSectionCard(
          child: FormField<List<String>>(
            initialValue: controller.selectedCategories.toList(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select at least one category';
              }
              return null;
            },
            builder: (FormFieldState<List<String>> field) {
              return Obx(() {
                // Update field value when categories change
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (field.value != controller.selectedCategories.toList()) {
                    field.didChange(controller.selectedCategories.toList());
                    field.validate();
                  }
                });

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: isMobile ? 8 : 16,
                      runSpacing: 8,
                      children: [
                        ...controller.categoryOptionNames.map((category) {
                          final isSelected = controller.selectedCategories
                              .contains(category);
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isSelected,
                                onChanged: controller.isViewMode.value
                                    ? null
                                    : (value) {
                                        controller.toggleCategory(category);
                                        field.didChange(
                                          controller.selectedCategories
                                              .toList(),
                                        );
                                        field.validate();
                                      },
                                activeColor: AppTheme.primaryColor,
                              ),
                              Text(category),
                            ],
                          );
                        }),
                        if (!controller.isViewMode.value)
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showAddCategoryDialog(context, controller),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add More'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: BorderSide(color: AppTheme.primaryColor),
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 16,
                                vertical: isMobile ? 8 : 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Obx(
                      () =>
                          controller.hasAttemptedSubmit.value &&
                              field.errorText != null
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8, left: 12),
                              child: Text(
                                field.errorText!,
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                );
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryAmountsField(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(label: 'AMOUNT :'),
        Obx(
          () => Wrap(
            spacing: isMobile ? 16 : 24,
            runSpacing: 16,
            children: controller.selectedCategories.map((category) {
              return _CategoryAmountField(
                key: ValueKey('category_amount_$category'),
                category: category,
                controller: controller,
                isMobile: isMobile,
                isTablet: isTablet,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showAddPrizeDialog(
    BuildContext context,
    CompetitionController controller,
  ) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Prize'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Prize Name *',
                    hintText: 'e.g., 6th, 7th',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Prize name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional description',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Obx(
            () => controller.isLoading.value
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  )
                : TextButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final success = await controller.addCustomPrize(
                          nameController.text.trim(),
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                        );
                        if (success && context.mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
                    child: const Text('Add'),
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(
    BuildContext context,
    CompetitionController controller,
  ) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name *',
                    hintText: 'e.g., SENIOR, JUNIOR',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Category name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional description',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Obx(
            () => controller.isLoading.value
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  )
                : TextButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final success = await controller.addCustomCategory(
                          nameController.text.trim(),
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                        );
                        if (success && context.mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
                    child: const Text('Add'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStagesField(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(label: 'STAGES :'),
        const SizedBox(height: 8),
        _optionSectionCard(
          child: FormField<List<String>>(
            initialValue: controller.selectedStages.toList(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select at least one stage';
              }
              return null;
            },
            builder: (FormFieldState<List<String>> field) {
              return Obx(() {
                // Update field value when stages change
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (field.value != controller.selectedStages.toList()) {
                    field.didChange(controller.selectedStages.toList());
                    field.validate();
                  }
                });

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: isMobile ? 8 : 16,
                      runSpacing: 8,
                      children: [
                        ...controller.stageOptionNames.map((stage) {
                          final isSelected = controller.selectedStages.contains(
                            stage,
                          );
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isSelected,
                                onChanged: controller.isViewMode.value
                                    ? null
                                    : (value) {
                                        controller.toggleStage(stage);
                                        field.didChange(
                                          controller.selectedStages.toList(),
                                        );
                                        field.validate();
                                      },
                                activeColor: AppTheme.primaryColor,
                              ),
                              Text(stage),
                            ],
                          );
                        }),
                        if (!controller.isViewMode.value)
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showAddStageDialog(context, controller),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add More'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: BorderSide(color: AppTheme.primaryColor),
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 16,
                                vertical: isMobile ? 8 : 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Obx(
                      () =>
                          controller.hasAttemptedSubmit.value &&
                              field.errorText != null
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8, left: 12),
                              child: Text(
                                field.errorText!,
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                );
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStageGroupsDisplay(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(label: 'STAGE GROUPS :'),
        Obx(() {
          // Observe stageGroups and groupOptions to trigger rebuild when they change
          controller.stageGroups;
          controller.groupOptions;
          final selectedStages = controller.selectedStages;

          return Wrap(
            spacing: isMobile ? 12 : 16,
            runSpacing: 12,
            children: selectedStages.map((stage) {
              final groups = controller.getStageGroups(stage);
              return InkWell(
                onTap: controller.isViewMode.value
                    ? null
                    : () => _showStageGroupsDialog(context, controller, stage),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Stage $stage:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 12 : 13,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!controller.isViewMode.value)
                            Icon(Icons.edit, size: 16, color: Colors.grey[600]),
                        ],
                      ),
                      const SizedBox(height: 4),
                      groups.isEmpty
                          ? Text(
                              'No groups selected',
                              style: TextStyle(
                                fontSize: isMobile ? 11 : 12,
                                color: Colors.grey[500],
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          : Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: groups.map((group) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppTheme.primaryColor.withOpacity(
                                        0.3,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    group,
                                    style: TextStyle(
                                      fontSize: isMobile ? 11 : 12,
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  void _showAddStageDialog(
    BuildContext context,
    CompetitionController controller,
  ) {
    final textController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Stage'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: textController,
                  decoration: const InputDecoration(
                    labelText: 'Stage Name *',
                    hintText: 'e.g., G, H',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Stage name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional description',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Obx(
            () => controller.isLoading.value
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  )
                : TextButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final stageName = textController.text
                            .trim()
                            .toUpperCase();
                        final success = await controller.addCustomStage(
                          stageName,
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                        );
                        if (success && context.mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
                    child: const Text('Add'),
                  ),
          ),
        ],
      ),
    );
  }

  void _showStageGroupsDialog(
    BuildContext context,
    CompetitionController controller,
    String stage,
  ) {
    final selectedGroups = List<String>.from(controller.getStageGroups(stage));
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? screenWidth * 0.9 : (isTablet ? 400 : 450),
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Groups for Stage $stage',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 12 : 16),
                // Add More button for groups
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close current dialog
                      _showAddGroupDialog(context, controller, stage);
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add New Group'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                // Groups Grid - Show all groups, disable those assigned to other stages
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: isMobile ? 8 : 12,
                      runSpacing: isMobile ? 8 : 12,
                      children: controller.groupOptionNames.map((group) {
                        final isSelected = selectedGroups.contains(group);
                        final isAssignedToOtherStage = !controller
                            .isGroupAvailable(group, stage);
                        final assignedStage = controller.getStageForGroup(
                          group,
                        );

                        return InkWell(
                          onTap: isAssignedToOtherStage
                              ? null
                              : () {
                                  setState(() {
                                    if (isSelected) {
                                      selectedGroups.remove(group);
                                    } else {
                                      selectedGroups.add(group);
                                    }
                                  });
                                },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 12 : 16,
                              vertical: isMobile ? 8 : 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : isAssignedToOtherStage
                                  ? Colors.grey[200]
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : isAssignedToOtherStage
                                    ? Colors.grey[400]!
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  size: isMobile ? 16 : 18,
                                  color: isSelected
                                      ? Colors.white
                                      : isAssignedToOtherStage
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                                SizedBox(width: isMobile ? 6 : 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      group,
                                      style: TextStyle(
                                        fontSize: isMobile ? 13 : 14,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? Colors.white
                                            : isAssignedToOtherStage
                                            ? Colors.grey[500]
                                            : Colors.grey[800],
                                        decoration: isAssignedToOtherStage
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    if (isAssignedToOtherStage &&
                                        assignedStage != null)
                                      Text(
                                        'Assigned to Stage $assignedStage',
                                        style: TextStyle(
                                          fontSize: isMobile ? 9 : 10,
                                          color: Colors.grey[500],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 20),
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    SizedBox(width: isMobile ? 8 : 12),
                    ElevatedButton(
                      onPressed: () {
                        // Ensure options are loaded before setting groups
                        if (controller.stageOptions.isEmpty ||
                            controller.groupOptions.isEmpty) {
                          Get.snackbar(
                            'Error',
                            'Please wait for options to load',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          return;
                        }
                        controller.setStageGroups(stage, selectedGroups);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 20,
                          vertical: isMobile ? 10 : 12,
                        ),
                      ),
                      child: Text(
                        'Save',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddGroupDialog(
    BuildContext context,
    CompetitionController controller,
    String stage,
  ) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add New Group'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name *',
                    hintText: 'e.g., XIV, XV',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Group name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional description',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          Obx(
            () => controller.isLoading.value
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  )
                : TextButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final groupName = nameController.text.trim();
                        final success = await controller.addCustomGroup(
                          groupName,
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                        );
                        if (success && dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          // Reopen the stage groups dialog with updated groups
                          _showStageGroupsDialog(context, controller, stage);
                        }
                      }
                    },
                    child: const Text('Add'),
                  ),
          ),
        ],
      ),
    );
  }
}

// Separate widget for category amount field to manage TextEditingController properly
class _CategoryAmountField extends StatefulWidget {
  final String category;
  final CompetitionController controller;
  final bool isMobile;
  final bool isTablet;

  const _CategoryAmountField({
    super.key,
    required this.category,
    required this.controller,
    required this.isMobile,
    required this.isTablet,
  });

  @override
  State<_CategoryAmountField> createState() => _CategoryAmountFieldState();
}

class _CategoryAmountFieldState extends State<_CategoryAmountField> {
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    // Convert category name to ID to look up in categoryAmounts
    final categoryId = widget.controller.getCategoryIdByName(widget.category);
    final currentAmount = categoryId != null
        ? widget.controller.categoryAmounts[categoryId.toString()]
                  ?.toString() ??
              '0'
        : '0';
    _amountController = TextEditingController(text: currentAmount);
  }

  @override
  void didUpdateWidget(_CategoryAmountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller text when category changes or when amount is reset
    // Convert category name to ID to look up in categoryAmounts
    final categoryId = widget.controller.getCategoryIdByName(widget.category);
    final currentAmount = categoryId != null
        ? widget.controller.categoryAmounts[categoryId.toString()]
                  ?.toString() ??
              '0'
        : '0';
    if (_amountController.text != currentAmount) {
      _amountController.text = currentAmount;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.isMobile ? double.infinity : 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.category,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: widget.isMobile ? 12 : 13,
            ),
          ),
          const SizedBox(height: 4),
          Obx(
            () => TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              readOnly: widget.controller.isViewMode.value,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: widget.controller.isViewMode.value
                    ? Colors.grey[200]
                    : Colors.grey[50],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: widget.isMobile ? 12 : 16,
                ),
                isDense: widget.isMobile,
                prefixText: '₹ ',
                hintText: 'Enter amount',
              ),
              onChanged: widget.controller.isViewMode.value
                  ? null
                  : (value) {
                      final amount = double.tryParse(value) ?? 0.0;
                      widget.controller.updateCategoryAmount(
                        widget.category,
                        amount,
                      );
                    },
            ),
          ),
        ],
      ),
    );
  }
}
