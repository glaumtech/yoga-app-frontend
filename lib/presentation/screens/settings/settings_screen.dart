import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/permission_store.dart';
import '../../controllers/settings_controller.dart';
import '../../widgets/admin_sidebar_layout.dart';
import 'permissions/permissions_tab.dart';
import 'institutions/institution_config_tab.dart';
import 'imports/imports_tab.dart';

/// Settings area with tabbed sections (same pattern as [ReportsScreen]).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    Get.put(SettingsController(), permanent: false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final permissionStore = Get.isRegistered<PermissionStore>()
        ? Get.find<PermissionStore>()
        : Get.put(PermissionStore());

    final tabs = <({String label, Widget view, String requiredKey})>[
      (
        label: 'Permissions',
        view: const SettingsPermissionsTab(),
        requiredKey: 'SETTINGS_PERMISSIONS',
      ),
      (
        label: 'Institution Config',
        view: const InstitutionConfigTab(),
        requiredKey: 'SHOW_INSTITUTION_CONFIG_TAB',
      ),
      (
        label: 'Imports',
        view: const SettingsImportsTab(),
        requiredKey: 'SHOW_IMPORT_TAB',
      ),
    ].where((t) => permissionStore.has(t.requiredKey)).toList();

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
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 5),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _buildTabs(isMobile, tabs.map((t) => t.label).toList()),
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
        indicator: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: radius,
        ),
        tabs: labels
            .map(
              (label) => Tab(
                height: isMobile ? 30 : 34,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Text(label),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
