import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/user_management_controller.dart';
import '../../controllers/competition_controller.dart';
import '../../widgets/admin_sidebar_layout.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/custom_loader.dart';
import '../../widgets/form_title.dart';
import '../../widgets/toggle_button_group.dart';
import '../../widgets/buttons.dart';
import '../../../data/models/user_management_model.dart';
import 'users_list_screen.dart';
import 'dart:io';
import 'dart:typed_data';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = Get.put(UserManagementController());
    // Initialize CompetitionController if not already initialized
    final competitionController = Get.put(CompetitionController());

    // Load competitions if empty - defer to avoid build phase error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (competitionController.competitions.isEmpty &&
          !competitionController.isLoading.value) {
        competitionController.loadCompetitions();
      }
      // Load user types if empty when screen first builds
      if (userController.userTypesList.isEmpty &&
          !userController.isLoadingUserTypes.value) {
        userController.loadUserTypes();
      }
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return AdminSidebarLayout(
      title: 'USERS',
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
                  () => ToggleButtonGroup(
                    options: [
                      ToggleButtonOption(
                        label: userController.isEditMode ? 'EDIT' : '+ CREATE',
                      ),
                      const ToggleButtonOption(label: '≡ LIST'),
                    ],
                    selectedIndex: userController.isListView.value ? 1 : 0,
                    onTap: (index) {
                      if (index == 1) {
                        // Switching to list view - reset form if in edit mode
                        if (userController.isEditMode) {
                          userController.resetForm();
                        }
                        userController.toggleViewMode(true);
                      } else {
                        // Switching to create/edit view
                        if (userController.isEditMode) {
                          // If already in edit mode and clicking edit button, reset and go to list
                          userController.resetForm();
                          userController.toggleViewMode(true);
                        } else {
                          // Switching to create view - reset form to ensure clean state
                          userController.resetForm();
                          // Reload user types if empty when switching to create view
                          if (userController.userTypesList.isEmpty &&
                              !userController.isLoadingUserTypes.value) {
                            userController.loadUserTypes();
                          }
                          userController.toggleViewMode(false);
                        }
                      }
                    },
                  ),
                ),
              ),
              Expanded(
                child: Obx(
                  () => userController.isListView.value
                      ? Padding(
                          padding: EdgeInsets.all(16),
                          child: const UsersListScreen(),
                        )
                      : SingleChildScrollView(
                          padding: EdgeInsets.all(isMobile ? 16 : 16),
                          child: Obx(
                            () => _buildForm(
                              context,
                              userController,
                              competitionController,
                              isMobile,
                              isTablet,
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
    UserManagementController controller,
    CompetitionController competitionController,
    bool isMobile,
    bool isTablet,
  ) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Obx(
                () => FormTitle(
                  text: controller.isEditMode ? 'EDIT USER' : 'CREATE USER',
                  isMobile: isMobile,
                  isTablet: isTablet,
                ),
              ),
              // Competition and Type in same line (desktop)
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
                        _buildUserTypeField(
                          context,
                          controller,
                          isMobile,
                          isTablet,
                        ),
                        SizedBox(height: isMobile ? 20 : 24),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        SizedBox(width: isTablet ? 16 : 24),
                        Expanded(
                          child: _buildUserTypeField(
                            context,
                            controller,
                            isMobile,
                            isTablet,
                          ),
                        ),
                      ],
                    ),
              SizedBox(height: isMobile ? 20 : 24),

              // Conditional Form Fields
              Obx(() {
                if (controller.selectedType.value == 'VOLUNTEERS') {
                  return _buildVolunteersTable(context, controller, isMobile);
                } else {
                  return _buildRegularUserForm(
                    context,
                    controller,
                    isMobile,
                    isTablet,
                  );
                }
              }),

              SizedBox(height: isMobile ? 24 : 32),

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
                      Icon(Icons.error_outline, color: Colors.red),
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
              Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CustomLoader(message: 'Processing...'),
                  );
                }
                return isMobile
                    ? Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: PrimaryButton(
                              text: controller.isEditMode
                                  ? 'UPDATE'
                                  : (controller.selectedType.value ==
                                            'VOLUNTEERS'
                                        ? 'SAVE CHANGES'
                                        : 'SUBMIT'),
                              icon: Icons.save,
                              onPressed: () async {
                                final success =
                                    controller.selectedType.value ==
                                        'VOLUNTEERS'
                                    ? await controller.createVolunteers()
                                    : await controller.createUser();

                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        controller.isEditMode
                                            ? 'User updated successfully'
                                            : 'User${controller.selectedType.value == 'VOLUNTEERS' ? 's' : ''} created successfully',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  // Reset form and switch to list view after successful update
                                  if (controller.isEditMode) {
                                    controller.resetForm();
                                    controller.toggleViewMode(true);
                                  }
                                }
                              },
                            ),
                          ),
                          if (controller.isEditMode) ...[
                            const SizedBox(height: 12),
                            cancelButton(
                              onPressed: () {
                                controller.resetForm();
                                controller.toggleViewMode(true);
                              },
                              isFullWidth: true,
                            ),
                          ],
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PrimaryButton(
                            text: controller.isEditMode
                                ? 'UPDATE'
                                : (controller.selectedType.value == 'VOLUNTEERS'
                                      ? 'SAVE CHANGES'
                                      : 'SUBMIT'),
                            icon: Icons.save,
                            onPressed: () async {
                              final success =
                                  controller.selectedType.value == 'VOLUNTEERS'
                                  ? await controller.createVolunteers()
                                  : await controller.createUser();

                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      controller.isEditMode
                                          ? 'User updated successfully'
                                          : 'User${controller.selectedType.value == 'VOLUNTEERS' ? 's' : ''} created successfully',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                // Reset form and switch to list view after successful update
                                if (controller.isEditMode) {
                                  controller.resetForm();
                                  controller.toggleViewMode(true);
                                }
                              }
                            },
                          ),
                          if (controller.isEditMode) ...[
                            const SizedBox(width: 16),
                            cancelButton(
                              onPressed: () {
                                controller.resetForm();
                                controller.toggleViewMode(true);
                              },
                            ),
                          ],
                        ],
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
    UserManagementController controller,
    CompetitionController competitionController,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMPETITION :',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                // Load stages and categories for selected competition
                controller.loadStagesAndCategoriesForCompetition(value);
              } else {
                // Clear stages and categories if no competition selected
                controller.availableStages.clear();
                controller.availableCategories.clear();
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

  Widget _buildUserTypeField(
    BuildContext context,
    UserManagementController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TYPE :',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          // Watch userTypesList to ensure reactivity
          controller.userTypesList;
          final userTypes = controller.userTypes;

          // Show loading indicator if types are being loaded
          if (controller.isLoadingUserTypes.value) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          // Show empty state if no types available
          if (userTypes.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    'No user types available',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isMobile ? 13 : 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => controller.loadUserTypes(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return isMobile
              ? Column(
                  children: userTypes.map((type) {
                    return InkWell(
                      onTap: () {
                        controller.selectedType.value = type;
                        // Reset form when type changes
                        if (type == 'VOLUNTEERS') {
                          controller.volunteerRows.value = List.generate(
                            4,
                            (index) => VolunteerRow(),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Radio<String>(
                              value: type,
                              groupValue: controller.selectedType.value,
                              onChanged: (value) {
                                if (value != null) {
                                  controller.selectedType.value = value;
                                  // Reset form when type changes
                                  if (value == 'VOLUNTEERS') {
                                    controller.volunteerRows.value =
                                        List.generate(
                                          4,
                                          (index) => VolunteerRow(),
                                        );
                                  }
                                }
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                type,
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                )
              : Row(
                  children: userTypes.map((type) {
                    return Expanded(
                      child: InkWell(
                        onTap: () {
                          controller.selectedType.value = type;
                          // Reset form when type changes
                          if (type == 'VOLUNTEERS') {
                            controller.volunteerRows.value = List.generate(
                              4,
                              (index) => VolunteerRow(),
                            );
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Radio<String>(
                              value: type,
                              groupValue: controller.selectedType.value,
                              onChanged: (value) {
                                if (value != null) {
                                  controller.selectedType.value = value;
                                  // Reset form when type changes
                                  if (value == 'VOLUNTEERS') {
                                    controller.volunteerRows.value =
                                        List.generate(
                                          4,
                                          (index) => VolunteerRow(),
                                        );
                                  }
                                }
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                type,
                                style: TextStyle(fontSize: isTablet ? 12 : 14),
                                overflow: TextOverflow.ellipsis,
                              ),
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

  Widget _buildRegularUserForm(
    BuildContext context,
    UserManagementController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name, Password, and Upload Photo - responsive layout
        isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NAME :',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : 16,
                            ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: controller.nameController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Password Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PASSWORD :',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : 16,
                            ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: controller.passwordController,
                        enabled: false,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          hintText: 'XXXXXXXX',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Upload Photo
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UPLOAD PHOTO :',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => _buildImagePreview(
                          controller.photoFile.value,
                          controller.photoBytes.value,
                          150,
                          150,
                          photoUrl: controller.photoUrl.value.isNotEmpty
                              ? controller.photoUrl.value
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => controller.pickPhoto(),
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
                    ],
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side: Name, Password, and Permissions
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Password in same line
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NAME :',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isTablet ? 14 : 16,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: controller.nameController,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Name is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: isTablet ? 12 : 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PASSWORD :',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isTablet ? 14 : 16,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: controller.passwordController,
                                    enabled: false,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                      hintText: 'XXXXXXXX',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Permissions (for SUB ADMIN and SPOT REG ADMIN) - HIDDEN FOR NOW
                        // if (controller.selectedType.value == 'SUB ADMIN' ||
                        //     controller.selectedType.value ==
                        //         'SPOT REG ADMIN(S)') ...[
                        //   const SizedBox(height: 24),
                        //   Column(
                        //     crossAxisAlignment: CrossAxisAlignment.start,
                        //     children: [
                        //       Text(
                        //         'PERMISSION :',
                        //         style: Theme.of(context).textTheme.titleMedium
                        //             ?.copyWith(
                        //               fontWeight: FontWeight.bold,
                        //               fontSize: isMobile
                        //                   ? 14
                        //                   : (isTablet ? 15 : 16),
                        //             ),
                        //       ),
                        //       const SizedBox(height: 8),
                        //       Obx(
                        //         () => Row(
                        //           children: UserManagementController.permissions
                        //               .map((permission) {
                        //                 return Expanded(
                        //                   child: InkWell(
                        //                     onTap: () => controller
                        //                         .togglePermission(permission),
                        //                     child: Row(
                        //                       mainAxisSize: MainAxisSize.min,
                        //                       children: [
                        //                         Checkbox(
                        //                           value: controller
                        //                               .selectedPermissions
                        //                               .contains(permission),
                        //                           onChanged: (value) =>
                        //                               controller
                        //                                   .togglePermission(
                        //                                     permission,
                        //                                   ),
                        //                           materialTapTargetSize:
                        //                               MaterialTapTargetSize
                        //                                   .shrinkWrap,
                        //                         ),
                        //                         const SizedBox(width: 4),
                        //                         Flexible(
                        //                           child: Text(
                        //                             permission,
                        //                             style: TextStyle(
                        //                               fontSize: isTablet
                        //                                   ? 12
                        //                                   : 14,
                        //                             ),
                        //                             overflow:
                        //                                 TextOverflow.ellipsis,
                        //                           ),
                        //                         ),
                        //                       ],
                        //                     ),
                        //                   ),
                        //                 );
                        //               })
                        //               .toList(),
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ],
                        // Allot Stages (for JURY(S)) - Desktop only
                        if (controller.selectedType.value == 'JURY(S)') ...[
                          const SizedBox(height: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'ALLOT STAGE(S) :',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isTablet ? 15 : 16,
                                        ),
                                  ),
                                  Obx(
                                    () => Checkbox(
                                      value: controller.selectedAllStage.value,
                                      onChanged: (value) => {
                                        if (value != null)
                                          {
                                            controller.selectedAllStage.value =
                                                value,
                                            if (value)
                                              {
                                                controller
                                                    .selectedStages
                                                    .value = controller.stages
                                                    .map((stage) => stage)
                                                    .toList(),
                                              }
                                            else
                                              {
                                                controller
                                                        .selectedStages
                                                        .value =
                                                    [],
                                              },
                                          },
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              Obx(
                                () => Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: controller.stages.map((stage) {
                                    return InkWell(
                                      onTap: () =>
                                          controller.toggleStage(stage),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Checkbox(
                                            value: controller.selectedStages
                                                .contains(stage),
                                            onChanged: (value) =>
                                                controller.toggleStage(stage),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            stage,
                                            style: TextStyle(
                                              fontSize: isTablet ? 12 : 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ],
                        // Allot Categories (for JURY(S)) - Desktop only
                        if (controller.selectedType.value == 'JURY(S)') ...[
                          const SizedBox(height: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'ALLOT CATEGORIES :',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isTablet ? 15 : 16,
                                        ),
                                  ),
                                  Checkbox(
                                    value: controller.selectedAllCategory.value,
                                    onChanged: (value) => {
                                      if (value != null)
                                        {
                                          controller.selectedAllCategory.value =
                                              value,
                                          if (value)
                                            {
                                              controller
                                                  .selectedCategories
                                                  .value = controller.categories
                                                  .map((category) => category)
                                                  .toList(),
                                            }
                                          else
                                            {
                                              controller
                                                      .selectedCategories
                                                      .value =
                                                  [],
                                            },
                                        },
                                    },
                                  ),
                                ],
                              ),
                              Obx(
                                () => Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: controller.categories.map((
                                    category,
                                  ) {
                                    return InkWell(
                                      onTap: () =>
                                          controller.toggleCategory(category),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Checkbox(
                                            value: controller.selectedCategories
                                                .contains(category),
                                            onChanged: (value) => controller
                                                .toggleCategory(category),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            category,
                                            style: TextStyle(
                                              fontSize: isTablet ? 12 : 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 24),
                  // Right side: Upload Photo, Allot Stages, Allot Categories
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UPLOAD PHOTO :',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: isTablet ? 14 : 16,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Obx(
                          () => _buildImagePreview(
                            controller.photoFile.value,
                            controller.photoBytes.value,
                            200,
                            200,
                            photoUrl: controller.photoUrl.value.isNotEmpty
                                ? controller.photoUrl.value
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => controller.pickPhoto(),
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
                      ],
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 24),

        // Permissions (for SUB ADMIN and SPOT REG ADMIN) - Mobile only - HIDDEN FOR NOW
        // if (isMobile &&
        //     (controller.selectedType.value == 'SUB ADMIN' ||
        //         controller.selectedType.value == 'SPOT REG ADMIN(S)')) ...[
        //   Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       Text(
        //         'PERMISSION :',
        //         style: Theme.of(context).textTheme.titleMedium?.copyWith(
        //           fontWeight: FontWeight.bold,
        //           fontSize: isMobile ? 14 : (isTablet ? 15 : 16),
        //         ),
        //       ),
        //       const SizedBox(height: 8),
        //       Obx(
        //         () => Column(
        //           children: UserManagementController.permissions.map((
        //             permission,
        //           ) {
        //             return InkWell(
        //               onTap: () => controller.togglePermission(permission),
        //               child: Padding(
        //                 padding: const EdgeInsets.symmetric(vertical: 4),
        //                 child: Row(
        //                   children: [
        //                     Checkbox(
        //                       value: controller.selectedPermissions.contains(
        //                         permission,
        //                       ),
        //                       onChanged: (value) =>
        //                           controller.togglePermission(permission),
        //                       materialTapTargetSize:
        //                           MaterialTapTargetSize.shrinkWrap,
        //                     ),
        //                     const SizedBox(width: 4),
        //                     Expanded(
        //                       child: Text(
        //                         permission,
        //                         style: const TextStyle(fontSize: 14),
        //                         overflow: TextOverflow.ellipsis,
        //                       ),
        //                     ),
        //                   ],
        //                 ),
        //               ),
        //             );
        //           }).toList(),
        //         ),
        //       ),
        //     ],
        //   ),
        //   const SizedBox(height: 24),
        // ],

        // Allot Stages (for JURY(S)) - Mobile only
        if (isMobile && controller.selectedType.value == 'JURY(S)') ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ALLOT STAGE(S) :',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 14 : (isTablet ? 15 : 16),
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.stages.map((stage) {
                    return InkWell(
                      onTap: () => controller.toggleStage(stage),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: controller.selectedStages.contains(stage),
                            onChanged: (value) => controller.toggleStage(stage),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(width: 4),
                          Text(stage, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],

        // Allot Categories (for JURY(S)) - Mobile only
        if (isMobile && controller.selectedType.value == 'JURY(S)') ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ALLOT CATEGORIES :',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 14 : (isTablet ? 15 : 16),
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Column(
                  children: controller.categories.map((category) {
                    return InkWell(
                      onTap: () => controller.toggleCategory(category),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Checkbox(
                              value: controller.selectedCategories.contains(
                                category,
                              ),
                              onChanged: (value) =>
                                  controller.toggleCategory(category),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                category,
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildVolunteersTable(
    BuildContext context,
    UserManagementController controller,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VOLUNTEERS :',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (isMobile)
          ...controller.volunteerRows.asMap().entries.map((entry) {
            return _buildVolunteerCard(
              context,
              controller,
              entry.key,
              entry.value,
            );
          }).toList()
        else
          _buildVolunteersTableDesktop(context, controller),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => controller.addVolunteerRow(),
            icon: const Icon(Icons.add),
            label: const Text('Add More'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildVolunteersTableDesktop(
    BuildContext context,
    UserManagementController controller,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth, // 100% width
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                AppTheme.primaryColor.withOpacity(0.1),
              ),
              columnSpacing: 30, // Space between columns
              columns: const [
                DataColumn(
                  label: Text(
                    'VOLUNTEER NO',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'VOLUNTEER NAME',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'PASSWORD',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'CELL',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'PHOTO',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: controller.volunteerRows.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                return DataRow(
                  cells: [
                    DataCell(
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(controller.generateVolunteerNo(index)),
                      ),
                    ),
                    DataCell(
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: SizedBox(
                          width: 250, // Increased input width
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
                      ),
                    ),
                    DataCell(
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'XXXXX',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                    ),
                    DataCell(
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: SizedBox(
                          width: 180, // Increased input width
                          child: TextFormField(
                            controller: row.cellController,
                            keyboardType: TextInputType.phone,
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
                      ),
                    ),
                    DataCell(
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton(
                              onPressed: () async {
                                await controller.pickPhotoForVolunteer(row);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                minimumSize: const Size(0, 32),
                              ),
                              child: const Text(
                                'BROWSE',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            Obx(() {
                              if (row.photoUrl.value.isNotEmpty) {
                                return Row(
                                  children: [
                                    const SizedBox(width: 8),
                                    _buildImagePreview(
                                      row.photoFile.value,
                                      row.photoBytes.value,
                                      40,
                                      40,
                                      borderRadius: 4,
                                    ),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVolunteerCard(
    BuildContext context,
    UserManagementController controller,
    int index,
    VolunteerRow row,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  controller.generateVolunteerNo(index),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (controller.volunteerRows.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => controller.removeVolunteerRow(index),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: row.nameController,
              decoration: const InputDecoration(
                labelText: 'VOLUNTEER NAME',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: row.cellController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'CELL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await controller.pickPhotoForVolunteer(row);
                  },
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
                Obx(() {
                  if (row.photoUrl.value.isNotEmpty) {
                    return Row(
                      children: [
                        const SizedBox(width: 16),
                        _buildImagePreview(
                          row.photoFile.value,
                          row.photoBytes.value,
                          60,
                          60,
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to display images on all platforms
  Widget _buildImagePreview(
    File? file,
    Uint8List? bytes,
    double width,
    double height, {
    double borderRadius = 8,
    String? photoUrl,
  }) {
    final hasLocalImage =
        (bytes != null) || (file != null && file.existsSync());
    final hasNetworkImage = photoUrl != null && photoUrl.isNotEmpty;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: hasLocalImage
            ? (kIsWeb
                  ? (bytes != null
                        ? Image.memory(bytes, fit: BoxFit.cover)
                        : _buildDefaultPhotoPreview())
                  : (file != null && file.existsSync()
                        ? Image.file(file, fit: BoxFit.cover)
                        : _buildDefaultPhotoPreview()))
            : hasNetworkImage
            ? _buildNetworkImage(photoUrl!, width, height)
            : _buildDefaultPhotoPreview(),
      ),
    );
  }

  Widget _buildNetworkImage(String imageUrl, double width, double height) {
    // Construct full URL if needed
    String fullUrl = imageUrl;
    if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
      // If it's a relative path, we need to construct the full URL
      // For now, assume the photoUrl from the model is already a full URL or relative path
      // If it's just a path like '/user/1/photo', we need to add base URL
      if (imageUrl.startsWith('/')) {
        // This is handled in the controller when setting photoUrl
        fullUrl = imageUrl;
      }
    }

    return Image.network(
      fullUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildDefaultPhotoPreview();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                : null,
            strokeWidth: 2,
          ),
        );
      },
    );
  }

  Widget _buildDefaultPhotoPreview() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, color: Colors.grey[400], size: 40),
          const SizedBox(height: 8),
          Text(
            'No Photo',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Users List Section
  Widget _buildUsersListSection(
    BuildContext context,
    UserManagementController userController,
    CompetitionController competitionController,
    bool isMobile,
    bool isTablet,
  ) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : (isTablet ? 20 : 24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search and Filter
            _buildListSearchAndFilter(
              context,
              userController,
              competitionController,
              isMobile,
              isTablet,
            ),
            SizedBox(height: isMobile ? 16 : 24),
            // Users List
            Obx(
              () =>
                  _buildUsersList(context, userController, isMobile, isTablet),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListSearchAndFilter(
    BuildContext context,
    UserManagementController userController,
    CompetitionController competitionController,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      children: [
        // Search Bar
        TextField(
          onChanged: (value) => userController.searchQuery.value = value,
          decoration: InputDecoration(
            hintText: 'Search by name, type, or competition...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: Obx(() {
              if (userController.searchQuery.value.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => userController.searchQuery.value = '',
                );
              }
              return const SizedBox.shrink();
            }),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        // Filter by Competition
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: isMobile ? double.infinity : (isTablet ? 160 : 180),
              child: Obx(
                () => DropdownButtonFormField<int?>(
                  value: userController.selectedEventId.value.isNotEmpty
                      ? int.tryParse(userController.selectedEventId.value)
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Filter by Competition',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    isDense: true,
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text(
                        'All Competitions',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...competitionController.competitions
                        .where((competition) => competition.id != null)
                        .map((competition) {
                          return DropdownMenuItem<int?>(
                            value: int.tryParse(competition.id!),
                            child: Text(
                              competition.competitionName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      userController.selectedEventId.value = value.toString();
                    } else {
                      userController.selectedEventId.value = '';
                    }
                    userController.loadUsers(eventId: value);
                  },
                ),
              ),
            ),
            SizedBox(width: isMobile ? 8 : 12),
            // Refresh Button
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                final eventId = userController.selectedEventId.value.isNotEmpty
                    ? int.tryParse(userController.selectedEventId.value)
                    : null;
                userController.loadUsers(eventId: eventId);
              },
              tooltip: 'Refresh',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUsersList(
    BuildContext context,
    UserManagementController controller,
    bool isMobile,
    bool isTablet,
  ) {
    if (controller.isLoading.value) {
      return const Center(child: CustomLoader());
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage.value,
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final eventId = controller.selectedEventId.value.isNotEmpty
                    ? int.tryParse(controller.selectedEventId.value)
                    : null;
                controller.loadUsers(eventId: eventId);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredUsers = controller.filteredUsers;

    if (filteredUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                controller.searchQuery.value.isNotEmpty
                    ? 'No users found matching your search'
                    : 'No users found',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (isMobile) {
      return _buildMobileUserList(context, filteredUsers, controller);
    } else {
      return _buildDesktopUserTable(
        context,
        filteredUsers,
        controller,
        isTablet,
      );
    }
  }

  Widget _buildMobileUserList(
    BuildContext context,
    List<UserManagementModel> users,
    UserManagementController controller,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildUserPhoto(user, 50),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildTypeChip(user.type),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildUserInfoRow('Competition', user.eventName ?? 'N/A'),
                if (user.volunteerNo != null)
                  _buildUserInfoRow('Volunteer No', user.volunteerNo!),
                if (user.cell != null) _buildUserInfoRow('Cell', user.cell!),
                if (user.permissions.isNotEmpty)
                  _buildUserInfoRow('Permissions', user.permissions.join(', ')),
                if (user.stages.isNotEmpty)
                  _buildUserInfoRow('Stages', user.stages.join(', ')),
                if (user.categories.isNotEmpty)
                  _buildUserInfoRow('Categories', user.categories.join(', ')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopUserTable(
    BuildContext context,
    List<UserManagementModel> users,
    UserManagementController controller,
    bool isTablet,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: tableWidth,
              child: Table(
                border: TableBorder.all(color: Colors.grey[300]!, width: 1),
                columnWidths: {
                  0: const FixedColumnWidth(80),
                  1: FlexColumnWidth(2.0),
                  2: FlexColumnWidth(1.5),
                  3: FlexColumnWidth(2.5),
                  4: FlexColumnWidth(1.5),
                },
                children: [
                  // Header Row
                  TableRow(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                    ),
                    children: [
                      _buildTableCell('PHOTO', isHeader: true),
                      _buildTableCell('NAME', isHeader: true),
                      _buildTableCell('TYPE', isHeader: true),
                      _buildTableCell('COMPETITION', isHeader: true),
                      _buildTableCell('CELL', isHeader: true),
                    ],
                  ),
                  // Data Rows
                  ...users.map((user) {
                    return TableRow(
                      children: [
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Center(child: _buildUserPhoto(user, 40)),
                          ),
                        ),
                        _buildTableCell(user.name, maxLines: 2),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: _buildTypeChip(user.type),
                          ),
                        ),
                        _buildTableCell(user.eventName ?? 'N/A', maxLines: 2),
                        _buildTableCell(user.cell ?? 'N/A'),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 14 : 13,
        ),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildUserPhoto(UserManagementModel user, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
        border: Border.all(color: Colors.grey[400]!, width: 2),
      ),
      child: user.photoUrl != null && user.photoUrl!.isNotEmpty
          ? ClipOval(
              child: kIsWeb
                  ? Image.network(
                      user.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.person, size: size * 0.6);
                      },
                    )
                  : Image.network(
                      user.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.person, size: size * 0.6);
                      },
                    ),
            )
          : Icon(Icons.person, size: size * 0.6, color: Colors.grey[600]),
    );
  }

  Widget _buildTypeChip(String type) {
    Color chipColor;
    switch (type.toUpperCase()) {
      case 'SUB ADMIN':
        chipColor = Colors.blue;
        break;
      case 'SPOT REG ADMIN(S)':
        chipColor = Colors.orange;
        break;
      case 'JURY(S)':
        chipColor = Colors.purple;
        break;
      case 'VOLUNTEERS':
        chipColor = Colors.green;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.5)),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUserInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

Widget _buildVolunteerCard(
  BuildContext context,
  UserManagementController controller,
  int index,
  VolunteerRow row,
) {
  return Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                controller.generateVolunteerNo(index),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (controller.volunteerRows.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => controller.removeVolunteerRow(index),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: row.nameController,
            decoration: const InputDecoration(
              labelText: 'VOLUNTEER NAME',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: row.cellController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'CELL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  await controller.pickPhotoForVolunteer(row);
                },
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
              Obx(() {
                if (row.photoUrl.value.isNotEmpty) {
                  return Row(
                    children: [
                      const SizedBox(width: 16),
                      _buildImagePreview(
                        row.photoFile.value,
                        row.photoBytes.value,
                        60,
                        60,
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ],
      ),
    ),
  );
}

// Helper widget to display images on all platforms
Widget _buildImagePreview(
  File? file,
  Uint8List? bytes,
  double width,
  double height, {
  double borderRadius = 8,
}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: kIsWeb
          ? (bytes != null
                ? Image.memory(bytes, fit: BoxFit.cover)
                : Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ))
          : (file != null && file.existsSync()
                ? Image.file(file, fit: BoxFit.cover)
                : Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, color: Colors.grey),
                  )),
    ),
  );
}

// Users List Section
Widget _buildUsersListSection(
  BuildContext context,
  UserManagementController userController,
  CompetitionController competitionController,
  bool isMobile,
  bool isTablet,
) {
  return Card(
    elevation: 4,
    margin: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: EdgeInsets.all(isMobile ? 12 : (isTablet ? 20 : 24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and Filter
          _buildListSearchAndFilter(
            context,
            userController,
            competitionController,
            isMobile,
            isTablet,
          ),
          SizedBox(height: isMobile ? 16 : 24),
          // Users List
          Obx(
            () => _buildUsersList(context, userController, isMobile, isTablet),
          ),
        ],
      ),
    ),
  );
}

Widget _buildListSearchAndFilter(
  BuildContext context,
  UserManagementController userController,
  CompetitionController competitionController,
  bool isMobile,
  bool isTablet,
) {
  return Column(
    children: [
      // Search Bar
      TextField(
        onChanged: (value) => userController.searchQuery.value = value,
        decoration: InputDecoration(
          hintText: 'Search by name, type, or competition...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Obx(() {
            if (userController.searchQuery.value.isNotEmpty) {
              return IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => userController.searchQuery.value = '',
              );
            }
            return const SizedBox.shrink();
          }),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
      SizedBox(height: isMobile ? 12 : 16),
      // Filter by Competition
      Row(
        children: [
          Expanded(
            child: Obx(
              () => DropdownButtonFormField<int?>(
                value: userController.selectedEventId.value.isNotEmpty
                    ? int.tryParse(userController.selectedEventId.value)
                    : null,
                decoration: InputDecoration(
                  labelText: 'Filter by Competition',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All Competitions'),
                  ),
                  ...competitionController.competitions
                      .where((competition) => competition.id != null)
                      .map((competition) {
                        return DropdownMenuItem<int?>(
                          value: int.tryParse(competition.id!),
                          child: Text(
                            competition.competitionName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                ],
                onChanged: (value) {
                  if (value != null) {
                    userController.selectedEventId.value = value.toString();
                  } else {
                    userController.selectedEventId.value = '';
                  }
                  userController.loadUsers(eventId: value);
                },
              ),
            ),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final eventId = userController.selectedEventId.value.isNotEmpty
                  ? int.tryParse(userController.selectedEventId.value)
                  : null;
              userController.loadUsers(eventId: eventId);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
    ],
  );
}

Widget _buildUsersList(
  BuildContext context,
  UserManagementController controller,
  bool isMobile,
  bool isTablet,
) {
  if (controller.isLoading.value) {
    return const Center(child: CustomLoader());
  }

  if (controller.errorMessage.value.isNotEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            controller.errorMessage.value,
            style: TextStyle(color: Colors.red[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final eventId = controller.selectedEventId.value.isNotEmpty
                  ? int.tryParse(controller.selectedEventId.value)
                  : null;
              controller.loadUsers(eventId: eventId);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  final filteredUsers = controller.filteredUsers;

  if (filteredUsers.isEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              controller.searchQuery.value.isNotEmpty
                  ? 'No users found matching your search'
                  : 'No users found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  if (isMobile) {
    return _buildMobileUserList(context, filteredUsers, controller);
  } else {
    return _buildDesktopUserTable(context, filteredUsers, controller, isTablet);
  }
}

Widget _buildMobileUserList(
  BuildContext context,
  List<UserManagementModel> users,
  UserManagementController controller,
) {
  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.all(12),
    itemCount: users.length,
    itemBuilder: (context, index) {
      final user = users[index];
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildUserPhoto(user, 50),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildTypeChip(user.type),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildUserInfoRow('Competition', user.eventName ?? 'N/A'),
              if (user.volunteerNo != null)
                _buildUserInfoRow('Volunteer No', user.volunteerNo!),
              if (user.cell != null) _buildUserInfoRow('Cell', user.cell!),
              if (user.permissions.isNotEmpty)
                _buildUserInfoRow('Permissions', user.permissions.join(', ')),
              if (user.stages.isNotEmpty)
                _buildUserInfoRow('Stages', user.stages.join(', ')),
              if (user.categories.isNotEmpty)
                _buildUserInfoRow('Categories', user.categories.join(', ')),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildDesktopUserTable(
  BuildContext context,
  List<UserManagementModel> users,
  UserManagementController controller,
  bool isTablet,
) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final tableWidth = constraints.maxWidth;
      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: tableWidth,
            child: Table(
              border: TableBorder.all(color: Colors.grey[300]!, width: 1),
              columnWidths: {
                0: const FixedColumnWidth(80),
                1: FlexColumnWidth(2.0),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(2.5),
                4: FlexColumnWidth(1.5),
              },
              children: [
                // Header Row
                TableRow(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                  ),
                  children: [
                    _buildTableCell('PHOTO', isHeader: true),
                    _buildTableCell('NAME', isHeader: true),
                    _buildTableCell('TYPE', isHeader: true),
                    _buildTableCell('COMPETITION', isHeader: true),
                    _buildTableCell('CELL', isHeader: true),
                  ],
                ),
                // Data Rows
                ...users.map((user) {
                  return TableRow(
                    children: [
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Center(child: _buildUserPhoto(user, 40)),
                        ),
                      ),
                      _buildTableCell(user.name, maxLines: 2),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: _buildTypeChip(user.type),
                        ),
                      ),
                      _buildTableCell(user.eventName ?? 'N/A', maxLines: 2),
                      _buildTableCell(user.cell ?? 'N/A'),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildTableCell(String text, {bool isHeader = false, int maxLines = 1}) {
  return Padding(
    padding: const EdgeInsets.all(12),
    child: Text(
      text,
      style: TextStyle(
        fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        fontSize: isHeader ? 14 : 13,
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    ),
  );
}

Widget _buildUserPhoto(UserManagementModel user, double size) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.grey[300],
      border: Border.all(color: Colors.grey[400]!, width: 2),
    ),
    child: user.photoUrl != null && user.photoUrl!.isNotEmpty
        ? ClipOval(
            child: kIsWeb
                ? Image.network(
                    user.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.person, size: size * 0.6);
                    },
                  )
                : Image.network(
                    user.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.person, size: size * 0.6);
                    },
                  ),
          )
        : Icon(Icons.person, size: size * 0.6, color: Colors.grey[600]),
  );
}

Widget _buildTypeChip(String type) {
  Color chipColor;
  switch (type.toUpperCase()) {
    case 'SUB ADMIN':
      chipColor = Colors.blue;
      break;
    case 'SPOT REG ADMIN(S)':
      chipColor = Colors.orange;
      break;
    case 'JURY(S)':
      chipColor = Colors.purple;
      break;
    case 'VOLUNTEERS':
      chipColor = Colors.green;
      break;
    default:
      chipColor = Colors.grey;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: chipColor.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: chipColor.withOpacity(0.5)),
    ),
    child: Text(
      type,
      style: TextStyle(
        color: chipColor,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

Widget _buildUserInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
      ],
    ),
  );
}
