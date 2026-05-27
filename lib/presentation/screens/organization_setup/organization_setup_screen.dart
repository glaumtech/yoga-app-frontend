import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_permission_record_model.dart';
import '../../controllers/organization_setup_controller.dart';

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
              final s = '${p.permissionName} ${p.permissionKey ?? ''} ${p.menu ?? ''} ${p.subMenu ?? ''} ${p.tab ?? ''}'
                  .toLowerCase();
              return query.trim().isEmpty ||
                  s.contains(query.trim().toLowerCase());
            }).toList()
              ..sort((a, b) => _permLabel(a).compareTo(_permLabel(b)));

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
                            subtitle: (p.menu ?? '').trim().isEmpty &&
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
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
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

    Widget singleColumnFields({required List<Widget> children}) {
      return Column(
        children:
            children.expand((w) => [w, const SizedBox(height: 16)]).toList()
              ..removeLast(),
      );
    }

    Widget permissionMultiSelect({
      required String label,
      required RxSet<int> selectedIds,
    }) {
      return Obx(() {
        final all = c.permissions.toList();
        final selected = selectedIds.toSet();
        final selectedPerms = all
            .where((p) => p.id != null && selected.contains(p.id))
            .toList()
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
        Get.snackbar(
          'Failed',
          c.errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }

    Widget buildStepIndicator() {
      return Obx(() {
        final step = c.currentStep.value;
        Widget chip(int index, String label) {
          final active = step == index;
          final done = step > index;
          return Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: done
                      ? Colors.green
                      : (active ? AppTheme.primaryColor : Colors.grey[300]),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: active || done ? Colors.white : Colors.grey[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    color: active ? AppTheme.primaryColor : Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              chip(0, 'Org & Plan'),
              Expanded(child: Container(height: 2, color: Colors.grey[300])),
              chip(1, 'Payment'),
              Expanded(child: Container(height: 2, color: Colors.grey[300])),
              chip(2, 'Admin Users'),
            ],
          ),
        );
      });
    }

    Widget buildPackageCards() {
      return Obx(() {
        final selectedId = c.selectedPackageId.value;
        final isSubmitting = c.isLoading.value;
        if (c.isLoadingPackages.value) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          );
        }
        if (c.packagesError.value.isNotEmpty && c.subscriptionPackages.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(c.packagesError.value, style: TextStyle(color: Colors.red[700])),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: c.loadSubscriptionPackages,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          );
        }
        if (c.subscriptionPackages.isEmpty) {
          return const Text('No subscription packages available.');
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossCount = constraints.maxWidth >= 700 ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: crossCount == 1 ? 96 : 104,
              ),
              itemCount: c.subscriptionPackages.length,
              itemBuilder: (context, index) {
                final pkg = c.subscriptionPackages[index];
                final selected = selectedId == pkg.id;
                return InkWell(
                  onTap: isSubmitting ? null : () => c.applySelectedPackage(pkg.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppTheme.primaryColor
                            : Colors.grey[300]!,
                        width: selected ? 2 : 1,
                      ),
                      color: selected
                          ? AppTheme.primaryColor.withOpacity(0.06)
                          : Colors.grey[50],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                pkg.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            if (selected)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '₹${pkg.price.toStringAsFixed(0)} • ${pkg.credits} credits',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            height: 1.2,
                          ),
                        ),
                        Text(
                          pkg.paymentModelLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            height: 1.2,
                          ),
                        ),
                        if (pkg.description != null &&
                            pkg.description!.trim().isNotEmpty)
                          Text(
                            pkg.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, height: 1.2),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
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
                  'Organization "${foundation.organization.organizationName}" and branch "${foundation.branch.branchName}" are created. Pay to activate your plan before creating admin users.',
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
                    Text(pkg.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('Amount: ₹${pkg.price.toStringAsFixed(0)}'),
                    Text('Credits: ${pkg.credits}'),
                    Text(pkg.paymentModelLabel),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            const Text(
              'Choose payment method',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Razorpay'),
                  selected: c.selectedCheckoutMethod.value == 'RAZORPAY',
                  onSelected: (_) => c.selectedCheckoutMethod.value = 'RAZORPAY',
                ),
                ChoiceChip(
                  label: const Text('GPay (UPI)'),
                  selected: c.selectedCheckoutMethod.value == 'GPAY',
                  onSelected: (_) => c.selectedCheckoutMethod.value = 'GPAY',
                ),
                ChoiceChip(
                  label: const Text('Cash'),
                  selected: c.selectedCheckoutMethod.value == 'CASH',
                  onSelected: (_) => c.selectedCheckoutMethod.value = 'CASH',
                ),
              ],
            ),
            if (c.selectedCheckoutMethod.value == 'GPAY' &&
                c.manualPaymentUpiIdController.text.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'UPI ID: ${c.manualPaymentUpiIdController.text.trim()}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
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
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: c.isProcessingPayment.value || c.subscriptionPaymentCompleted.value
                    ? null
                    : c.completeSubscriptionPayment,
                icon: c.isProcessingPayment.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.payment),
                label: Text(
                  c.subscriptionPaymentCompleted.value
                      ? 'Payment completed'
                      : (c.selectedCheckoutMethod.value == 'CASH'
                          ? 'Confirm cash payment'
                          : (c.selectedCheckoutMethod.value == 'GPAY'
                              ? 'Pay with GPay (UPI)'
                              : 'Pay with Razorpay')),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
      });
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
                child: Form(
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

                    final detailsLeft = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        sectionTitle('Organization'),
                        gridOrColumn(
                          desktopColumns: 3,
                          tabletColumns: 2,
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
                            TextFormField(
                              controller: c.organizationCodeController,
                              textInputAction: TextInputAction.next,
                              decoration: deco(
                                label: 'Organization Code (optional)',
                                icon: Icons.qr_code_2_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        sectionTitle('Subscription Package'),
                        const Text(
                          'Choose a plan from the database. Payment is collected before admin users are created.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        buildPackageCards(),
                        const SizedBox(height: 8),
                        singleColumnFields(
                          children: [
                            TextFormField(
                              controller: c.manualPaymentUpiIdController,
                              textInputAction: TextInputAction.next,
                              decoration: deco(
                                label: 'Manual Payment UPI ID (optional)',
                                icon: Icons.account_balance_wallet_outlined,
                                hint: 'example@upi',
                              ),
                            ),
                            TextFormField(
                              controller: c.manualPaymentQrPathController,
                              textInputAction: TextInputAction.next,
                              decoration: deco(
                                label: 'Manual Payment QR Path (optional)',
                                icon: Icons.qr_code_outlined,
                                hint: 'uploads/payment-qr/org1.png',
                              ),
                            ),
                            TextFormField(
                              controller: c.subscriptionCreditsController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              decoration: deco(
                                label: 'Subscription Credits (optional)',
                                icon: Icons.confirmation_num_outlined,
                              ),
                            ),
                            TextFormField(
                              controller: c.packCreditsController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              decoration: deco(
                                label: 'Pack Credits (optional)',
                                icon: Icons.inventory_2_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        sectionTitle('Branch'),
                        gridOrColumn(
                          desktopColumns: 3,
                          tabletColumns: 3,
                          children: [
                            TextFormField(
                              controller: c.branchNameController,
                              textInputAction: TextInputAction.next,
                              validator: (v) => c.requiredValidator(
                                v,
                                fieldName: 'Branch name',
                              ),
                              decoration: deco(
                                label: 'Branch Name',
                                icon: Icons.account_tree_outlined,
                              ),
                            ),
                            TextFormField(
                              controller: c.branchCodeController,
                              textInputAction: TextInputAction.next,
                              decoration: deco(
                                label: 'Branch Code (optional)',
                                icon: Icons.qr_code_outlined,
                              ),
                            ),
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
                            TextFormField(
                              controller: c.stateIdController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              decoration: deco(
                                label: 'State ID (optional)',
                                icon: Icons.map_outlined,
                              ),
                            ),
                            TextFormField(
                              controller: c.cityIdController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              decoration: deco(
                                label: 'City ID (optional)',
                                icon: Icons.location_city_outlined,
                              ),
                            ),
                            TextFormField(
                              controller: c.pincodeController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              decoration: deco(
                                label: 'Pincode (optional)',
                                icon: Icons.pin_drop_outlined,
                              ),
                            ),
                            TextFormField(
                              controller: c.themeController,
                              textInputAction: TextInputAction.next,
                              decoration: deco(
                                label: 'Theme (optional)',
                                icon: Icons.palette_outlined,
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
                        const SizedBox(height: 16),
                        sectionTitle('Branch logo (optional)'),
                        Obx(
                          () => Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1.2,
                                  ),
                                ),
                                child: c.logoBytes.value == null
                                    ? Icon(
                                        Icons.image_outlined,
                                        color: Colors.grey[500],
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.memory(
                                          c.logoBytes.value!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Wrap(
                                  spacing: 10,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: c.isLoading.value
                                          ? null
                                          : c.pickLogoFromGallery,
                                      icon: const Icon(Icons.upload_file),
                                      label: const Text('Choose logo'),
                                    ),
                                    TextButton(
                                      onPressed: c.isLoading.value
                                          ? null
                                          : c.clearLogo,
                                      child: const Text('Clear'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    final usersRight = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        sectionTitle('Organization Admin User'),
                        singleColumnFields(
                          children: [
                            TextFormField(
                              controller: c.orgAdminNameController,
                              textInputAction: TextInputAction.next,
                              validator: (v) => c.requiredValidator(
                                v,
                                fieldName: 'Org admin name',
                              ),
                              decoration: deco(
                                label: 'Name',
                                icon: Icons.person_outline,
                              ),
                            ),
                            TextFormField(
                              controller: c.orgAdminUserNameController,
                              textInputAction: TextInputAction.next,
                              validator: (v) => c.requiredValidator(
                                v,
                                fieldName: 'Org admin username',
                              ),
                              decoration: deco(
                                label: 'Username',
                                icon: Icons.badge_outlined,
                              ),
                            ),
                            TextFormField(
                              controller: c.orgAdminPasswordController,
                              textInputAction: TextInputAction.next,
                              obscureText: true,
                              validator: (v) => c.requiredValidator(
                                v,
                                fieldName: 'Org admin password',
                              ),
                              decoration: deco(
                                label: 'Password',
                                icon: Icons.lock_outline,
                              ),
                            ),
                            permissionMultiSelect(
                              label: 'Org Admin Permissions',
                              selectedIds: c.orgAdminPermissionIds,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        sectionTitle('Branch Admin User'),
                        singleColumnFields(
                          children: [
                            TextFormField(
                              controller: c.branchAdminNameController,
                              textInputAction: TextInputAction.next,
                              validator: (v) => c.requiredValidator(
                                v,
                                fieldName: 'Branch admin name',
                              ),
                              decoration: deco(
                                label: 'Name',
                                icon: Icons.person_outline,
                              ),
                            ),
                            TextFormField(
                              controller: c.branchAdminUserNameController,
                              textInputAction: TextInputAction.next,
                              validator: (v) => c.requiredValidator(
                                v,
                                fieldName: 'Branch admin username',
                              ),
                              decoration: deco(
                                label: 'Username',
                                icon: Icons.badge_outlined,
                              ),
                            ),
                            TextFormField(
                              controller: c.branchAdminPasswordController,
                              textInputAction: TextInputAction.done,
                              obscureText: true,
                              validator: (v) => c.requiredValidator(
                                v,
                                fieldName: 'Branch admin password',
                              ),
                              decoration: deco(
                                label: 'Password',
                                icon: Icons.lock_outline,
                              ),
                            ),
                            permissionMultiSelect(
                              label: 'Branch Admin Permissions',
                              selectedIds: c.branchAdminPermissionIds,
                            ),
                          ],
                        ),
                      ],
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
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
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
                          final busy = c.isLoading.value || c.isProcessingPayment.value;
                          String label;
                          if (step == 0) {
                            label = c.requiresSubscriptionPayment
                                ? 'Continue to Payment'
                                : 'Continue to Admin Users';
                          } else if (step == 1) {
                            label = 'Pay & Continue to Admin Users';
                          } else {
                            label = 'Complete Setup';
                          }
                          return Row(
                            children: [
                              if (step > 0)
                                TextButton(
                                  onPressed: busy ? null : c.goBackStep,
                                  child: const Text('Back'),
                                ),
                              Expanded(
                                child: SizedBox(
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
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        buildStepIndicator(),
                        Obx(
                          () => Text(
                            c.stepTitle,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                          ),
                        ),
                        Obx(
                          () => Text(
                            c.currentStep.value == 0
                                ? 'Enter organization details and select a subscription package.'
                                : c.currentStep.value == 1
                                    ? 'Pay for your subscription, then create admin users.'
                                    : 'Create organization and branch admin accounts.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Obx(() {
                          final step = c.currentStep.value;
                          if (step == 1) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                buildPaymentStepPanel(context),
                                footer,
                              ],
                            );
                          }
                          if (step == 2) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                usersRight,
                                footer,
                              ],
                            );
                          }
                          if (!isWide) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                detailsLeft,
                                footer,
                              ],
                            );
                          }
                          return Column(
                            children: [
                              detailsLeft,
                              footer,
                            ],
                          );
                        }),
                      ],
                    );
                  },
                ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
