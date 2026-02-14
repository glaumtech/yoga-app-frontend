import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/school_controller.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/custom_loader.dart';
import '../../widgets/form_title.dart';

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
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                SizedBox(height: isMobile ? 20 : 24),

                // District, State, Pincode in row (desktop) or column (mobile)
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
                          _buildDistrictField(
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
                            child: _buildDistrictField(
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

                // Submit Button
                Center(
                  child: Obx(
                    () => controller.isLoading.value
                        ? const CustomLoader(message: 'Submitting...')
                        : PrimaryButton(
                            text: 'SUBMIT',
                            icon: Icons.check_circle,
                            onPressed: () => controller.submitSchool(),
                          ),
                  ),
                ),

                // Developer Notes
                SizedBox(height: isMobile ? 24 : 32),
                _buildDeveloperNotes(context, isMobile),
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

  Widget _buildDistrictField(
    BuildContext context,
    SchoolController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'District :',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => DropdownButtonFormField<String>(
            value: controller.selectedDistrict.value.isNotEmpty
                ? controller.selectedDistrict.value
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
              'Select District',
              style: TextStyle(fontSize: isMobile ? 14 : 16),
            ),
            style: TextStyle(fontSize: isMobile ? 14 : 16),
            items: controller.selectedState.value.isNotEmpty
                ? controller
                      .getDistrictsForState(controller.selectedState.value)
                      .map((district) {
                        return DropdownMenuItem<String>(
                          value: district,
                          child: Text(
                            district,
                            style: TextStyle(fontSize: isMobile ? 14 : 16),
                          ),
                        );
                      })
                      .toList()
                : [],
            onChanged: (value) {
              controller.selectedDistrict.value = value ?? '';
              controller.selectedPincode.value = '';
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select district';
              }
              return null;
            },
          ),
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
        Obx(
          () => DropdownButtonFormField<String>(
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
            items: SchoolController.states.map((state) {
              return DropdownMenuItem<String>(
                value: state,
                child: Text(
                  state,
                  style: TextStyle(fontSize: isMobile ? 14 : 16),
                ),
              );
            }).toList(),
            onChanged: (value) {
              controller.selectedState.value = value ?? '';
              controller.selectedDistrict.value = '';
              controller.selectedPincode.value = '';
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select state';
              }
              return null;
            },
          ),
        ),
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
        Obx(
          () => DropdownButtonFormField<String>(
            value: controller.selectedPincode.value.isNotEmpty
                ? controller.selectedPincode.value
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
              'Select Pincode',
              style: TextStyle(fontSize: isMobile ? 14 : 16),
            ),
            style: TextStyle(fontSize: isMobile ? 14 : 16),
            items: controller.selectedDistrict.value.isNotEmpty
                ? controller
                      .getPincodesForDistrict(controller.selectedDistrict.value)
                      .map((pincode) {
                        return DropdownMenuItem<String>(
                          value: pincode,
                          child: Text(
                            pincode,
                            style: TextStyle(fontSize: isMobile ? 14 : 16),
                          ),
                        );
                      })
                      .toList()
                : [],
            onChanged: (value) {
              controller.selectedPincode.value = value ?? '';
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select pincode';
              }
              return null;
            },
          ),
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

  Widget _buildDeveloperNotes(BuildContext context, bool isMobile) {
    return Container(
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
            '//If the Admin/Sub-Admin wants to add an address, we need this manual adding option.',
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '//The above given reports has to be auto-populated by our bots or web crawlers or any latest efficient techniques',
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '//The reports will be populated based on the District and State selected.',
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '//The printable pdf format will be in A4 size page displaying the address in two halves',
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
