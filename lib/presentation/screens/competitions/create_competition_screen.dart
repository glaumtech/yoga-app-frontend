import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../core/constants/championship_style.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/permission_store.dart';
import '../../../config/app_config.dart';
import '../../../core/utils/storage_service.dart';
import '../../../data/models/competition_model.dart';
import '../../controllers/competition_controller.dart';
import '../../widgets/admin_sidebar_layout.dart';
import '../../widgets/form_title.dart';
import '../../widgets/toggle_button_group.dart';
import '../../widgets/buttons.dart';
import '../../widgets/form_label_with_hint.dart';
import '../../widgets/competition_registration_qr_panel.dart';
import '../../widgets/subscription/subscription_plan_picker.dart';
import '../../../data/models/subscription_package_model.dart';
import 'competitions_list_screen.dart';

class CreateCompetitionScreen extends StatelessWidget {
  const CreateCompetitionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CompetitionController());

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

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
        child: Obx(() {
          final _ = controller.formKeyRevision.value;
          return Form(
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

                // Left: all form fields | Right: brochure + registration QR (desktop/tablet)
                if (isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMainFormFieldsColumn(
                        context,
                        controller,
                        isMobile,
                        isTablet,
                      ),
                      SizedBox(height: isMobile ? 20 : 24),
                      _buildBrochureAndQrSidebar(
                        context,
                        controller,
                        isMobile,
                        isTablet,
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildMainFormFieldsColumn(
                          context,
                          controller,
                          isMobile,
                          isTablet,
                        ),
                      ),
                      SizedBox(width: isTablet ? 16 : 24),
                      Expanded(
                        flex: 1,
                        child: _buildBrochureAndQrSidebar(
                          context,
                          controller,
                          isMobile,
                          isTablet,
                        ),
                      ),
                    ],
                  ),

                // Error Message
                Obx(() {
                  if (controller.errorMessage.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final showBuyNow = controller.shouldShowSubscriptionBuyNow;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                        if (showBuyNow) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: controller
                                      .isProcessingSubscriptionPayment.value
                                  ? null
                                  : () async {
                                      await controller
                                          .prepareSubscriptionTopUpFlow();
                                    },
                              icon: const Icon(Icons.shopping_cart_outlined),
                              label: const Text('Buy credits'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),

                if (controller.showSubscriptionTopUp.value &&
                    !controller.isEditMode.value &&
                    !controller.isViewMode.value)
                  _buildSubscriptionTopUpSection(
                    context,
                    controller,
                    isMobile,
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
                                      final ok = await controller
                                          .createCompetition();
                                      if (ok && context.mounted) {
                                        final permissionStore =
                                            Get.isRegistered<PermissionStore>()
                                            ? Get.find<PermissionStore>()
                                            : Get.put(PermissionStore());
                                        final saved = controller
                                            .lastSavedCompetitionForQr
                                            .value;
                                        if (permissionStore.has(
                                              'SHOW_COMP_QR_CODE_ON_ADMIN',
                                            ) &&
                                            saved != null) {
                                          await showCompetitionRegistrationQrDialog(
                                            context,
                                            saved,
                                          );
                                        }
                                        controller
                                            .clearLastSavedCompetitionForQr();
                                      }
                                    },
                                    isLoading: controller.isLoading,
                                    text: controller.createCompetitionButtonLabel,
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
                                      final ok = await controller
                                          .createCompetition();
                                      if (ok && context.mounted) {
                                        final permissionStore =
                                            Get.isRegistered<PermissionStore>()
                                            ? Get.find<PermissionStore>()
                                            : Get.put(PermissionStore());
                                        final saved = controller
                                            .lastSavedCompetitionForQr
                                            .value;
                                        if (permissionStore.has(
                                              'SHOW_COMP_QR_CODE_ON_ADMIN',
                                            ) &&
                                            saved != null) {
                                          await showCompetitionRegistrationQrDialog(
                                            context,
                                            saved,
                                          );
                                        }
                                        controller
                                            .clearLastSavedCompetitionForQr();
                                      }
                                    },
                                    isLoading: controller.isLoading,
                                    text: controller.createCompetitionButtonLabel,
                                    width: controller
                                            .requiresPrepaidCompetitionPayment
                                        ? 300
                                        : 200,
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
          );
        }),
      ),
    );
  }

  Widget _buildMainFormFieldsColumn(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
    bool isTablet,
  ) {
    final gap = SizedBox(height: isMobile ? 20 : 24);
    final gapSm = SizedBox(width: isTablet ? 12 : 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          context,
          controller,
          label: 'COMPETITION NAME :',
          textController: controller.competitionNameController,
          isRequired: true,
          isMobile: isMobile,
          isTablet: isTablet,
        ),
        gap,
        _buildTextField(
          context,
          controller,
          label: 'DESCRIPTION :',
          textController: controller.descriptionController,
          isRequired: true,
          maxLines: 2,
          isMobile: isMobile,
          isTablet: isTablet,
        ),
        gap,
        _buildTextField(
          context,
          controller,
          label: 'ADDRESS :',
          textController: controller.addressController,
          isRequired: true,
          maxLines: 2,
          isMobile: isMobile,
          isTablet: isTablet,
        ),
        gap,
        if (isMobile)
          Column(
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
              gap,
              _buildDateField(
                context,
                controller,
                label: 'EVENT END DATE :',
                isStartDate: false,
                isDisplayAd: false,
                isMobile: isMobile,
                isTablet: isTablet,
              ),
              gap,
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
        else
          Row(
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
              gapSm,
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
              gapSm,
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
        gap,
        if (isMobile)
          Column(
            children: [
              _buildTimeField(
                context,
                controller,
                label: 'EVENT START TIME :',
                isStartTime: true,
                isRequired: false,
                isMobile: isMobile,
                isTablet: isTablet,
              ),
              gap,
              _buildTimeField(
                context,
                controller,
                label: 'EVENT END TIME :',
                isStartTime: false,
                isRequired: true,
                isMobile: isMobile,
                isTablet: isTablet,
              ),
              gap,
              _buildPublishResultNowField(
                context,
                controller,
                isMobile: isMobile,
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTimeField(
                      context,
                      controller,
                      label: 'EVENT START TIME :',
                      isStartTime: true,
                      isRequired: false,
                      isMobile: isMobile,
                      isTablet: isTablet,
                    ),
                  ),
                  gapSm,
                  Expanded(
                    child: _buildTimeField(
                      context,
                      controller,
                      label: 'EVENT END TIME :',
                      isStartTime: false,
                      isRequired: true,
                      isMobile: isMobile,
                      isTablet: isTablet,
                    ),
                  ),
                ],
              ),
              gap,
              _buildPublishResultNowField(
                context,
                controller,
                isMobile: isMobile,
              ),
            ],
          ),
        gap,
        if (isMobile)
          Column(
            children: [
              _buildParticipantsPerStageField(
                context,
                controller,
                isMobile,
                isTablet,
              ),
              gap,
              _buildMarksField(context, controller, isMobile, isTablet),
            ],
          )
        else
          Row(
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
              gapSm,
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
        gap,
        _buildChampionshipStyleField(context, controller, isMobile, isTablet),
        gap,
        _buildBestSchoolAwardField(context, controller, isMobile, isTablet),
        gap,
        _buildPrizesField(context, controller, isMobile, isTablet),
        gap,
        _buildCategoriesField(context, controller, isMobile, isTablet),
        gap,
        _buildStagesField(context, controller, isMobile, isTablet),
        gap,
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
                    gap,
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSubscriptionTopUpSection(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
        color: Colors.orange.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.credit_card_outlined,
                    color: Colors.orange.shade900,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Get competition credits',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.orange.shade900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Obx(
                        () {
                          final isPerParticipant =
                              controller.selectedSubscriptionMode?.modeKey ==
                              'PAY_PER_PARTICIPANT';
                          return Text(
                            isPerParticipant
                                ? 'Select the On Demand plan, then pay to unlock saving this competition.'
                                : 'Pick your subscription type and plan, then pay to unlock saving this competition.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: Colors.orange.shade900
                                  .withValues(alpha: 0.85),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(
                  () {
                    final isPerParticipant =
                        controller.selectedSubscriptionMode?.modeKey ==
                        'PAY_PER_PARTICIPANT';
                    return SubscriptionPlanPicker(
                      modes: controller.subscriptionModes.toList(),
                      packages: controller.subscriptionBasePackages,
                      selectedModeId:
                          controller.selectedSubscriptionModeId.value,
                      selectedPackageId:
                          controller.selectedSubscriptionPackageId.value,
                      onModeSelected: controller.onSubscriptionModeSelected,
                      onPackageSelected:
                          controller.onSubscriptionPackageSelected,
                      isLoadingModes:
                          controller.isLoadingSubscriptionModes.value,
                      isLoadingPackages:
                          controller.isLoadingSubscriptionPackages.value,
                      modesError:
                          controller.subscriptionModesError.value.isEmpty
                          ? null
                          : controller.subscriptionModesError.value,
                      packagesError:
                          controller.subscriptionPackagesError.value.isEmpty
                          ? null
                          : controller.subscriptionPackagesError.value,
                      onRetryModes: controller.loadSubscriptionModes,
                      onRetryPackages: controller.loadSubscriptionPackages,
                      enabled:
                          !controller.isProcessingSubscriptionPayment.value,
                      excludeAddons: true,
                      modeSectionTitle: 'Step 1 — Subscription type',
                      packageSectionTitle: controller.subscriptionPlanStepTitle,
                      modeSelectorStyle:
                          SubscriptionModeSelectorStyle.dropdown,
                    );
                  },
                ),
                Obx(() {
                  final addons = controller.subscriptionAddonPackages;
                  if (addons.isEmpty) return const SizedBox.shrink();
                  final expanded = controller.showSubscriptionAddonOptions.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: controller.isProcessingSubscriptionPayment.value
                              ? null
                              : controller.toggleSubscriptionAddonOptions,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  size: 20,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Need only one extra competition?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                                Text(
                                  expanded ? 'Hide add-on' : 'View add-on',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  expanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (expanded) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Optional — buy a single extra credit without changing your main plan.',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 10),
                        _buildAddonPackageGrid(context, controller, addons),
                      ],
                    ],
                  );
                }),
              ],
            ),
          ),
          Obx(() {
            final selected = controller.selectedSubscriptionPackage;
            if (selected == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryColor,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selected.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selected.creditsSummary,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${selected.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: isMobile
                ? Column(
                    children: [
                      saveButton(
                        onPressed: () async {
                          await controller
                              .purchaseSubscriptionPackageAndRetryCreate();
                        },
                        text: 'Pay & save competition',
                        isLoading: controller.isProcessingSubscriptionPayment,
                        isFullWidth: true,
                      ),
                      const SizedBox(height: 8),
                      cancelButton(
                        onPressed: () {
                          controller.showSubscriptionTopUp.value = false;
                          controller.showSubscriptionAddonOptions.value = false;
                        },
                        text: 'Cancel',
                        isFullWidth: true,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: saveButton(
                          onPressed: () async {
                            await controller
                                .purchaseSubscriptionPackageAndRetryCreate();
                          },
                          text: 'Pay & save competition',
                          isLoading: controller.isProcessingSubscriptionPayment,
                          isFullWidth: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      cancelButton(
                        onPressed: () {
                          controller.showSubscriptionTopUp.value = false;
                          controller.showSubscriptionAddonOptions.value = false;
                        },
                        text: 'Cancel',
                        width: 140,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddonPackageGrid(
    BuildContext context,
    CompetitionController controller,
    List<SubscriptionPackageModel> addons,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth >= 480 && addons.length >= 2
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 76,
          ),
          itemCount: addons.length,
          itemBuilder: (context, index) {
            final pkg = addons[index];
            return Obx(() {
              final selected =
                  controller.selectedSubscriptionPackageId.value == pkg.id;
              final enabled =
                  !controller.isProcessingSubscriptionPayment.value;
              return InkWell(
                onTap: enabled
                    ? () => controller.onSubscriptionPackageSelected(pkg)
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppTheme.primaryColor
                          : Colors.grey[300]!,
                      width: selected ? 2 : 1,
                    ),
                    color: selected
                        ? AppTheme.primaryColor.withValues(alpha: 0.06)
                        : Colors.grey[50],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              pkg.tierWithPriceLine,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (selected)
                            Icon(
                              Icons.check_circle,
                              size: 18,
                              color: AppTheme.primaryColor,
                            ),
                        ],
                      ),
                      if (pkg.description != null &&
                          pkg.description!.trim().isNotEmpty)
                        Text(
                          pkg.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5),
                        ),
                    ],
                  ),
                ),
              );
            });
          },
        );
      },
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

  Widget _buildBrochureAndQrSidebar(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBrochureUpload(context, controller, isMobile, isTablet),
        Obx(() {
          final permissionStore = Get.isRegistered<PermissionStore>()
              ? Get.find<PermissionStore>()
              : Get.put(PermissionStore());
          final comp = controller.competitionToEdit.value;
          final showQr =
              permissionStore.has('SHOW_COMP_QR_CODE_ON_ADMIN') &&
              (controller.isEditMode.value || controller.isViewMode.value) &&
              comp?.id != null &&
              comp!.id!.isNotEmpty;
          if (!showQr) return const SizedBox.shrink();
          return Padding(
            padding: EdgeInsets.only(top: isMobile ? 20 : 24),
            child: CompetitionRegistrationQrPanel(
              competition: comp,
              compact: true,
            ),
          );
        }),
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
        const FormLabelWithHint(label: 'UPLOAD BROCHURE :'),
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
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    CompetitionController.brochureUploadNotes,
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 12,
                      color: Colors.grey[600],
                      height: 1.4,
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
      final showImageOverlay = hasBrochure && controller.isBrochureImage;

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
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Obx(
                          () => _buildBrochureContentPreview(controller),
                        ),
                      ),
                    ),
                    if (showImageOverlay)
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
      width: double.infinity,
      height: double.infinity,
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

  String _brochurePdfFileName(CompetitionController controller) {
    final name = controller.brochureFileName.value.trim();
    return name.isNotEmpty ? name : 'PDF brochure';
  }

  String _formatBrochureFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(bytes < 10 * 1024 ? 1 : 0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// WhatsApp-style document card (icon, name, size · PDF).
  Widget _buildWhatsAppStylePdfCard({
    required String fileName,
    int? fileSizeBytes,
    bool expanded = false,
  }) {
    final subtitleParts = <String>[
      if (fileSizeBytes != null) _formatBrochureFileSize(fileSizeBytes),
      'PDF',
    ];

    final card = Container(
      constraints: BoxConstraints(maxWidth: expanded ? 400 : 320),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 4, color: const Color(0xFFE53935)),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? 14 : 12,
              vertical: expanded ? 12 : 10,
            ),
            child: Row(
              children: [
                Container(
                  width: expanded ? 52 : 44,
                  height: expanded ? 58 : 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.picture_as_pdf,
                    color: const Color(0xFFE53935),
                    size: expanded ? 34 : 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: expanded ? 15 : 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitleParts.join(' • '),
                        style: TextStyle(
                          fontSize: expanded ? 13 : 12,
                          color: Colors.grey[600],
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
    );

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFE7E7E7),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: card,
    );
  }

  Widget _buildPdfBrochurePreview(
    CompetitionController controller, {
    Uint8List? bytes,
  }) {
    return _buildWhatsAppStylePdfCard(
      fileName: _brochurePdfFileName(controller),
      fileSizeBytes: bytes?.length,
      expanded: false,
    );
  }

  Widget _buildImageBrochurePreview({Uint8List? bytes}) {
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultBrochurePreview();
        },
      );
    }
    return _buildDefaultBrochurePreview();
  }

  /// PNG / JPG / JPEG → image preview; PDF → WhatsApp-style card.
  Widget _buildBrochureContentPreview(CompetitionController controller) {
    final brochureBytes = controller.brochureBytes.value;
    final brochureFileLocal = controller.brochureFileLocal.value;
    final isEditMode = controller.isEditMode.value;
    final isViewMode = controller.isViewMode.value;
    final competitionId = controller.competitionToEdit.value?.id;
    final updateTimestamp = controller.brochureUpdateTimestamp.value;

    if (brochureBytes != null && brochureBytes.isNotEmpty) {
      if (controller.isBrochurePdf) {
        return _buildPdfBrochurePreview(controller, bytes: brochureBytes);
      }
      return _buildImageBrochurePreview(bytes: brochureBytes);
    }

    if (brochureFileLocal != null && brochureFileLocal.existsSync()) {
      if (controller.isBrochurePdf) {
        return FutureBuilder<Uint8List>(
          future: brochureFileLocal.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data;
            if (data == null || data.isEmpty) {
              return _buildPdfBrochurePreview(controller);
            }
            if (CompetitionController.brochureBytesLookLikeImage(data)) {
              return _buildImageBrochurePreview(bytes: data);
            }
            return _buildPdfBrochurePreview(controller, bytes: data);
          },
        );
      }
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

    if ((isEditMode || isViewMode) && competitionId != null) {
      return _BrochureApiPreview(
        key: ValueKey(
          updateTimestamp > 0
              ? 'brochure_${competitionId}_$updateTimestamp'
              : 'brochure_$competitionId',
        ),
        competitionId: competitionId,
        cacheBust: updateTimestamp,
        filenameHintPdf: controller.isBrochurePdf,
        pdfPreview: (bytes) =>
            _buildPdfBrochurePreview(controller, bytes: bytes),
        imagePreview: (bytes) => _buildImageBrochurePreview(bytes: bytes),
        fallback: _buildDefaultBrochurePreview,
      );
    }

    return _buildDefaultBrochurePreview();
  }

  Widget _buildBrochureDialogPreview(CompetitionController controller) {
    return _BrochureDialogContent(
      loadBytes: () => _loadBrochureBytesForPreview(controller),
      filenameHintPdf: controller.isBrochurePdf,
    );
  }

  /// Loads brochure bytes for preview. Saved competition files come from API;
  /// local pick only when the user chose a new file in this session.
  static Future<Uint8List?> _loadBrochureBytesForPreview(
    CompetitionController controller,
  ) async {
    if (controller.hasLocalBrochure) {
      final cached = controller.brochureBytes.value;
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      final localFile = controller.brochureFileLocal.value;
      if (localFile != null && localFile.existsSync()) {
        return localFile.readAsBytes();
      }
    }

    final competitionId = controller.competitionToEdit.value?.id;
    if (competitionId != null) {
      return _fetchBrochureBytesFromApi(
        competitionId,
        cacheBust: controller.brochureUpdateTimestamp.value,
      );
    }

    final cached = controller.brochureBytes.value;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    return null;
  }

  static Future<Uint8List?> _fetchBrochureBytesFromApi(
    String competitionId, {
    int cacheBust = 0,
  }) async {
    final base = AppConfig.baseUrl.replaceAll(RegExp(r'/$'), '');
    final path = cacheBust > 0
        ? '${EndPoints.competitionBrochure(competitionId)}?t=$cacheBust'
        : EndPoints.competitionBrochure(competitionId);
    final url = '$base$path';

    final headers = <String, String>{};
    final token = StorageService.getString(AppConstants.tokenKey);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http
        .get(Uri.parse(url), headers: headers)
        .timeout(BaseUrl.apiTimeout);

    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      return null;
    }

    final bytes = response.bodyBytes;
    if (CompetitionController.brochureBytesLookLikeJson(bytes)) {
      return null;
    }
    return bytes;
  }

  void _showBrochurePreviewDialog(
    BuildContext context,
    CompetitionController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final dialogHeight = MediaQuery.of(context).size.height * 0.88;
        final dialogWidth = MediaQuery.of(context).size.width * 0.9;
        return Dialog(
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: Column(
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
                // Preview content (PDF: full-height scrollable viewer)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Obx(() => _buildBrochureDialogPreview(controller)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _dateFieldKey({required bool isStartDate, required bool isDisplayAd}) {
    if (isDisplayAd) return CompetitionController.dateFieldDisplayAd;
    if (isStartDate) return CompetitionController.dateFieldStart;
    return CompetitionController.dateFieldEnd;
  }

  String? Function(DateTime?) _dateFieldValidator(
    CompetitionController controller, {
    required bool isStartDate,
    required bool isDisplayAd,
  }) {
    if (isDisplayAd) return controller.validateDisplayAdFrom;
    if (isStartDate) return controller.validateEventStartDate;
    return controller.validateEventEndDate;
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
    final validateDate = _dateFieldValidator(
      controller,
      isStartDate: isStartDate,
      isDisplayAd: isDisplayAd,
    );
    final dateFieldKey = _dateFieldKey(
      isStartDate: isStartDate,
      isDisplayAd: isDisplayAd,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(label: label, bottomSpacing: 0),
        Obx(() {
          final _ = controller.competitionDatesRevision.value;
          final showErrors = controller.shouldShowCompetitionDateError(
            dateFieldKey,
          );
          return FormField<DateTime>(
            initialValue: isStartDate
                ? controller.eventStartDate.value
                : isDisplayAd
                ? controller.displayAdFrom.value
                : controller.eventEndDate.value,
            validator: isRequired ? validateDate : null,
            builder: (FormFieldState<DateTime> field) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!field.mounted) return;
                final syncedDate = isStartDate
                    ? controller.eventStartDate.value
                    : isDisplayAd
                    ? controller.displayAdFrom.value
                    : controller.eventEndDate.value;
                if (field.value != syncedDate) {
                  field.didChange(syncedDate);
                }
                if (showErrors || syncedDate != null) {
                  field.validate();
                }
              });

              return Obx(() {
                final displayedDate = isStartDate
                    ? controller.eventStartDate.value
                    : isDisplayAd
                    ? controller.displayAdFrom.value
                    : controller.eventEndDate.value;

                return InkWell(
                  onTap: controller.isViewMode.value
                      ? null
                      : () async {
                          final didPick = await _selectDate(
                            context,
                            controller,
                            isStartDate: isStartDate,
                            isDisplayAd: isDisplayAd,
                          );
                          if (didPick) {
                            controller.markCompetitionDateFieldTouched(
                              dateFieldKey,
                            );
                          }
                          final updatedDate = isStartDate
                              ? controller.eventStartDate.value
                              : isDisplayAd
                              ? controller.displayAdFrom.value
                              : controller.eventEndDate.value;
                          field.didChange(updatedDate);
                          field.validate();
                          controller.notifyCompetitionDatesChanged();
                          if (updatedDate != null) {
                            controller.alertCompetitionDateValidationIssue();
                          }
                        },
                  child: InputDecorator(
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
                      errorText: showErrors ? field.errorText : null,
                    ),
                    child: Text(
                      displayedDate != null
                          ? DateFormat('yyyy-MM-dd').format(displayedDate)
                          : '',
                      style: TextStyle(
                        color: displayedDate != null
                            ? Colors.black
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                );
              });
            },
          );
        }),
      ],
    );
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Future<bool> _selectDate(
    BuildContext context,
    CompetitionController controller, {
    bool isStartDate = false,
    bool isDisplayAd = false,
  }) async {
    final today = _dateOnly(DateTime.now());
    final start = controller.eventStartDate.value != null
        ? _dateOnly(controller.eventStartDate.value!)
        : null;
    final end = controller.eventEndDate.value != null
        ? _dateOnly(controller.eventEndDate.value!)
        : null;
    final displayAd = controller.displayAdFrom.value != null
        ? _dateOnly(controller.displayAdFrom.value!)
        : null;

    final maxFuture = today.add(const Duration(days: 365 * 2));

    late DateTime initialDate;
    late DateTime firstDate;
    late DateTime lastDate;

    if (isStartDate) {
      initialDate = start ?? today;
      firstDate = today;
      if (controller.isEditMode.value &&
          start != null &&
          start.isBefore(today)) {
        firstDate = start;
      }
      lastDate = maxFuture;
    } else if (isDisplayAd) {
      initialDate = displayAd ?? start ?? today;
      firstDate = today;
      lastDate = start ?? maxFuture;
      if (displayAd != null && start != null && displayAd.isAfter(start)) {
        lastDate = displayAd;
      }
    } else {
      initialDate = end ?? start ?? today;
      firstDate = start ?? today;
      lastDate = maxFuture;
      if (end != null && start != null && end.isBefore(start)) {
        firstDate = end;
      }
    }

    if (firstDate.isAfter(lastDate)) {
      firstDate = lastDate;
    }
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    }
    if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked == null) return false;

    final normalized = _dateOnly(picked);
    if (isStartDate) {
      controller.eventStartDate.value = normalized;
      final currentEnd = controller.eventEndDate.value;
      if (currentEnd != null && _dateOnly(currentEnd).isBefore(normalized)) {
        controller.eventEndDate.value = null;
      }
    } else if (isDisplayAd) {
      controller.displayAdFrom.value = normalized;
    } else {
      controller.eventEndDate.value = normalized;
    }
    controller.notifyCompetitionDatesChanged();
    return true;
  }

  String _timeFieldKey({required bool isStartTime}) {
    return isStartTime
        ? CompetitionController.dateFieldStartTime
        : CompetitionController.dateFieldEndTime;
  }

  String? Function(TimeOfDay?) _timeFieldValidator(
    CompetitionController controller, {
    required bool isStartTime,
  }) {
    return isStartTime
        ? controller.validateEventStartTime
        : controller.validateEventEndTime;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final formatted = CompetitionModel.formatTimeOfDay(time);
    return formatted ?? '';
  }

  Widget _buildTimeField(
    BuildContext context,
    CompetitionController controller, {
    required String label,
    required bool isStartTime,
    required bool isRequired,
    bool isMobile = false,
    bool isTablet = false,
  }) {
    final validateTime = _timeFieldValidator(
      controller,
      isStartTime: isStartTime,
    );
    final timeFieldKey = _timeFieldKey(isStartTime: isStartTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(
          label: label,
          hintText: isRequired ? null : 'Optional',
          reserveHintSpace: true,
          bottomSpacing: 0,
        ),
        Obx(() {
          final _ = controller.competitionDatesRevision.value;
          final showErrors = controller.shouldShowCompetitionDateError(
            timeFieldKey,
          );
          return FormField<TimeOfDay?>(
            initialValue: isStartTime
                ? controller.eventStartTime.value
                : controller.eventEndTime.value,
            validator: validateTime,
            builder: (FormFieldState<TimeOfDay?> field) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!field.mounted) return;
                final syncedTime = isStartTime
                    ? controller.eventStartTime.value
                    : controller.eventEndTime.value;
                if (field.value != syncedTime) {
                  field.didChange(syncedTime);
                }
                if (showErrors || syncedTime != null) {
                  field.validate();
                }
              });

              return Obx(() {
                final displayedTime = isStartTime
                    ? controller.eventStartTime.value
                    : controller.eventEndTime.value;

                return InkWell(
                  onTap: controller.isViewMode.value
                      ? null
                      : () async {
                          final didPick = await _selectTime(
                            context,
                            controller,
                            isStartTime: isStartTime,
                          );
                          if (didPick) {
                            controller.markCompetitionDateFieldTouched(
                              timeFieldKey,
                            );
                          }
                          final updatedTime = isStartTime
                              ? controller.eventStartTime.value
                              : controller.eventEndTime.value;
                          field.didChange(updatedTime);
                          field.validate();
                          controller.notifyCompetitionDatesChanged();
                          if (updatedTime != null) {
                            controller.alertCompetitionDateValidationIssue();
                          }
                        },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      hintText: isRequired ? 'Select time' : 'Optional',
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
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isStartTime && displayedTime != null)
                                  IconButton(
                                    tooltip: 'Clear start time',
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      controller.eventStartTime.value = null;
                                      field.didChange(null);
                                      field.validate();
                                      controller
                                          .markCompetitionDateFieldTouched(
                                            timeFieldKey,
                                          );
                                      controller
                                          .notifyCompetitionDatesChanged();
                                    },
                                  ),
                                const Icon(Icons.access_time),
                              ],
                            ),
                      errorText: showErrors ? field.errorText : null,
                    ),
                    child: Text(
                      displayedTime != null
                          ? _formatTimeOfDay(displayedTime)
                          : '',
                      style: TextStyle(
                        color: displayedTime != null
                            ? Colors.black
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                );
              });
            },
          );
        }),
      ],
    );
  }

  Future<bool> _selectTime(
    BuildContext context,
    CompetitionController controller, {
    required bool isStartTime,
  }) async {
    final current = isStartTime
        ? controller.eventStartTime.value
        : controller.eventEndTime.value;
    final picked = await showTimePicker(
      context: context,
      initialTime:
          current ??
          (isStartTime
              ? const TimeOfDay(hour: 9, minute: 0)
              : const TimeOfDay(hour: 18, minute: 0)),
    );
    if (picked == null) return false;

    if (isStartTime) {
      controller.eventStartTime.value = picked;
    } else {
      controller.eventEndTime.value = picked;
    }
    controller.notifyCompetitionDatesChanged();
    return true;
  }

  Widget _buildPublishResultNowField(
    BuildContext context,
    CompetitionController controller, {
    bool isMobile = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FormLabelWithHint(
          label: 'PUBLISH THE RESULT NOW :',
          hintText: 'Optional',
          reserveHintSpace: true,
          bottomSpacing: 0,
        ),
        Obx(
          () {
            final enabled = !controller.isViewMode.value;
            return InkWell(
              onTap: enabled
                  ? () {
                      controller.publishResultNow.value =
                          !controller.publishResultNow.value;
                    }
                  : null,
              child: InputDecorator(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: controller.isViewMode.value
                      ? Colors.grey[200]
                      : Colors.grey[50],
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: isMobile ? 4 : 8,
                  ),
                  isDense: isMobile,
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: controller.publishResultNow.value,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      onChanged: enabled
                          ? (value) {
                              controller.publishResultNow.value =
                                  value ?? false;
                            }
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        'Publish results immediately',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: enabled ? Colors.black : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
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
                  isExpanded: true,
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
                  isExpanded: true,
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
            isExpanded: true,
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
            hint: const Text(
              'Select participants per stage',
              overflow: TextOverflow.ellipsis,
            ),
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

  Widget _buildBestSchoolAwardField(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(
          label: 'BEST SCHOOL AWARD :',
          hintText:
              'Optional. Schools with at least this many registered participants appear in Reports as Best School Award winners.',
          hintSpacing: isMobile ? 6 : 4,
          bottomSpacing: isMobile ? 10 : 8,
        ),
        _optionSectionCard(
          child: Obx(() {
            final readOnly = controller.isViewMode.value;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Best School Award above:',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: isMobile ? 72 : 84,
                  child: TextFormField(
                    controller:
                        controller.bestSchoolAwardMinParticipantsController,
                    readOnly: readOnly,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: 'e.g. 15',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: readOnly ? Colors.grey[200] : Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: isMobile ? 12 : 14,
                      ),
                      isDense: isMobile,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'participants',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildChampionshipStyleField(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(
          label: 'CHAMPIONS / CHAMPIONSHIP STYLE :',
          hintText:
              'Choose whether Champions is a separate registration category or filled from 1st-place winners (boys & girls) in other categories.',
          hintSpacing: isMobile ? 6 : 4,
          bottomSpacing: isMobile ? 10 : 8,
        ),
        _optionSectionCard(
          child: Obx(() {
            final selected = controller.championshipStyle.value;
            final readOnly = controller.isViewMode.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...ChampionshipStyle.values.map((style) {
                  return RadioListTile<ChampionshipStyle>(
                    value: style,
                    groupValue: selected,
                    onChanged: readOnly
                        ? null
                        : (value) {
                            if (value != null) {
                              controller.setChampionshipStyle(value);
                            }
                          },
                    activeColor: AppTheme.primaryColor,
                    title: Text(
                      style.label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      style.description,
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        color: Colors.grey[700],
                        height: isMobile ? 1.35 : 1.3,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: isMobile ? 4 : 0,
                    ),
                    dense: !isMobile,
                  );
                }),
                if (controller.hasAttemptedSubmit.value &&
                    selected == null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Please select a championship style',
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ],
                if (selected == ChampionshipStyle.fromFirstPlaceWinners) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      'Champions category is not selectable for this competition. '
                      'It will be populated from 1st-place winners in Common/Special categories (boys and girls).',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ],
            );
          }),
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
                      spacing: isMobile ? 12 : 20,
                      runSpacing: isMobile ? 12 : 16,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      children: [
                        ...controller.categoryOptionNames.map((category) {
                          final isSelected = controller.selectedCategories
                              .contains(category);
                          final isChampions = controller
                              .isChampionsCategoryName(category);
                          final championsDisabled =
                              isChampions &&
                              !controller.canSelectChampionsCategory;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: isSelected,
                                    onChanged:
                                        controller.isViewMode.value ||
                                            championsDisabled
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
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  Text(
                                    category,
                                    style: championsDisabled
                                        ? TextStyle(color: Colors.grey[500])
                                        : null,
                                  ),
                                ],
                              ),
                              if (isSelected) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: isMobile ? 160 : 180,
                                  child: _CategoryAmountField(
                                    key: ValueKey('category_amount_$category'),
                                    category: category,
                                    controller: controller,
                                    isMobile: isMobile,
                                    isTablet: isTablet,
                                  ),
                                ),
                              ],
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
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Stage Name *',
                    hintText: 'e.g., G, H',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Stage name is required';
                    }
                    if (value.trim().length > 100) {
                      return 'Stage name must be 100 characters or less';
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
                  maxLength: 100,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Group name is required';
                    }
                    if (value.trim().length > 100) {
                      return 'Group name must be 100 characters or less';
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
    return Obx(
      () => TextFormField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        readOnly: widget.controller.isViewMode.value,
        style: TextStyle(
          fontSize: widget.isMobile ? 14 : 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
          ),
          filled: true,
          fillColor: widget.controller.isViewMode.value
              ? Colors.grey[200]
              : Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: widget.isMobile ? 14 : 16,
          ),
          isDense: false,
          prefixText: '₹ ',
          prefixStyle: TextStyle(
            fontSize: widget.isMobile ? 14 : 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        onChanged: widget.controller.isViewMode.value
            ? null
            : (value) {
                final amount = double.tryParse(value) ?? 0.0;
                widget.controller.updateCategoryAmount(widget.category, amount);
              },
      ),
    );
  }
}

/// Loads brochure bytes from the API with auth (works on web; [Image.network] headers often fail).
class _BrochureApiPreview extends StatefulWidget {
  const _BrochureApiPreview({
    super.key,
    required this.competitionId,
    required this.cacheBust,
    required this.filenameHintPdf,
    required this.pdfPreview,
    required this.imagePreview,
    required this.fallback,
  });

  final String competitionId;
  final int cacheBust;
  final bool filenameHintPdf;
  final Widget Function(Uint8List bytes) pdfPreview;
  final Widget Function(Uint8List bytes) imagePreview;
  final Widget Function() fallback;

  @override
  State<_BrochureApiPreview> createState() => _BrochureApiPreviewState();
}

class _BrochureApiPreviewState extends State<_BrochureApiPreview> {
  Uint8List? _bytes;
  bool _isPdf = false;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _BrochureApiPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.competitionId != widget.competitionId ||
        oldWidget.cacheBust != widget.cacheBust ||
        oldWidget.filenameHintPdf != widget.filenameHintPdf) {
      _load();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _failed = false;
      _bytes = null;
    });

    try {
      final base = AppConfig.baseUrl.replaceAll(RegExp(r'/$'), '');
      final path = widget.cacheBust > 0
          ? '${EndPoints.competitionBrochure(widget.competitionId)}?t=${widget.cacheBust}'
          : EndPoints.competitionBrochure(widget.competitionId);
      final url = '$base$path';

      final headers = <String, String>{};
      final token = StorageService.getString(AppConstants.tokenKey);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(BaseUrl.apiTimeout);

      if (!mounted) return;

      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        setState(() {
          _loading = false;
          _failed = true;
        });
        return;
      }

      final body = response.bodyBytes;
      final contentType = response.headers['content-type'];
      final kind = CompetitionController.brochureKindFromBytes(
        body,
        contentType: contentType,
        filenameHintPdf: widget.filenameHintPdf,
      );

      setState(() {
        _bytes = body;
        _isPdf = kind == BrochureFileKind.pdf;
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_failed || _bytes == null) {
      return widget.fallback();
    }
    if (_isPdf) {
      return widget.pdfPreview(_bytes!);
    }
    return widget.imagePreview(_bytes!);
  }
}

/// Brochure preview dialog: PDF (scrollable) or image based on file content.
class _BrochureDialogContent extends StatefulWidget {
  const _BrochureDialogContent({
    required this.loadBytes,
    required this.filenameHintPdf,
  });

  final Future<Uint8List?> Function() loadBytes;
  final bool filenameHintPdf;

  @override
  State<_BrochureDialogContent> createState() => _BrochureDialogContentState();
}

class _BrochureDialogContentState extends State<_BrochureDialogContent> {
  PdfController? _pdfController;
  Uint8List? _imageBytes;
  bool _loading = true;
  bool _failed = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _pdfController?.dispose();
    _pdfController = null;
    _imageBytes = null;

    setState(() {
      _loading = true;
      _failed = false;
      _errorMessage = null;
    });

    try {
      final bytes = await widget.loadBytes();
      if (!mounted) return;

      if (bytes == null || bytes.isEmpty) {
        setState(() {
          _loading = false;
          _failed = true;
          _errorMessage =
              'Brochure could not be loaded. Check that a file is uploaded and the server is running.';
        });
        return;
      }

      final kind = CompetitionController.brochureKindFromBytes(
        bytes,
        filenameHintPdf: widget.filenameHintPdf,
      );

      if (kind == BrochureFileKind.pdf) {
        final pdfController = PdfController(
          document: PdfDocument.openData(bytes),
        );
        if (!mounted) {
          pdfController.dispose();
          return;
        }
        setState(() {
          _pdfController = pdfController;
          _loading = false;
        });
        return;
      }

      if (kind == BrochureFileKind.image ||
          !CompetitionController.brochureBytesLookLikePdf(bytes)) {
        setState(() {
          _imageBytes = bytes;
          _loading = false;
        });
        return;
      }

      setState(() {
        _loading = false;
        _failed = true;
        _errorMessage = 'Unsupported brochure format.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
        _errorMessage = 'Failed to load brochure: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_failed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: Colors.grey[500],
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Unable to load brochure',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_pdfController != null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: PdfView(
            controller: _pdfController!,
            scrollDirection: Axis.vertical,
            backgroundDecoration: const BoxDecoration(color: Colors.white),
            onDocumentError: (error) {
              if (!mounted) return;
              setState(() {
                _failed = true;
                _errorMessage = error.toString();
                _pdfController?.dispose();
                _pdfController = null;
              });
            },
          ),
        ),
      );
    }

    if (_imageBytes != null) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4,
        child: Center(
          child: Image.memory(
            _imageBytes!,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              size: 64,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
