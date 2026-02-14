import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/jury_scoring_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/custom_loader.dart';

class JuryScoringScreen extends StatelessWidget {
  const JuryScoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(JuryScoringController());
    final authController = Get.find<AuthController>();
    final roleName =
        authController.currentUser.value?.roleName.toUpperCase() ?? '';
    final isJury = roleName.contains('JURY');
    final isJudge = roleName.contains('JUDGE');
    final isJuryOrJudge = isJury || isJudge;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    // Show without sidebar for jury and judge users
    final content = Scaffold(
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
                      SizedBox(height: isMobile ? 5 : 20),

                      // Queue Status and Refresh Button
                      _buildQueueAndRefreshSection(
                        controller,
                        isMobile,
                        isTablet,
                      ),
                      SizedBox(height: isMobile ? 5 : 24),

                      // Participants Display with Scoring Inputs
                      _buildParticipantsSection(controller, isMobile, isTablet),
                      SizedBox(height: isMobile ? 10 : 24),

                      // Submit Button
                      _buildSubmitButton(
                        context,
                        controller,
                        isMobile,
                        isTablet,
                      ),

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

    // If jury or judge, return content directly without sidebar
    if (isJuryOrJudge) {
      return content;
    }

    // If admin, wrap with sidebar layout (optional - can add AdminSidebarLayout if needed)
    return content;
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
              Padding(
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
                        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 13 : 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value.isEmpty ? null : value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: value.isNotEmpty
                    ? AppTheme.primaryColor
                    : Colors.grey[300]!,
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
              vertical: 14,
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
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: isMobile ? 14 : 15,
            ),
          ),
          style: TextStyle(
            fontSize: isMobile ? 14 : 15,
            color: Colors.grey[800],
          ),
          icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
        ),
      ],
    );
  }

  Widget _buildQueueAndRefreshSection(
    JuryScoringController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Queue Status and Asana Number
        Obx(
          () => Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[50]!, Colors.blue[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue[200]!, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue[100]!.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.queue, color: Colors.blue[800], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'IN QUEUE : ${controller.queueCount.value}',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (controller.currentParticipants.isNotEmpty) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.1),
                        AppTheme.primaryColor.withOpacity(0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fitness_center,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ASANA ${controller.currentAsanaNumber.value}',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // Refresh Button
        Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => controller.refreshAndReallocate(),
            icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
            tooltip: 'Refresh and Reallocate',
            padding: const EdgeInsets.all(12),
          ),
        ),
      ],
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // A, B, C Label - Above the gray box
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
                          const SizedBox(height: 12),
                          // Checkbox, Code, and Name
                          Row(
                            children: [
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
                              const SizedBox(width: 12),
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
                                  participant.participantCode ?? 'N/A',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  participant.participantName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Scoring Input
                          TextFormField(
                            controller:
                                controller.scoreControllers[participantId],
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Score',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppTheme.primaryColor,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // A, B, C Label - Above the gray box
                            Center(
                              child: Container(
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
                            ),
                            const SizedBox(height: 16),
                            // Checkbox, Code, and Name
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
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
                                    participant.participantCode ?? 'N/A',
                                    style: TextStyle(
                                      fontSize: isTablet ? 12 : 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    participant.participantName,
                                    style: TextStyle(
                                      fontSize: isTablet ? 12 : 13,
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Scoring Input
                            TextFormField(
                              controller:
                                  controller.scoreControllers[participantId],
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Score',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
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
      child: SizedBox(
        width: isMobile ? double.infinity : (isTablet ? 320 : 420),
        height: 56,
        child: ElevatedButton(
          onPressed: controller.isLoading.value
              ? null
              : () => controller.submitScores(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            shadowColor: AppTheme.primaryColor.withOpacity(0.4),
          ),
          child: controller.isLoading.value
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
      ),
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
}
