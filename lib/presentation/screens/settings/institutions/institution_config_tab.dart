import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../controllers/institution_config_controller.dart';
import '../../../widgets/form_title.dart';

class InstitutionConfigTab extends StatefulWidget {
  const InstitutionConfigTab({super.key});

  @override
  State<InstitutionConfigTab> createState() => _InstitutionConfigTabState();
}

class _InstitutionConfigTabState extends State<InstitutionConfigTab> {
  @override
  void initState() {
    super.initState();
    Get.put(InstitutionConfigController(), permanent: false);
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<InstitutionConfigController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildInnerTabs(isMobile),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _TypesTab(controller: c),
                _CategoriesTab(controller: c),
              ],
            ),
          ),
        ],
      ),
    );
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
              child: Text('Types'),
            ),
          ),
          Tab(
            height: isMobile ? 30 : 34,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text('Categories'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypesTab extends StatelessWidget {
  final InstitutionConfigController controller;
  const _TypesTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final listCard = Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormTitle(
              text: 'Institution Types',
              isMobile: isMobile,
              isTablet: false,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(() {
                if (controller.isLoadingTypes.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ReorderableListView.builder(
                  itemCount: controller.types.length,
                  onReorder: controller.reorderTypes,
                  itemBuilder: (context, index) {
                    final t = controller.types[index];
                    return ListTile(
                      key: ValueKey('type_${t.id}'),
                      title: Text(t.displayName),
                      subtitle: Text(t.typeName),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit),
                            onPressed: () => controller.startEditType(t),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Delete type'),
                                  content: Text('Delete "${t.displayName}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                await controller.deleteType(t.id);
                              }
                            },
                          ),
                          const Icon(Icons.drag_handle),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );

    final formCard = _TypeForm(controller: controller);

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: isMobile
          ? SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 360, child: listCard),
                  const SizedBox(height: 12),
                  formCard,
                ],
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: listCard),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: formCard),
              ],
            ),
    );
  }
}

class _TypeForm extends StatelessWidget {
  final InstitutionConfigController controller;
  const _TypeForm({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(() {
                final screenWidth = MediaQuery.of(context).size.width;
                final isMobile = screenWidth < 600;
                return FormTitle(
                  text: controller.editingTypeId.value == null
                      ? 'Create Type'
                      : 'Edit Type',
                  isMobile: isMobile,
                  isTablet: false,
                );
              }),
              const SizedBox(height: 12),
              TextField(
                controller: controller.typeDisplayNameController,
                decoration: const InputDecoration(labelText: 'Display Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller.typeNameController,
                decoration: const InputDecoration(
                  labelText: 'Type Key (e.g. GOVT_SCHOOL)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller.typeDescriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: controller.startCreateType,
                    child: const Text('Clear'),
                  ),
                  const SizedBox(width: 10),
                  Obx(() {
                    final isEdit = controller.editingTypeId.value != null;
                    return ElevatedButton(
                      onPressed: controller.saveType,
                      child: Text(isEdit ? 'Update' : 'Save'),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoriesTab extends StatelessWidget {
  final InstitutionConfigController controller;
  const _CategoriesTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final listCard = Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormTitle(text: 'Categories', isMobile: isMobile, isTablet: false),
            const SizedBox(height: 10),
            Obx(() {
              final types = controller.types;
              return DropdownButtonFormField<int>(
                value: controller.selectedTypeId.value,
                items: types
                    .map(
                      (t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(t.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (v) => controller.selectType(v),
                decoration: const InputDecoration(
                  labelText: 'Institution Type',
                ),
              );
            }),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(() {
                if (controller.isLoadingCategories.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ReorderableListView.builder(
                  itemCount: controller.categories.length,
                  onReorder: controller.reorderCategories,
                  itemBuilder: (context, index) {
                    final cat = controller.categories[index];
                    return ListTile(
                      key: ValueKey('cat_${cat.id}'),
                      title: Text(cat.displayName),
                      subtitle: Text(cat.categoryName),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit),
                            onPressed: () => controller.startEditCategory(cat),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Delete category'),
                                  content: Text('Delete "${cat.displayName}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                await controller.deleteCategory(cat.id);
                              }
                            },
                          ),
                          const Icon(Icons.drag_handle),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );

    final formCard = _CategoryForm(controller: controller);

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: isMobile
          ? SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 420, child: listCard),
                  const SizedBox(height: 12),
                  formCard,
                ],
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: listCard),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: formCard),
              ],
            ),
    );
  }
}

class _CategoryForm extends StatelessWidget {
  final InstitutionConfigController controller;
  const _CategoryForm({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(() {
                final screenWidth = MediaQuery.of(context).size.width;
                final isMobile = screenWidth < 600;
                return FormTitle(
                  text: controller.editingCategoryId.value == null
                      ? 'Create Category'
                      : 'Edit Category',
                  isMobile: isMobile,
                  isTablet: false,
                );
              }),
              const SizedBox(height: 12),
              TextField(
                controller: controller.categoryDisplayNameController,
                decoration: const InputDecoration(labelText: 'Display Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller.categoryNameController,
                decoration: const InputDecoration(labelText: 'Category Key'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller.categoryDescriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: controller.startCreateCategory,
                    child: const Text('Clear'),
                  ),
                  const SizedBox(width: 10),
                  Obx(() {
                    final isEdit = controller.editingCategoryId.value != null;
                    return ElevatedButton(
                      onPressed: controller.saveCategory,
                      child: Text(isEdit ? 'Update' : 'Save'),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
