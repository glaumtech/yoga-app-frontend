import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../controllers/reports_users_tab_controller.dart';
import '../../../data/models/user_management_model.dart';

class ReportsUsersTab extends StatelessWidget {
  const ReportsUsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final tabController = Get.put(
      ReportsUsersTabController(),
      permanent: false,
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Obx(() {
      if (tabController.userController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (tabController.userController.errorMessage.value.isNotEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 12),
                Text(
                  tabController.userController.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[700]),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => tabController.loadUsers(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }

      final allUsers = tabController.users;
      // Always render sections (even when list is empty), so role types never "hide".
      final grouped = tabController.groupByType(allUsers);
      final selectedRole = tabController.typeFilter.value;

      return RefreshIndicator(
        onRefresh: () async {
          await tabController.refresh();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          children: [
            _buildRolesRow(isMobile, tabController),
            const SizedBox(height: 12),
            if (allUsers.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  selectedRole == 'ALL'
                      ? 'No users found for this competition.'
                      : 'No users found in $selectedRole for this competition.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ...[
              'SUB ADMIN',
              'SPOT REG ADMIN(S)',
              'JURY(S)',
              'VOLUNTEERS',
              'OTHERS',
            ].expand((type) {
              final users = grouped[type] ?? const <UserManagementModel>[];
              return [
                ...users.map((u) => _userCard(u, isMobile)),
                if (users.isNotEmpty) const SizedBox(height: 16),
              ];
            }),
          ],
        ),
      );
    });
  }

  Widget _buildRolesRow(
    bool isMobile,
    ReportsUsersTabController tabController,
  ) {
    return Obx(() {
      final paginationText = tabController.paginationText();
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildTypeFilterChips(isMobile, tabController)),
          const SizedBox(width: 12),
          if (paginationText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                paginationText,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildTypeFilterChips(
    bool isMobile,
    ReportsUsersTabController tabController,
  ) {
    const options = <String>[
      'ALL',
      'SUB ADMIN',
      'SPOT REG ADMIN(S)',
      'JURY(S)',
      'VOLUNTEERS',
    ];

    return Obx(() {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((label) {
          final selected = tabController.typeFilter.value == label;
          return ChoiceChip(
            label: Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : Colors.grey[800],
              ),
            ),
            selected: selected,
            selectedColor: AppTheme.primaryColor,
            backgroundColor: Colors.grey[100],
            side: BorderSide(
              color: selected
                  ? AppTheme.primaryColor
                  : Colors.grey[300] ?? Colors.grey,
            ),
            onSelected: (_) => tabController.setTypeFilter(label),
          );
        }).toList(),
      );
    });
  }

  Widget _userCard(UserManagementModel user, bool isMobile) {
    final tabController = Get.find<ReportsUsersTabController>();
    final showPassword =
        (tabController.userController.currentUser.value?.userTypeName
                ?.toUpperCase() ==
            'SUB_ADMIN') ||
        (tabController.userController.currentUser.value?.type.toUpperCase() ==
            'SUB ADMIN');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                  child: Text(
                    (user.name.isNotEmpty ? user.name[0] : 'U').toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: isMobile ? 14 : 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tabController.displayRole(user),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (user.id != null)
                  Text(
                    '#${user.id}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _metaRow('Competition', user.displayEventName ?? 'N/A'),
            if (user.volunteerNo != null && user.volunteerNo!.isNotEmpty)
              _metaRow('Volunteer No', user.volunteerNo!),
            if (user.cell != null && user.cell!.isNotEmpty)
              _metaRow('Cell', user.cell!),
            if (user.permissions.isNotEmpty)
              _metaRow('Permissions', user.permissions.join(', ')),
            if (user.stages.isNotEmpty)
              _metaRow('Stages', user.stages.join(', ')),
            if (user.categories.isNotEmpty)
              _metaRow('Categories', user.categories.join(', ')),
            _metaRow('Created', _formatStamp(user.createdAt, user.createdBy)),
            if (user.updatedAt != null)
              _metaRow('Updated', _formatStamp(user.updatedAt, user.updatedBy)),
            // if (showPassword &&
            //     (user.confirmPassword != null || user.password != null))
            //   _metaRow(
            //     'Password',
            //     user.confirmPassword ?? user.password ?? 'N/A',
            //   ),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatStamp(DateTime? dt, String? by) {
    if (dt == null) return '-';
    final text = DateFormat('MMM dd, yyyy hh:mm a').format(dt);
    if (by != null && by.trim().isNotEmpty) {
      return '$text (by $by)';
    }
    return text;
  }
}
