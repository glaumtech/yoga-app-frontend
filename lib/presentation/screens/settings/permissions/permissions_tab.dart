import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/app_permission_record_model.dart';
import '../../../controllers/settings_controller.dart';
import '../../../widgets/buttons.dart';

SettingsController? _activeSettingsController() {
  return Get.isRegistered<SettingsController>()
      ? Get.find<SettingsController>()
      : null;
}

class SettingsPermissionsTab extends StatelessWidget {
  const SettingsPermissionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Obx(() {
      final controller = _activeSettingsController();
      if (controller == null) {
        return const SizedBox.shrink();
      }
      if (controller.isLoading.value && controller.permissions.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      return RefreshIndicator(
        onRefresh: () async {
          await controller.loadPermissions();
          await controller.loadUserTypes();
        },
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 5),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildInnerTabs(isMobile),
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _CreatePermissionTab(isMobile: isMobile),
                    _AssignPermissionTab(isMobile: isMobile),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildInnerTabs(bool isMobile) {
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
        tabs: [
          Tab(
            height: isMobile ? 30 : 34,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text('Create Permission'),
            ),
          ),
          Tab(
            height: isMobile ? 30 : 34,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text('Assign Permission'),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _permissionSubtitle(BuildContext context, AppPermissionRecord p) {
  final metaStyle = Theme.of(
    context,
  ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]);

  final parts = <Widget>[];
  if (p.description != null && p.description!.isNotEmpty) {
    parts.add(Text(p.description!));
  }

  final meta = <String>[];
  if (p.permissionKey != null && p.permissionKey!.isNotEmpty) {
    meta.add('Key: ${p.permissionKey}');
  }
  if (p.type != null && p.type!.isNotEmpty) {
    meta.add('Type: ${p.type}');
  }
  if (p.menu != null && p.menu!.isNotEmpty) {
    meta.add('Menu: ${p.menu}');
  }
  if (p.subMenu != null && p.subMenu!.isNotEmpty) {
    meta.add('Sub-menu: ${p.subMenu}');
  }
  if (p.tab != null && p.tab!.isNotEmpty) {
    meta.add('Tab: ${p.tab}');
  }

  if (meta.isNotEmpty) {
    parts.add(Text(meta.join(' · '), style: metaStyle));
  }

  if (parts.isEmpty) {
    return Text('No extra details', style: metaStyle);
  }

  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: parts);
}

class _CreatePermissionTab extends StatelessWidget {
  final bool isMobile;
  const _CreatePermissionTab({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final controller = _activeSettingsController();
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = !isMobile && constraints.maxWidth >= 1100;

        Widget formCard() {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Obx(() {
                final active = _activeSettingsController();
                if (active == null) {
                  return const SizedBox.shrink();
                }
                final isEdit = active.isEditMode.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'EDIT PERMISSION' : 'CREATE PERMISSION',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 14 : 16,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    SizedBox(height: isMobile ? 16 : 20),
                    Obx(() {
                      final active = _activeSettingsController();
                      if (active == null) {
                        return const SizedBox.shrink();
                      }
                      // Force rebuild after update/reset so field state is cleared.
                      final trigger = active.formResetTrigger.value;
                      return KeyedSubtree(
                        key: ValueKey('permission_form_$trigger'),
                        child: Form(
                          key: controller.formKey,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          final cols = isMobile
                              ? 1
                              : (w >= 900 ? 3 : (w >= 650 ? 2 : 1));
                          final gap = 12.0;
                          final itemW = cols == 1
                              ? w
                              : ((w - (gap * (cols - 1))) / cols);

                          Widget row3(Widget a, Widget b, Widget c) {
                            if (cols == 1) {
                              return Column(
                                children: [
                                  a,
                                  const SizedBox(height: 12),
                                  b,
                                  const SizedBox(height: 12),
                                  c,
                                ],
                              );
                            }
                            if (cols == 2) {
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(width: itemW, child: a),
                                      const SizedBox(width: 12),
                                      SizedBox(width: itemW, child: b),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(width: double.infinity, child: c),
                                ],
                              );
                            }
                            return Row(
                              children: [
                                SizedBox(width: itemW, child: a),
                                const SizedBox(width: 12),
                                SizedBox(width: itemW, child: b),
                                const SizedBox(width: 12),
                                SizedBox(width: itemW, child: c),
                              ],
                            );
                          }

                          Widget row2(Widget a, Widget b) {
                            if (cols == 1) {
                              return Column(
                                children: [a, const SizedBox(height: 12), b],
                              );
                            }
                            if (cols == 2) {
                              return Row(
                                children: [
                                  SizedBox(width: itemW, child: a),
                                  const SizedBox(width: 12),
                                  SizedBox(width: itemW, child: b),
                                ],
                              );
                            }
                            // 3-column layout: keep two fields aligned to grid
                            return Row(
                              children: [
                                SizedBox(width: itemW, child: a),
                                const SizedBox(width: 12),
                                SizedBox(width: itemW, child: b),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: itemW,
                                  child: const SizedBox.shrink(),
                                ),
                              ],
                            );
                          }

                          final name = _FieldBlock(
                            label: 'PERMISSION NAME :',
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: active.nameController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: _fieldDecoration(isMobile),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Permission name is required'
                                  : null,
                            ),
                          );
                          final key = _FieldBlock(
                            label: 'PERMISSION KEY :',
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: active.permissionKeyController,
                              decoration: _fieldDecoration(isMobile),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Permission key is required'
                                  : null,
                            ),
                          );
                          final menu = _FieldBlock(
                            label: 'MENU (OPTIONAL)',
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: active.menuController,
                              decoration: _fieldDecoration(isMobile),
                            ),
                          );
                          final subMenu = _FieldBlock(
                            label: 'SUB-MENU (OPTIONAL)',
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: active.subMenuController,
                              decoration: _fieldDecoration(isMobile),
                            ),
                          );
                          final type = _FieldBlock(
                            label: 'TYPE :',
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: active.typeController,
                              decoration: _fieldDecoration(isMobile),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Type is required'
                                  : null,
                            ),
                          );
                          final tab = _FieldBlock(
                            label: 'TAB (OPTIONAL)',
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: active.tabController,
                              decoration: _fieldDecoration(isMobile),
                            ),
                          );
                          final desc = _FieldBlock(
                            label: 'DESCRIPTION (OPTIONAL)',
                            isMobile: isMobile,
                            child: TextFormField(
                              controller: active.descriptionController,
                              maxLines: 2,
                              decoration: _fieldDecoration(isMobile),
                            ),
                          );

                          return Column(
                            children: [
                              row3(name, key, const SizedBox.shrink()),
                              const SizedBox(height: 12),
                              row2(menu, subMenu),
                              const SizedBox(height: 12),
                              row2(type, tab),
                              const SizedBox(height: 12),
                              desc,
                            ],
                          );
                            },
                          ),
                        ),
                      );
                    }),
                    Obx(
                      () => active.errorMessage.value.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(
                                top: 12,
                                bottom: 12,
                              ),
                              child: Text(
                                active.errorMessage.value,
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 16),
                    if (isEdit)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          saveButton(
                            onPressed: active.submitUpdatePermission,
                            isLoading: active.isSaving,
                            text: 'UPDATE',
                            width: isMobile ? null : 160,
                            height: 42,
                            isFullWidth: isMobile,
                          ),
                          if (!isMobile) ...[
                            const SizedBox(width: 16),
                            cancelButton(
                              onPressed: active.resetForm,
                              text: 'CANCEL',
                              width: 160,
                              height: 42,
                            ),
                          ],
                        ],
                      )
                    else
                      Align(
                        alignment: Alignment.center,
                        child: saveButton(
                          onPressed: active.submitCreatePermission,
                          isLoading: active.isSaving,
                          text: 'SAVE',
                          width: isMobile ? null : 160,
                          height: 42,
                          isFullWidth: isMobile,
                        ),
                      ),
                    if (isEdit && isMobile) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.center,
                        child: cancelButton(
                          onPressed: active.resetForm,
                          text: 'CANCEL',
                          width: isMobile ? null : 160,
                          height: 42,
                          isFullWidth: true,
                        ),
                      ),
                    ],
                  ],
                );
              }),
            ),
          );
        }

        Widget permissionsList({required bool scrollable}) {
          final header = Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Existing permissions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          );

          final content = Obx(() {
            if (controller.permissions.isEmpty) {
              return Center(
                child: Text(
                  'No permissions yet.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              );
            }

            final tiles = controller.permissions.map((p) {
              final hasId = p.id != null;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  isThreeLine: true,
                  title: Text(
                    p.permissionName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: _permissionSubtitle(context, p),
                  trailing: hasId
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => controller.startEdit(p),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline),
                              color: Colors.red[700],
                              onPressed: () =>
                                  controller.confirmDeletePermission(p),
                            ),
                          ],
                        )
                      : null,
                ),
              );
            }).toList();

            if (scrollable) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: tiles,
              );
            }
            return Column(children: tiles);
          });

          if (!scrollable) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [header, content],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              Expanded(child: content),
            ],
          );
        }

        if (isWide) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: formCard(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(flex: 6, child: permissionsList(scrollable: true)),
              ],
            ),
          );
        }

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          children: [
            formCard(),
            const SizedBox(height: 24),
            permissionsList(scrollable: false),
          ],
        );
      },
    );
  }
}

