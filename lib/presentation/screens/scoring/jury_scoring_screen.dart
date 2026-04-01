import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../controllers/jury_scoring_controller.dart';
import '../../controllers/user_management_controller.dart';
import '../../widgets/custom_loader.dart';

class JuryScoringScreen extends StatelessWidget {
  const JuryScoringScreen({super.key});

  Widget _buildScoreChip({
    required String scoreText,
    required bool isMobile,
    bool isTablet = false,
  }) {
    final hasScore = scoreText.trim().isNotEmpty;
    final display = hasScore ? scoreText.trim() : 'Not scored';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 12,
        vertical: isMobile ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: hasScore
            ? AppTheme.primaryColor.withOpacity(0.12)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: hasScore
              ? AppTheme.primaryColor.withOpacity(0.35)
              : Colors.grey[300]!,
        ),
      ),
      child: Text(
        display,
        style: TextStyle(
          fontSize: isMobile ? 13 : (isTablet ? 14 : 15),
          fontWeight: FontWeight.w800,
          color: hasScore ? AppTheme.primaryColor : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildParticipantHeaderRow({
    required String participantId,
    required String regNo,
    required String name,
    required bool checked,
    required ValueChanged<bool?> onChanged,
    required bool isMobile,
    required bool isTablet,
    required bool isCompactWidth,
    required String label,
    required String scoreText,
  }) {
    // Compact layout (mobile OR narrow widths): use 2 rows to avoid overlap.
    if (isMobile || isCompactWidth) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (participantId.isNotEmpty) ...[
                _buildParticipantAvatar(participantId, isMobile, size: 46),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey[850],
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      regNo,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: checked,
                    onChanged: onChanged,
                    activeColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _buildScoreChip(scoreText: scoreText, isMobile: true),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Tablet/Desktop: single row, no overlay (prevents overlap).
    return Row(
      children: [
        if (participantId.isNotEmpty) ...[
          _buildParticipantAvatar(
            participantId,
            isMobile,
            size: isTablet ? 48 : 56,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: isTablet ? 13 : 14,
                  color: Colors.grey[850],
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 4),
              Text(
                regNo,
                style: TextStyle(
                  fontSize: isTablet ? 11.5 : 12.5,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: checked,
              onChanged: onChanged,
              activeColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 6),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 10 : 12,
                vertical: isTablet ? 6 : 7,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _buildScoreChip(
              scoreText: scoreText,
              isMobile: isMobile,
              isTablet: isTablet,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParticipantAvatar(
    String participantId,
    bool isMobile, {
    double? size,
  }) {
    final url =
        '${BaseUrl.baseUrl}${EndPoints.participantRegistrationPhoto(participantId)}';
    final s = size ?? (isMobile ? 28.0 : 32.0);

    return ClipOval(
      child: Image.network(
        url,
        width: s,
        height: s,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: s,
          height: s,
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: Icon(
            Icons.person,
            size: isMobile ? 18 : 20,
            color: Colors.grey[600],
          ),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: s,
            height: s,
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: SizedBox(
              width: isMobile ? 16 : 18,
              height: isMobile ? 16 : 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isWeb = screenWidth >= 1024;
    final userController = Get.isRegistered<UserManagementController>()
        ? Get.find<UserManagementController>()
        : Get.put(UserManagementController());

    // Create a fresh controller per screen visit, and auto-remove it when leaving
    // so the assignments API is called every time user navigates here.
    return GetBuilder<JuryScoringController>(
      init: JuryScoringController(),
      autoRemove: true,
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: SafeArea(
            child: Obx(
              () => controller.isLoading.value
                  ? const Center(child: CustomLoader())
                  : CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          elevation: 0,
                          backgroundColor: AppTheme.primaryColor,
                          floating: true,
                          snap: true,
                          pinned: false,
                          titleSpacing: 12,
                          title: SizedBox(
                            width: double.infinity,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'SCORING SCREEN',
                                    style: TextStyle(
                                      fontSize: isMobile ? 15 : 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Obx(() {
                                    final name =
                                        (controller
                                                    .juryAssignment
                                                    .value
                                                    ?.competitionName ??
                                                '')
                                            .trim();
                                    if (name.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    return Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: isMobile ? 13 : 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    );
                                  }),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Obx(() {
                                    final u = userController.currentUser.value;
                                    final userName = (u?.name ?? '').trim();
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (userName.isNotEmpty)
                                          ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: isMobile ? 140 : 220,
                                            ),
                                            child: Text(
                                              userName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: isMobile ? 12 : 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white.withOpacity(
                                                  0.95,
                                                ),
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.logout,
                                            color: Colors.white,
                                          ),
                                          tooltip: 'Logout',
                                          onPressed: () =>
                                              controller.handleLogout(context),
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            isMobile ? 5 : (isWeb ? 32 : 5),
                            isMobile ? 5 : (isWeb ? 24 : 5),
                            isMobile ? 5 : (isWeb ? 32 : 5),
                            isMobile ? 5 : (isWeb ? 24 : 5),
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSelectionSection(
                                  context,
                                  controller,
                                  isMobile,
                                  isTablet,
                                ),
                                _buildParticipantsSection(
                                  context,
                                  controller,
                                  isMobile,
                                  isTablet,
                                ),
                                Obx(() {
                                  controller.juryAssignment.value;
                                  if (controller.currentParticipants.isEmpty) {
                                    return const SizedBox.shrink();
                                  }

                                  final readyToSubmit =
                                      controller.canSubmitScores.value;
                                  final minWhole =
                                      controller.effectiveMinimumMarks;
                                  final maxWhole =
                                      controller.effectiveMaximumMarks;
                                  return Column(
                                    children: [
                                      SizedBox(height: isMobile ? 1 : 24),
                                      Opacity(
                                        opacity: readyToSubmit ? 1.0 : 0.55,
                                        child: IgnorePointer(
                                          ignoring: !readyToSubmit,
                                          child: _buildSubmitButton(
                                            context,
                                            controller,
                                            isMobile,
                                            isTablet,
                                          ),
                                        ),
                                      ),
                                      if (!readyToSubmit) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          'Please enter scores for all 5 asanas for all participants (whole score $minWhole–$maxWhole).',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: isMobile ? 11 : 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                }),
                                if (controller
                                    .getPendingJuries()
                                    .isNotEmpty) ...[
                                  SizedBox(height: isMobile ? 10 : 20),
                                  _buildPendingJuriesNote(controller),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
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
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 20,
                  vertical: isMobile ? 10 : 16,
                ),
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
                          if (isExpanded)
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
                            const SizedBox(height: 2),
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
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 20,
                  vertical: isMobile ? 10 : 16,
                ),
                child: Obx(() {
                  final hasScores = controller.hasScoresEntered.value;
                  return isMobile
                      ? Column(
                          children: [
                            _buildSelectionDropdown(
                              context,
                              label: 'STAGE',
                              value: controller.selectedStage.value,
                              items: controller.getAvailableStages(),
                              onChanged: hasScores
                                  ? null
                                  : (value) => controller.setSelectedStage(
                                      value ?? '',
                                    ),
                              isMobile: isMobile,
                              isTablet: isTablet,
                            ),
                            const SizedBox(height: 12),
                            _buildSelectionDropdown(
                              context,
                              label: 'CATEGORY',
                              value: controller.selectedCategory.value,
                              items: controller.getAvailableCategories(),
                              onChanged: hasScores
                                  ? null
                                  : (value) => controller.setSelectedCategory(
                                      value ?? '',
                                    ),
                              isMobile: isMobile,
                              isTablet: isTablet,
                            ),
                            const SizedBox(height: 12),
                            _buildSelectionDropdown(
                              context,
                              label: 'GROUPS',
                              value: controller.selectedGroup.value,
                              items: controller.getAvailableGroups(),
                              onChanged: hasScores
                                  ? null
                                  : (value) => controller.setSelectedGroup(
                                      value ?? '',
                                    ),
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
                                onChanged: hasScores
                                    ? null
                                    : (value) => controller.setSelectedStage(
                                        value ?? '',
                                      ),
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
                                onChanged: hasScores
                                    ? null
                                    : (value) => controller.setSelectedCategory(
                                        value ?? '',
                                      ),
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
                                onChanged: hasScores
                                    ? null
                                    : (value) => controller.setSelectedGroup(
                                        value ?? '',
                                      ),
                                isMobile: isMobile,
                                isTablet: isTablet,
                              ),
                            ),
                          ],
                        );
                }),
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
    required Function(String?)? onChanged,
    required bool isMobile,
    required bool isTablet,
  }) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: isMobile ? 13 : 15,
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
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isMobile ? 12 : 16,
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
              fontSize: isMobile ? 13 : 15,
              color: Colors.grey[800],
            ),
          ),
        );
      }).toList(),
      hint: Text(
        'Select $label',
        style: TextStyle(color: Colors.grey[500], fontSize: isMobile ? 13 : 15),
      ),
      style: TextStyle(fontSize: isMobile ? 13 : 15, color: Colors.grey[800]),
      icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
    );
  }

  Widget _buildParticipantsSection(
    BuildContext context,
    JuryScoringController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Obx(() {
      final currentAsanaNum = controller.currentAsana.value;
      final hasParticipants = controller.currentParticipants.isNotEmpty;
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 8 : (isTablet ? 16 : 24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Queue info + Asana + refresh inside the participants box
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'QUEUE INFO',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${controller.remainingCount.value}',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  // Asana navigation in the middle (between queue info and refresh)
                  if (hasParticipants)
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 5),
                        padding: EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'ASANA $currentAsanaNum',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  Obx(() {
                    final hasScores = controller.hasScoresEntered.value;
                    return IconButton(
                      onPressed: (controller.isLoading.value || hasScores)
                          ? null
                          : () => controller.refreshAndReallocate(),
                      icon: controller.isLoading.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryColor,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.refresh,
                              color: hasScores
                                  ? Colors.grey[400]
                                  : AppTheme.primaryColor,
                              size: isMobile ? 20 : 22,
                            ),
                      tooltip: hasScores
                          ? 'Submit scores before refreshing'
                          : 'Refresh queue',
                    );
                  }),
                ],
              ),

              if (controller.currentParticipants.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          controller.errorMessage.value.isNotEmpty
                              ? controller.errorMessage.value
                              : 'No participants available. Please select Stage, Category, and Group.',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            color: controller.errorMessage.value.isNotEmpty
                                ? Colors.red
                                : Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (controller.errorMessage.value.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              controller.errorMessage.value = '';
                              if (controller.selectedStage.value.isNotEmpty) {
                                controller.loadParticipantsForSelection();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                _buildParticipantsContent(
                  context,
                  controller,
                  isMobile,
                  isTablet,
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildParticipantsContent(
    BuildContext context,
    JuryScoringController controller,
    bool isMobile,
    bool isTablet,
  ) {
    final labels = ['A', 'B', 'C'];

    return Obx(() {
      // Display up to 3 participants (reactive)
      final participantsToShow = controller.currentParticipants
          .take(3)
          .toList();
      final isCompactWidth = MediaQuery.of(context).size.width < 800;
      return Column(
        children: [
          SizedBox(height: 5),
          // Participants with scoring sliders for current asana
          isMobile
              ? Column(
                  children: participantsToShow.asMap().entries.map((entry) {
                    final participant = entry.value;
                    final participantId = participant.id ?? '';
                    final label = labels[entry.key];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Score row with A/B/C label beside the score
                          Obx(() {
                            controller.scoreUpdateTrigger.value;
                            final asanaNum = controller.currentAsana.value;
                            final scoreText = controller.getFormattedScore(
                              participantId,
                              asanaNum,
                            );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: _buildParticipantHeaderRow(
                                participantId: participantId,
                                regNo:
                                    (participant.registrationNo ??
                                            participant.participantCode ??
                                            'N/A')
                                        .toString(),
                                name: participant.participantName,
                                checked:
                                    controller
                                        .selectedParticipantCheckboxes[participantId] ??
                                    false,
                                onChanged: (value) => controller
                                    .toggleParticipantCheckbox(participantId),
                                isMobile: isMobile,
                                isTablet: isTablet,
                                isCompactWidth: isCompactWidth,
                                label: label,
                                scoreText: scoreText,
                              ),
                            );
                          }),
                          const SizedBox(height: 6),
                          // Score selectors (mobile: whole on first row, decimal on next row)
                          Obx(() {
                            // Listen to score update trigger to rebuild when scores change
                            controller.scoreUpdateTrigger.value;
                            controller.juryAssignment.value;
                            final asanaNum = controller.currentAsana.value;
                            final score = controller.getAsanaScore(
                              participantId,
                              asanaNum,
                            );
                            final wholeValue = score?['whole'] ?? 0;
                            final decimalValue = score?['decimal'] ?? 0;
                            final wholeOptions =
                                controller.wholeScoreValueOptions;
                            final minWhole = controller.effectiveMinimumMarks;

                            return isMobile
                                ? Column(
                                    children: [
                                      _buildScoreSlider(
                                        label: '',
                                        values: wholeOptions,
                                        currentValue: wholeValue > 0
                                            ? wholeValue
                                            : 0,
                                        onValueChanged: (value) {
                                          controller.setAsanaScore(
                                            participantId,
                                            asanaNum,
                                            value,
                                            decimalValue,
                                          );
                                        },
                                        isMobile: isMobile,
                                      ),
                                      const SizedBox(height: 6),
                                      // Decimal slider (0, 0.25, 0.5, 0.75)
                                      _buildScoreSlider(
                                        label: '',
                                        values: [0, 25, 50, 75],
                                        currentValue: decimalValue,
                                        onValueChanged: (value) {
                                          controller.setAsanaScore(
                                            participantId,
                                            asanaNum,
                                            wholeValue > 0
                                                ? wholeValue
                                                : minWhole,
                                            value,
                                          );
                                        },
                                        isMobile: isMobile,
                                        isDecimal: true,
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: _buildScoreSlider(
                                          label: '',
                                          values: wholeOptions,
                                          currentValue: wholeValue > 0
                                              ? wholeValue
                                              : 0,
                                          onValueChanged: (value) {
                                            controller.setAsanaScore(
                                              participantId,
                                              asanaNum,
                                              value,
                                              decimalValue,
                                            );
                                          },
                                          isMobile: isMobile,
                                          isTablet: isTablet,
                                        ),
                                      ),
                                      SizedBox(width: isTablet ? 12 : 16),
                                      Expanded(
                                        child: _buildScoreSlider(
                                          label: '',
                                          values: [0, 25, 50, 75],
                                          currentValue: decimalValue,
                                          onValueChanged: (value) {
                                            controller.setAsanaScore(
                                              participantId,
                                              asanaNum,
                                              wholeValue > 0
                                                  ? wholeValue
                                                  : minWhole,
                                              value,
                                            );
                                          },
                                          isMobile: isMobile,
                                          isTablet: isTablet,
                                          isDecimal: true,
                                        ),
                                      ),
                                    ],
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
                            // Score value centered above header row
                            Obx(() {
                              controller.scoreUpdateTrigger.value;
                              final asanaNum = controller.currentAsana.value;
                              final scoreText = controller.getFormattedScore(
                                participantId,
                                asanaNum,
                              );
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: _buildParticipantHeaderRow(
                                  participantId: participantId,
                                  regNo:
                                      (participant.registrationNo ??
                                              participant.participantCode ??
                                              'N/A')
                                          .toString(),
                                  name: participant.participantName,
                                  checked:
                                      controller
                                          .selectedParticipantCheckboxes[participantId] ??
                                      false,
                                  onChanged: (value) => controller
                                      .toggleParticipantCheckbox(participantId),
                                  isMobile: isMobile,
                                  isTablet: isTablet,
                                  isCompactWidth: isCompactWidth,
                                  label: labels[entry.key],
                                  scoreText: scoreText,
                                ),
                              );
                            }),
                            const SizedBox(height: 10),
                            // Score selectors (whole then decimal)
                            Obx(() {
                              controller.scoreUpdateTrigger.value;
                              controller.juryAssignment.value;
                              final asanaNum = controller.currentAsana.value;
                              final score = controller.getAsanaScore(
                                participantId,
                                asanaNum,
                              );
                              final wholeValue = score?['whole'] ?? 0;
                              final decimalValue = score?['decimal'] ?? 0;
                              final wholeOptions =
                                  controller.wholeScoreValueOptions;
                              final minWhole = controller.effectiveMinimumMarks;

                              return Column(
                                children: [
                                  _buildScoreSlider(
                                    label: '',
                                    values: wholeOptions,
                                    currentValue: wholeValue > 0
                                        ? wholeValue
                                        : 0,
                                    onValueChanged: (value) {
                                      controller.setAsanaScore(
                                        participantId,
                                        asanaNum,
                                        value,
                                        decimalValue,
                                      );
                                    },
                                    isMobile: isMobile,
                                    isTablet: isTablet,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildScoreSlider(
                                    label: '',
                                    values: [0, 25, 50, 75],
                                    currentValue: decimalValue,
                                    onValueChanged: (value) {
                                      controller.setAsanaScore(
                                        participantId,
                                        asanaNum,
                                        wholeValue > 0 ? wholeValue : minWhole,
                                        value,
                                      );
                                    },
                                    isMobile: isMobile,
                                    isTablet: isTablet,
                                    isDecimal: true,
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      );
    });
  }

  Widget _buildScoreSlider({
    required String label,
    required List<int> values,
    required int currentValue,
    required Function(int) onValueChanged,
    bool isMobile = false,
    bool isTablet = false,
    bool isDecimal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: isDecimal ? (isMobile ? 40 : 45) : (isMobile ? 50 : 60),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              final scrollController = ScrollController();

              // Scroll to selected value after build - ensure first value is visible
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (scrollController.hasClients) {
                  final selectedIndex = values.indexOf(currentValue);
                  final maxScroll = scrollController.position.maxScrollExtent;

                  if (selectedIndex >= 0) {
                    // Estimate button width including margins
                    final buttonWidth = isDecimal
                        ? (isMobile ? 46.0 : 56.0)
                        : (isMobile ? 58.0 : 72.0);

                    // Get available width for scrolling
                    final availableWidth =
                        MediaQuery.of(context).size.width *
                        (isDecimal ? 0.4 : 0.6);

                    // Calculate scroll position to show selected value
                    final buttonStartPosition = selectedIndex * buttonWidth;

                    // If selected value is beyond visible area, scroll to show it
                    if (buttonStartPosition >
                        scrollController.offset +
                            availableWidth -
                            buttonWidth) {
                      final scrollPosition =
                          buttonStartPosition - (availableWidth * 0.3);
                      scrollController.animateTo(
                        scrollPosition.clamp(0.0, maxScroll),
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                      );
                    } else if (selectedIndex == 0 &&
                        scrollController.offset > 0) {
                      scrollController.jumpTo(0);
                    }
                  } else {
                    scrollController.jumpTo(0);
                  }
                }
              });

              return Row(
                children: [
                  // Left arrow
                  IconButton(
                    onPressed: () {
                      final currentIndex = values.indexOf(currentValue);
                      if (currentIndex == -1) {
                        onValueChanged(values.first);
                      } else if (currentIndex > 0) {
                        onValueChanged(values[currentIndex - 1]);
                        // Scroll to show the new selected value
                        if (scrollController.hasClients) {
                          final buttonWidth = isDecimal
                              ? (isMobile ? 46.0 : 56.0)
                              : (isMobile ? 58.0 : 72.0);
                          final newIndex = currentIndex - 1;
                          final scrollPosition = (newIndex * buttonWidth) - 50;
                          scrollController.animateTo(
                            scrollPosition.clamp(
                              0.0,
                              scrollController.position.maxScrollExtent,
                            ),
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                          );
                        }
                      }
                    },
                    icon: Icon(
                      Icons.chevron_left,
                      color: AppTheme.primaryColor,
                      size: isDecimal ? (isMobile ? 20 : 22) : null,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  // Value buttons - Scrollable horizontally
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: values.map((value) {
                          final isSelected = value == currentValue;
                          final displayValue = isDecimal
                              ? (value == 0
                                    ? '0'
                                    : value == 25
                                    ? '0.25'
                                    : value == 50
                                    ? '0.5'
                                    : value == 75
                                    ? '0.75'
                                    : '0.$value')
                              : value.toString();
                          return InkWell(
                            key: isSelected
                                ? ValueKey('selected_$value')
                                : null,
                            onTap: () => onValueChanged(value),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: isDecimal ? 3 : 4,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: isDecimal
                                    ? (isMobile ? 8 : 10)
                                    : (isMobile ? 12 : 16),
                                vertical: isDecimal
                                    ? (isMobile ? 6 : 8)
                                    : (isMobile ? 8 : 12),
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                displayValue,
                                style: TextStyle(
                                  fontSize: isDecimal
                                      ? (isMobile ? 11 : 12)
                                      : (isMobile ? 14 : 16),
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[800],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  // Right arrow
                  IconButton(
                    onPressed: () {
                      final currentIndex = values.indexOf(currentValue);
                      if (currentIndex == -1) {
                        onValueChanged(values.first);
                      } else if (currentIndex < values.length - 1) {
                        onValueChanged(values[currentIndex + 1]);
                        // Scroll to show the new selected value
                        if (scrollController.hasClients) {
                          final buttonWidth = isDecimal
                              ? (isMobile ? 46.0 : 56.0)
                              : (isMobile ? 58.0 : 72.0);
                          final newIndex = currentIndex + 1;
                          final scrollPosition = (newIndex * buttonWidth) - 50;
                          scrollController.animateTo(
                            scrollPosition.clamp(
                              0.0,
                              scrollController.position.maxScrollExtent,
                            ),
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                          );
                        }
                      }
                    },
                    icon: Icon(
                      Icons.chevron_right,
                      color: AppTheme.primaryColor,
                      size: isDecimal ? (isMobile ? 20 : 22) : null,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
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
          height: isMobile ? 48 : 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : () => controller.submitScores(),
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
                      Icon(
                        Icons.check_circle_outline,
                        size: isMobile ? 20 : 22,
                      ),
                      SizedBox(width: isMobile ? 6 : 8),
                      Text(
                        'SUBMIT',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: isMobile ? 0.8 : 1.2,
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
      padding: const EdgeInsets.all(12),
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
              style: TextStyle(fontSize: 13, color: Colors.orange[900]),
            ),
          ),
        ],
      ),
    );
  }
}
