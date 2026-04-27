import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/school_controller.dart';
import '../../widgets/form_title.dart';
import '../../widgets/buttons.dart';
import '../../widgets/location/city_search_field.dart';
import '../../widgets/location/state_search_field.dart';
import '../../../data/models/institution_category_model.dart';

class SchoolCreateScreen extends StatelessWidget {
  final bool hideButtons;

  const SchoolCreateScreen({super.key, this.hideButtons = false});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SchoolController());

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 16),
      child: Card(
        elevation: 4,
        margin: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Form(
            key: controller.formKey,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: double.infinity),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  FormTitle(
                    text: 'Institutions',
                    isMobile: isMobile,
                    isTablet: isTablet,
                  ),

                  // Institution Type and Category (moved to top)
                  _buildInstitutionTypeField(
                    context,
                    controller,
                    isMobile,
                    isTablet,
                  ),
                  SizedBox(height: isMobile ? 20 : 24),

                  // Institution Name and Address in same row (desktop) or column (mobile)
                  isMobile
                      ? Column(
                          children: [
                            _buildTextField(
                              context,
                              label: 'Institution Name :',
                              controller: controller.institutionNameController,
                              isMobile: isMobile,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter institution name';
                                }
                                if (value.trim().length < 3) {
                                  return 'Institution name must be at least 3 characters';
                                }
                                if (value.trim().length > 255) {
                                  return 'Institution name must not exceed 255 characters';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: isMobile ? 20 : 24),

                            _buildTextField(
                              context,
                              label: 'Institution Short Name :',
                              controller:
                                  controller.institutionShortNameController,
                              isMobile: isMobile,
                            ),
                            SizedBox(height: isMobile ? 20 : 24),
                            _buildTextField(
                              context,
                              label: 'Email ID :',
                              controller: controller.emailController,
                              isMobile: isMobile,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final emailRegex = RegExp(
                                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                  );
                                  if (!emailRegex.hasMatch(value.trim())) {
                                    return 'Please enter a valid email address';
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildTextField(
                                context,
                                label: 'Institution Name :',
                                controller:
                                    controller.institutionNameController,
                                isMobile: isMobile,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter institution name';
                                  }
                                  if (value.trim().length < 3) {
                                    return 'Institution name must be at least 3 characters';
                                  }
                                  if (value.trim().length > 255) {
                                    return 'Institution name must not exceed 255 characters';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(width: isTablet ? 16 : 20),
                            Expanded(
                              child: _buildTextField(
                                context,
                                label: 'Institution Short Name :',
                                controller:
                                    controller.institutionShortNameController,
                                isMobile: isMobile,
                              ),
                            ),
                            SizedBox(width: isTablet ? 16 : 20),
                            Expanded(
                              child: _buildTextField(
                                context,
                                label: 'Email ID :',
                                controller: controller.emailController,
                                isMobile: isMobile,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final emailRegex = RegExp(
                                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                    );
                                    if (!emailRegex.hasMatch(value.trim())) {
                                      return 'Please enter a valid email address';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                  SizedBox(height: isMobile ? 20 : 24),

                  // Address field
                  _buildTextField(
                    context,
                    label: 'Address :',
                    controller: controller.addressController,
                    isMobile: isMobile,
                    maxLines: isMobile ? 3 : 1,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter address';
                      }
                      if (value.trim().length < 10) {
                        return 'Address must be at least 10 characters';
                      }
                      if (value.trim().length > 2000) {
                        return 'Address must not exceed 2000 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: isMobile ? 20 : 24),

                  // State, City, Pincode in row (desktop) or column (mobile)
                  isMobile
                      ? Column(
                          children: [
                            _buildStateField(
                              context,
                              controller,
                              isMobile,
                              isTablet,
                            ),
                            SizedBox(height: isMobile ? 20 : 24),
                            _buildCityField(
                              context,
                              controller,
                              isMobile,
                              isTablet,
                            ),
                            SizedBox(height: isMobile ? 20 : 24),
                            _buildPincodeField(
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
                              child: _buildStateField(
                                context,
                                controller,
                                isMobile,
                                isTablet,
                              ),
                            ),
                            SizedBox(width: isTablet ? 8 : 12),
                            Expanded(
                              flex: 1,
                              child: _buildCityField(
                                context,
                                controller,
                                isMobile,
                                isTablet,
                              ),
                            ),
                            SizedBox(width: isTablet ? 8 : 12),
                            Expanded(
                              flex: 1,
                              child: _buildPincodeField(
                                context,
                                controller,
                                isMobile,
                                isTablet,
                              ),
                            ),
                          ],
                        ),
                  SizedBox(height: isMobile ? 20 : 24),

                  // Error Message
                  Obx(
                    () => controller.errorMessage.value.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              controller.errorMessage.value,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Action Buttons (Save/Update and Cancel) - Hide when used in dialog
                  if (!hideButtons)
                    Obx(
                      () => isMobile
                          ? Column(
                              children: [
                                saveButton(
                                  onPressed: () => controller.submitSchool(),
                                  isLoading: controller.isLoading,
                                  text: controller.isEditMode.value
                                      ? 'UPDATE'
                                      : 'SAVE',
                                  isFullWidth: true,
                                ),
                                const SizedBox(height: 12),
                                cancelButton(
                                  onPressed: () {
                                    // Check edit mode before resetting
                                    final wasInEditMode =
                                        controller.isEditMode.value;
                                    controller.resetForm();
                                    // Redirect to list view if in edit mode
                                    if (wasInEditMode) {
                                      controller.toggleViewMode(true);
                                    }
                                  },
                                  isFullWidth: true,
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                saveButton(
                                  onPressed: () => controller.submitSchool(),
                                  isLoading: controller.isLoading,
                                  text: controller.isEditMode.value
                                      ? 'UPDATE'
                                      : 'SAVE',
                                  width: 200,
                                ),
                                const SizedBox(width: 16),
                                cancelButton(
                                  onPressed: () {
                                    // Check edit mode before resetting
                                    final wasInEditMode =
                                        controller.isEditMode.value;
                                    controller.resetForm();
                                    // Redirect to list view if in edit mode
                                    if (wasInEditMode) {
                                      controller.toggleViewMode(true);
                                    }
                                  },
                                  width: 200,
                                ),
                              ],
                            ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required bool isMobile,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    void Function(String?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: maxLines > 1 ? 12 : 12,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          style: TextStyle(fontSize: isMobile ? 14 : 16),
          validator: validator,
          onChanged: onChanged,
        ),
      ],
    );
  }

  InputDecoration _schoolLocationDecoration(
    bool isMobile, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: 12,
      ),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildStateField(
    BuildContext context,
    SchoolController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'State :',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (controller.isLoadingStates.value) {
            return TextFormField(
              readOnly: true,
              style: TextStyle(fontSize: isMobile ? 14 : 16),
              decoration: _schoolLocationDecoration(
                isMobile,
                suffixIcon: const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ).copyWith(hintText: 'Loading states...'),
            );
          }

          return StateSearchField(
            textEditingController: controller.createFormStateTextController,
            focusNode: controller.createFormStateFocusNode,
            states: List.from(controller.states),
            decorationBuilder: ({Widget? suffixIcon}) =>
                _schoolLocationDecoration(isMobile, suffixIcon: suffixIcon),
            isMobile: isMobile,
            hintText: 'Search or select state',
            onStateId: controller.setCreateFormState,
            validator: (_) {
              if (controller.selectedStateId.value <= 0) {
                return 'Please select state';
              }
              return null;
            },
          );
        }),
      ],
    );
  }

  Widget _buildCityField(
    BuildContext context,
    SchoolController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'City :',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (controller.isLoadingCities.value) {
            return TextFormField(
              readOnly: true,
              style: TextStyle(fontSize: isMobile ? 14 : 16),
              decoration: _schoolLocationDecoration(
                isMobile,
                suffixIcon: const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ).copyWith(hintText: 'Loading cities...'),
            );
          }

          if (controller.selectedStateId.value <= 0) {
            return TextFormField(
              readOnly: true,
              style: TextStyle(fontSize: isMobile ? 14 : 16),
              decoration: _schoolLocationDecoration(
                isMobile,
              ).copyWith(hintText: 'Select state first'),
            );
          }

          final availableCities =
              controller.cities
                  .where((c) => c.stateId == controller.selectedStateId.value)
                  .toList()
                ..sort((a, b) => a.cityName.compareTo(b.cityName));

          return CitySearchField(
            textEditingController: controller.createFormCityTextController,
            focusNode: controller.createFormCityFocusNode,
            cities: availableCities,
            decorationBuilder: ({Widget? suffixIcon}) =>
                _schoolLocationDecoration(isMobile, suffixIcon: suffixIcon),
            isMobile: isMobile,
            hintText: 'Search or select city',
            onCityId: controller.setCreateFormCity,
            validator: (_) {
              if (controller.selectedStateId.value <= 0) {
                return 'Please select state first';
              }
              if (controller.selectedCity.value.isEmpty) {
                return 'Please select city';
              }
              return null;
            },
          );
        }),
      ],
    );
  }

  Widget _buildPincodeField(
    BuildContext context,
    SchoolController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pincode :',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller.pincodeController,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
            hintText: 'Enter Pincode',
            counterText: '',
          ),
          style: TextStyle(fontSize: isMobile ? 14 : 16),
          keyboardType: TextInputType.number,
          maxLength: 6,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter pincode';
            }
            if (value.length != 6) {
              return 'Pincode must be 6 digits';
            }
            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
              return 'Pincode must contain only numbers';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildInstitutionTypeField(
    BuildContext context,
    SchoolController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Institution Type :',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (controller.isLoadingInstitutionTypes.value) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (controller.institutionTypes.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'No institution types available',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: controller.institutionTypes.map((type) {
              final isSelected =
                  controller.selectedInstitutionTypeId.value == type.id;

              return Padding(
                padding: EdgeInsets.only(bottom: isMobile ? 10 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<int>(
                          value: type.id,
                          groupValue:
                              controller.selectedInstitutionTypeId.value,
                          onChanged: (value) async {
                            if (value != null) {
                              controller.selectedInstitutionTypeId.value =
                                  value;
                              controller.selectedInstitutionType.value =
                                  type.displayName;
                              // Clear category selection
                              controller.selectedInstitutionCategoryId.value =
                                  0;
                              controller.selectedInstitutionCategory.value = '';
                              controller.selectedInstitutionCategoryIds.clear();
                              // Load categories for this institution type
                              await controller
                                  .loadInstitutionCategoriesByTypeId(value);
                            }
                          },
                          activeColor: Colors.green,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        Flexible(
                          child: Text(
                            type.displayName,
                            style: TextStyle(fontSize: isMobile ? 14 : 16),
                          ),
                        ),
                      ],
                    ),
                    if (isSelected)
                      Padding(
                        padding: EdgeInsets.only(
                          left: isMobile ? 28 : 30,
                          top: 6,
                        ),
                        child: _buildSubCategoryField(
                          context,
                          controller,
                          '', // label hidden to match screenshot
                          controller.institutionCategories,
                          isMobile,
                          isTablet,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildSubCategoryField(
    BuildContext context,
    SchoolController controller,
    String label,
    List<dynamic> categories, // InstitutionCategoryModel list
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.trim().isNotEmpty) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: controller.isLoadingInstitutionCategories.value
                    ? null
                    : () => _showAddCategoryDialog(context, controller),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add New'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green[700],
                  side: BorderSide(color: Colors.green[700]!),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 14,
                    vertical: isMobile ? 10 : 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Obx(() {
          if (controller.isLoadingInstitutionCategories.value) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          final selectedType = controller.institutionTypes.firstWhereOrNull(
            (t) => t.id == controller.selectedInstitutionTypeId.value,
          );
          final isYogaCenter =
              (selectedType?.typeName.toUpperCase() == 'YOGA_CENTER');

          final categoryList = categories
              .whereType<InstitutionCategoryModel>()
              .toList();

          if (categoryList.isEmpty) {
            return const SizedBox.shrink();
          }

          void syncSelectedNames() {
            final names = categoryList
                .where(
                  (c) =>
                      controller.selectedInstitutionCategoryIds.contains(c.id),
                )
                .map((c) => c.displayName)
                .toList();
            controller.selectedInstitutionCategory.value = names.join(', ');
            controller.selectedInstitutionCategoryId.value =
                controller.selectedInstitutionCategoryIds.isNotEmpty
                ? controller.selectedInstitutionCategoryIds.first
                : 0;
          }

          if (!isYogaCenter) {
            final selectedId =
                controller.selectedInstitutionCategoryIds.isNotEmpty
                ? controller.selectedInstitutionCategoryIds.first
                : (controller.selectedInstitutionCategoryId.value > 0
                      ? controller.selectedInstitutionCategoryId.value
                      : 0);

            return Wrap(
              spacing: isMobile ? 14 : 18,
              runSpacing: isMobile ? 8 : 10,
              children: categoryList.map((c) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<int>(
                      value: c.id,
                      groupValue: selectedId == 0 ? null : selectedId,
                      onChanged: (value) {
                        if (value == null) return;
                        controller.selectedInstitutionCategoryIds
                          ..clear()
                          ..add(value);
                        syncSelectedNames();
                      },
                      activeColor: Colors.green,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    Text(
                      c.displayName,
                      style: TextStyle(fontSize: isMobile ? 13.5 : 15),
                    ),
                  ],
                );
              }).toList(),
            );
          }

          // Yoga Center: multi-select inline checkboxes (like screenshot)
          return Wrap(
            spacing: isMobile ? 14 : 18,
            runSpacing: isMobile ? 8 : 10,
            children: categoryList.map((c) {
              final checked = controller.selectedInstitutionCategoryIds
                  .contains(c.id);
              return InkWell(
                onTap: () {
                  if (checked) {
                    controller.selectedInstitutionCategoryIds.remove(c.id);
                  } else {
                    controller.selectedInstitutionCategoryIds.add(c.id);
                  }
                  syncSelectedNames();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: checked,
                      onChanged: (v) {
                        if (v == true) {
                          controller.selectedInstitutionCategoryIds.add(c.id);
                        } else {
                          controller.selectedInstitutionCategoryIds.remove(
                            c.id,
                          );
                        }
                        syncSelectedNames();
                      },
                      activeColor: Colors.green,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    Text(
                      c.displayName,
                      style: TextStyle(fontSize: isMobile ? 13.5 : 15),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }),
        // Show custom category if selected
        Obx(() {
          if (controller.selectedInstitutionCategory.value.isNotEmpty &&
              controller.selectedInstitutionCategoryId.value == 0) {
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Selected: ${controller.selectedInstitutionCategory.value}',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: Colors.green[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: Colors.green[700],
                      onPressed: () {
                        controller.selectedInstitutionCategory.value = '';
                        controller.selectedInstitutionCategoryId.value = 0;
                        controller.selectedInstitutionCategoryIds.clear();
                      },
                      tooltip: 'Clear selection',
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  void _showAddCategoryDialog(
    BuildContext context,
    SchoolController controller,
  ) {
    final categoryController = TextEditingController();
    final selectedType = controller.institutionTypes.firstWhereOrNull(
      (t) => t.id == controller.selectedInstitutionTypeId.value,
    );
    final institutionTypeName = selectedType?.displayName ?? 'Institution';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Category for $institutionTypeName'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: categoryController,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              hintText: 'Enter category name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter category name';
              }
              if (value.trim().length < 2) {
                return 'Category name must be at least 2 characters';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Obx(
            () => TextButton(
              onPressed: controller.isLoadingInstitutionCategories.value
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        final category = categoryController.text.trim();
                        final success = await controller
                            .createInstitutionCategory(category);
                        if (success && context.mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              child: controller.isLoadingInstitutionCategories.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
