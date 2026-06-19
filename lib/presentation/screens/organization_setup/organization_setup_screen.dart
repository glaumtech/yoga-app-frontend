import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../widgets/selectable_option_cards.dart';
import '../../widgets/subscription/subscription_plan_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/models/app_permission_record_model.dart';
import '../../controllers/organization_setup_controller.dart';
import '../../widgets/location/district_search_field.dart';
import '../../widgets/location/state_search_field.dart';

class OrganizationSetupScreen extends StatelessWidget {
  const OrganizationSetupScreen({super.key});

  String _permLabel(AppPermissionRecord p) {
    final name = p.permissionName.trim();
    final key = (p.permissionKey ?? '').trim();
    if (key.isEmpty) return name;
    if (name.isEmpty) return key;
    return '$name ($key)';
  }

  Future<void> _openPermissionPicker({
    required BuildContext context,
    required String title,
    required List<AppPermissionRecord> allPermissions,
    required Set<int> initialSelectedIds,
    required void Function(Set<int> next) onApply,
  }) async {
    final selected = {...initialSelectedIds};
    String query = '';

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final filtered = allPermissions.where((p) {
              final s =
                  '${p.permissionName} ${p.permissionKey ?? ''} ${p.menu ?? ''} ${p.subMenu ?? ''} ${p.tab ?? ''}'
                      .toLowerCase();
              return query.trim().isEmpty ||
                  s.contains(query.trim().toLowerCase());
            }).toList()..sort((a, b) => _permLabel(a).compareTo(_permLabel(b)));

            final allIds = allPermissions
                .map((p) => p.id)
                .whereType<int>()
                .where((id) => id != 0)
                .toSet();
            final selectedAllCount = selected.intersection(allIds).length;
            final bool? selectAllValue = allIds.isEmpty
                ? false
                : (selectedAllCount == 0
                      ? false
                      : (selectedAllCount == allIds.length ? true : null));

            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search permissions...',
                      ),
                      onChanged: (v) => setState(() => query = v),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      dense: true,
                      tristate: true,
                      value: selectAllValue,
                      title: Text(
                        'Select all (${allIds.length})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: selectedAllCount == 0
                          ? null
                          : Text('Selected: $selectedAllCount'),
                      onChanged: allIds.isEmpty
                          ? null
                          : (v) {
                              setState(() {
                                if (v == true) {
                                  selected.addAll(allIds);
                                } else {
                                  selected.removeAll(allIds);
                                }
                              });
                            },
                      controlAffinity: ListTileControlAffinity.trailing,
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final p = filtered[i];
                          final id = p.id ?? 0;
                          final checked = id != 0 && selected.contains(id);
                          return CheckboxListTile(
                            dense: true,
                            value: checked,
                            title: Text(_permLabel(p)),
                            subtitle:
                                (p.menu ?? '').trim().isEmpty &&
                                    (p.tab ?? '').trim().isEmpty
                                ? null
                                : Text(
                                    [
                                      if ((p.menu ?? '').trim().isNotEmpty)
                                        'Menu: ${p.menu}',
                                      if ((p.subMenu ?? '').trim().isNotEmpty)
                                        'Sub: ${p.subMenu}',
                                      if ((p.tab ?? '').trim().isNotEmpty)
                                        'Tab: ${p.tab}',
                                    ].join('  •  '),
                                  ),
                            onChanged: id == 0
                                ? null
                                : (v) {
                                    setState(() {
                                      if (v == true) {
                                        selected.add(id);
                                      } else {
                                        selected.remove(id);
                                      }
                                    });
                                  },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                OutlinedButton(
                  onPressed: () => setState(() => selected.clear()),
                  child: const Text('Clear'),
                ),
                ElevatedButton(
                  onPressed: () {
                    onApply(selected);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(OrganizationSetupController());

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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      );
    }

    Widget sectionTitle(String title) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
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

    Widget permissionMultiSelect({
      required String label,
      required RxSet<int> selectedIds,
    }) {
      return Obx(() {
        final all = c.permissions.toList();
        final selected = selectedIds.toSet();
        final selectedPerms =
            all.where((p) => p.id != null && selected.contains(p.id)).toList()
              ..sort((a, b) => _permLabel(a).compareTo(_permLabel(b)));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selected.isEmpty
                              ? 'No permissions selected'
                              : '${selected.length} permission(s) selected',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: c.isLoadingPermissions.value
                            ? null
                            : () async {
                                if (c.permissions.isEmpty) {
                                  await c.loadPermissions();
                                }
                                if (!context.mounted) return;
                                await _openPermissionPicker(
                                  context: context,
                                  title: label,
                                  allPermissions: c.permissions,
                                  initialSelectedIds: selected,
                                  onApply: (next) {
                                    selectedIds
                                      ..clear()
                                      ..addAll(next);
                                  },
                                );
                              },
                        icon: const Icon(Icons.playlist_add_check),
                        label: const Text('Select'),
                      ),
                    ],
                  ),
                  if (c.permissionsError.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        c.permissionsError.value,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  if (selectedPerms.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedPerms.map((p) {
                        final id = p.id ?? 0;
                        return Chip(
                          label: Text(p.permissionName),
                          onDeleted: id == 0
                              ? null
                              : () => selectedIds.remove(id),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      });
    }

    Future<void> onSubmit() async {
      if (c.isLoading.value || c.isProcessingPayment.value) return;
      final ok = await c.submitSetup();
      if (!context.mounted) return;

      if (!ok && c.errorMessage.value.isNotEmpty) {
        SnackbarHelper.show(
          title: 'Failed',
          message: c.errorMessage.value,
          backgroundColor: Colors.red,
        );
      }
    }

    Widget buildStepIndicator() {
      return Obx(() {
        final step = c.currentStep.value;
        Widget chip(int index, String label) {
          final active = step == index;
          final done = step > index;
          final canTap =
              index == 0 || index == 1 || (index == 2 && c.canOpenAdminStep);
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: canTap ? () => c.goToStep(index) : null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: done
                            ? Colors.green
                            : (active
                                  ? AppTheme.primaryColor
                                  : Colors.grey[300]),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: active || done
                                ? Colors.white
                                : Colors.grey[700],
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
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: active
                              ? AppTheme.primaryColor
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              chip(0, 'Organization'),
              Expanded(child: Container(height: 2, color: Colors.grey[300])),
              chip(1, 'Plan & Payment'),
              Expanded(child: Container(height: 2, color: Colors.grey[300])),
              chip(2, 'Admin Users'),
            ],
          ),
        );
      });
    }

    Widget buildPaymentStepPanel(BuildContext context) {
      return Obx(() {
        final pkg = c.selectedPackage;
        final foundation = c.foundationResult.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(
              () => SubscriptionPlanPicker(
                modes: c.subscriptionModes.toList(),
                packages: c.subscriptionPackages.toList(),
                selectedModeId: c.selectedSubscriptionModeId.value,
                selectedPackageId: c.selectedPackageId.value,
                isLoadingModes: c.isLoadingModes.value,
                isLoadingPackages: c.isLoadingPackages.value,
                modesError: c.modesError.value.isEmpty
                    ? null
                    : c.modesError.value,
                packagesError: c.packagesError.value.isEmpty
                    ? null
                    : c.packagesError.value,
                onRetryModes: c.loadSubscriptionModes,
                onRetryPackages: c.reloadSubscriptionPackages,
                enabled: !c.isLoading.value && !c.isProcessingPayment.value,
                excludeAddons: true,
                modeSectionTitle: 'Plan type',
                packageSectionTitle: 'Package',
                onModeSelected: c.selectSubscriptionMode,
                onPackageSelected: (pkg) => c.applySelectedPackage(pkg.id),
              ),
            ),
            const SizedBox(height: 14),
            if (!c.requiresSubscriptionPayment) ...[
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: const Text(
                  'On Demand has no upfront subscription payment. '
                  'Select a package, then continue to create admin users. '
                  'Competition fees are collected when you create each competition.',
                ),
              ),
            ],
            if (c.requiresSubscriptionPayment) ...[
            sectionTitle('Complete Subscription Payment'),
            if (foundation != null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  'Organization "${foundation.organization.organizationName}" is created. Complete payment, then create admin users.',
                ),
              ),
            if (pkg != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c.selectedSubscriptionMode?.name ?? pkg.paymentModelLabel} — ${pkg.tierWithPriceLine}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (pkg.description != null &&
                        pkg.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(pkg.description!),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 4),
            sectionTitle('Payment method'),
            const SizedBox(height: 8),
            SelectableOptionCards(
              options: const [
                SelectableOptionItem(
                  value: 'RAZORPAY',
                  label: 'Razorpay',
                  subtitle: 'Pay online with card, UPI, or net banking',
                  icon: Icons.credit_card_outlined,
                ),
                SelectableOptionItem(
                  value: 'CASH',
                  label: 'Cash',
                  subtitle: 'Mark payment as received offline',
                  icon: Icons.payments_outlined,
                ),
              ],
              selectedValue: c.selectedCheckoutMethod.value,
              enabled: !c.isLoading.value && !c.isProcessingPayment.value,
              onSelected: (value) => c.selectedCheckoutMethod.value = value,
            ),
            if (c.selectedCheckoutMethod.value == 'CASH')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Cash mode marks payment as received and continues to admin setup.',
                  style: TextStyle(color: Colors.orange[800], fontSize: 12),
                ),
              ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420, minWidth: 240),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: c.isProcessingPayment.value
                        ? null
                        : (c.subscriptionPaymentCompleted.value
                              ? c.continueToAdminStep
                              : c.completeSubscriptionPayment),
                    icon: c.isProcessingPayment.value
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            c.subscriptionPaymentCompleted.value
                                ? Icons.arrow_forward
                                : Icons.payment,
                          ),
                    label: Text(
                      c.subscriptionPaymentCompleted.value
                          ? 'Continue to Admin Users'
                          : (c.selectedCheckoutMethod.value == 'CASH'
                                ? 'Confirm cash payment'
                                : 'Pay with Razorpay'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            ],
            if (!c.requiresSubscriptionPayment) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420, minWidth: 240),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: c.isProcessingPayment.value
                          ? null
                          : (c.subscriptionPaymentCompleted.value
                                ? c.continueToAdminStep
                                : c.completeSubscriptionPayment),
                      icon: Icon(
                        c.subscriptionPaymentCompleted.value
                            ? Icons.arrow_forward
                            : Icons.arrow_forward_outlined,
                      ),
                      label: Text(
                        c.subscriptionPaymentCompleted.value
                            ? 'Continue to Admin Users'
                            : 'Continue to Admin Users',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      });
    }

    Widget buildAdminUserSection({
      required BuildContext context,
      required double maxWidth,
    }) {
      final useSideBySide = maxWidth >= 720;
      const credentialsCardWidth = 420.0;
      const profileCardWidth = 280.0;

      Widget buildProfileCard() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Profile picture (optional)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final hasPhoto = c.branchAdminPhotoBytes.value != null;
              final busy = c.isLoading.value;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasPhoto
                        ? AppTheme.primaryColor.withValues(alpha: 0.45)
                        : Colors.grey.shade300,
                    width: hasPhoto ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: busy
                          ? null
                          : () => c.pickBranchAdminPhoto(
                              ImageSource.gallery,
                              context,
                            ),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: hasPhoto ? 140 : 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            style: hasPhoto
                                ? BorderStyle.solid
                                : BorderStyle.none,
                          ),
                        ),
                        child: hasPhoto
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.memory(
                                  c.branchAdminPhotoBytes.value!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.account_circle_outlined,
                                    size: 48,
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.85,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to add photo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'PNG or JPG recommended',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
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
                        onPressed: busy
                            ? null
                            : () => c.pickBranchAdminPhoto(
                                ImageSource.gallery,
                                context,
                              ),
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: Text(hasPhoto ? 'Change photo' : 'Upload photo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          minimumSize: const Size(double.infinity, 40),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () => c.pickBranchAdminPhoto(
                                ImageSource.camera,
                                context,
                              ),
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text('Take photo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          minimumSize: const Size(double.infinity, 40),
                        ),
                      ),
                    ),
                    if (hasPhoto) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: busy ? null : c.clearBranchAdminPhoto,
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

      Widget buildCredentialsFields() {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.admin_panel_settings_outlined,
                      color: AppTheme.primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin account',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Credentials for the primary admin who will manage this organization.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: c.branchAdminNameController,
                textInputAction: TextInputAction.next,
                validator: (v) => c.requiredValidator(v, fieldName: 'Name'),
                decoration: deco(
                  label: 'Full name',
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: c.branchAdminUserNameController,
                textInputAction: TextInputAction.next,
                validator: (v) => c.requiredValidator(v, fieldName: 'Username'),
                decoration: deco(
                  label: 'Username',
                  icon: Icons.badge_outlined,
                  hint: 'Used to sign in',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: c.branchAdminEmailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) => c.emailValidator(v, fieldName: 'Email'),
                decoration: deco(
                  label: 'Email',
                  icon: Icons.email_outlined,
                  hint: 'For login recovery and notifications',
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => TextFormField(
                  controller: c.branchAdminPasswordController,
                  readOnly: true,
                  obscureText: !c.branchAdminPasswordVisible.value,
                  decoration: deco(
                    label: 'Password',
                    icon: Icons.lock_outline,
                    hint: 'Auto-generated — save before completing',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            c.branchAdminPasswordVisible.value
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          tooltip: c.branchAdminPasswordVisible.value
                              ? 'Hide password'
                              : 'Show password',
                          onPressed: c.toggleBranchAdminPasswordVisibility,
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Regenerate password',
                          onPressed: c.regenerateBranchAdminPassword,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      if (useSideBySide) {
        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: credentialsCardWidth,
                child: buildCredentialsFields(),
              ),
              const SizedBox(width: 24),
              SizedBox(width: profileCardWidth, child: buildProfileCard()),
            ],
          ),
        );
      }

      final narrowCardWidth = maxWidth.clamp(280.0, credentialsCardWidth);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: narrowCardWidth, child: buildProfileCard()),
          const SizedBox(height: 16),
          SizedBox(width: narrowCardWidth, child: buildCredentialsFields()),
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
            final busy = c.isLoading.value;

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
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'PNG or JPG recommended',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
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

    return Scaffold(
      appBar: AppBar(title: const Text('Organization Setup')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.12),
              AppTheme.secondaryColor.withOpacity(0.08),
              Colors.white,
              AppTheme.accentColor.withOpacity(0.08),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, viewport) => SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 10 : 0,
                vertical: isMobile ? 12 : 10,
              ),
              child: SizedBox(
                width: viewport.maxWidth,
                child: Obx(() {
                  // Rebuild form after successful setup reset.
                  final _ = c.formRevision.value;
                  return Form(
                    key: c.formKey,
                    child: Container(
                      width: viewport.maxWidth,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.12),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(isMobile ? 20 : 28),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 1100;

                          final organizationDetailsFields = Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
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
                                    decoration: deco(
                                      label: 'Commencing Year (optional)',
                                      icon: Icons.calendar_month_outlined,
                                      hint: 'e.g. 2025',
                                    ),
                                  ),
                                  TextFormField(
                                    controller: c.emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    decoration: deco(
                                      label: 'Email (optional)',
                                      icon: Icons.email_outlined,
                                    ),
                                  ),
                                  TextFormField(
                                    controller: c.phoneNoController,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.next,
                                    decoration: deco(
                                      label: 'Phone No (optional)',
                                      icon: Icons.phone_outlined,
                                    ),
                                  ),
                                  TextFormField(
                                    controller: c.mobileNoController,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.next,
                                    decoration: deco(
                                      label: 'Mobile No (optional)',
                                      icon: Icons.smartphone_outlined,
                                    ),
                                  ),
                                  TextFormField(
                                    controller: c.websiteUrlController,
                                    keyboardType: TextInputType.url,
                                    textInputAction: TextInputAction.next,
                                    decoration: deco(
                                      label: 'Website URL (optional)',
                                      icon: Icons.public_outlined,
                                    ),
                                  ),
                                  TextFormField(
                                    controller: c.countryController,
                                    textInputAction: TextInputAction.next,
                                    decoration: deco(
                                      label: 'Country (optional)',
                                      icon: Icons.flag_outlined,
                                    ),
                                  ),
                                  Obx(() {
                                    if (c.isLoadingStates.value) {
                                      return TextFormField(
                                        readOnly: true,
                                        decoration:
                                            deco(
                                              label: 'State (optional)',
                                              icon: Icons.map_outlined,
                                            ).copyWith(
                                              hintText: 'Loading states...',
                                              suffixIcon: const Padding(
                                                padding: EdgeInsets.all(12),
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
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
                                      decorationBuilder:
                                          ({Widget? suffixIcon}) => deco(
                                            label: 'State (optional)',
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
                                        decoration:
                                            deco(
                                              label: 'District (optional)',
                                              icon:
                                                  Icons.location_city_outlined,
                                            ).copyWith(
                                              hintText: 'Loading districts...',
                                              suffixIcon: const Padding(
                                                padding: EdgeInsets.all(12),
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
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
                                        decoration:
                                            deco(
                                              label: 'District (optional)',
                                              icon:
                                                  Icons.location_city_outlined,
                                            ).copyWith(
                                              hintText: 'Select state first',
                                            ),
                                      );
                                    }
                                    return DistrictSearchField(
                                      key: ValueKey(
                                        'org_setup_district_${stateId}_$districtListVersion',
                                      ),
                                      textEditingController:
                                          c.districtSearchTextController,
                                      focusNode: c.districtSearchFocusNode,
                                      districts: List.from(c.districts),
                                      decorationBuilder:
                                          ({Widget? suffixIcon}) => deco(
                                            label: 'District (optional)',
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
                                    decoration: deco(
                                      label: 'Pincode (optional)',
                                      icon: Icons.pin_drop_outlined,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: c.addressController,
                                textInputAction: TextInputAction.next,
                                maxLines: 3,
                                decoration: deco(
                                  label: 'Address (optional)',
                                  icon: Icons.home_outlined,
                                ),
                              ),
                            ],
                          );

                          final useSideBySideLogo = constraints.maxWidth >= 720;

                          final detailsLeft = Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              useSideBySideLogo
                                  ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: organizationDetailsFields,
                                        ),
                                        const SizedBox(width: 20),
                                        SizedBox(
                                          width: 300,
                                          child: buildLogoSection(),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        organizationDetailsFields,
                                        const SizedBox(height: 16),
                                        buildLogoSection(),
                                      ],
                                    ),
                            ],
                          );

                          final usersRight = buildAdminUserSection(
                            context: context,
                            maxWidth: constraints.maxWidth,
                          );

                          final footer = Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 22),
                              Obx(
                                () => c.errorMessage.value.isNotEmpty
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        margin: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.red.shade200,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade100,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.error_outline_rounded,
                                                color: Colors.red.shade700,
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                c.errorMessage.value,
                                                style: TextStyle(
                                                  color: Colors.red.shade700,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              Obx(() {
                                final step = c.currentStep.value;
                                final busy =
                                    c.isLoading.value ||
                                    c.isProcessingPayment.value;
                                final showPrimaryAction = step != 1;
                                String label;
                                if (step == 0) {
                                  label = 'Continue to Plan & Payment';
                                } else {
                                  label = 'Complete Setup';
                                }
                                final buttonWidth =
                                    (MediaQuery.sizeOf(context).width - 48)
                                        .clamp(220.0, 520.0);
                                final primaryButton = SizedBox(
                                  width: buttonWidth,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: busy ? null : onSubmit,
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      backgroundColor: AppTheme.primaryColor,
                                    ),
                                    child: busy
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            label,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                );

                                if (step > 0) {
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton(
                                          onPressed: busy ? null : c.goBackStep,
                                          child: const Text('Back'),
                                        ),
                                      ),
                                      if (showPrimaryAction)
                                        Center(child: primaryButton),
                                    ],
                                  );
                                }

                                if (!showPrimaryAction) {
                                  return const SizedBox.shrink();
                                }

                                return Center(child: primaryButton);
                              }),
                            ],
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              buildStepIndicator(),

                              Obx(
                                () => Text(
                                  c.currentStep.value == 0
                                      ? 'Enter organization details.'
                                      : c.currentStep.value == 1
                                      ? 'Select your On Demand package to continue setup.'
                                      : 'Create the primary admin account for this organization.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ),
                              const SizedBox(height: 15),
                              Obx(() {
                                final step = c.currentStep.value;
                                if (step == 1) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      buildPaymentStepPanel(context),
                                      footer,
                                    ],
                                  );
                                }
                                if (step == 2) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [usersRight, footer],
                                  );
                                }
                                if (!isWide) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [detailsLeft, footer],
                                  );
                                }
                                return Column(children: [detailsLeft, footer]);
                              }),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
