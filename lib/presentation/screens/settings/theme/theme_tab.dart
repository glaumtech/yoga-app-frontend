import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/role_display_name.dart';
import '../../../controllers/settings_controller.dart';
import '../../../controllers/user_management_controller.dart';
import '../../../widgets/primary_button.dart';

class SettingsThemeTab extends StatelessWidget {
  const SettingsThemeTab({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SettingsController>()) {
      return const SizedBox.shrink();
    }
    final controller = Get.find<SettingsController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Obx(() {
      final user = Get.isRegistered<UserManagementController>()
          ? Get.find<UserManagementController>().currentUser.value
          : null;
      final selectedType = controller.selectedThemeUserType;
      final roleLabel = displayRoleName(selectedType?.typeName);
      final previewColor =
          controller.selectedThemePreviewColor ?? AppTheme.primaryColor;
      final secondary = AppTheme.secondaryColorFor(previewColor);
      final themeableTypes = controller.themeableUserTypes;

      return SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Role theme colour',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  controller.canManageAllRoleThemes
                      ? 'Choose a role type and set its accent colour. '
                          'Users see this colour when they log in with that role.'
                      : 'Set the accent colour for $roleLabel. '
                          'This helps identify which role is logged in across the app.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 20),
                if (controller.isLoadingUserTypes.value &&
                    themeableTypes.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (themeableTypes.isEmpty)
                  Text(
                    'No role types available for theme configuration.',
                    style: TextStyle(color: Colors.grey[700]),
                  )
                else ...[
                  DropdownButtonFormField<int>(
                    key: ValueKey(controller.selectedThemeUserTypeId.value),
                    isExpanded: true,
                    value: controller.selectedThemeUserTypeId.value,
                    decoration: InputDecoration(
                      labelText: 'Role type',
                      prefixIcon: Icon(Icons.badge_outlined, color: previewColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    selectedItemBuilder: (context) => themeableTypes
                        .map(
                          (type) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              displayRoleName(type.typeName),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    items: themeableTypes
                        .map(
                          (type) => DropdownMenuItem<int>(
                            value: type.id,
                            child: Text(
                              displayRoleName(type.typeName),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: controller.canManageAllRoleThemes &&
                            themeableTypes.length > 1
                        ? (value) {
                            if (value != null) {
                              controller.selectThemeUserType(value);
                            }
                          }
                        : null,
                  ),
                  const SizedBox(height: 20),
                  _PreviewCard(
                    roleLabel: roleLabel,
                    userName: user?.name ?? 'User',
                    primary: previewColor,
                    secondary: secondary,
                  ),
                ],
                if (themeableTypes.isNotEmpty) ...[
                const SizedBox(height: 24),
                Form(
                  key: controller.themeFormKey,
                  child: TextFormField(
                    initialValue: controller.themeColorInput.value,
                    key: ValueKey(controller.themeColorInput.value),
                    decoration: InputDecoration(
                      labelText: 'Hex colour',
                      hintText: '#4CAF50',
                      prefixIcon: Icon(Icons.palette_outlined, color: previewColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorText: controller.themeErrorMessage.value.isNotEmpty
                          ? controller.themeErrorMessage.value
                          : null,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[#0-9A-Fa-f]')),
                      LengthLimitingTextInputFormatter(7),
                    ],
                    validator: controller.validateThemeHex,
                    onChanged: controller.previewThemeFromInput,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Quick picks',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: SettingsController.themePresetColors.map((hex) {
                    final color = AppTheme.parseHexColor(hex) ?? previewColor;
                    final selected =
                        controller.themeColorInput.value.toUpperCase() ==
                            hex.toUpperCase();
                    return InkWell(
                      onTap: () => controller.selectThemeColor(hex),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? Colors.black87 : Colors.grey[300]!,
                            width: selected ? 2.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.35),
                              blurRadius: selected ? 8 : 2,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: selected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          text: 'Reset to default',
                          isOutlined: true,
                          height: 48,
                          onPressed: controller.isSavingTheme.value
                              ? null
                              : () => controller.resetThemeToDefault(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          text: 'Save theme',
                          height: 48,
                          isLoading: controller.isSavingTheme.value,
                          onPressed: controller.isSavingTheme.value
                              ? null
                              : () => controller.saveThemeColor(),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.roleLabel,
    required this.userName,
    required this.primary,
    required this.secondary,
  });

  final String roleLabel;
  final String userName;
  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, secondary],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Icon(Icons.settings, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      roleLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, secondary],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.dashboard, color: Colors.white, size: 18),
                      SizedBox(height: 12),
                      Icon(Icons.people, color: Colors.white70, size: 18),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Theme',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sidebar, tabs, and buttons use this colour.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                            ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: null,
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          disabledBackgroundColor: primary,
                          disabledForegroundColor: Colors.white,
                        ),
                        child: const Text('Sample button'),
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
  }
}
