import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/utils/storage_service.dart';
import '../../../routes/app_routes.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/organization_update_controller.dart';
import '../../widgets/admin_sidebar_layout.dart';
import '../../widgets/location/district_search_field.dart';
import '../../widgets/location/state_search_field.dart';
import '../../widgets/organization/organization_proof_image_upload.dart';
import '../../widgets/pinned_scroll_views.dart';

class OrganizationUpdateScreen extends StatelessWidget {
  const OrganizationUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(OrganizationUpdateController());
    final isCompleteRoute =
        GoRouterState.of(context).matchedLocation ==
        AppRoutes.organizationComplete;
    if (isCompleteRoute) {
      c.mandatoryMode.value = true;
    } else if (StorageService.getBool(
          AppConstants.orgMandatoryUpdateRequiredKey,
        ) ==
        true) {
      c.mandatoryMode.value = true;
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    InputDecoration deco({
      required String label,
      IconData? icon,
      String? hint,
      Widget? suffixIcon,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
        prefixIcon: icon == null
            ? null
            : Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 20),
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      );
    }

    Widget gridOrColumn({
      required List<Widget> children,
      int desktopColumns = 3,
      int tabletColumns = 2,
    }) {
      if (isMobile) {
        return Column(
          children:
              children.expand((w) => [w, const SizedBox(height: 16)]).toList()
                ..removeLast(),
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth >= 1100
              ? desktopColumns
              : (constraints.maxWidth >= 640 ? tabletColumns : 1);
          final itemWidth = constraints.maxWidth / crossAxisCount;
          const itemHeight = 78.0;
          final childAspectRatio = itemWidth / itemHeight;

          return GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
            children: children,
          );
        },
      );
    }

    Widget buildStepIndicator({bool allowStepSwitch = false}) {
      return Obx(() {
        final step = c.currentStep.value;
        Widget chip(int index, String label) {
          final active = step == index;
          final done = step > index;
          final content = Column(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: done
                    ? Colors.green
                    : (active ? AppTheme.primaryColor : Colors.grey[300]),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: active || done ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  color: active ? AppTheme.primaryColor : Colors.grey[600],
                ),
              ),
            ],
          );
          if (allowStepSwitch) {
            return Expanded(
              child: InkWell(
                onTap: c.isSaving.value
                    ? null
                    : () {
                        c.currentStep.value = index;
                      },
                borderRadius: BorderRadius.circular(8),
                child: content,
              ),
            );
          }
          return Expanded(child: content);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              chip(0, 'Organization'),
              Expanded(child: Container(height: 2, color: Colors.grey[300])),
              chip(1, 'Document'),
            ],
          ),
        );
      });
    }

    Widget buildDocumentStepPanel() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Proof Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => OrganizationProofDetailsLayout(
              panField: TextFormField(
                controller: c.panNumberController,
                textCapitalization: TextCapitalization.characters,
                validator: (v) => validatePanNumber(v),
                decoration: deco(
                  label: 'PAN Number',
                  icon: Icons.badge_outlined,
                  hint: 'ABCDE1234F',
                ),
              ),
              aadharField: TextFormField(
                controller: c.aadharNumberController,
                keyboardType: TextInputType.number,
                validator: (v) => validateAadharNumber(v),
                decoration: deco(
                  label: 'Aadhar Number',
                  icon: Icons.fingerprint_outlined,
                  hint: '12-digit number',
                ),
              ),
              panDocumentBytes: c.panImageBytes,
              panDocumentFileName: c.panDocumentFileName,
              aadharDocumentBytes: c.aadharDocumentBytes,
              aadharDocumentFileName: c.aadharDocumentFileName,
              busy: c.isLoading.value || c.isSaving.value,
              onPickPan: c.pickPanDocument,
              onPickAadhar: c.pickAadharDocument,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              organizationProofUploadNotes,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ),
          Obx(
            () => buildOrganizationProofUploadErrorBanner(c.errorMessage.value),
          ),
          const SizedBox(height: 24),
          Text(
            'Bank Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            organizationBankDetailsNote,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          gridOrColumn(
            desktopColumns: 2,
            tabletColumns: 2,
            children: [
              TextFormField(
                controller: c.bankAccountNumberController,
                keyboardType: TextInputType.number,
                validator: (v) =>
                    validateRequiredField(v, fieldName: 'Account number'),
                decoration: deco(
                  label: 'Account Number',
                  icon: Icons.account_balance_outlined,
                ),
              ),
              TextFormField(
                controller: c.bankIfscController,
                textCapitalization: TextCapitalization.characters,
                validator: validateIfsc,
                decoration: deco(
                  label: 'IFSC Number',
                  icon: Icons.numbers_outlined,
                ),
              ),
              TextFormField(
                controller: c.bankBranchController,
                validator: (v) =>
                    validateRequiredField(v, fieldName: 'Bank branch'),
                decoration: deco(
                  label: 'Bank Branch',
                  icon: Icons.location_city_outlined,
                ),
              ),
              TextFormField(
                controller: c.bankNameController,
                validator: (v) =>
                    validateRequiredField(v, fieldName: 'Bank name'),
                decoration: deco(
                  label: 'Bank Name',
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              TextFormField(
                controller: c.gstNumberController,
                textCapitalization: TextCapitalization.characters,
                validator: validateGstNumber,
                decoration: deco(
                  label: 'GST Number (optional)',
                  icon: Icons.receipt_long_outlined,
                  hint: '22AAAAA0000A1Z5',
                ),
              ),
            ],
          ),
        ],
      );
    }

    Widget buildLogoSection() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Organization logo (optional)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Obx(() {
            final hasLogo = c.logoBytes.value != null;
            final busy = c.isSaving.value || c.isLoading.value;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasLogo
                      ? AppTheme.primaryColor.withValues(alpha: 0.45)
                      : Colors.grey.shade300,
                  width: hasLogo ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    onTap: busy ? null : c.pickLogoFromGallery,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: hasLogo ? 120 : 96,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          style: hasLogo ? BorderStyle.solid : BorderStyle.none,
                        ),
                      ),
                      child: hasLogo
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.memory(
                                c.logoBytes.value!,
                                fit: BoxFit.contain,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 36,
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.85,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to upload logo',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'PNG or JPG recommended',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : c.pickLogoFromGallery,
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: Text(hasLogo ? 'Change logo' : 'Upload logo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        minimumSize: const Size(double.infinity, 40),
                      ),
                    ),
                  ),
                  if (hasLogo) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: busy ? null : c.clearLogo,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Remove'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          minimumSize: const Size(double.infinity, 40),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      );
    }

    Future<void> onContinue() async {
      if (c.isSaving.value) return;
      final ok = await c.continueToDocumentsStep();
      if (!context.mounted) return;
      if (!ok && c.errorMessage.value.isNotEmpty) {
        SnackbarHelper.show(
          title: 'Validation',
          message: c.errorMessage.value,
          backgroundColor: Colors.red,
        );
      }
    }

    Future<void> onLogout() async {
      if (c.isSaving.value) return;
      final authController = Get.find<AuthController>();
      await authController.signOut();
      if (!context.mounted) return;
      context.go(AppRoutes.login);
    }

    Future<void> onUpdate() async {
      if (c.isSaving.value) return;
      final wasMandatory = c.mandatoryMode.value;
      final ok = await c.save();
      if (!context.mounted) return;
      if (ok) {
        SnackbarHelper.show(
          title: 'Updated',
          message: wasMandatory
              ? 'Organization details saved. You can now use the app.'
              : 'Organization details updated successfully',
          backgroundColor: Colors.green,
        );
        if (wasMandatory && !c.mandatoryMode.value) {
          context.go(AppRoutes.home);
        }
      } else if (c.errorMessage.value.isNotEmpty) {
        SnackbarHelper.show(
          title: 'Update failed',
          message: c.errorMessage.value,
          backgroundColor: Colors.red,
        );
      }
    }

    Widget buildPageBody() {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.08),
              Colors.white,
              AppTheme.accentColor.withOpacity(0.06),
            ],
          ),
        ),
        child: Obx(() {
          if (c.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (c.loadError.value.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                    const SizedBox(height: 12),
                    Text(
                      c.loadError.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: c.loadCurrentBranch,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return PinnedVerticalScrollView(
            padding: EdgeInsets.all(isMobile ? 12 : 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Form(
                  key: c.formKey,
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 20 : 28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final useSideBySideLogo =
                            constraints.maxWidth >= 720;
                        final mandatory = c.mandatoryMode.value;

                        return Obx(() {
                          final step = c.currentStep.value;
                          final organizationDetailsFields = Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                step == 0
                                    ? 'Update Organization Details'
                                    : 'Update documents and bank details',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 20),
                              if (step == 0) ...[
                              TextFormField(
                                controller: c.organizationNameController,
                              textInputAction: TextInputAction.next,
                              validator: (v) => c.requiredValidator(
                                v,
                                fieldName: 'Organization name',
                              ),
                              decoration: deco(
                                label: 'Organization Name',
                                icon: Icons.business_outlined,
                              ),
                            ),
                            const SizedBox(height: 12),
                            gridOrColumn(
                              desktopColumns: 3,
                              tabletColumns: 3,
                              children: [
                                TextFormField(
                                  controller: c.commencingYearController,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  validator: c.commencingYearValidator,
                                  decoration: deco(
                                    label: 'Commencing Year',
                                    icon: Icons.calendar_month_outlined,
                                    hint: 'e.g. 2025',
                                  ),
                                ),
                                TextFormField(
                                  controller: c.emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  validator: c.emailValidator,
                                  decoration: deco(
                                    label: 'Email',
                                    icon: Icons.email_outlined,
                                  ),
                                ),
                                TextFormField(
                                  controller: c.phoneNoController,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) => c.phoneValidator(
                                    v,
                                    fieldName: 'phone number',
                                  ),
                                  decoration: deco(
                                    label: 'Phone No',
                                    icon: Icons.phone_outlined,
                                  ),
                                ),
                                TextFormField(
                                  controller: c.mobileNoController,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) => c.phoneValidator(
                                    v,
                                    fieldName: 'mobile number',
                                    required: false,
                                  ),
                                  decoration: deco(
                                    label: 'Mobile No (optional)',
                                    icon: Icons.smartphone_outlined,
                                  ),
                                ),
                                TextFormField(
                                  controller: c.websiteUrlController,
                                  keyboardType: TextInputType.url,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) =>
                                      c.websiteValidator(v, required: false),
                                  decoration: deco(
                                    label: 'Website URL (optional)',
                                    icon: Icons.public_outlined,
                                  ),
                                ),
                                TextFormField(
                                  controller: c.countryController,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) =>
                                      c.requiredValidator(v, fieldName: 'Country'),
                                  decoration: deco(
                                    label: 'Country',
                                    icon: Icons.flag_outlined,
                                  ),
                                ),
                                Obx(() {
                                  if (c.isLoadingStates.value) {
                                    return TextFormField(
                                      readOnly: true,
                                      decoration: deco(
                                        label: 'State',
                                        icon: Icons.map_outlined,
                                      ).copyWith(
                                        hintText: 'Loading states...',
                                        suffixIcon: const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return StateSearchField(
                                    textEditingController:
                                        c.stateSearchTextController,
                                    focusNode: c.stateSearchFocusNode,
                                    states: List.from(c.states),
                                    validator: c.stateValidator,
                                    decorationBuilder:
                                        ({Widget? suffixIcon}) => deco(
                                          label: 'State',
                                          icon: Icons.map_outlined,
                                        ).copyWith(suffixIcon: suffixIcon),
                                    isMobile: isMobile,
                                    hintText: 'Search or select state',
                                    onStateId: c.setSelectedState,
                                  );
                                }),
                                Obx(() {
                                  final stateId = c.selectedStateId.value;
                                  final districtListVersion =
                                      c.districts.length;
                                  if (c.isLoadingDistricts.value) {
                                    return TextFormField(
                                      readOnly: true,
                                      decoration: deco(
                                        label: 'District',
                                        icon: Icons.location_city_outlined,
                                      ).copyWith(
                                        hintText: 'Loading districts...',
                                        suffixIcon: const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  if (stateId <= 0) {
                                    return TextFormField(
                                      readOnly: true,
                                      validator: c.districtValidator,
                                      decoration: deco(
                                        label: 'District',
                                        icon: Icons.location_city_outlined,
                                      ).copyWith(
                                        hintText: 'Select state first',
                                      ),
                                    );
                                  }
                                  return DistrictSearchField(
                                    key: ValueKey(
                                      'org_update_district_${stateId}_$districtListVersion',
                                    ),
                                    textEditingController:
                                        c.districtSearchTextController,
                                    focusNode: c.districtSearchFocusNode,
                                    districts: List.from(c.districts),
                                    validator: c.districtValidator,
                                    decorationBuilder:
                                        ({Widget? suffixIcon}) => deco(
                                          label: 'District',
                                          icon: Icons.location_city_outlined,
                                        ).copyWith(suffixIcon: suffixIcon),
                                    isMobile: isMobile,
                                    hintText: 'Search or select district',
                                    onDistrictSelected: c.onDistrictSelected,
                                  );
                                }),
                                TextFormField(
                                  controller: c.pincodeController,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  validator: c.pincodeValidator,
                                  decoration: deco(
                                    label: 'Pincode',
                                    icon: Icons.pin_drop_outlined,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: c.addressController,
                              textInputAction: TextInputAction.done,
                              maxLines: 3,
                              validator: (v) =>
                                  c.requiredValidator(v, fieldName: 'Address'),
                              decoration: deco(
                                label: 'Address',
                                icon: Icons.home_outlined,
                              ),
                            ),
                              ] else
                                buildDocumentStepPanel(),
                            ],
                          );

                          final formBody = step == 0
                              ? (useSideBySideLogo
                                  ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: organizationDetailsFields,
                                        ),
                                        const SizedBox(width: 24),
                                        SizedBox(
                                          width: 280,
                                          child: buildLogoSection(),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        organizationDetailsFields,
                                        const SizedBox(height: 20),
                                        buildLogoSection(),
                                      ],
                                    ))
                              : organizationDetailsFields;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (mandatory) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  margin: const EdgeInsets.only(bottom: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orange.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.orange.shade800,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Please complete all mandatory organization details to continue using the application.',
                                          style: TextStyle(
                                            color: Colors.orange.shade900,
                                            fontSize: 13,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              buildStepIndicator(allowStepSwitch: mandatory),
                              const SizedBox(height: 8),
                              formBody,
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  if (mandatory)
                                    OutlinedButton.icon(
                                      onPressed: c.isSaving.value
                                          ? null
                                          : onLogout,
                                      icon: const Icon(Icons.logout, size: 18),
                                      label: const Text('Logout'),
                                    )
                                  else if (step > 0)
                                    TextButton(
                                      onPressed: c.isSaving.value
                                          ? null
                                          : c.goBackStep,
                                      child: const Text('Back'),
                                    )
                                  else
                                    OutlinedButton(
                                      onPressed: c.isSaving.value
                                          ? null
                                          : () => context.pop(),
                                      child: const Text('Cancel'),
                                    ),
                                  const Spacer(),
                                  if (mandatory && step > 0)
                                    TextButton(
                                      onPressed: c.isSaving.value
                                          ? null
                                          : c.goBackStep,
                                      child: const Text('Back'),
                                    ),
                                  if (mandatory && step > 0)
                                    const SizedBox(width: 8),
                                  Obx(() {
                                    final canContinue =
                                        c.canContinueToDocuments;
                                    final primaryLabel = step == 0
                                        ? 'Continue to Documents'
                                        : 'Update';
                                    return FilledButton.icon(
                                      onPressed: c.isSaving.value ||
                                              (step == 0 && !canContinue)
                                          ? null
                                          : (step == 0 ? onContinue : onUpdate),
                                      icon: c.isSaving.value
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Icon(
                                              step == 0
                                                  ? Icons.arrow_forward
                                                  : Icons.update,
                                            ),
                                      label: Text(
                                        c.isSaving.value
                                            ? (step == 0
                                                ? 'Saving...'
                                                : 'Updating...')
                                            : primaryLabel,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ],
                          );
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      );
    }

    return Obx(() {
      final mandatory = c.mandatoryMode.value;
      if (mandatory) {
        return PopScope(
          canPop: false,
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Text('Complete Organization Details'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            body: buildPageBody(),
          ),
        );
      }

      return AdminSidebarLayout(
        title: 'Organization',
        child: buildPageBody(),
      );
    });
  }
}