class _AssignPermissionTab extends StatelessWidget {
  final bool isMobile;
  const _AssignPermissionTab({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final controller = _activeSettingsController();
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ASSIGN PERMISSIONS',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 14 : 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Obx(() {
                  if (controller.isLoadingUserTypes.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return DropdownButtonFormField<int>(
                    key: ValueKey(controller.selectedUserTypeId.value),
                    initialValue: controller.selectedUserTypeId.value,
                    decoration: _dropdownDecoration(
                      isMobile,
                    ).copyWith(labelText: 'Select Role'),
                    items: controller.userTypes
                        .map(
                          (ut) => DropdownMenuItem<int>(
                            value: ut.id,
                            child: Text(ut.typeName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) controller.selectUserType(v);
                    },
                  );
                }),
                const SizedBox(height: 12),
                Obx(() {
                  if (controller.selectedUserTypeId.value == null) {
                    return Text(
                      'Select a role to assign permissions.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                    );
                  }
                  final grouped = controller.groupedPermissionsByMenu;
                  return Column(
                    children: grouped.entries.map((e) {
                      final menu = e.key.trim();
                      final list = e.value;
                      final showHeader = menu.isNotEmpty;
                      final idsInGroup = list
                          .map((p) => p.id ?? -1)
                          .where((id) => id > 0)
                          .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showHeader) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      menu,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Transform.scale(
                                    scale: 0.82,
                                    child: Switch(
                                      value:
                                          idsInGroup.isNotEmpty &&
                                          idsInGroup.every(
                                            controller
                                                .assignedPermissionIds
                                                .contains,
                                          ),
                                      onChanged: idsInGroup.isEmpty
                                          ? null
                                          : (v) => controller
                                                .setAssignedForPermissions(
                                                  idsInGroup,
                                                  v,
                                                ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          ...list.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final p = entry.value;
                            final id = p.id ?? -1;
                            final enabled = controller.assignedPermissionIds
                                .contains(id);

                            return Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: (idx == list.length - 1)
                                        ? Colors.transparent
                                        : Colors.grey[200]!,
                                  ),
                                ),
                              ),
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 2,
                                ),
                                leading: Transform.scale(
                                  scale: 0.82,
                                  child: Switch(
                                    value: enabled,
                                    onChanged: (v) =>
                                        controller.toggleAssigned(id, v),
                                  ),
                                ),
                                title: Text(
                                  p.permissionName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                        ],
                      );
                    }).toList(),
                  );
                }),
                const SizedBox(height: 16),
                Obx(() {
                  if (controller.selectedUserTypeId.value == null) {
                    return const SizedBox.shrink();
                  }
                  return Align(
                    alignment: Alignment.center,
                    child: saveButton(
                      onPressed: controller.saveAssignedPermissions,
                      isLoading: controller.isAssignSaving,
                      text: 'SAVE',
                      width: isMobile ? null : 160,
                      height: 42,
                      isFullWidth: isMobile,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldBlock extends StatelessWidget {
  final String label;
  final bool isMobile;
  final Widget child;
  const _FieldBlock({
    required this.label,
    required this.isMobile,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

InputDecoration _fieldDecoration(bool isMobile) {
  return InputDecoration(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding: EdgeInsets.symmetric(
      horizontal: isMobile ? 12 : 16,
      vertical: 12,
    ),
    filled: true,
    fillColor: Colors.white,
  );
}

InputDecoration _dropdownDecoration(bool isMobile) {
  return InputDecoration(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding: EdgeInsets.symmetric(
      horizontal: isMobile ? 12 : 16,
      vertical: 12,
    ),
    isDense: isMobile,
    filled: true,
    fillColor: Colors.white,
  );
}
