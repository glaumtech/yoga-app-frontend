import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/jury_scoring_controller.dart';
import '../../controllers/user_management_controller.dart';
import '../../widgets/custom_loader.dart';
import '../../../routes/app_routes.dart';

class JuryScoringScreen extends StatelessWidget {
  const JuryScoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(JuryScoringController(), permanent: false);

    // Always reset and load data when screen is built (ensures fresh data for new user)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.resetAndLoadData();
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        title: Text(
          'SCORING SCREEN',
          style: TextStyle(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              // Show confirmation dialog
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true && context.mounted) {
                try {
                  // Logout from user management controller
                  try {
                    if (Get.isRegistered<UserManagementController>()) {
                      final userController =
                          Get.find<UserManagementController>();
                      await userController.logout();
                    }
                  } catch (e) {
                    // UserManagementController might not be registered, ignore
                  }

                  // Navigate to login screen
                  if (context.mounted) {
                    context.go(AppRoutes.login);
                  }
                } catch (e) {
                  // Show error if logout fails
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error during logout: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(
          () => controller.isLoading.value
              ? const Center(child: CustomLoader())
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selection Links Section
                      _buildSelectionSection(
                        context,
                        controller,
                        isMobile,
                        isTablet,
                      ),
                      SizedBox(height: isMobile ? 5 : 24),

                      // Participants Display with Scoring Inputs
                      _buildParticipantsSection(controller, isMobile, isTablet),

                      // Submit Button - Only show when participants are available
                      Obx(() {
                        if (controller.currentParticipants.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          children: [
                            SizedBox(height: isMobile ? 10 : 24),
                            _buildSubmitButton(
                              context,
                              controller,
                              isMobile,
                              isTablet,
                            ),
                          ],
                        );
                      }),

                      // Pending Juries Note
                      if (controller.getPendingJuries().isNotEmpty) ...[
                        SizedBox(height: isMobile ? 10 : 20),
                        _buildPendingJuriesNote(controller),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSelectionSection(
    BuildContext context,
    JuryScoringController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Obx(() {
      final isExpanded = controller.isSelectionExpanded.value;

      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            // Collapsed Header - Always Visible
            InkWell(
              onTap: () => controller.toggleSelectionExpanded(),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Container(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      color: AppTheme.primaryColor,
                      size: isMobile ? 20 : 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SELECT',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (!isExpanded) ...[
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (controller.selectedStage.value.isNotEmpty)
                                  _buildSelectionChip(
                                    'STAGE: ${controller.selectedStage.value}',
                                    isMobile,
                                  ),
                                if (controller
                                    .selectedCategory
                                    .value
                                    .isNotEmpty)
                                  _buildSelectionChip(
                                    'CATEGORY: ${controller.selectedCategory.value}',
                                    isMobile,
                                  ),
                                if (controller.selectedGroup.value.isNotEmpty)
                                  _buildSelectionChip(
                                    'GROUP: ${controller.selectedGroup.value}',
                                    isMobile,
                                  ),
                                if (controller.selectedStage.value.isEmpty &&
                                    controller.selectedCategory.value.isEmpty &&
                                    controller.selectedGroup.value.isEmpty)
                                  Text(
                                    'Tap to select filters',
                                    style: TextStyle(
                                      fontSize: isMobile ? 11 : 12,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppTheme.primaryColor,
                      size: isMobile ? 24 : 28,
                    ),
                  ],
                ),
              ),
            ),
            // Expanded Content - Dropdowns
            if (isExpanded)
              Obx(
                () => Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  child: isMobile
                      ? Column(
                          children: [
                            _buildSelectionDropdown(
                              context,
                              label: 'STAGE',
                              value: controller.selectedStage.value,
                              items: controller.getAvailableStages(),
                              onChanged: (value) =>
                                  controller.setSelectedStage(value ?? ''),
                              isMobile: isMobile,
                              isTablet: isTablet,
                            ),
                            const SizedBox(height: 12),
                            _buildSelectionDropdown(
                              context,
                              label: 'CATEGORY',
                              value: controller.selectedCategory.value,
                              items: controller.getAvailableCategories(),
                              onChanged: (value) =>
                                  controller.setSelectedCategory(value ?? ''),
                              isMobile: isMobile,
                              isTablet: isTablet,
                            ),
                            const SizedBox(height: 12),
                            _buildSelectionDropdown(
                              context,
                              label: 'GROUPS',
                              value: controller.selectedGroup.value,
                              items: controller.getAvailableGroups(),
                              onChanged: (value) =>
                                  controller.setSelectedGroup(value ?? ''),
                              isMobile: isMobile,
                              isTablet: isTablet,
                            ),
                            const SizedBox(height: 12),
                            // Search and Refresh buttons side by side
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSearchButton(
                                    controller,
                                    isMobile,
                                    isTablet,
                                  ),
                                ),
                                SizedBox(width: isMobile ? 12 : 16),
                                _buildRefreshButton(
                                  controller,
                                  isMobile,
                                  isTablet,
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _buildSelectionDropdown(
                                context,
                                label: 'STAGE',
                                value: controller.selectedStage.value,
                                items: controller.getAvailableStages(),
                                onChanged: (value) =>
                                    controller.setSelectedStage(value ?? ''),
                                isMobile: isMobile,
                                isTablet: isTablet,
                              ),
                            ),
                            SizedBox(width: isTablet ? 16 : 20),
                            Expanded(
                              child: _buildSelectionDropdown(
                                context,
                                label: 'CATEGORY',
                                value: controller.selectedCategory.value,
                                items: controller.getAvailableCategories(),
                                onChanged: (value) =>
                                    controller.setSelectedCategory(value ?? ''),
                                isMobile: isMobile,
                                isTablet: isTablet,
                              ),
                            ),
                            SizedBox(width: isTablet ? 16 : 20),
                            Expanded(
                              child: _buildSelectionDropdown(
                                context,
                                label: 'GROUPS',
                                value: controller.selectedGroup.value,
                                items: controller.getAvailableGroups(),
                                onChanged: (value) =>
                                    controller.setSelectedGroup(value ?? ''),
                                isMobile: isMobile,
                                isTablet: isTablet,
                              ),
                            ),
                            SizedBox(width: isTablet ? 16 : 20),
                            _buildSearchButton(controller, isMobile, isTablet),
                            SizedBox(width: isTablet ? 12 : 16),
                            _buildRefreshButton(controller, isMobile, isTablet),
                          ],
                        ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildSelectionChip(String label, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: isMobile ? 11 : 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSelectionDropdown(
    BuildContext context, {
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isMobile,
    required bool isTablet,
  }) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: isMobile ? 14 : 15,
          color: Colors.grey[600],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: value.isNotEmpty ? AppTheme.primaryColor : Colors.grey[300]!,
            width: value.isNotEmpty ? 2 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              color: Colors.grey[800],
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      hint: Text(
        'Select $label',
        style: TextStyle(color: Colors.grey[500], fontSize: isMobile ? 14 : 15),
      ),
      style: TextStyle(fontSize: isMobile ? 14 : 15, color: Colors.grey[800]),
      icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
    );
  }

  Widget _buildSearchButton(
    JuryScoringController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Container(
      height: isMobile ? 56 : 56,
      width: isMobile ? double.infinity : 56,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: controller.isLoading.value
            ? null
            : () => controller.searchParticipants(),
        icon: controller.isLoading.value
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.search, color: Colors.white, size: 24),
        tooltip: 'Search Participants',
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildRefreshButton(
    JuryScoringController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Container(
      height: isMobile ? 56 : 56,
      width: isMobile ? 56 : 56,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: controller.isLoading.value
            ? null
            : () => controller.refreshAndReallocate(),
        icon: controller.isLoading.value
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.refresh, color: Colors.white, size: 24),
        tooltip: 'Refresh and Reallocate',
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildParticipantsSection(
    JuryScoringController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Obx(() {
      if (controller.currentParticipants.isEmpty) {
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Text(
                'No participants available. Please select Stage, Category, and Group.',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }

      // Display up to 3 participants
      final participantsToShow = controller.currentParticipants
          .take(3)
          .toList();
      final labels = ['A', 'B', 'C'];

      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: isMobile
              ? Column(
                  children: participantsToShow.asMap().entries.map((entry) {
                    final participant = entry.value;
                    final participantId = participant.id ?? '';
                    final label = labels[entry.key];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // A, B, C Label with Checkbox, Registration Number, and Name in same row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // A, B, C Label
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Checkbox
                              Checkbox(
                                value:
                                    controller
                                        .selectedParticipantCheckboxes[participantId] ??
                                    false,
                                onChanged: (value) => controller
                                    .toggleParticipantCheckbox(participantId),
                                activeColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Registration Number
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  participant.registrationNo ??
                                      participant.participantCode ??
                                      'N/A',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Participant Name on same line
                              Expanded(
                                child: Text(
                                  participant.participantName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Scoring Inputs for 5 Asanas
                          ...List.generate(JuryScoringController.numberOfAsanas, (
                            index,
                          ) {
                            final asanaNum = index + 1;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildMarkSelectionWidget(
                                controller: controller
                                    .scoreControllers[participantId]?[asanaNum],
                                label: 'ASANA $asanaNum',
                                isMobile: isMobile,
                                minMarks: controller.minimumMarks,
                                maxMarks: controller.maximumMarks,
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }).toList(),
                )
              : Row(
                  children: participantsToShow.asMap().entries.map((entry) {
                    final participant = entry.value;
                    final participantId = participant.id ?? '';

                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(
                          right: entry.key < participantsToShow.length - 1
                              ? 12
                              : 0,
                        ),
                        padding: EdgeInsets.all(isTablet ? 16 : 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // A, B, C Label with Checkbox, Registration Number, and Name in same row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // A, B, C Label
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    labels[entry.key],
                                    style: TextStyle(
                                      fontSize: isTablet ? 20 : 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Checkbox
                                Checkbox(
                                  value:
                                      controller
                                          .selectedParticipantCheckboxes[participantId] ??
                                      false,
                                  onChanged: (value) => controller
                                      .toggleParticipantCheckbox(participantId),
                                  activeColor: AppTheme.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                                const SizedBox(width: 8),
                                // Registration Number
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    participant.registrationNo ??
                                        participant.participantCode ??
                                        'N/A',
                                    style: TextStyle(
                                      fontSize: isTablet ? 12 : 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Participant Name on same line
                                Expanded(
                                  child: Text(
                                    participant.participantName,
                                    style: TextStyle(
                                      fontSize: isTablet ? 12 : 13,
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Scoring Inputs for 5 Asanas
                            ...List.generate(
                              JuryScoringController.numberOfAsanas,
                              (index) {
                                final asanaNum = index + 1;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildMarkSelectionWidget(
                                    controller: controller
                                        .scoreControllers[participantId]?[asanaNum],
                                    label: 'ASANA $asanaNum',
                                    isMobile: isMobile,
                                    isTablet: isTablet,
                                    minMarks: controller.minimumMarks,
                                    maxMarks: controller.maximumMarks,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      );
    });
  }

  Widget _buildSubmitButton(
    BuildContext context,
    JuryScoringController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Center(
      child: Obx(() {
        final isLoading = controller.isLoading.value;
        return SizedBox(
          width: isMobile ? double.infinity : (isTablet ? 320 : 420),
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () async {
                    try {
                      // Prevent multiple simultaneous submissions
                      if (!controller.isLoading.value) {
                        await controller.submitScores();
                      }
                    } catch (e, stackTrace) {
                      print('Error in submit button onPressed: $e');
                      print('Stack trace: $stackTrace');
                      // Error is already handled in submitScores, but ensure loading state is reset
                      if (controller.isLoading.value) {
                        controller.isLoading.value = false;
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.6),
              disabledForegroundColor: Colors.white.withOpacity(0.7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: isLoading ? 2 : 4,
              shadowColor: AppTheme.primaryColor.withOpacity(0.4),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'SUBMIT',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      }),
    );
  }

  Widget _buildPendingJuriesNote(JuryScoringController controller) {
    final pendingJuries = controller.getPendingJuries();
    if (pendingJuries.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange[800]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Jury ${pendingJuries.join(', ')} ${pendingJuries.length == 1 ? 'is' : 'are'} yet to submit the scores.',
              style: TextStyle(fontSize: 14, color: Colors.orange[900]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkSelectionWidget({
    required TextEditingController? controller,
    required String label,
    bool isMobile = false,
    bool isTablet = false,
    int minMarks = 0,
    int maxMarks = 100,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: isMobile ? 14 : (isTablet ? 15 : 16),
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
        hintText: 'Enter score ($minMarks - $maxMarks)',
        hintStyle: TextStyle(
          fontSize: isMobile ? 13 : 14,
          color: Colors.grey[500],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 20,
          vertical: isMobile ? 14 : 16,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      style: TextStyle(fontSize: isMobile ? 14 : 15, color: Colors.grey[800]),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return null; // Allow empty (optional field)
        }
        final score = double.tryParse(value);
        if (score == null) {
          return 'Please enter a valid number';
        }
        if (score < minMarks) {
          return 'Score must be at least $minMarks';
        }
        if (score > maxMarks) {
          return 'Score must not exceed $maxMarks';
        }
        return null;
      },
      onChanged: (value) {
        // Optional: Format the value as user types
        if (value.isNotEmpty) {
          final score = double.tryParse(value);
          if (score != null && controller != null) {
            // Validate and update if needed
            if (score < minMarks || score > maxMarks) {
              // Value is out of range, but let validator handle it
              return;
            }
          }
        }
      },
    );
  }
}
