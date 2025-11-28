import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/judge_model.dart';
import '../../controllers/judge_controller.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/custom_loader.dart';
import '../../widgets/app_dialog.dart';

class JudgeManagementScreen extends StatelessWidget {
  const JudgeManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final judgeController = Get.find<JudgeController>();
    // Load judges if list is empty (first time visit)
    if (judgeController.judges.isEmpty && !judgeController.isLoading.value) {
      judgeController.loadJudges();
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.05),
              Colors.white,
              AppTheme.secondaryColor.withOpacity(0.03),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Back Button
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () => context.pop(),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.gavel, color: AppTheme.primaryColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Judge Management',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                          ),
                          Obx(
                            () => Text(
                              '${judgeController.judges.length} Judges',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Search Bar
                    if (!isMobile)
                      Container(
                        width: 250,
                        height: 40,
                        margin: const EdgeInsets.only(right: 12),
                        child: TextField(
                          onChanged: (value) =>
                              judgeController.searchQuery.value = value,
                          decoration: InputDecoration(
                            hintText: 'Search judges...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    // Responsive Create Button
                    PrimaryButton(
                      text: isMobile ? ' ' : 'Create',
                      icon: Icons.add,
                      onPressed: () {
                        debugPrint('Create button pressed');
                        _showJudgeForm(context, judgeController);
                      },
                    ),
                  ],
                ),
              ),
              // Search Bar for Mobile
              if (isMobile)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: TextField(
                    onChanged: (value) =>
                        judgeController.searchQuery.value = value,
                    decoration: InputDecoration(
                      hintText: 'Search judges...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              // Body Section
              Expanded(
                child: Obx(() {
                  if (judgeController.isLoading.value) {
                    return const CustomLoader(message: 'Loading judges...');
                  }

                  final filteredJudges = judgeController.filteredJudges;

                  if (filteredJudges.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.gavel_outlined,
                                size: 64,
                                color: AppTheme.primaryColor.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              judgeController.searchQuery.value.isNotEmpty
                                  ? 'No Judges Found'
                                  : 'No Judges Found',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              judgeController.searchQuery.value.isNotEmpty
                                  ? 'Try adjusting your search'
                                  : 'Create your first judge to get started',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                            if (judgeController.searchQuery.value.isEmpty) ...[
                              const SizedBox(height: 32),
                              PrimaryButton(
                                text: 'Create Judge',
                                icon: Icons.add,
                                onPressed: () =>
                                    _showJudgeForm(context, judgeController),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => judgeController.loadJudges(),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = isMobile
                            ? 1
                            : isTablet
                            ? 2
                            : 5;
                        final padding = isMobile ? 16.0 : 24.0;

                        return GridView.builder(
                          padding: EdgeInsets.all(padding),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: isMobile ? 1.0 : 1,
                              ),
                          itemCount: filteredJudges.length,
                          itemBuilder: (context, index) {
                            final judge = filteredJudges[index];
                            return _buildJudgeCard(
                              context,
                              judge,
                              judgeController,
                            );
                          },
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJudgeCard(
    BuildContext context,
    JudgeModel judge,
    JudgeController controller,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showJudgeForm(context, controller, judge: judge),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, AppTheme.primaryColor.withOpacity(0.02)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and menu
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.gavel,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton(
                      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(
                                Icons.edit,
                                size: 20,
                                color: AppTheme.primaryColor,
                              ),
                              SizedBox(width: 12),
                              Text('Edit'),
                            ],
                          ),
                          onTap: () => Future.delayed(
                            const Duration(milliseconds: 100),
                            () => _showJudgeForm(
                              context,
                              controller,
                              judge: judge,
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 12),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                          onTap: () => Future.delayed(
                            const Duration(milliseconds: 100),
                            () =>
                                _confirmDelete(context, controller, judge.id!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Name
                Text(
                  judge.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Designation
                Row(
                  children: [
                    Icon(Icons.work_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        judge.designation,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Username
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        judge.username,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (judge.email != null && judge.email!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  // Email
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          judge.email!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        judge.address,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showJudgeForm(
    BuildContext context,
    JudgeController controller, {
    JudgeModel? judge,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final dialogWidth = isMobile
        ? screenWidth * 0.95
        : isTablet
        ? 600.0
        : 700.0;

    // Initialize form in controller
    controller.errorMessage.value = ''; // Clear any previous errors
    if (judge != null) {
      controller.initializeFormForEdit(judge);
    } else {
      controller.resetForm();
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Obx(
                      () => Icon(
                        controller.isEditMode ? Icons.edit : Icons.add_circle,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(
                        () => Text(
                          controller.isEditMode ? 'Edit Judge' : 'Create Judge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Form Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Name
                      TextField(
                        controller: controller.nameController,
                        decoration: InputDecoration(
                          labelText: 'Name *',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Designation
                      TextField(
                        controller: controller.designationController,
                        decoration: InputDecoration(
                          labelText: 'Designation *',
                          prefixIcon: const Icon(Icons.work),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Username
                      TextField(
                        controller: controller.usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username *',
                          prefixIcon: const Icon(Icons.account_circle),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Email
                      TextField(
                        controller: controller.emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Address
                      TextField(
                        controller: controller.addressController,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      // Password (only for new judges or when editing)
                      Obx(
                        () => TextField(
                          controller: controller.passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: controller.isEditMode
                                ? 'New Password (leave empty to keep current)'
                                : 'Password *',
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Confirm Password
                      Obx(
                        () => TextField(
                          controller: controller.confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: controller.isEditMode
                                ? 'Confirm New Password'
                                : 'Confirm Password *',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Error Message Display
                      Obx(
                        () => controller.errorMessage.value.isNotEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                margin: const EdgeInsets.only(bottom: 8),
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
                                        controller.errorMessage.value,
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
                    ],
                  ),
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        controller.resetForm();
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    Obx(
                      () => PrimaryButton(
                        text: controller.isEditMode ? 'Update' : 'Create',
                        onPressedAsync: () async {
                          final success = await controller.submitForm();
                          if (success && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        width: 120,
                        height: 44,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    JudgeController controller,
    String judgeId,
  ) {
    AppDialog.show(
      context,
      title: 'Delete Judge',
      message: 'Are you sure you want to delete this judge?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
      onConfirm: () {
        controller.deleteJudge(judgeId);
        Navigator.pop(context);
      },
    );
  }
}
