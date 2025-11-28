import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/participant_controller.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;

class RegistrationFormScreen extends StatelessWidget {
  final String eventId;
  final String? participantId; // For edit mode - participant ID to fetch

  const RegistrationFormScreen({
    super.key,
    required this.eventId,
    this.participantId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ParticipantController>();

    // Fetch participant details from API if participantId is provided
    if (participantId != null && participantId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Always fetch if participantId is different from current edit participant
        final currentEditId = controller.participantToEdit.value?.id;
        if (currentEditId != participantId) {
          // Reset form first to clear any previous data
          controller.resetForm();
          // Then fetch and populate
          controller.fetchParticipantById(participantId!);
        }
      });
    } else {
      // If no participantId, ensure form is reset for new registration
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (controller.isEditMode) {
          controller.resetForm();
        }
      });
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final maxWidth = isMobile ? double.infinity : (isTablet ? 700.0 : 900.0);

    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.isEditMode ? 'Edit Participant' : 'Registration Form',
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '1st District Level Schools & Colleges',
                          style: Theme.of(context).textTheme.titleSmall,
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Yogasana championship 2025',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Photo Section
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'PHOTO COMPULSORY',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) => SafeArea(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            leading: const Icon(
                                              Icons.photo_library,
                                            ),
                                            title: const Text(
                                              'Choose from Gallery',
                                            ),
                                            onTap: () {
                                              Navigator.pop(context);
                                              controller.pickImage();
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(
                                              Icons.camera_alt,
                                            ),
                                            title: const Text('Take Photo'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              controller.takePhoto();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: Obx(
                                  () => FutureBuilder<Uint8List?>(
                                    future: controller.getImageBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Container(
                                          width: isMobile ? 150 : 180,
                                          height: isMobile ? 180 : 220,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }

                                      return Obx(() {
                                        final imageBytes = snapshot.data;
                                        final hasNewImage =
                                            imageBytes != null ||
                                            (controller.selectedImage.value !=
                                                null);

                                        // Check for existing photo from API - reactive to existingPhotoUrl changes
                                        final hasExistingPhoto =
                                            controller.isEditMode &&
                                            controller
                                                .existingPhotoUrl
                                                .value
                                                .isNotEmpty;

                                        return Container(
                                          width: isMobile ? 150 : 180,
                                          height: isMobile ? 180 : 220,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child:
                                              hasNewImage && imageBytes != null
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.memory(
                                                    imageBytes,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              : hasExistingPhoto
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.network(
                                                    controller
                                                        .existingPhotoUrl
                                                        .value,
                                                    fit: BoxFit.cover,
                                                    loadingBuilder:
                                                        (
                                                          context,
                                                          child,
                                                          loadingProgress,
                                                        ) {
                                                          if (loadingProgress ==
                                                              null) {
                                                            return child;
                                                          }
                                                          return Center(
                                                            child: CircularProgressIndicator(
                                                              value:
                                                                  loadingProgress
                                                                          .expectedTotalBytes !=
                                                                      null
                                                                  ? loadingProgress
                                                                            .cumulativeBytesLoaded /
                                                                        loadingProgress
                                                                            .expectedTotalBytes!
                                                                  : null,
                                                            ),
                                                          );
                                                        },
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          print(
                                                            'Error loading image: $error',
                                                          );
                                                          print(
                                                            'Image URL: ${controller.existingPhotoUrl.value}',
                                                          );
                                                          return const Icon(
                                                            Icons
                                                                .add_photo_alternate,
                                                            size: 64,
                                                          );
                                                        },
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.add_photo_alternate,
                                                  size: 64,
                                                ),
                                        );
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Participant Name
                  TextFormField(
                    controller: controller.nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name of the Participant (IN BLOCK LETTERS)',
                      hintText: 'Enter full name in capital letters',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Participant name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category Selection
                  Text(
                    'Category:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Obx(
                    () => Column(
                      children: [
                        CheckboxListTile(
                          title: const Text('Common'),
                          value: controller.isCategorySelected(
                            AppConstants.categoryCommon,
                          ),
                          onChanged: (bool? checked) {
                            controller.toggleCategory(
                              AppConstants.categoryCommon,
                            );
                          },
                        ),
                        CheckboxListTile(
                          title: const Text('Special'),
                          value: controller.isCategorySelected(
                            AppConstants.categorySpecial,
                          ),
                          onChanged: (bool? checked) {
                            controller.toggleCategory(
                              AppConstants.categorySpecial,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date of Birth and Age - Responsive Layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (isMobile) {
                        // Mobile: Stack vertically
                        return Obx(
                          () => Column(
                            children: [
                              InkWell(
                                onTap: () =>
                                    controller.selectDateOfBirth(context),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Date of Birth',
                                    suffixIcon: Icon(Icons.calendar_today),
                                  ),
                                  child: Text(
                                    controller.dateOfBirth.value != null
                                        ? app_date_utils
                                              .AppDateUtils.formatDate(
                                            controller.dateOfBirth.value!,
                                          )
                                        : 'Select Date of Birth',
                                    style: TextStyle(
                                      color:
                                          controller.dateOfBirth.value != null
                                          ? Colors.black
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                              if (controller.dateOfBirth.value != null) ...[
                                const SizedBox(height: 16),
                                InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Age',
                                  ),
                                  child: Text(
                                    app_date_utils.AppDateUtils.calculateAge(
                                      controller.dateOfBirth.value!,
                                    ).toString(),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      } else {
                        // Tablet/Desktop: Side by side
                        return Obx(
                          () => Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () =>
                                      controller.selectDateOfBirth(context),
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Date of Birth',
                                      suffixIcon: Icon(Icons.calendar_today),
                                    ),
                                    child: Text(
                                      controller.dateOfBirth.value != null
                                          ? app_date_utils
                                                .AppDateUtils.formatDate(
                                              controller.dateOfBirth.value!,
                                            )
                                          : 'Select Date of Birth',
                                      style: TextStyle(
                                        color:
                                            controller.dateOfBirth.value != null
                                            ? Colors.black
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (controller.dateOfBirth.value != null) ...[
                                const SizedBox(width: 16),
                                Expanded(
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Age',
                                    ),
                                    child: Text(
                                      app_date_utils.AppDateUtils.calculateAge(
                                        controller.dateOfBirth.value!,
                                      ).toString(),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Gender Selection
                  Text(
                    'Sex (✓):',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (isMobile) {
                        // Mobile: Stack vertically
                        return Obx(
                          () => Column(
                            children: [
                              RadioListTile<String>(
                                title: const Text('Male'),
                                value: AppConstants.genderMale,
                                groupValue: controller.gender.value.isEmpty
                                    ? null
                                    : controller.gender.value,
                                onChanged: (value) {
                                  controller.setGender(value);
                                },
                              ),
                              RadioListTile<String>(
                                title: const Text('Female'),
                                value: AppConstants.genderFemale,
                                groupValue: controller.gender.value.isEmpty
                                    ? null
                                    : controller.gender.value,
                                onChanged: (value) {
                                  controller.setGender(value);
                                },
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Tablet/Desktop: Side by side
                        return Obx(
                          () => Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Male'),
                                  value: AppConstants.genderMale,
                                  groupValue: controller.gender.value.isEmpty
                                      ? null
                                      : controller.gender.value,
                                  onChanged: (value) {
                                    controller.setGender(value);
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Female'),
                                  value: AppConstants.genderFemale,
                                  groupValue: controller.gender.value.isEmpty
                                      ? null
                                      : controller.gender.value,
                                  onChanged: (value) {
                                    controller.setGender(value);
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Standard/Group Selection
                  Text(
                    'Tick (✓) Your Std. / Group:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => Column(
                      children: AppConstants.standards.map((standard) {
                        return RadioListTile<String>(
                          title: Text(standard),
                          value: standard,
                          groupValue: controller.standard.value.isEmpty
                              ? null
                              : controller.standard.value,
                          onChanged: (value) {
                            controller.setStandard(value);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // School Name and Address - Responsive Layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (isMobile) {
                        // Mobile: Stack vertically
                        return Column(
                          children: [
                            TextFormField(
                              controller: controller.schoolNameController,
                              decoration: const InputDecoration(
                                labelText:
                                    'Name & Address of the School / Institution',
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'School name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: controller.addressController,
                              decoration: const InputDecoration(
                                labelText: 'Address',
                              ),
                              maxLines: 3,
                            ),
                          ],
                        );
                      } else {
                        // Tablet/Desktop: Side by side
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: controller.schoolNameController,
                                decoration: const InputDecoration(
                                  labelText:
                                      'Name & Address of the School / Institution',
                                ),
                                maxLines: 3,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'School name is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: controller.addressController,
                                decoration: const InputDecoration(
                                  labelText: 'Address',
                                ),
                                maxLines: 3,
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Yoga Master Name and Contact - Responsive Layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (isMobile) {
                        // Mobile: Stack vertically
                        return Column(
                          children: [
                            TextFormField(
                              controller: controller.yogaMasterNameController,
                              decoration: const InputDecoration(
                                labelText: 'Yoga Master Name',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Yoga master name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller:
                                  controller.yogaMasterContactController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Yoga Master Contact No.',
                              ),
                              validator: (value) {
                                // Only validate format if a value is provided
                                if (value != null && value.trim().isNotEmpty) {
                                  if (!GetUtils.isPhoneNumber(value)) {
                                    return 'Please enter a valid phone number';
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                        );
                      } else {
                        // Tablet/Desktop: Side by side
                        return Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: controller.yogaMasterNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Yoga Master Name',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Yoga master name is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller:
                                    controller.yogaMasterContactController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Yoga Master Contact No.',
                                ),
                                validator: (value) {
                                  // Only validate format if a value is provided
                                  if (value != null &&
                                      value.trim().isNotEmpty) {
                                    if (!GetUtils.isPhoneNumber(value)) {
                                      return 'Please enter a valid phone number';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 32),

                  // Loading State for Fetching Participant
                  Obx(
                    () => controller.isLoadingParticipant.value
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade300),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Loading participant details...',
                                  style: TextStyle(color: Colors.blue.shade700),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Error Message Display
                  Obx(
                    () => controller.errorMessage.value.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Text(
                              controller.errorMessage.value,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Submit Button
                  Obx(
                    () => ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : () async {
                              // Validate form first
                              if (!controller.formKey.currentState!
                                  .validate()) {
                                return;
                              }

                              if (controller.dateOfBirth.value == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select date of birth',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              if (controller.gender.value.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select gender'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              if (controller.selectedCategories.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select at least one category',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              if (controller.standard.value.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select standard/group',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              if (controller.isEditMode &&
                                  controller.participantToEdit.value?.id !=
                                      null) {
                                // Update existing participant
                                final success = await controller
                                    .submitUpdateForm(
                                      controller.participantToEdit.value!.id!,
                                    );
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Participant updated successfully!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  // Just pop - let the previous screen handle its own refresh
                                  // This prevents unnecessary event-based API calls
                                  context.pop();
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        controller.errorMessage.value.isNotEmpty
                                            ? controller.errorMessage.value
                                            : 'Failed to update participant',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } else {
                                // Create new participant
                                final success = await controller
                                    .submitRegistrationForm(eventId: eventId);
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Registration submitted successfully!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  context.pop();
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        controller.errorMessage.value.isNotEmpty
                                            ? controller.errorMessage.value
                                            : 'Failed to submit registration',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Obx(
                              () => Text(
                                controller.isEditMode
                                    ? 'Update Participant'
                                    : 'Submit Registration',
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
