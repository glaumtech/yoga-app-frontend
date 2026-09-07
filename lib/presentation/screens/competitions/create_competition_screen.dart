import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/permission_store.dart';
import '../../../config/app_config.dart';
import '../../../core/utils/storage_service.dart';
import '../../../data/models/competition_model.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/first_competition_gate_service.dart';
import '../../../routes/app_routes.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/competition_controller.dart';
import '../../models/competition_grade_entry.dart';
import '../../widgets/admin_sidebar_layout.dart';
import '../../widgets/toggle_button_group.dart';
import '../../widgets/buttons.dart';
import '../../widgets/form_label_with_hint.dart';
import '../../widgets/competition_registration_qr_panel.dart';
import '../../widgets/pinned_scroll_views.dart';
import '../../widgets/subscription/subscription_plan_picker.dart';
import '../../../data/models/subscription_package_model.dart';
import 'competitions_list_screen.dart';
import 'widgets/add_category_dialog.dart';
import 'widgets/category_asanas_config_wizard.dart';
import 'widgets/tie_breaker_dialog.dart';
import 'widgets/apply_upgrade_dialog.dart';
import '../../../data/models/category_config_model.dart';

class CreateCompetitionScreen extends StatefulWidget {
  const CreateCompetitionScreen({super.key});

  @override
  State<CreateCompetitionScreen> createState() =>
      _CreateCompetitionScreenState();
}

