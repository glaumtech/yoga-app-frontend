import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../controllers/user_management_controller.dart';
import '../../controllers/competition_controller.dart';
import '../../widgets/admin_sidebar_layout.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/custom_loader.dart';
import '../../widgets/responsive_admin_table.dart';
import '../../widgets/form_title.dart';
import '../../widgets/toggle_button_group.dart';
import '../../widgets/pinned_scroll_views.dart';
import '../../widgets/buttons.dart';
import '../../widgets/photo_source_buttons.dart';
import '../../../data/models/user_management_model.dart';
import 'users_list_screen.dart';
import 'dart:async' show unawaited;
import 'dart:io';
import 'dart:typed_data';

/// API `userName` for tables; em dash when unset.
String _userNameOrDash(UserManagementModel user) {
  final u = user.userName?.trim();
  if (u != null && u.isNotEmpty) return u;
  return '—';
}

Widget _buildEmailField(
  UserManagementController controller, {
  required double labelFontSize,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'EMAIL :',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: labelFontSize),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller.emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          hintText: 'user@example.com',
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return null;
          }
          if (!GetUtils.isEmail(value.trim())) {
            return 'Enter a valid email address';
          }
          return null;
        },
      ),
    ],
  );
}

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = Get.put(UserManagementController());
    // Initialize CompetitionController if not already initialized
    final competitionController = Get.put(CompetitionController());

    // Load competitions if empty - defer to avoid build phase error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!competitionController.isLoadingHomeCompetitions.value) {
        competitionController.ensureRegistrationCompetitionChoicesLoaded();
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
                        userController.resetVolunteerEntrySession();
                        if (userController.isEditMode ||
                            userController.selectedType.value == 'VOLUNTEERS') {
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
                      : PinnedVerticalScrollView(
                          padding: EdgeInsets.all(isMobile ? 16 : 16),
                          child: Obx(() {
                            // Must read Rx values here so GetX tracks this Obx (nested
                            // widgets' Obx callbacks do not count for this parent).
                            userController.userToEdit.value;
                            userController.selectedType.value;
                            userController.selectedEventId.value;
                            return _buildForm(
                              context,
                              userController,
                              competitionController,
                              isMobile,
                              isTablet,
                            );
                          }),
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
        child: Obx(() {
          // Rebuild [Form] when the controller issues a new GlobalKey (see [UserManagementController._refreshFormKey]).
          final _ = controller.formKeyRevision.value;
          return Form(
            key: controller.formKey,
            autovalidateMode: AutovalidateMode.disabled,
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

                _buildFormErrorBanner(context, controller, isMobile),

                // Submit and Cancel Buttons (volunteers save via Add More, like bulk)
                Obx(() {
                  if (controller.selectedType.value == 'VOLUNTEERS' &&
                      !controller.isEditMode) {
                    return const SizedBox.shrink();
                  }
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
                                    : 'SUBMIT',
                                icon: Icons.save,
                                onPressed: () async {
                                  final isVolunteers =
                                      controller.selectedType.value ==
                                      'VOLUNTEERS';
                                  final success = isVolunteers
                                      ? (controller.isEditMode
                                            ? await controller
                                                  .updateVolunteerUser()
                                            : await controller
                                                  .createVolunteers())
                                      : await controller.createUser();

                                  if (success && context.mounted) {
                                    SnackbarHelper.showSuccess(
                                      context,
                                      controller.isEditMode
                                          ? 'User updated successfully'
                                          : 'User${isVolunteers ? 's' : ''} created successfully',
                                    );
                                    if (controller.isEditMode || isVolunteers) {
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
                              text: controller.isEditMode ? 'UPDATE' : 'SUBMIT',
                              icon: Icons.save,
                              onPressed: () async {
                                final isVolunteers =
                                    controller.selectedType.value ==
                                    'VOLUNTEERS';
                                final success = isVolunteers
                                    ? (controller.isEditMode
                                          ? await controller
                                                .updateVolunteerUser()
                                          : await controller.createVolunteers())
                                    : await controller.createUser();

                                if (success && context.mounted) {
                                  SnackbarHelper.showSuccess(
                                    context,
                                    controller.isEditMode
                                        ? 'User updated successfully'
                                        : 'User${isVolunteers ? 's' : ''} created successfully',
                                  );
                                  if (controller.isEditMode || isVolunteers) {
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
          );
        }),
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
            onChanged: (value) async {
              if (value != null) {
                controller.selectedEventId.value = value;
                controller.errorMessage.value = '';
                final match = competitionController.competitions
                    .where((c) => c.id == value)
                    .toList();
                if (match.isNotEmpty) {
                  controller.selectedEventName.value =
                      match.first.competitionName;
                }
                if (!controller.isVolunteersSelectedType()) {
                  controller.loadStagesAndCategoriesForCompetition(value);
                }
                if (controller.selectedType.value == 'VOLUNTEERS' &&
                    !controller.isEditMode) {
                  await controller.prepareVolunteerEntry();
                }
              } else {
                controller.selectedEventName.value = '';
                controller.availableStages.clear();
                controller.availableCategories.clear();
                if (controller.selectedType.value == 'VOLUNTEERS') {
                  controller.resetVolunteerEntrySession();
                }
              }
            },
            validator: (_) {
              // Read controller so validation stays correct when Obx rebuilds the dropdown.
              if (controller.selectedEventId.value.isEmpty) {
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

          return Wrap(
            spacing: isMobile ? 0 : 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: userTypes.map((type) {
              return _buildUserTypeRadioOption(
                controller: controller,
                type: type,
                fontSize: isMobile ? 14 : (isTablet ? 13 : 14),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildPasswordAutoGeneratedHint({double fontSize = 12}) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        'Passwords will be auto generated',
        style: TextStyle(fontSize: fontSize, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildUserTypeRadioOption({
    required UserManagementController controller,
    required String type,
    required double fontSize,
  }) {
    Future<void> onTypeSelected(String value) async {
      final previousType = controller.selectedType.value;
      controller.selectedType.value = value;
      controller.errorMessage.value = '';
      if (value == 'VOLUNTEERS') {
        await controller.prepareVolunteerEntry();
        if (controller.selectedEventId.value.trim().isNotEmpty) {
          controller.errorMessage.value = '';
        }
      } else if (previousType == 'VOLUNTEERS') {
        controller.resetVolunteerEntrySession();
      }
    }

    return InkWell(
      onTap: () => unawaited(onTypeSelected(type)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<String>(
              value: type,
              groupValue: controller.selectedType.value,
              onChanged: (value) {
                if (value != null) {
                  unawaited(onTypeSelected(value));
                }
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            Text(type, style: TextStyle(fontSize: fontSize)),
          ],
        ),
      ),
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
                  // API userName (`user_name`)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'USER NAME :',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : 16,
                            ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: controller.userNameController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        validator: (_) {
                          if (controller.userNameController.text
                              .trim()
                              .isEmpty) {
                            return 'User name is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                        validator: (_) {
                          if (controller.nameController.text.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildEmailField(
                    controller,
                    labelFontSize: isMobile ? 14 : 16,
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
                      _buildPasswordAutoGeneratedHint(
                        fontSize: isMobile ? 12 : 13,
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
                      PhotoSourceButtons(
                        onPick: (source, ctx) =>
                            controller.pickPhoto(source, context: ctx),
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
                        // API userName and Password in same line
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'USER NAME :',
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
                                    controller: controller.userNameController,
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
                                    validator: (_) {
                                      if (controller.userNameController.text
                                          .trim()
                                          .isEmpty) {
                                        return 'User name is required';
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
                                  _buildPasswordAutoGeneratedHint(
                                    fontSize: isTablet ? 11 : 12,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildEmailField(
                          controller,
                          labelFontSize: isTablet ? 14 : 16,
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NAME :',
                              style: Theme.of(context).textTheme.titleMedium
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
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              validator: (_) {
                                if (controller.nameController.text
                                    .trim()
                                    .isEmpty) {
                                  return 'Name is required';
                                }
                                return null;
                              },
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
                              Text(
                                'GENDER OPTIONS :',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isTablet ? 15 : 16,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Obx(
                                () => Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: [
                                    InkWell(
                                      onTap: () =>
                                          controller.selectedMale.value =
                                              !controller.selectedMale.value,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Checkbox(
                                            value:
                                                controller.selectedMale.value,
                                            onChanged: (value) =>
                                                controller.selectedMale.value =
                                                    value ?? false,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Boys',
                                            style: TextStyle(
                                              fontSize: isTablet ? 12 : 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () =>
                                          controller.selectedFemale.value =
                                              !controller.selectedFemale.value,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Checkbox(
                                            value:
                                                controller.selectedFemale.value,
                                            onChanged: (value) =>
                                                controller
                                                        .selectedFemale
                                                        .value =
                                                    value ?? false,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Girls',
                                            style: TextStyle(
                                              fontSize: isTablet ? 12 : 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                              Obx(() {
                                final stageLabels = controller.availableStages
                                    .map((s) => s.name)
                                    .toList();
                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: stageLabels.map((stage) {
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
                                );
                              }),
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
                              Obx(() {
                                final categoryLabels = controller
                                    .availableCategories
                                    .map((c) => c.name)
                                    .toList();
                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: categoryLabels.map((category) {
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
                                );
                              }),
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
                        PhotoSourceButtons(
                          onPick: (source, ctx) =>
                              controller.pickPhoto(source, context: ctx),
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
                'GENDER OPTIONS :',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 14 : (isTablet ? 15 : 16),
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Row(
                  children: [
                    InkWell(
                      onTap: () => controller.selectedMale.value =
                          !controller.selectedMale.value,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: controller.selectedMale.value,
                            onChanged: (value) =>
                                controller.selectedMale.value = value ?? false,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(width: 4),
                          const Text('Boys', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => controller.selectedFemale.value =
                          !controller.selectedFemale.value,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: controller.selectedFemale.value,
                            onChanged: (value) =>
                                controller.selectedFemale.value =
                                    value ?? false,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(width: 4),
                          const Text('Girls', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
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
              Obx(() {
                final stageLabels = controller.availableStages
                    .map((s) => s.name)
                    .toList();
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: stageLabels.map((stage) {
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
                );
              }),
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
              Obx(() {
                final categoryLabels = controller.availableCategories
                    .map((c) => c.name)
                    .toList();
                return Column(
                  children: categoryLabels.map((category) {
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
                );
              }),
            ],
          ),
        ],
      ],
    );
  }

  static const double _kVolunteerTableFieldHeight = 48;

  /// Matches [BulkRegistrationScreen._bulkTableFieldDecoration].
  static InputDecoration _volunteerBulkFieldDecoration({
    Widget? suffixIcon,
    String? hintText,
  }) {
    const border = OutlineInputBorder();
    return InputDecoration(
      border: border,
      enabledBorder: border,
      focusedBorder: border,
      disabledBorder: border,
      errorBorder: border,
      focusedErrorBorder: border,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      isDense: false,
      suffixIcon: suffixIcon,
      hintText: hintText,
    );
  }

  /// Bordered read-only password cell (same look as bulk date / select fields).
  Widget _buildVolunteerPasswordField({required bool readOnly}) {
    return SizedBox(
      height: _kVolunteerTableFieldHeight,
      child: InputDecorator(
        decoration: _volunteerBulkFieldDecoration(),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            readOnly ? 'Saved' : 'XXXXX',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[readOnly ? 700 : 400],
              fontWeight: readOnly ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormErrorBanner(
    BuildContext context,
    UserManagementController controller,
    bool isMobile,
  ) {
    return Obx(() {
      final message = controller.errorMessage.value;
      final competitionSelected = controller.selectedEventId.value
          .trim()
          .isNotEmpty;
      if (message.isEmpty) {
        return const SizedBox.shrink();
      }
      if (message == 'Please select a competition' && competitionSelected) {
        return const SizedBox.shrink();
      }

      return Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 420,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(color: Colors.red[700], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildVolunteerMobileField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }

  static String? _validateVolunteerCell(String? value) {
    final cell = value?.trim() ?? '';
    if (cell.isEmpty) return null;
    if (cell.length != 10) {
      return 'Cell number must be exactly 10 digits';
    }
    if (RegExp(r'^(\d)\1{9}$').hasMatch(cell)) {
      return 'Invalid cell number';
    }
    if (cell == '9876543210' || cell == '0123456789') {
      return 'Invalid cell number';
    }
    return null;
  }

  Widget _buildVolunteerCellField({
    required TextEditingController controller,
    required bool readOnly,
    bool showLabel = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      maxLength: 10,
      style: const TextStyle(fontSize: 12),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: readOnly ? null : _validateVolunteerCell,
      decoration: _volunteerBulkFieldDecoration().copyWith(
        counterText: '',
        hintText: showLabel ? '10-digit mobile' : null,
        errorStyle: const TextStyle(fontSize: 11, height: 1.1),
      ),
    );
  }

  Widget _buildVolunteerPhotoColumn({
    required BuildContext context,
    required UserManagementController controller,
    required VolunteerRow row,
    required bool readOnly,
    double previewSize = 48,
  }) {
    return Obx(() {
      final hasPhoto = row.photoUrl.value.isNotEmpty;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (hasPhoto) ...[
            _buildImagePreview(
              row.photoFile.value,
              row.photoBytes.value,
              previewSize,
              previewSize,
              borderRadius: 6,
            ),
            const SizedBox(height: 6),
          ],
          if (!readOnly)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                _buildVolunteerPhotoButton(
                  icon: Icons.upload_file,
                  label: 'BROWSE',
                  onPressed: () => controller.pickPhotoForVolunteer(
                    row,
                    ImageSource.gallery,
                    context: context,
                  ),
                ),
                _buildVolunteerPhotoButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'CAMERA',
                  onPressed: () => controller.pickPhotoForVolunteer(
                    row,
                    ImageSource.camera,
                    context: context,
                  ),
                ),
              ],
            ),
        ],
      );
    });
  }

  Widget _buildVolunteerPhotoButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 10)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
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
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'VOLUNTEER NAME',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Expanded(
                  child: Text(
                    'PASSWORD',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Expanded(
                  child: Text(
                    'CELL',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'PHOTO',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        Obx(
          () => Column(
            children: controller.volunteerRows.asMap().entries.map((entry) {
              return _buildVolunteerTableRow(
                context,
                controller,
                entry.key,
                entry.value,
                isMobile,
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Align(
            alignment: Alignment.center,
            child: Obx(
              () => controller.isLoading.value
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CustomLoader(size: 24),
                    )
                  : TextButton.icon(
                      onPressed: controller.isEditMode
                          ? null
                          : () async {
                              controller.errorMessage.value = '';
                              await controller.registerCurrentVolunteer(
                                context: context,
                              );
                            },
                      icon: const Icon(Icons.add),
                      label: const Text('Add More'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVolunteerTableRow(
    BuildContext context,
    UserManagementController controller,
    int index,
    VolunteerRow row,
    bool isMobile,
  ) {
    if (isMobile) {
      return Obx(() {
        final readOnly = row.isRegistered.value && !controller.isEditMode;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: readOnly ? AppTheme.primaryColor.withOpacity(0.06) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (readOnly)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Saved',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                _buildVolunteerMobileField(
                  'VOLUNTEER NAME',
                  SizedBox(
                    height: _kVolunteerTableFieldHeight,
                    child: TextFormField(
                      controller: row.nameController,
                      readOnly: readOnly,
                      style: const TextStyle(fontSize: 12),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: readOnly
                          ? null
                          : (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter volunteer name';
                              }
                              return null;
                            },
                      decoration: _volunteerBulkFieldDecoration(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildVolunteerMobileField(
                  'PASSWORD',
                  _buildVolunteerPasswordField(readOnly: readOnly),
                ),
                const SizedBox(height: 12),
                _buildVolunteerMobileField(
                  'CELL',
                  SizedBox(
                    height: _kVolunteerTableFieldHeight,
                    child: _buildVolunteerCellField(
                      controller: row.cellController,
                      readOnly: readOnly,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildVolunteerPhotoColumn(
                    context: context,
                    controller: controller,
                    row: row,
                    readOnly: readOnly,
                    previewSize: 56,
                  ),
                ),
              ],
            ),
          ),
        );
      });
    }

    return Obx(() {
      final readOnly = row.isRegistered.value && !controller.isEditMode;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: readOnly ? AppTheme.primaryColor.withOpacity(0.06) : null,
          border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (readOnly)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Saved',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  SizedBox(
                    height: _kVolunteerTableFieldHeight,
                    child: TextFormField(
                      controller: row.nameController,
                      readOnly: readOnly,
                      style: const TextStyle(fontSize: 12),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: readOnly
                          ? null
                          : (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter volunteer name';
                              }
                              return null;
                            },
                      decoration: _volunteerBulkFieldDecoration(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _buildVolunteerPasswordField(readOnly: readOnly)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: _kVolunteerTableFieldHeight,
                    child: _buildVolunteerCellField(
                      controller: row.cellController,
                      readOnly: readOnly,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _buildVolunteerPhotoColumn(
                context: context,
                controller: controller,
                row: row,
                readOnly: readOnly,
                previewSize: 44,
              ),
            ),
          ],
        ),
      );
    });
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
                _buildUserInfoRow('USER NAME', _userNameOrDash(user)),
                _buildUserInfoRow('NAME', user.name),
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
    return ResponsiveAdminTable(
      columnWidths: const {
        0: FixedColumnWidth(80),
        1: FlexColumnWidth(1.6),
        2: FlexColumnWidth(1.6),
        3: FlexColumnWidth(1.4),
        4: FlexColumnWidth(2.2),
        5: FlexColumnWidth(1.5),
      },
      rows: [
        TableRow(
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
          ),
          children: [
            _buildTableCell('PHOTO', isHeader: true),
            _buildTableCell('USER NAME', isHeader: true),
            _buildTableCell('NAME', isHeader: true),
            _buildTableCell('TYPE', isHeader: true),
            _buildTableCell('COMPETITION', isHeader: true),
            _buildTableCell('CELL', isHeader: true),
          ],
        ),
        ...users.map((user) {
          return TableRow(
            children: [
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(child: _buildUserPhoto(user, 40)),
                ),
              ),
              _buildTableCell(_userNameOrDash(user), maxLines: 2),
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
        }),
      ],
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
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => controller.removeVolunteerRow(index),
                tooltip: 'Remove volunteer',
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
              PhotoSourceButtons(
                onPick: (source, ctx) =>
                    controller.pickPhotoForVolunteer(row, source, context: ctx),
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
              _buildUserInfoRow('USER NAME', _userNameOrDash(user)),
              _buildUserInfoRow('NAME', user.name),
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
  return ResponsiveAdminTable(
    columnWidths: const {
      0: FixedColumnWidth(80),
      1: FlexColumnWidth(1.6),
      2: FlexColumnWidth(1.6),
      3: FlexColumnWidth(1.4),
      4: FlexColumnWidth(2.2),
      5: FlexColumnWidth(1.5),
    },
    rows: [
      TableRow(
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
        ),
        children: [
          _buildTableCell('PHOTO', isHeader: true),
          _buildTableCell('USER NAME', isHeader: true),
          _buildTableCell('NAME', isHeader: true),
          _buildTableCell('TYPE', isHeader: true),
          _buildTableCell('COMPETITION', isHeader: true),
          _buildTableCell('CELL', isHeader: true),
        ],
      ),
      ...users.map((user) {
        return TableRow(
          children: [
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Center(child: _buildUserPhoto(user, 40)),
              ),
            ),
            _buildTableCell(_userNameOrDash(user), maxLines: 2),
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
      }),
    ],
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
