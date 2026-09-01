import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/master_record_model.dart';
import '../../../../data/repositories/masters_repository.dart';
import '../../../controllers/masters_settings_controller.dart';
import '../../../widgets/form_title.dart';
import '../../../widgets/pinned_scroll_views.dart';

class MastersTab extends StatefulWidget {
  const MastersTab({super.key});

  @override
  State<MastersTab> createState() => _MastersTabState();
}

class _MastersTabState extends State<MastersTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static final _tabTypes = [
    MasterTableType.categories,
    MasterTableType.stages,
    MasterTableType.prizes,
  ];

  @override
  void initState() {
    super.initState();
    Get.put(MastersSettingsController(), permanent: false);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (!Get.isRegistered<MastersSettingsController>()) return;
    final controller = Get.find<MastersSettingsController>();
    controller.clearForm(_tabTypes[_tabController.index]);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    if (Get.isRegistered<MastersSettingsController>()) {
      Get.delete<MastersSettingsController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Column(
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
            controller: _tabController,
            children: [
              MasterTablePanel(
                type: MasterTableType.categories,
                title: 'Categories',
              ),
              MasterTablePanel(
                type: MasterTableType.stages,
                title: 'Stages',
              ),
              MasterTablePanel(
                type: MasterTableType.prizes,
                title: 'Prizes',
              ),
            ],
          ),
        ),
      ],
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
        controller: _tabController,
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
        tabs: const [
          Tab(
            height: 34,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text('Categories'),
            ),
          ),
          Tab(
            height: 34,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text('Stages'),
            ),
          ),
          Tab(
            height: 34,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text('Prizes'),
            ),
          ),
        ],
      ),
    );
  }
}

class MasterTablePanel extends StatelessWidget {
  final MasterTableType type;
  final String title;

  const MasterTablePanel({
    super.key,
    required this.type,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MastersSettingsController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return RefreshIndicator(
      onRefresh: () => controller.reload(type),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = !isMobile && constraints.maxWidth >= 1100;

          final formCard = _MasterForm(type: type, title: title);
          final listCard = _MasterList(type: type, title: title);

          return Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: formCard),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: SizedBox(height: 520, child: listCard)),
                    ],
                  )
                : PinnedVerticalScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        formCard,
                        const SizedBox(height: 12),
                        SizedBox(height: 420, child: listCard),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _MasterForm extends StatelessWidget {
  final MasterTableType type;
  final String title;

  const _MasterForm({required this.type, required this.title});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MastersSettingsController>();
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          final isEdit = controller.isEditing(type);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? 'EDIT $title'.toUpperCase() : 'CREATE $title'.toUpperCase(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 14 : 16,
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(height: isMobile ? 16 : 20),
              TextField(
                controller: controller.nameController,
                decoration: const InputDecoration(labelText: 'NAME'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'DESCRIPTION (OPTIONAL)',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isEdit)
                    TextButton(
                      onPressed: () => controller.startCreate(type),
                      child: const Text('Cancel'),
                    ),
                  if (isEdit) const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => controller.save(type),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 42),
                    ),
                    child: Text(isEdit ? 'UPDATE' : 'SAVE'),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _MasterList extends StatelessWidget {
  final MasterTableType type;
  final String title;

  const _MasterList({required this.type, required this.title});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MastersSettingsController>();
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormTitle(text: 'Existing $title', isMobile: isMobile, isTablet: false),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(() {
                if (controller.loadingFor(type).value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = controller.listFor(type);
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'No $title found.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _MasterListTile(type: type, item: item);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _MasterListTile extends StatelessWidget {
  final MasterTableType type;
  final MasterRecordModel item;

  const _MasterListTile({required this.type, required this.item});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MastersSettingsController>();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text(
        item.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: item.subtitle.isNotEmpty ? Text(item.subtitle) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit),
            onPressed: () => controller.startEdit(type, item),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text('Delete ${item.name}?'),
                  content: const Text('This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await controller.delete(type, item);
              }
            },
          ),
        ],
      ),
    );
  }
}
