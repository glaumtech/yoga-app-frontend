import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/permission_store.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/user_management_controller.dart';
import '../../widgets/admin_sidebar_layout.dart';
import 'permissions/permissions_tab.dart';
import 'institutions/institution_config_tab.dart';
import 'imports/imports_tab.dart';
import 'certificate/certificate_template_tab.dart';
import 'theme/theme_tab.dart';
import 'reset_scoring/reset_scoring_data_tab.dart';
import 'amount_config/amount_config_tab.dart';
import 'legal/legal_document_settings_tab.dart';

/// Re-enable when Imports settings are ready to ship.
const bool _kShowImportsTab = false;

/// Settings area with tabbed sections (same pattern as [ReportsScreen]).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.initialTab});

  /// Optional settings tab id, e.g. `certificate`.
  final String? initialTab;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<SettingsController>()) {
      Get.put(SettingsController(), permanent: false);
    }
  }

  @override
  void dispose() {
    if (Get.isRegistered<SettingsController>()) {
      Get.delete<SettingsController>(force: true);
    }
    super.dispose();
  }

  bool get _isApplicationAdmin {
    final userController = Get.isRegistered<UserManagementController>()
        ? Get.find<UserManagementController>()
        : null;
    final role = (userController?.currentUser.value?.userTypeName ??
            userController?.currentUser.value?.type ??
            '')
        .trim()
        .toUpperCase();
    return role == 'APPLICATION_ADMIN';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final permissionStore = Get.isRegistered<PermissionStore>()
        ? Get.find<PermissionStore>()
        : Get.put(PermissionStore());
    final isApplicationAdmin = _isApplicationAdmin;

    final tabs = <({String id, String label, Widget view, String requiredKey, bool applicationAdminOnly})>[
      (
        id: 'permissions',
        label: 'Permissions',
        view: const SettingsPermissionsTab(),
        requiredKey: 'SETTINGS_PERMISSIONS',
        applicationAdminOnly: false,
      ),
      (
        id: 'institution',
        label: 'Institution Config',
        view: const InstitutionConfigTab(),
        requiredKey: 'SHOW_INSTITUTION_CONFIG_TAB',
        applicationAdminOnly: false,
      ),
      (
        id: 'certificate',
        label: 'Certificate template',
        view: const CertificateTemplateTab(),
        requiredKey: 'SHOW_INSTITUTION_CONFIG_TAB',
        applicationAdminOnly: false,
      ),
      if (_kShowImportsTab)
        (
          id: 'imports',
          label: 'Imports',
          view: const SettingsImportsTab(),
          requiredKey: 'SHOW_IMPORT_TAB',
          applicationAdminOnly: false,
        ),
      (
        id: 'theme',
        label: 'Theme',
        view: const SettingsThemeTab(),
        requiredKey: 'SHOW_SETTINGS_THEME_TAB',
        applicationAdminOnly: false,
      ),
      (
        id: 'reset',
        label: 'Reset Data',
        view: const ResetScoringDataTab(),
        requiredKey: 'RESET_COMPETITION_SCORING_DATA',
        applicationAdminOnly: false,
      ),
      (
        id: 'amount',
        label: 'Amount Configuration',
        view: const AmountConfigTab(),
        requiredKey: 'SHOW_SETTINGS_MASTERS_TAB',
        applicationAdminOnly: true,
      ),
      (
        id: 'terms',
        label: 'Terms and Conditions',
        view: const LegalDocumentSettingsTab(docType: 'terms'),
        requiredKey: 'SHOW_SETTINGS_LEGAL_TAB',
        applicationAdminOnly: true,
      ),
      (
        id: 'privacy',
        label: 'Privacy Policy',
        view: const LegalDocumentSettingsTab(docType: 'privacy'),
        requiredKey: 'SHOW_SETTINGS_LEGAL_TAB',
        applicationAdminOnly: true,
      ),
    ].where((t) {
      if (t.applicationAdminOnly && !isApplicationAdmin) return false;
      return permissionStore.has(t.requiredKey);
    }).toList();

    final requestedTabRaw = widget.initialTab?.trim().toLowerCase() ?? '';
    final requestedTab = switch (requestedTabRaw) {
      'master' || 'masters' => 'amount',
      'location' ||
      'locations' ||
      'state' ||
      'city' ||
      'district' ||
      'pincode' =>
        'institution',
      _ => requestedTabRaw,
    };
    var initialIndex = 0;
    if (requestedTab.isNotEmpty) {
      final idx = tabs.indexWhere((t) => t.id == requestedTab);
      if (idx >= 0) initialIndex = idx;
    }

    return AdminSidebarLayout(
      title: 'Settings',
      child: tabs.isEmpty
          ? Center(
              child: Text(
                'No settings access for your role.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            )
          : DefaultTabController(
              length: tabs.length,
              initialIndex: initialIndex,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 5,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _buildTabs(
                        isMobile,
                        tabs.map((t) => t.label).toList(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: tabs.map((t) => t.view).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTabs(bool isMobile, List<String> labels) {
    final bg = Colors.grey[100]!;
    final radius = BorderRadius.circular(12);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 10),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TabBar(
        isScrollable: true,
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[800],
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: isMobile ? 12 : 13,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: isMobile ? 12 : 13,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: radius,
        ),
        tabs: [
          for (final label in labels)
            Tab(
              height: isMobile ? 30 : 34,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Text(label),
              ),
            ),
        ],
      ),
    );
  }
}
