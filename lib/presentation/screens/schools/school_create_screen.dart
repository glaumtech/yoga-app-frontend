import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/school_controller.dart';
import '../../widgets/form_title.dart';
import '../../widgets/buttons.dart';
import '../../../data/models/city_model.dart';

class SchoolCreateScreen extends StatelessWidget {
  const SchoolCreateScreen({super.key});

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                FormTitle(
                  text: 'SCHOOLS & COLLEGES LIST',
                  isMobile: isMobile,
                  isTablet: isTablet,
                ),

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
                            label: 'Address :',
                            controller: controller.addressController,
                            isMobile: isMobile,
                            maxLines: 3,
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
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildTextField(
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
                          ),
                          SizedBox(width: isTablet ? 16 : 20),
                          Expanded(
                            child: _buildTextField(
                              context,
                              label: 'Address :',
                              controller: controller.addressController,
                              isMobile: isMobile,
                              maxLines: 1,
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
                          ),
                        ],
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
                        children: [
                          Expanded(
                            child: _buildStateField(
                              context,
                              controller,
                              isMobile,
                              isTablet,
                            ),
                          ),
                          SizedBox(width: isTablet ? 16 : 20),
                          Expanded(
                            child: _buildCityField(
                              context,
                              controller,
                              isMobile,
                              isTablet,
                            ),
                          ),
                          SizedBox(width: isTablet ? 16 : 20),
                          Expanded(
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

                // Institution Type Radio Buttons
                _buildInstitutionTypeField(
                  context,
                  controller,
                  isMobile,
                  isTablet,
                ),
                SizedBox(height: isMobile ? 24 : 32),

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

                // Action Buttons (Save/Update and Cancel)
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
                                controller.resetForm();
                                // Redirect to list view if in edit mode
                                if (controller.isEditMode.value) {
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
                                controller.resetForm();
                                // Redirect to list view if in edit mode
                                if (controller.isEditMode.value) {
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
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required bool isMobile,
    int maxLines = 1,
    String? Function(String?)? validator,
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
        ),
      ],
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
            return DropdownButtonFormField<String>(
              value: null,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              hint: Text(
                'Loading states...',
                style: TextStyle(fontSize: isMobile ? 14 : 16),
              ),
              items: [],
              onChanged: null,
            );
          }

          return DropdownButtonFormField<String>(
            value: controller.selectedState.value.isNotEmpty
                ? controller.selectedState.value
                : null,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: 12,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            hint: Text(
              'Select State',
              style: TextStyle(fontSize: isMobile ? 14 : 16),
            ),
            style: TextStyle(fontSize: isMobile ? 14 : 16),
            items: controller.states.map((state) {
              return DropdownMenuItem<String>(
                value: state.stateName,
                child: Text(
                  state.stateName,
                  style: TextStyle(fontSize: isMobile ? 14 : 16),
                ),
              );
            }).toList(),
            onChanged: (value) async {
              if (value != null) {
                final selectedState = controller.states.firstWhere(
                  (s) => s.stateName == value,
                );
                controller.selectedState.value = value;
                controller.selectedStateId.value = selectedState.id;
                controller.selectedCity.value = '';
                controller.pincodeController.clear();
                controller.cities.clear();

                // Load cities for selected state
                await controller.loadCitiesByStateId(selectedState.id);
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
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
            return DropdownButtonFormField<String>(
              value: null,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              hint: Text(
                'Loading cities...',
                style: TextStyle(fontSize: isMobile ? 14 : 16),
              ),
              items: [],
              onChanged: null,
            );
          }

          // Get all cities for the selected state
          List<CityModel> availableCities = [];
          if (controller.selectedStateId.value > 0) {
            availableCities = controller.cities
                .where(
                  (city) => city.stateId == controller.selectedStateId.value,
                )
                .toList();
            availableCities.sort((a, b) => a.cityName.compareTo(b.cityName));
          }

          return DropdownButtonFormField<String>(
            value: controller.selectedCity.value.isNotEmpty
                ? controller.selectedCity.value
                : null,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: 12,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            hint: Text(
              controller.selectedState.value.isEmpty
                  ? 'Select State first'
                  : 'Select City',
              style: TextStyle(fontSize: isMobile ? 14 : 16),
            ),
            style: TextStyle(fontSize: isMobile ? 14 : 16),
            items: availableCities.map((city) {
              return DropdownMenuItem<String>(
                value: city.cityName,
                child: Text(
                  city.cityName,
                  style: TextStyle(fontSize: isMobile ? 14 : 16),
                ),
              );
            }).toList(),
            onChanged: controller.selectedState.value.isEmpty
                ? null
                : (value) {
                    if (value != null) {
                      final selectedCity = availableCities.firstWhereOrNull(
                        (city) => city.cityName == value,
                      );
                      if (selectedCity != null) {
                        controller.selectedCity.value = value;
                        // Auto-populate pincode
                        controller.pincodeController.text =
                            selectedCity.pincode;
                      }
                    }
                  },
            validator: (value) {
              if (controller.selectedState.value.isEmpty) {
                return 'Please select state first';
              }
              if (value == null || value.isEmpty) {
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
        Obx(
          () => Wrap(
            spacing: isMobile ? 16 : 24,
            runSpacing: isMobile ? 12 : 16,
            children: SchoolController.institutionTypes.map((type) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio<String>(
                    value: type,
                    groupValue: controller.selectedInstitutionType.value,
                    onChanged: (value) {
                      controller.selectedInstitutionType.value = value ?? '';
                    },
                    activeColor: Colors.green,
                  ),
                  Text(type, style: TextStyle(fontSize: isMobile ? 14 : 16)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