class _CreateCompetitionScreenState extends State<CreateCompetitionScreen> {
  @override
  void initState() {
    super.initState();
    // CompetitionController is kept alive across routes, so onInit/loadOptions
    // may not run again. Refresh prizes/categories/stages whenever this screen opens.
    final controller = Get.put(CompetitionController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.loadOptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<CompetitionController>()
        ? Get.find<CompetitionController>()
        : Get.put(CompetitionController());
    final firstCompetitionGate =
        Get.isRegistered<FirstCompetitionGateService>()
        ? Get.find<FirstCompetitionGateService>()
        : Get.put(FirstCompetitionGateService(), permanent: true);

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    bool isMandatoryMode() {
      firstCompetitionGate.requiresFirstCompetition.value;
      return StorageService.getBool(AppConstants.firstCompetitionRequiredKey) ==
              true ||
          firstCompetitionGate.isGateActive();
    }

    Future<void> onLogout() async {
      final authController = Get.find<AuthController>();
      await authController.signOut();
      if (!context.mounted) return;
      context.go(AppRoutes.login);
    }

    Widget buildMandatoryBanner() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        margin: EdgeInsets.only(
          top: isMobile ? 8 : 10,
          bottom: 12,
          left: isMobile ? 16 : 24,
          right: isMobile ? 16 : 24,
        ),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.orange.shade800,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Please create your first competition and complete payment to continue using the application.',
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildPageContent({required bool mandatory}) {
      return Container(
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
              if (mandatory) buildMandatoryBanner(),
              if (!mandatory)
                Padding(
                  padding: EdgeInsets.only(
                    top: isMobile ? 10 : 14,
                    bottom: 4,
                    left: isMobile ? 16 : 24,
                    right: isMobile ? 16 : 24,
                  ),
                  child: Obx(
                    () => ToggleButtonGroup(
                      options: [
                        ToggleButtonOption(
                          label: controller.isViewMode.value
                              ? 'View'
                              : controller.isEditMode.value
                              ? 'Edit'
                              : 'Create',
                          icon: controller.isViewMode.value
                              ? Icons.visibility_outlined
                              : controller.isEditMode.value
                              ? Icons.edit_outlined
                              : Icons.add_rounded,
                        ),
                        const ToggleButtonOption(
                          label: 'List',
                          icon: Icons.list_alt_rounded,
                        ),
                      ],
                      selectedIndex: controller.isListView.value ? 1 : 0,
                      onTap: (index) => controller.toggleViewMode(index == 1),
                    ),
                  ),
                ),
              Expanded(
                child: Obx(
                  () => controller.isListView.value && !mandatory
                      ? const CompetitionsListScreen()
                      : PinnedVerticalScrollView(
                          padding: EdgeInsets.fromLTRB(
                            isMobile ? 12 : 20,
                            isMobile ? 8 : 12,
                            isMobile ? 12 : 20,
                            isMobile ? 16 : 24,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: double.infinity,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildForm(
                                    context,
                                    controller,
                                    isMobile,
                                    isTablet,
                                  ),
                                  if (mandatory) ...[
                                    const SizedBox(height: 16),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: OutlinedButton.icon(
                                        onPressed: onLogout,
                                        icon: const Icon(Icons.logout, size: 18),
                                        label: const Text('Logout'),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Obx(() {
      final mandatory = isMandatoryMode();
      if (mandatory) {
        if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
          controller.enterFirstCompetitionOnboardingMode();
        } else {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            controller.enterFirstCompetitionOnboardingMode();
          });
        }
        return PopScope(
          canPop: false,
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Text('Create Your First Competition'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            body: buildPageContent(mandatory: true),
          ),
        );
      }

      return AdminSidebarLayout(
        title: 'COMPETITIONS',
        child: buildPageContent(mandatory: false),
      );
    });
  }

  Widget _buildForm(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
    bool isTablet,
  ) {
    final horizontalPad = isMobile ? 0.0 : 4.0;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalPad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 14 : (isTablet ? 20 : 28),
          isMobile ? 16 : 22,
          isMobile ? 14 : (isTablet ? 20 : 28),
          isMobile ? 16 : 22,
        ),
        child: Obx(() {
          final _ = controller.formKeyRevision.value;
          return Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCompetitionFormHeader(controller, isMobile, isTablet),

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
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: Color(0xFFDC2626)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                controller.errorMessage.value,
                                style: const TextStyle(
                                  color: Color(0xFFB91C1C),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (showBuyNow) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: controller
                                      .isProcessingSubscriptionPayment.value
                                  ? null
                                  : () async {
                                      await controller
                                          .prepareSubscriptionTopUpFlow();
                                    },
                              icon: const Icon(Icons.shopping_cart_outlined),
                              label: const Text('Buy credits'),
                              style: FilledButton.styleFrom(
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

                Obx(() {
                  if (controller.isViewMode.value ||
                      !controller.isOnDemandOrg.value) {
                    return const SizedBox.shrink();
                  }
                  controller.categoryConfigDrafts.length;
                  controller.categoryConfigDrafts.toList();
                  controller.selectedCategoryIds.length;
                  controller.maintenancePaidAsanas.value;
                  controller.maintenancePaidChallenge.value;
                  controller.onDemandAsanasFeePaise.value;
                  controller.onDemandChallengeFeePaise.value;
                  controller.onDemandExtraFeeForCompetition.value;
                  controller.onDemandPaymentGatewayFeePercent.value;
                  controller.onDemandPlatformFeePercent.value;
                  final breakdown = controller.competitionMaintenanceBreakdown();
                  if (breakdown.totalAmount <= 0) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(
                      top: isMobile ? 8 : 12,
                      bottom: isMobile ? 4 : 8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.payments_outlined,
                            size: 18, color: AppTheme.primaryColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₹${breakdown.baseAmount.toStringAsFixed(2)}'
                                ' + ₹${breakdown.feeAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Total payable: ₹${breakdown.totalAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color.lerp(
                                          AppTheme.primaryColor,
                                          Colors.black,
                                          0.25) ??
                                      AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                SizedBox(height: isMobile ? 20 : 28),
                const Divider(height: 1, color: AppColors.divider),
                SizedBox(height: isMobile ? 16 : 20),
                _buildFormActions(context, controller, isMobile),
                SizedBox(height: isMobile ? 8 : 12),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCompetitionFormHeader(
    CompetitionController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Obx(() {
      final isView = controller.isViewMode.value;
      final isEdit = controller.isEditMode.value;
      final title = isView
          ? 'View competition'
          : isEdit
              ? 'Edit competition'
              : 'Create competition';
      final icon = isView
          ? Icons.visibility_outlined
          : isEdit
              ? Icons.edit_outlined
              : Icons.emoji_events_outlined;
      final chipLabel = isView ? 'View' : isEdit ? 'Edit' : 'Create';

      return Padding(
        padding: EdgeInsets.only(bottom: isMobile ? 20 : 28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: isMobile ? 44 : 52,
              height: isMobile ? 44 : 52,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: isMobile ? 22 : 26),
            ),
            SizedBox(width: isMobile ? 12 : 16),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: isMobile ? 20 : (isTablet ? 22 : 24),
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppColors.textPrimary,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      chipLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color.lerp(
                              AppTheme.primaryColor,
                              Colors.black,
                              0.28,
                            ) ??
                            AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFormActions(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
  ) {
    return Obx(() {
      if (controller.isViewMode.value) {
        final btn = cancelButton(
          onPressed: () {
            controller.clearForm();
            controller.toggleViewMode(true);
          },
          isFullWidth: isMobile,
          width: isMobile ? null : 200,
        );
        return isMobile
            ? btn
            : Row(mainAxisAlignment: MainAxisAlignment.end, children: [btn]);
      }

      controller.isOnDemandOrg.value;
      controller.isEditMode.value;
      controller.maintenancePaidAsanas.value;
      controller.maintenancePaidChallenge.value;
      controller.categoryConfigDrafts.length;

      final primary = controller.isEditMode.value
          ? saveButton(
              onPressed: () async {
                await controller.updateCompetition();
              },
              isLoading: controller.isLoading,
              text: controller.createCompetitionButtonLabel,
              isFullWidth: isMobile,
              width: isMobile
                  ? null
                  : (controller.requiresPrepaidCompetitionPayment ? 300 : 200),
            )
          : saveButton(
              onPressed: () async {
                final ok = await controller.createCompetition();
                if (ok && context.mounted) {
                  final permissionStore = Get.isRegistered<PermissionStore>()
                      ? Get.find<PermissionStore>()
                      : Get.put(PermissionStore());
                  final saved = controller.lastSavedCompetitionForQr.value;
                  if (permissionStore.has('SHOW_COMP_QR_CODE_ON_ADMIN') &&
                      saved != null) {
                    await showCompetitionRegistrationQrDialog(context, saved);
                  }
                  controller.clearLastSavedCompetitionForQr();
                }
              },
              isLoading: controller.isLoading,
              text: controller.createCompetitionButtonLabel,
              isFullWidth: isMobile,
              width: isMobile
                  ? null
                  : (controller.requiresPrepaidCompetitionPayment ? 300 : 200),
            );

      final cancel = cancelButton(
        onPressed: () {
          controller.clearForm();
          controller.toggleViewMode(true);
        },
        isFullWidth: isMobile,
        width: isMobile ? null : 200,
      );

      if (isMobile) {
        return Column(
          children: [
            primary,
            const SizedBox(height: 12),
            cancel,
          ],
        );
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          cancel,
          const SizedBox(width: 12),
          primary,
        ],
      );
    });
  }

  Widget _buildMainFormFieldsColumn(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
    bool isTablet,
  ) {
    final gap = SizedBox(height: isMobile ? 14 : 18);
    final gapSm = SizedBox(width: isTablet ? 12 : 16);
    final fieldGap = SizedBox(height: isMobile ? 14 : 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _formSectionHeader(
                icon: Icons.info_outline_rounded,
                title: 'Basic details',
                isMobile: isMobile,
              ),
              fieldGap,
              _buildTextField(
                context,
                controller,
                label: 'Competition name',
                textController: controller.competitionNameController,
                fieldKey: controller.competitionNameFieldKey,
                focusNode: controller.competitionNameFocusNode,
                isRequired: true,
                isMobile: isMobile,
                isTablet: isTablet,
              ),
              fieldGap,
              _buildTextField(
                context,
                controller,
                label: 'Description',
                textController: controller.descriptionController,
                fieldKey: controller.descriptionFieldKey,
                focusNode: controller.descriptionFocusNode,
                isRequired: true,
                maxLines: 3,
                isMobile: isMobile,
                isTablet: isTablet,
                minTrimmedLength: CompetitionController.descriptionMinLength,
                minLengthMessage: CompetitionController.descriptionMinLengthMessage,
                lengthWarningTouched: controller.descriptionTouched,
                lengthWarningText: controller.descriptionText,
                onLengthWarningChanged: (value) {
                  controller.markDescriptionTouched();
                  controller.descriptionText.value = value;
                },
              ),
              fieldGap,
              _buildTextField(
                context,
                controller,
                label: 'Address / venue details',
                textController: controller.addressController,
                fieldKey: controller.addressFieldKey,
                focusNode: controller.addressFocusNode,
                isRequired: true,
                maxLines: 2,
                isMobile: isMobile,
                isTablet: isTablet,
                minTrimmedLength: CompetitionController.addressMinLength,
                minLengthMessage: CompetitionController.addressMinLengthMessage,
                lengthWarningTouched: controller.addressTouched,
                lengthWarningText: controller.addressText,
                onLengthWarningChanged: (value) {
                  controller.markAddressTouched();
                  controller.addressText.value = value;
                },
              ),
            ],
          ),
        ),
        gap,
        _buildSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _formSectionHeader(
                icon: Icons.calendar_month_rounded,
                title: 'Schedule & publishing',
                isMobile: isMobile,
              ),
              fieldGap,
              if (isMobile)
                Column(
                  children: [
                    _buildDateField(
                      context,
                      controller,
                      label: 'Event start date',
                      isStartDate: true,
                      isDisplayAd: false,
                      isMobile: isMobile,
                      isTablet: isTablet,
                    ),
                    fieldGap,
                    _buildDateField(
                      context,
                      controller,
                      label: 'Event end date',
                      isStartDate: false,
                      isDisplayAd: false,
                      isMobile: isMobile,
                      isTablet: isTablet,
                    ),
                    fieldGap,
                    _buildDateField(
                      context,
                      controller,
                      label: 'Display ad from',
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
                        label: 'Event start date',
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
                        label: 'Event end date',
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
                        label: 'Display ad from',
                        isStartDate: false,
                        isDisplayAd: true,
                        isRequired: true,
                        isMobile: isMobile,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                ),
              fieldGap,
              if (isMobile)
                Column(
                  children: [
                    _buildTimeField(
                      context,
                      controller,
                      label: 'Event start time',
                      isStartTime: true,
                      isRequired: false,
                      isMobile: isMobile,
                      isTablet: isTablet,
                    ),
                    fieldGap,
                    _buildTimeField(
                      context,
                      controller,
                      label: 'Event end time',
                      isStartTime: false,
                      isRequired: true,
                      isMobile: isMobile,
                      isTablet: isTablet,
                    ),
                    fieldGap,
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
                            label: 'Event start time',
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
                            label: 'Event end time',
                            isStartTime: false,
                            isRequired: true,
                            isMobile: isMobile,
                            isTablet: isTablet,
                          ),
                        ),
                      ],
                    ),
                    fieldGap,
                    _buildPublishResultNowField(
                      context,
                      controller,
                      isMobile: isMobile,
                    ),
                  ],
                ),
            ],
          ),
        ),
        gap,
        _buildSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _formSectionHeader(
                icon: Icons.school_outlined,
                title: 'Best school award',
                isMobile: isMobile,
              ),
              fieldGap,
              _buildBestSchoolAwardField(
                context,
                controller,
                isMobile,
                isTablet,
                showOuterLabel: false,
              ),
            ],
          ),
        ),
        SizedBox(height: isMobile ? 10 : 12),
        _buildCertificateTemplateLinkCard(context, isMobile: isMobile),
        gap,
        _buildSectionCard(
          key: controller.categoriesSectionKey,
          child: _buildCategoryCardsSection(
            context,
            controller,
            isMobile,
            isTablet,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _formSectionHeader({
    required IconData icon,
    required String title,
    required bool isMobile,
  }) {
    final primary = AppTheme.primaryColor;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 14.5 : 15.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.15,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCertificateTemplateLinkCard(
    BuildContext context, {
    required bool isMobile,
  }) {
    final permissionStore = Get.isRegistered<PermissionStore>()
        ? Get.find<PermissionStore>()
        : Get.put(PermissionStore());
    if (!permissionStore.has('MENU_SETTINGS')) {
      return const SizedBox.shrink();
    }

    final primary = AppTheme.primaryColor;
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(
            AppRoutes.settingsPath(tab: AppRoutes.settingsCertificateTab),
          ),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium_outlined,
                  size: isMobile ? 15 : 16,
                  color: primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Certificate template',
                  style: TextStyle(
                    fontSize: isMobile ? 12.5 : 13,
                    fontWeight: FontWeight.w700,
                    color: primary,
                    decoration: TextDecoration.underline,
                    decorationColor: primary.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 13,
                  color: primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({Key? key, required Widget child}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: child,
    );
  }

  Widget _buildCategoryCardsSection(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
    bool isTablet,
  ) {
    final readOnly = controller.isViewMode.value;
    final primary = AppTheme.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.layers_rounded, size: 20, color: primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (!readOnly)
              FilledButton.icon(
                onPressed: () => _onAddCategory(context, controller),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Category'),
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          final drafts = controller.categoryConfigDrafts.toList();
          if (drafts.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary.withValues(alpha: 0.06),
                    AppColors.surfaceAlt,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primary.withValues(alpha: 0.18)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primary.withValues(alpha: 0.2)),
                    ),
                    child: Icon(
                      Icons.category_outlined,
                      size: 28,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'No categories yet',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add Common, Champions, Special Groups, or a Challenge\nwith Online or Offline mode.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (!readOnly) ...[
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: () => _onAddCategory(context, controller),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add your first category'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(color: primary.withValues(alpha: 0.45)),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          final hasActions = drafts.any(
            (c) =>
                c.configured &&
                (c.tieBreakerEnabled || _isUpgradeEnabled(c)),
          );

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: drafts.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : 2,
              // Tall enough for wrapped fee chips, 2-line summary, and
              // Tie Breaker / Apply Upgrade actions without Column overflow.
              mainAxisExtent: hasActions ? 248 : 204,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemBuilder: (context, index) {
              final cat = drafts[index];
              return _buildCategoryCard(context, controller, cat, readOnly);
            },
          );
        }),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    CompetitionController controller,
    CompetitionCategoryConfigModel cat,
    bool readOnly,
  ) {
    final primary = AppTheme.primaryColor;
    final accent = cat.isChallenge
        ? const Color(0xFF0284C7)
        : (cat.configured ? primary : const Color(0xFFD97706));

    Color formatBg;
    Color formatFg;
    if (cat.isChallenge) {
      formatBg = const Color(0xFFE0F2FE);
      formatFg = const Color(0xFF0369A1);
    } else if (cat.configured) {
      formatBg = primary.withValues(alpha: 0.12);
      formatFg = Color.lerp(primary, Colors.black, 0.35) ?? primary;
    } else {
      formatBg = const Color(0xFFFFF7ED);
      formatFg = const Color(0xFFC2410C);
    }

    final modeBg = cat.isOnlineMode
        ? const Color(0xFFEFF6FF)
        : const Color(0xFFF3F4F6);
    final modeFg = cat.isOnlineMode
        ? const Color(0xFF1D4ED8)
        : const Color(0xFF4B5563);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onCategoryCardTap(context, controller, cat),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                cat.categoryName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  letterSpacing: 0.2,
                                  color: AppColors.textPrimary,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!readOnly)
                              IconButton(
                                onPressed: () =>
                                    controller.removeCategoryDraft(cat.draftId),
                                icon: const Icon(Icons.delete_outline_rounded),
                                iconSize: 18,
                                color: const Color(0xFFEF4444),
                                tooltip: 'Remove category',
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _categoryMetaChip(
                              icon: cat.isChallenge
                                  ? Icons.bolt_rounded
                                  : Icons.self_improvement_rounded,
                              label: cat.statusLabel,
                              background: formatBg,
                              foreground: formatFg,
                            ),
                            _categoryMetaChip(
                              icon: cat.isOnlineMode
                                  ? Icons.cloud_outlined
                                  : Icons.storefront_outlined,
                              label: cat.modeLabel,
                              background: modeBg,
                              foreground: modeFg,
                            ),
                            _categoryMetaChip(
                              icon: Icons.payments_outlined,
                              label: cat.feeSummaryLabel,
                              background: AppColors.surfaceAlt,
                              foreground: AppColors.textSecondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          cat.contentSummary,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (cat.configured &&
                            (cat.tieBreakerEnabled ||
                                _isUpgradeEnabled(cat))) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (cat.tieBreakerEnabled)
                                _categoryActionChip(
                                  label: 'Tie Breaker',
                                  icon: Icons.balance_rounded,
                                  onTap: () => _openTieBreaker(
                                    context,
                                    controller,
                                    cat,
                                  ),
                                ),
                              if (cat.tieBreakerEnabled &&
                                  _isUpgradeEnabled(cat))
                                _categoryActionChip(
                                  label: 'Apply Upgrade',
                                  icon: Icons.arrow_upward_rounded,
                                  onTap: () => _applyCategoryUpgrade(
                                    context,
                                    controller,
                                    cat,
                                  ),
                                ),
                            ],
                          ),
                        ],
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  cat.isChallenge
                                      ? 'Open challenge settings'
                                      : 'Configure rules & asanas',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: primary,
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _categoryMetaChip({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onAddCategory(
    BuildContext context,
    CompetitionController controller,
  ) async {
    final existingCategories = controller.categoryConfigDrafts
        .where((c) => c.categoryName.trim().isNotEmpty)
        .map(
          (c) => ExistingCategoryEntry(
            name: c.categoryName,
            mode: c.mode,
          ),
        )
        .toList();
    final result = await AddCategoryDialog.show(
      context,
      existingCategories: existingCategories,
    );
    if (result == null || !context.mounted) return;
    final format = (result['format'] ?? 'ASANAS').toUpperCase();
    final mode = (result['mode'] ?? 'OFFLINE').toUpperCase() == 'ONLINE'
        ? 'ONLINE'
        : 'OFFLINE';
    final name = (result['name'] ?? '').trim().toUpperCase();
    if (name.isEmpty) return;

    final draft = await controller.createCategoryDraftPersisted(
      name: name,
      format: format,
      mode: mode,
    );
    if (draft == null || !context.mounted) return;

    await _openAsanasWizard(context, controller, draft);
  }

  Future<void> _onCategoryCardTap(
    BuildContext context,
    CompetitionController controller,
    CompetitionCategoryConfigModel cat,
  ) async {
    await _openAsanasWizard(context, controller, cat);
  }

  Future<void> _openTieBreaker(
    BuildContext context,
    CompetitionController controller,
    CompetitionCategoryConfigModel cat,
  ) async {
    final competitionId =
        int.tryParse(controller.competitionToEdit.value?.id ?? '');
    final categoryId = cat.categoryId;
    if (competitionId == null || categoryId == null) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Tie Breaker'),
          content: const Text(
            'Save the competition and category first, then run Tie Breaker after scoring.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    await TieBreakerDialog.show(
      context,
      competitionId: competitionId,
      categoryId: categoryId,
      categoryName: cat.categoryName,
    );
  }

  bool _isUpgradeEnabled(CompetitionCategoryConfigModel cat) {
    final hasTop = cat.upgradeTop != null && cat.upgradeTop! > 0;
    final hasTarget = cat.upgradeToCategoryId != null ||
        (cat.upgradeToCategoryName?.trim().isNotEmpty ?? false);
    return hasTop && hasTarget;
  }

  Widget _categoryActionChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final primary = AppTheme.primaryColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: primary.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: primary),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color.lerp(primary, Colors.black, 0.25) ?? primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyCategoryUpgrade(
    BuildContext context,
    CompetitionController controller,
    CompetitionCategoryConfigModel cat,
  ) async {
    final competitionId =
        int.tryParse(controller.competitionToEdit.value?.id ?? '');
    final categoryId = cat.categoryId;
    if (competitionId == null || categoryId == null) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Apply Upgrade'),
          content: const Text(
            'Save the competition and category first, then apply upgrade after scoring / tie breaker.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    await ApplyUpgradeDialog.show(
      context,
      competitionId: competitionId,
      categoryId: categoryId,
      categoryName: cat.categoryName,
    );
  }

  Future<void> _openAsanasWizard(
    BuildContext context,
    CompetitionController controller,
    CompetitionCategoryConfigModel cat,
  ) async {
    final others = controller.categoryConfigDrafts
        .where((c) => c.draftId != cat.draftId)
        .map((c) => c.categoryName)
        .toList();
    final saved = await CategoryAsanasConfigWizard.show(
      context,
      config: cat,
      otherCategoryNames: others,
      readOnly: controller.isViewMode.value,
      competitionController: controller,
    );
    if (saved != null) {
      controller.upsertCategoryDraft(saved);
    }
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
    Key? fieldKey,
    FocusNode? focusNode,
    bool isRequired = false,
    int maxLines = 1,
    bool isMobile = false,
    bool isTablet = false,
    TextAlign textAlign = TextAlign.left,
    int? minTrimmedLength,
    String? minLengthMessage,
    RxBool? lengthWarningTouched,
    RxString? lengthWarningText,
    ValueChanged<String>? onLengthWarningChanged,
  }) {
    return Column(
      key: fieldKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(
          label: label,
          labelStyle: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: isMobile ? 13 : 13.5,
            height: 1.2,
            color: AppColors.textSecondary,
          ),
          bottomSpacing: 8,
        ),
        Obx(
          () => TextFormField(
            controller: textController,
            focusNode: focusNode,
            maxLines: maxLines,
            textAlign: textAlign,
            readOnly: competitionController.isViewMode.value,
            onChanged: onLengthWarningChanged,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
              ),
              filled: true,
              fillColor: competitionController.isViewMode.value
                  ? Colors.grey[200]
                  : Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: isMobile ? 12 : 14,
              ),
              isDense: isMobile,
              errorStyle: minTrimmedLength != null
                  ? const TextStyle(height: 0, fontSize: 0)
                  : null,
            ),
            validator: isRequired && !competitionController.isViewMode.value
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return minLengthMessage ?? 'This field is required';
                    }
                    if (minTrimmedLength != null &&
                        value.trim().length < minTrimmedLength) {
                      return minLengthMessage;
                    }
                    return null;
                  }
                : null,
          ),
        ),
        if (minTrimmedLength != null &&
            minLengthMessage != null &&
            lengthWarningTouched != null &&
            lengthWarningText != null)
          Obx(() {
            final showWarning =
                !competitionController.isViewMode.value &&
                (lengthWarningTouched.value ||
                    competitionController.hasAttemptedSubmit.value) &&
                lengthWarningText.value.trim().length < minTrimmedLength;
            if (!showWarning) return const SizedBox.shrink();
            return _buildInlineFieldWarning(minLengthMessage);
          }),
      ],
    );
  }

  Widget _buildInlineFieldWarning(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
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
        _buildSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _formSectionHeader(
                icon: Icons.picture_as_pdf_outlined,
                title: 'Brochure',
                isMobile: isMobile,
              ),
              SizedBox(height: isMobile ? 14 : 16),
              _buildBrochureUpload(
                context,
                controller,
                isMobile,
                isTablet,
                showOuterLabel: false,
              ),
              SizedBox(height: isMobile ? 16 : 18),
              _buildGoogleDriveFolderField(
                controller,
                isMobile,
              ),
            ],
          ),
        ),
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
            padding: EdgeInsets.only(top: isMobile ? 14 : 18),
            child: _buildSectionCard(
              child: CompetitionRegistrationQrPanel(
                competition: comp,
                compact: true,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGoogleDriveFolderField(
    CompetitionController controller,
    bool isMobile,
  ) {
    return Obx(() {
      final email = controller.googleDriveServiceAccountEmail.value.trim();
      final serverReason = controller.googleDriveServerReason.value.trim();
      final String hint;
      if (!controller.googleDriveServerConfigured.value &&
          serverReason.isNotEmpty) {
        hint = serverReason;
      } else if (email.isEmpty) {
        hint =
            'Share this folder with the app Google service account as Editor, then paste the folder link.';
      } else {
        hint =
            'Share this folder with $email as Editor, then paste the folder link.';
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormLabelWithHint(
            label: 'Google Drive folder URL',
            hintText: hint,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: isMobile ? 13 : 13.5,
              height: 1.2,
              color: AppColors.textSecondary,
            ),
            hintStyle: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: AppColors.textMuted,
              height: 1.35,
            ),
            bottomSpacing: 8,
          ),
          TextFormField(
            controller: controller.googleDriveFolderUrlController,
            readOnly: controller.isViewMode.value,
            decoration: InputDecoration(
              hintText: 'https://drive.google.com/drive/folders/...',
              hintStyle: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted.withValues(alpha: 0.8),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
              ),
              filled: true,
              fillColor: controller.isViewMode.value
                  ? Colors.grey[200]
                  : Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: isMobile ? 12 : 14,
              ),
              isDense: isMobile,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildBrochureUpload(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
    bool isTablet, {
    bool showOuterLabel = true,
  }) {
    return Column(
      key: controller.brochureSectionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showOuterLabel) const FormLabelWithHint(label: 'Upload brochure'),
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
                      : const SizedBox(height: 10),
                ),
                Obx(
                  () => controller.isViewMode.value
                      ? const SizedBox.shrink()
                      : SizedBox(
                          width: double.infinity,
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
                            icon: const Icon(Icons.upload_file_rounded, size: 18),
                            label: const Text('Choose file'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: BorderSide(
                                color:
                                    AppTheme.primaryColor.withValues(alpha: 0.55),
                              ),
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 16,
                                vertical: isMobile ? 12 : 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    CompetitionController.brochureUploadNotes,
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 12,
                      color: AppColors.textMuted,
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
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            field.errorText!,
                            style: const TextStyle(
                              color: Color(0xFFB91C1C),
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
    final sectionKey = isDisplayAd
        ? controller.displayAdFromFieldKey
        : isStartDate
        ? controller.eventStartDateFieldKey
        : controller.eventEndDateFieldKey;

    return Column(
      key: sectionKey,
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

  String _timeFieldKey({
    required bool isStartTime,
    bool isResultsPublishTime = false,
  }) {
    if (isResultsPublishTime) {
      return CompetitionController.dateFieldResultsPublishTime;
    }
    return isStartTime
        ? CompetitionController.dateFieldStartTime
        : CompetitionController.dateFieldEndTime;
  }

  String? Function(TimeOfDay?) _timeFieldValidator(
    CompetitionController controller, {
    required bool isStartTime,
    bool isResultsPublishTime = false,
  }) {
    if (isResultsPublishTime) {
      return controller.validateResultsPublishTime;
    }
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
    bool isResultsPublishTime = false,
  }) {
    final validateTime = _timeFieldValidator(
      controller,
      isStartTime: isStartTime,
      isResultsPublishTime: isResultsPublishTime,
    );
    final timeFieldKey = _timeFieldKey(
      isStartTime: isStartTime,
      isResultsPublishTime: isResultsPublishTime,
    );

    TimeOfDay? readTime() {
      if (isResultsPublishTime) {
        return controller.resultsPublishTime.value;
      }
      return isStartTime
          ? controller.eventStartTime.value
          : controller.eventEndTime.value;
    }

    return Column(
      key: isResultsPublishTime
          ? controller.resultsPublishTimeFieldKey
          : (isStartTime ? null : controller.eventEndTimeFieldKey),
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
            initialValue: readTime(),
            validator: validateTime,
            builder: (FormFieldState<TimeOfDay?> field) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!field.mounted) return;
                final syncedTime = readTime();
                if (field.value != syncedTime) {
                  field.didChange(syncedTime);
                }
                if (showErrors || syncedTime != null) {
                  field.validate();
                }
              });

              return Obx(() {
                final displayedTime = readTime();
                final fieldEnabled = !controller.isViewMode.value &&
                    (!isResultsPublishTime || !controller.publishResultNow.value);

                return InkWell(
                  onTap: fieldEnabled
                      ? () async {
                          final didPick = await _selectTime(
                            context,
                            controller,
                            isStartTime: isStartTime,
                            isResultsPublishTime: isResultsPublishTime,
                          );
                          if (didPick) {
                            controller.markCompetitionDateFieldTouched(
                              timeFieldKey,
                            );
                          }
                          final updatedTime = readTime();
                          field.didChange(updatedTime);
                          field.validate();
                          controller.notifyCompetitionDatesChanged();
                          if (updatedTime != null) {
                            controller.alertCompetitionDateValidationIssue();
                          }
                        }
                      : null,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      hintText: isRequired ? 'Select time' : 'Optional',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: !fieldEnabled
                          ? Colors.grey[200]
                          : (controller.isViewMode.value
                              ? Colors.grey[200]
                              : Colors.grey[50]),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: isMobile ? 12 : 16,
                      ),
                      isDense: isMobile,
                      suffixIcon: fieldEnabled
                          ? Row(
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
                                if (isResultsPublishTime &&
                                    displayedTime != null &&
                                    !isRequired)
                                  IconButton(
                                    tooltip: 'Clear results publish time',
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      controller.resultsPublishTime.value =
                                          null;
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
                            )
                          : const Icon(Icons.access_time),
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
    bool isResultsPublishTime = false,
  }) async {
    final current = isResultsPublishTime
        ? controller.resultsPublishTime.value
        : (isStartTime
            ? controller.eventStartTime.value
            : controller.eventEndTime.value);
    final picked = await showTimePicker(
      context: context,
      initialTime:
          current ??
          (isStartTime
              ? const TimeOfDay(hour: 9, minute: 0)
              : const TimeOfDay(hour: 18, minute: 0)),
    );
    if (picked == null) return false;

    if (isResultsPublishTime) {
      controller.resultsPublishTime.value = picked;
    } else if (isStartTime) {
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
        if (isMobile) ...[
          const FormLabelWithHint(
            label: 'PUBLISH THE RESULT NOW :',
            hintText: 'Optional',
            reserveHintSpace: true,
            bottomSpacing: 0,
          ),
          _buildPublishResultNowCheckbox(context, controller, isMobile: isMobile),
          const SizedBox(height: 12),
          _buildResultsPublishTimeField(
            context,
            controller,
            isMobile: isMobile,
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FormLabelWithHint(
                      label: 'PUBLISH THE RESULT NOW :',
                      hintText: 'Optional',
                      reserveHintSpace: true,
                      bottomSpacing: 0,
                    ),
                    _buildPublishResultNowCheckbox(
                      context,
                      controller,
                      isMobile: isMobile,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResultsPublishTimeField(
                  context,
                  controller,
                  isMobile: isMobile,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPublishResultNowCheckbox(
    BuildContext context,
    CompetitionController controller, {
    bool isMobile = false,
  }) {
    return Obx(
      () {
        final enabled = !controller.isViewMode.value;
        return InkWell(
          onTap: enabled
              ? () {
                  controller.publishResultNow.value =
                      !controller.publishResultNow.value;
                  controller.notifyCompetitionDatesChanged();
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
                          controller.publishResultNow.value = value ?? false;
                          controller.notifyCompetitionDatesChanged();
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
    );
  }

  Widget _buildResultsPublishTimeField(
    BuildContext context,
    CompetitionController controller, {
    bool isMobile = false,
  }) {
    return Obx(() {
      final isRequired = !controller.publishResultNow.value;
      return _buildTimeField(
        context,
        controller,
        label: 'RESULTS PUBLISH TIME :',
        isStartTime: false,
        isRequired: isRequired,
        isMobile: isMobile,
        isResultsPublishTime: true,
      );
    });
  }

  Widget _buildMarksField(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
    bool isTablet,
  ) {
    InputDecoration markDecoration() {
      return InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: controller.isViewMode.value
            ? Colors.grey[200]
            : Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: isMobile ? 10 : 14,
        ),
        isDense: true,
        hint: Text(
          'Select',
          style: TextStyle(fontSize: isMobile ? 12 : 13),
        ),
      );
    }

    List<DropdownMenuItem<int>> markItems() {
      return CompetitionController.marksOptions
          .map(
            (value) => DropdownMenuItem(
              value: value,
              child: Text(
                value.toString(),
                style: TextStyle(fontSize: isMobile ? 12 : 13),
              ),
            ),
          )
          .toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: FormLabelWithHint(label: 'MARKS : Minimum'),
            ),
            SizedBox(width: isMobile ? 6 : 8),
            Expanded(
              child: FormLabelWithHint(label: 'Maximum'),
            ),
            SizedBox(width: isMobile ? 6 : 8),
            Expanded(
              child: FormLabelWithHint(label: 'Skipped Asana'),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Obx(
                () => DropdownButtonFormField<int>(
                  isExpanded: true,
                  value: controller.minimumMarks.value > 0
                      ? controller.minimumMarks.value
                      : null,
                  decoration: markDecoration(),
                  items: markItems(),
                  onChanged: controller.isViewMode.value
                      ? null
                      : (value) =>
                            controller.minimumMarks.value = value ?? 0,
                ),
              ),
            ),
            SizedBox(width: isMobile ? 6 : 8),
            Expanded(
              child: Obx(
                () => DropdownButtonFormField<int>(
                  isExpanded: true,
                  value: controller.maximumMarks.value > 0
                      ? controller.maximumMarks.value
                      : null,
                  decoration: markDecoration(),
                  items: markItems(),
                  onChanged: controller.isViewMode.value
                      ? null
                      : (value) =>
                            controller.maximumMarks.value = value ?? 0,
                ),
              ),
            ),
            SizedBox(width: isMobile ? 6 : 8),
            Expanded(
              child: Obx(
                () => DropdownButtonFormField<int>(
                  isExpanded: true,
                  value: controller.skippedAsanaMarks.value,
                  decoration: markDecoration(),
                  items: markItems(),
                  onChanged: controller.isViewMode.value
                      ? null
                      : (value) =>
                            controller.skippedAsanaMarks.value = value ?? 0,
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
      key: controller.participantsPerStageFieldKey,
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
      key: controller.prizesSectionKey,
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
                    Wrap(
                      spacing: isMobile ? 8 : 16,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ...controller.prizeOptionNames.map((prize) {
                          final isSelected =
                              controller.selectedPrizes.contains(prize);
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
                                          controller.selectedPrizes.toList(),
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
                        if (!controller.isViewMode.value)
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
          ),
        ),
      ],
    );
  }

  Widget _buildBestSchoolAwardField(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
    bool isTablet, {
    bool showOuterLabel = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showOuterLabel)
          FormLabelWithHint(
            label: 'Best school award',
            hintText:
                'Optional. Schools with at least this many registered participants appear in Reports as Best School Award winners.',
            hintSpacing: isMobile ? 6 : 4,
            bottomSpacing: isMobile ? 10 : 8,
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Obx(() {
            final readOnly = controller.isViewMode.value;
            final labelStyle = TextStyle(
              fontSize: isMobile ? 13.5 : 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            );

            final inputField = SizedBox(
              width: isMobile ? 72 : 84,
              child: TextFormField(
                controller: controller.bestSchoolAwardMinParticipantsController,
                readOnly: readOnly,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'e.g. 15',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: readOnly ? Colors.grey[200] : AppColors.inputFill,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: isMobile ? 12 : 14,
                  ),
                  isDense: isMobile,
                ),
              ),
            );

            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Show award for schools with at least',
                    style: labelStyle,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      inputField,
                      const SizedBox(width: 8),
                      Text('participants', style: labelStyle),
                    ],
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Show award for schools with at least',
                  style: labelStyle,
                ),
                const SizedBox(width: 10),
                inputField,
                const SizedBox(width: 8),
                Text('participants', style: labelStyle),
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
      key: controller.categoriesSectionKey,
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add New Prize'),
        content: Form(
          key: formKey,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          Obx(
            () => controller.isAddingOption.value
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final success = await controller.addCustomPrize(
                        nameController.text.trim(),
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                      );
                      if (success && dialogContext.mounted) {
                        Navigator.pop(dialogContext);
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add New Category'),
        content: Form(
          key: formKey,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          Obx(
            () => controller.isAddingOption.value
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final success = await controller.addCustomCategory(
                        nameController.text.trim(),
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                      );
                      if (success && dialogContext.mounted) {
                        Navigator.pop(dialogContext);
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
      key: controller.stagesSectionKey,
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

  Widget _buildGradesField(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
  ) {
    return Column(
      key: controller.gradesSectionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(
          label: 'GRADES :',
          hintText:
              'Optional. Add grade names with mark ranges (e.g. A+ for 90–100).',
          hintSpacing: isMobile ? 6 : 4,
          bottomSpacing: isMobile ? 10 : 8,
        ),
        _optionSectionCard(
          child: Obx(() {
            final readOnly = controller.isViewMode.value;
            final entries = controller.gradeEntries
                .where((e) => e.nameController.text.trim().isNotEmpty)
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entries.isEmpty)
                  Text(
                    readOnly ? 'No grades configured' : 'No grades added yet',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 15,
                      color: Colors.grey[600],
                    ),
                  )
                else
                  Wrap(
                    spacing: isMobile ? 8 : 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final entry in entries)
                        Tooltip(
                          message: _gradeRangeTooltip(entry),
                          waitDuration: const Duration(milliseconds: 250),
                          child: Chip(
                            label: Text(
                              entry.nameController.text.trim(),
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            backgroundColor:
                                AppTheme.primaryColor.withOpacity(0.10),
                            side: BorderSide(
                              color: AppTheme.primaryColor.withOpacity(0.35),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 4 : 6,
                              vertical: 0,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                if (!readOnly) ...[
                  SizedBox(height: entries.isEmpty ? 10 : 12),
                  OutlinedButton.icon(
                    onPressed: () =>
                        _showGradesDialog(context, controller, isMobile),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      entries.isEmpty ? 'Add grade' : 'Edit grades',
                    ),
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
              ],
            );
          }),
        ),
      ],
    );
  }

  String _gradeRangeTooltip(CompetitionGradeEntry entry) {
    final min = entry.minMarkController.text.trim();
    final max = entry.maxMarkController.text.trim();
    if (min.isEmpty && max.isEmpty) return 'No mark range set';
    if (min.isEmpty) return 'Max: $max';
    if (max.isEmpty) return 'Min: $min';
    return 'Min: $min  Max: $max';
  }

  void _showGradesDialog(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
  ) {
    final drafts = controller.gradeEntries
        .map(
          (e) => CompetitionGradeEntry(
            gradeName: e.nameController.text,
            markRangeMin: e.minMarkController.text,
            markRangeMax: e.maxMarkController.text,
          ),
        )
        .toList();
    if (drafts.isEmpty) {
      drafts.add(CompetitionGradeEntry());
    }

    var saved = false;
    String? errorText;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final markFieldWidth = isMobile ? 88.0 : 100.0;

            return PopScope(
              onPopInvokedWithResult: (didPop, _) {
                if (didPop && !saved) {
                  for (final draft in drafts) {
                    draft.dispose();
                  }
                }
              },
              child: AlertDialog(
                title: Text(
                  controller.gradeEntries.isEmpty
                      ? 'Add Grades'
                      : 'Edit Grades',
                ),
                content: SizedBox(
                  width: isMobile ? double.maxFinite : 520,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add grade names with mark ranges (e.g. A+ for 90–100).',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(drafts.length, (index) {
                          final entry = drafts[index];
                          void refreshAddMore() => setDialogState(() {});
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index < drafts.length - 1 ? 12 : 0,
                            ),
                            child: isMobile
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildGradeNameField(
                                        entry: entry,
                                        isMobile: isMobile,
                                        onChanged: (_) => refreshAddMore(),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildGradeMarkField(
                                              controller:
                                                  entry.minMarkController,
                                              label: 'Min',
                                              isMobile: isMobile,
                                              width: markFieldWidth,
                                              onChanged: (_) =>
                                                  refreshAddMore(),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            child: Text(
                                              'to',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: _buildGradeMarkField(
                                              controller:
                                                  entry.maxMarkController,
                                              label: 'Max',
                                              isMobile: isMobile,
                                              width: markFieldWidth,
                                              onChanged: (_) =>
                                                  refreshAddMore(),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              setDialogState(() {
                                                drafts[index].dispose();
                                                drafts.removeAt(index);
                                                if (drafts.isEmpty) {
                                                  drafts.add(
                                                    CompetitionGradeEntry(),
                                                  );
                                                }
                                              });
                                            },
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color: Colors.red[700],
                                            ),
                                            tooltip: 'Remove grade',
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: _buildGradeNameField(
                                          entry: entry,
                                          isMobile: isMobile,
                                          onChanged: (_) => refreshAddMore(),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      _buildGradeMarkField(
                                        controller: entry.minMarkController,
                                        label: 'Min',
                                        isMobile: isMobile,
                                        width: markFieldWidth,
                                        onChanged: (_) => refreshAddMore(),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Text(
                                          'to',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      _buildGradeMarkField(
                                        controller: entry.maxMarkController,
                                        label: 'Max',
                                        isMobile: isMobile,
                                        width: markFieldWidth,
                                        onChanged: (_) => refreshAddMore(),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setDialogState(() {
                                            drafts[index].dispose();
                                            drafts.removeAt(index);
                                            if (drafts.isEmpty) {
                                              drafts.add(
                                                CompetitionGradeEntry(),
                                              );
                                            }
                                          });
                                        },
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: Colors.red[700],
                                        ),
                                        tooltip: 'Remove grade',
                                      ),
                                    ],
                                  ),
                          );
                        }),
                        const SizedBox(height: 12),
                        Builder(
                          builder: (_) {
                            final canAddMore = drafts.isNotEmpty &&
                                drafts.every((entry) => entry.isComplete);
                            return OutlinedButton.icon(
                              onPressed: canAddMore
                                  ? () {
                                      setDialogState(() {
                                        drafts.add(CompetitionGradeEntry());
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add More'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                                disabledForegroundColor: Colors.grey[500],
                                side: BorderSide(
                                  color: canAddMore
                                      ? AppTheme.primaryColor
                                      : Colors.grey.shade400,
                                ),
                              ),
                            );
                          },
                        ),
                        if (errorText != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            errorText!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      final validationError =
                          controller.validateGradeEntries(drafts);
                      if (validationError != null) {
                        setDialogState(() => errorText = validationError);
                        return;
                      }

                      final toKeep = drafts
                          .where((entry) => entry.hasAnyInput)
                          .toList();
                      for (final draft in drafts) {
                        if (!toKeep.contains(draft)) {
                          draft.dispose();
                        }
                      }

                      saved = true;
                      controller.replaceGradeEntries(toKeep);
                      Navigator.pop(dialogContext);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGradeNameField({
    required CompetitionGradeEntry entry,
    required bool isMobile,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: entry.nameController,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Grade name',
        hintText: 'e.g. A+',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isMobile ? 12 : 14,
        ),
        isDense: isMobile,
      ),
    );
  }

  Widget _buildGradeMarkField({
    required TextEditingController controller,
    required String label,
    required bool isMobile,
    required double width,
    ValueChanged<String>? onChanged,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          hintText: '0-999',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: isMobile ? 12 : 14,
          ),
          isDense: isMobile,
        ),
      ),
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add New Stage'),
        content: Form(
          key: formKey,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          Obx(
            () => controller.isAddingOption.value
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final stageName =
                          textController.text.trim().toUpperCase();
                      final success = await controller.addCustomStage(
                        stageName,
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                      );
                      if (success && dialogContext.mounted) {
                        Navigator.pop(dialogContext);
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
                  child: PinnedVerticalScrollView(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          Obx(
            () => controller.isAddingOption.value
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
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
                        if (context.mounted) {
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
    return Obx(() {
      final categoryId =
          widget.controller.getCategoryIdByName(widget.category);
      final storedAmount = categoryId != null
          ? widget.controller.categoryAmounts[categoryId.toString()] ?? 0.0
          : 0.0;
      final includePlatformFee = categoryId != null
          ? widget.controller.categoryExtraFeeIncludedFor(categoryId)
          : false;
      if (categoryId != null) {
        widget.controller.categoryIncludeFee[categoryId.toString()];
      }
      widget.controller.onDemandPlatformFeePercent.value;
      widget.controller.onDemandPaymentGatewayFeePercent.value;
      final showFeeBreakdown =
          widget.controller.isOnDemandOrg.value && storedAmount > 0;
      final breakdown = showFeeBreakdown && categoryId != null
          ? widget.controller.breakdownCategoryAmount(
              storedAmount,
              includePlatformFee: includePlatformFee,
              categoryId: categoryId,
            )
          : null;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
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
                    widget.controller.updateCategoryAmount(
                      widget.category,
                      amount,
                    );
                  },
          ),
          if (widget.controller.isOnDemandOrg.value && categoryId != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: includePlatformFee,
                  onChanged: widget.controller.isViewMode.value
                      ? null
                      : (value) {
                          widget.controller.toggleCategoryIncludeFee(
                            widget.category,
                            value,
                          );
                        },
                  activeColor: AppTheme.primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  'INCLUDE FEE',
                  style: TextStyle(
                    fontSize: widget.isMobile ? 11 : 12,
                  ),
                ),
              ],
            ),
          ],
          if (breakdown != null) ...[
            const SizedBox(height: 6),
            if (includePlatformFee) ...[
              Text(
                'Amount: ₹${breakdown.baseAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: widget.isMobile ? 11 : 12,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Fee: ₹${breakdown.totalFee.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: widget.isMobile ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Total: ₹${breakdown.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: widget.isMobile ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ] else ...[
              Text(
                'Total payable: ₹${breakdown.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: widget.isMobile ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Fee: ₹${breakdown.totalFee.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: widget.isMobile ? 11 : 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ],
        ],
      );
    });
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
