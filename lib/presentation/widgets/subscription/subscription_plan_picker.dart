import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/subscription_catalog_filter.dart';
import '../../../data/models/subscription_mode_model.dart';
import '../../../data/models/subscription_package_model.dart';
import '../selectable_option_cards.dart';

enum SubscriptionModeSelectorStyle { cards, dropdown }

/// Reusable subscription mode + package selector.
///
/// Set [excludeAddons] to hide ADDON tiers (e.g. during organization creation).
class SubscriptionPlanPicker extends StatelessWidget {
  const SubscriptionPlanPicker({
    super.key,
    required this.modes,
    required this.packages,
    required this.selectedModeId,
    required this.selectedPackageId,
    required this.onModeSelected,
    required this.onPackageSelected,
    this.isLoadingModes = false,
    this.isLoadingPackages = false,
    this.modesError,
    this.packagesError,
    this.onRetryModes,
    this.onRetryPackages,
    this.enabled = true,
    this.excludeAddons = true,
    this.showModeSection = true,
    this.showPackageSection = true,
    this.modeSectionTitle = 'Subscription mode',
    this.packageSectionTitle = 'Package',
    this.modeSelectorStyle = SubscriptionModeSelectorStyle.cards,
  });

  final List<SubscriptionModeModel> modes;
  final List<SubscriptionPackageModel> packages;
  final int? selectedModeId;
  final int? selectedPackageId;
  final ValueChanged<SubscriptionModeModel> onModeSelected;
  final ValueChanged<SubscriptionPackageModel> onPackageSelected;
  final bool isLoadingModes;
  final bool isLoadingPackages;
  final String? modesError;
  final String? packagesError;
  final VoidCallback? onRetryModes;
  final VoidCallback? onRetryPackages;
  final bool enabled;
  final bool excludeAddons;
  final bool showModeSection;
  final bool showPackageSection;
  final String modeSectionTitle;
  final String packageSectionTitle;
  final SubscriptionModeSelectorStyle modeSelectorStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showModeSection) ...[
          Text(
            modeSectionTitle,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildModeSelector(),
          const SizedBox(height: 16),
        ],
        if (showPackageSection) ...[
          Text(
            packageSectionTitle,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildPackageSelector(),
        ],
      ],
    );
  }

  Widget _buildModeSelector() {
    if (isLoadingModes) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }
    if (modesError != null && modesError!.isNotEmpty && modes.isEmpty) {
      return _errorBlock(modesError!, onRetryModes);
    }
    if (modes.isEmpty) {
      return Text(
        modesError?.isNotEmpty == true
            ? modesError!
            : 'No subscription modes available.',
        style: TextStyle(color: Colors.red[700], fontSize: 13),
      );
    }

    final sortedModes = SubscriptionCatalogFilter.sortModes(modes);

    if (modeSelectorStyle == SubscriptionModeSelectorStyle.dropdown) {
      return _buildModeDropdown(sortedModes);
    }

    final options = sortedModes
        .map(
          (mode) => SelectableOptionItem(
            value: '${mode.id}',
            label: mode.name,
            subtitle: _modeSubtitle(mode.modeKey),
            icon: _modeIcon(mode.modeKey),
          ),
        )
        .toList();

    return SelectableOptionCards(
      options: options,
      selectedValue:
          selectedModeId == null ? null : '$selectedModeId',
      enabled: enabled,
      onSelected: (value) {
        final id = int.tryParse(value);
        if (id == null) return;
        for (final mode in sortedModes) {
          if (mode.id == id) {
            onModeSelected(mode);
            return;
          }
        }
      },
    );
  }

  Widget _buildModeDropdown(List<SubscriptionModeModel> sortedModes) {
    final validIds = sortedModes.map((m) => m.id).toSet();
    final value = selectedModeId != null && validIds.contains(selectedModeId)
        ? selectedModeId
        : null;

    SubscriptionModeModel? selectedMode;
    if (value != null) {
      for (final m in sortedModes) {
        if (m.id == value) {
          selectedMode = m;
          break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: modeSectionTitle,
            hintText: 'Select subscription type',
            prefixIcon: Icon(
              selectedMode != null
                  ? _modeIcon(selectedMode.modeKey)
                  : Icons.layers_outlined,
              color: AppTheme.primaryColor,
            ),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          items: sortedModes
              .map(
                (mode) => DropdownMenuItem<int>(
                  value: mode.id,
                  child: Text(
                    mode.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: !enabled
              ? null
              : (id) {
                  if (id == null) return;
                  for (final mode in sortedModes) {
                    if (mode.id == id) {
                      onModeSelected(mode);
                      return;
                    }
                  }
                },
        ),
        if (selectedMode != null) ...[
          const SizedBox(height: 8),
          Text(
            _modeSubtitle(selectedMode.modeKey),
            style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3),
          ),
        ],
      ],
    );
  }

  static IconData _modeIcon(String modeKey) {
    switch (modeKey) {
      case 'USER_PACK_SUBSCRIPTION':
        return Icons.groups_outlined;
      case 'PAY_PER_PARTICIPANT':
        return Icons.payments_outlined;
      case 'ORG_SUBSCRIPTION':
      default:
        return Icons.calendar_month_outlined;
    }
  }

  static String _modeSubtitle(String modeKey) {
    switch (modeKey) {
      case 'USER_PACK_SUBSCRIPTION':
        return 'License competitions with user-pack tiers';
      case 'PAY_PER_PARTICIPANT':
        return 'Maintenance fee + online participant payments';
      case 'ORG_SUBSCRIPTION':
      default:
        return 'Annual plan with competition credits';
    }
  }

  Widget _buildPackageSelector() {
    if (selectedModeId == null) {
      return Text(
        'Select a subscription mode to view packages.',
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      );
    }
    if (isLoadingPackages) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }
    if (packagesError != null && packagesError!.isNotEmpty && packages.isEmpty) {
      return _errorBlock(packagesError!, onRetryPackages);
    }
    if (packages.isEmpty) {
      return const Text('No packages available for this mode.');
    }

    final sortedPackages = SubscriptionCatalogFilter.sortPackages(packages);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = _packageColumnCount(
          constraints.maxWidth,
          sortedPackages.length,
        );
        final rowHeight = crossCount >= 3 ? 76.0 : (crossCount == 2 ? 72.0 : 68.0);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: rowHeight,
          ),
          itemCount: sortedPackages.length,
          itemBuilder: (context, index) {
            final pkg = sortedPackages[index];
            return _PackageTierCard(
              package: pkg,
              selected: selectedPackageId == pkg.id,
              enabled: enabled,
              onTap: () => onPackageSelected(pkg),
            );
          },
        );
      },
    );
  }

  /// Up to 3 columns (Basic | Standard | Pro) when width allows.
  static int _packageColumnCount(double width, int itemCount) {
    if (itemCount <= 1) return 1;
    if (width >= 720 && itemCount >= 3) return 3;
    if (width >= 480 && itemCount >= 2) return 2;
    return 1;
  }

  Widget _errorBlock(String message, VoidCallback? onRetry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message, style: TextStyle(color: Colors.red[700])),
        if (onRetry != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ],
    );
  }
}

class _PackageTierCard extends StatelessWidget {
  const _PackageTierCard({
    required this.package,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final SubscriptionPackageModel package;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
          color: selected
              ? AppTheme.primaryColor.withValues(alpha: 0.06)
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
                    package.tierWithPriceLine,
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
            if (package.description != null &&
                package.description!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  package.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, height: 1.15),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
