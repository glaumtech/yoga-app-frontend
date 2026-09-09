import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/sponsor_controller.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/custom_loader.dart';
import '../../widgets/form_title.dart';
import '../../widgets/searchable_dropdown_field.dart';
import '../../widgets/pinned_scroll_views.dart';

class SponsorCreateScreen extends StatelessWidget {
  const SponsorCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SponsorController());

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return PinnedVerticalScrollView(
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
                  text: 'SPONSORS',
                  isMobile: isMobile,
                  isTablet: isTablet,
                ),

                // Competition Selection and Number of Students in same row
                isMobile
                    ? Column(
                        children: [
                          _buildCompetitionField(
                            context,
                            controller,
                            isMobile,
                            isTablet,
                          ),
                          SizedBox(height: isMobile ? 20 : 24),
                          _buildNumberOfStudentsField(
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
                            child: _buildCompetitionField(
                              context,
                              controller,
                              isMobile,
                              isTablet,
                            ),
                          ),
                          SizedBox(width: isTablet ? 16 : 24),
                          Expanded(
                            child: _buildNumberOfStudentsField(
                              context,
                              controller,
                              isMobile,
                              isTablet,
                            ),
                          ),
                        ],
                      ),
                SizedBox(height: isMobile ? 20 : 24),

                // Payment Mode Section
                _buildPaymentModeSection(context, isMobile, isTablet),
                SizedBox(height: isMobile ? 20 : 24),

                // Billing Information Section
                _buildBillingInformationSection(
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
                            onPressed: () => controller.submitSponsor(),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompetitionField(
    BuildContext context,
    SponsorController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sponsor for :',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => SearchableDropdownField(
            selectedValue: controller.selectedCompetitionId.value.isNotEmpty
                ? controller.selectedCompetitionId.value
                : null,
            hintText: 'Select Competition',
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: 16,
            ),
            items: controller.competitions
                .where((c) => c.id != null)
                .map(
                  (competition) => SearchableDropdownItem(
                    value: competition.id!,
                    label: competition.competitionName,
                  ),
                )
                .toList(),
            onChanged: (value) {
              controller.selectedCompetitionId.value = value;
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a competition';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 8),
        // Informational text under the dropdown
        Text(
          '(You are encouraging the Govt/Govt-Aided students who need financial support to participate in this event)',
          style: TextStyle(
            fontSize: isMobile ? 12 : 13,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildNumberOfStudentsField(
    BuildContext context,
    SponsorController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Number of Students :',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => DropdownButtonFormField<int>(
            value: controller.selectedNumberOfStudents.value > 0
                ? controller.selectedNumberOfStudents.value
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
              'Select number of students',
              style: TextStyle(fontSize: isMobile ? 14 : 16),
            ),
            style: TextStyle(fontSize: isMobile ? 14 : 16),
            items: List.generate(10, (index) => index + 1).map((number) {
              return DropdownMenuItem<int>(
                value: number,
                child: Text(
                  number.toString(),
                  style: TextStyle(fontSize: isMobile ? 14 : 16),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                controller.selectedNumberOfStudents.value = value;
                controller.numberOfStudentsController.text = value.toString();
              }
            },
            validator: (value) {
              if (value == null || value <= 0) {
                return 'Please select number of students';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 8),
        // Hint text under the dropdown
        Text(
          'Select number of Students you would like to sponsor',
          style: TextStyle(
            fontSize: isMobile ? 12 : 13,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
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
        Text(
          'Payment Mode :',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        const SizedBox(height: 8),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBillingInformationSection(
    BuildContext context,
    SponsorController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(
          'Billing Information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
            fontSize: isMobile ? 18 : 20,
          ),
        ),
        SizedBox(height: isMobile ? 20 : 24),

        // Sponsor's Name and Address in same row (desktop) or column (mobile)
        isMobile
            ? Column(
                children: [
                  _buildTextField(
                    context,
                    label: "Sponsor's Name :",
                    controller: controller.sponsorNameController,
                    isMobile: isMobile,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter sponsor name';
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
                    maxLines: 2,
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
                      label: "Sponsor's Name :",
                      controller: controller.sponsorNameController,
                      isMobile: isMobile,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter sponsor name';
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

        // City, State, Pincode in row (desktop) or column (mobile)
        isMobile
            ? Column(
                children: [
                  _buildTextField(
                    context,
                    label: 'City :',
                    controller: controller.cityController,
                    isMobile: isMobile,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter city';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: isMobile ? 20 : 24),
                  _buildTextField(
                    context,
                    label: 'State :',
                    controller: controller.stateController,
                    isMobile: isMobile,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter state';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: isMobile ? 20 : 24),
                  _buildTextField(
                    context,
                    label: 'Pincode :',
                    controller: controller.pincodeController,
                    isMobile: isMobile,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter pincode';
                      }
                      if (value.length != 6) {
                        return 'Pincode must be 6 digits';
                      }
                      return null;
                    },
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      context,
                      label: 'City :',
                      controller: controller.cityController,
                      isMobile: isMobile,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter city';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 20),
                  Expanded(
                    child: _buildTextField(
                      context,
                      label: 'State :',
                      controller: controller.stateController,
                      isMobile: isMobile,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter state';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 20),
                  Expanded(
                    child: _buildTextField(
                      context,
                      label: 'Pincode :',
                      controller: controller.pincodeController,
                      isMobile: isMobile,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter pincode';
                        }
                        if (value.length != 6) {
                          return 'Pincode must be 6 digits';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
        SizedBox(height: isMobile ? 20 : 24),

        // Cell Phone, WhatsApp, and Email in same row (desktop) or column (mobile)
        isMobile
            ? Column(
                children: [
                  _buildTextField(
                    context,
                    label: 'Cell Phone :',
                    controller: controller.cellPhoneController,
                    isMobile: isMobile,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter cell phone';
                      }
                      if (value.length != 10) {
                        return 'Cell phone must be 10 digits';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: isMobile ? 20 : 24),
                  _buildTextField(
                    context,
                    label: 'WhatsApp :',
                    controller: controller.whatsappController,
                    isMobile: isMobile,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          value.length != 10) {
                        return 'WhatsApp must be 10 digits';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: isMobile ? 20 : 24),
                  _buildTextField(
                    context,
                    label: 'E-mail Address :',
                    controller: controller.emailController,
                    isMobile: isMobile,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter email address';
                      }
                      if (!GetUtils.isEmail(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      context,
                      label: 'Cell Phone :',
                      controller: controller.cellPhoneController,
                      isMobile: isMobile,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter cell phone';
                        }
                        if (value.length != 10) {
                          return 'Cell phone must be 10 digits';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: isTablet ? 12 : 16),
                  Expanded(
                    child: _buildTextField(
                      context,
                      label: 'WhatsApp :',
                      controller: controller.whatsappController,
                      isMobile: isMobile,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            value.length != 10) {
                          return 'WhatsApp must be 10 digits';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: isTablet ? 12 : 16),
                  Expanded(
                    child: _buildTextField(
                      context,
                      label: 'E-mail Address :',
                      controller: controller.emailController,
                      isMobile: isMobile,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email address';
                        }
                        if (!GetUtils.isEmail(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required bool isMobile,
    TextInputType? keyboardType,
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
          keyboardType: keyboardType,
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
}
