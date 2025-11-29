import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/scoring_controller.dart';
import '../../controllers/participant_controller.dart';
import '../../../data/models/participant_model.dart';
import '../../../data/models/judge_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class AdminScoringScreen extends StatelessWidget {
  const AdminScoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller if not already initialized
    ScoringController scoringController;
    try {
      scoringController = Get.find<ScoringController>();
    } catch (e) {
      scoringController = Get.put(ScoringController());
    }
    // Initialize participant(s) from route extra if available
    final args = GoRouterState.of(context).extra;
    if (args != null) {
      if (args is Map<String, dynamic>) {
        // Map with participants, eventId, assignedId, and optionally category
        final participantsList = args['participants'];
        final eventId = args['eventId']?.toString() ?? '';
        final assignedId = args['assignedId'];
        final category = args['category']?.toString();
        if (participantsList is List<ParticipantModel> &&
            participantsList.isNotEmpty) {
          // Always reset and reinitialize to prevent showing previous data
          scoringController.reset();
          scoringController.initializeWithParticipants(
            participantsList,
            eventId: eventId,
            assignedId: assignedId is int
                ? assignedId
                : (assignedId is String ? int.tryParse(assignedId) : null),
            category: category,
          );
        }
      } else if (args is List<ParticipantModel> && args.isNotEmpty) {
        // Multiple participants (backward compatibility)
        scoringController.reset();
        scoringController.initializeWithParticipants(args);
      } else if (args is ParticipantModel) {
        // Single participant
        scoringController.reset();
        scoringController.initializeWithParticipant(args);
      }
    } else {
      // No args provided, reset to clear any previous data
      scoringController.reset();
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Add Scores',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(
        () => scoringController.participant.value == null
            ? _buildParticipantSelection(context, scoringController)
            : LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final isMobile = screenWidth < 600;
                  final isTablet = screenWidth >= 600 && screenWidth < 1024;
                  final isDesktop = screenWidth >= 1024;

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile
                          ? 16
                          : isTablet
                          ? 24
                          : 32,
                      vertical: isMobile ? 16 : 24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isDesktop ? 1200 : double.infinity,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Participant Info Card - Redesigned
                            _buildParticipantInfoCard(
                              context,
                              scoringController,
                              isMobile,
                            ),
                            SizedBox(height: isMobile ? 16 : 20),

                            // Scoring Section - Redesigned
                            _buildScoringSection(
                              context,
                              scoringController,
                              isMobile,
                              isTablet,
                              isDesktop,
                            ),
                            SizedBox(height: isMobile ? 20 : 24),

                            // Grand Total Display - Redesigned
                            _buildGrandTotalCard(scoringController, isMobile),
                            SizedBox(height: isMobile ? 20 : 24),

                            // Save Button - Only show for last participant
                            Obx(() {
                              final isLastParticipant =
                                  !scoringController.hasNextParticipant;
                              if (isLastParticipant) {
                                return _buildSaveButton(
                                  context,
                                  scoringController,
                                  isMobile,
                                );
                              }
                              return const SizedBox.shrink();
                            }),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildParticipantInfoCard(
    BuildContext context,
    ScoringController controller,
    bool isMobile,
  ) {
    final participant = controller.participant.value!;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Row(
          children: [
            Container(
              width: isMobile ? 50 : 60,
              height: isMobile ? 50 : 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  participant.participantName[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: isMobile ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    participant.participantName,
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isMobile ? 4 : 6),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: isMobile ? 14 : 16,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: isMobile ? 4 : 4),
                      Flexible(
                        child: Text(
                          'Age: ${participant.age} | ${participant.gender}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: isMobile ? 12 : 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 2 : 4),
                  Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: isMobile ? 14 : 16,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: isMobile ? 4 : 4),
                      Flexible(
                        child: Text(
                          '${participant.standard} • ${participant.schoolName}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: isMobile ? 12 : 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Participant Navigation (if multiple participants)
            Obx(() {
              if (controller.participants.length > 1) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: controller.hasPreviousParticipant
                            ? AppTheme.primaryColor
                            : Colors.grey[400],
                        size: isMobile ? 18 : 20,
                      ),
                      onPressed: controller.hasPreviousParticipant
                          ? controller.previousParticipant
                          : null,
                      tooltip: 'Previous Participant',
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${controller.currentParticipantIndex.value + 1} / ${controller.participants.length}',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: controller.hasNextParticipant
                            ? AppTheme.primaryColor
                            : Colors.grey[400],
                        size: isMobile ? 18 : 20,
                      ),
                      onPressed: controller.hasNextParticipant
                          ? controller.nextParticipant
                          : null,
                      tooltip: 'Next Participant',
                    ),
                  ],
                );
              } else if (controller.isAdmin) {
                return IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: AppTheme.primaryColor,
                    size: isMobile ? 20 : 24,
                  ),
                  onPressed: () => controller.clearParticipant(),
                  tooltip: 'Change Participant',
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildScoringSection(
    BuildContext context,
    ScoringController controller,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 8 : 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                    ),
                    child: Icon(
                      Icons.score,
                      color: AppTheme.primaryColor,
                      size: isMobile ? 20 : 24,
                    ),
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  Text(
                    'Jury Scores',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Show judge name for judges only
              Obx(() {
                if (controller.isJudge) {
                  final judge = controller.currentJudge.value;
                  if (judge != null) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 10 : 12,
                        vertical: isMobile ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person,
                            color: AppTheme.primaryColor,
                            size: isMobile ? 16 : 18,
                          ),
                          SizedBox(width: isMobile ? 4 : 6),
                          Text(
                            judge.name,
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          // Yoga Poses (Tasks) Section
          Obx(() {
            final yogaPoses = controller.currentYogaPoses;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tasks (Yoga Poses)',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    if (yogaPoses.length < 5)
                      TextButton.icon(
                        onPressed: controller.addYogaPose,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Task'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ...yogaPoses.asMap().entries.map((entry) {
                  final index = entry.key;
                  final pose = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: pose.poseName,
                            decoration: InputDecoration(
                              labelText: 'Task Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (value) {
                              pose.poseName = value;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: pose.scoreController,
                            decoration: InputDecoration(
                              labelText: 'Score',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        if (yogaPoses.length > 1)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => controller.removeYogaPose(index),
                            tooltip: 'Remove Task',
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            );
          }),
          // Show jury scores only for admin (judges don't need "Your Score" section)
          Obx(() {
            if (controller.isAdmin) {
              return Column(
                children: [
                  SizedBox(height: isMobile ? 20 : 24),
                  // Show all jury scores for admin in responsive grid
                  if (isDesktop)
                    // Desktop: 2 columns
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 3.5,
                          ),
                      itemCount: AppConstants.juryCount,
                      itemBuilder: (context, index) {
                        final juryPosition = index + 1;
                        final judge = controller.juryJudgeMap[juryPosition];
                        return _buildJuryScoreCard(
                          context,
                          controller,
                          juryPosition,
                          judge,
                          isEditable: true,
                          showScore: true,
                          isMobile: isMobile,
                        );
                      },
                    )
                  else if (isTablet)
                    // Tablet: 2 columns
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.2,
                          ),
                      itemCount: AppConstants.juryCount,
                      itemBuilder: (context, index) {
                        final juryPosition = index + 1;
                        final judge = controller.juryJudgeMap[juryPosition];
                        return _buildJuryScoreCard(
                          context,
                          controller,
                          juryPosition,
                          judge,
                          isEditable: true,
                          showScore: true,
                          isMobile: isMobile,
                        );
                      },
                    )
                  else
                    // Mobile: Single column
                    Column(
                      children: List.generate(AppConstants.juryCount, (index) {
                        final juryPosition = index + 1;
                        final judge = controller.juryJudgeMap[juryPosition];
                        return _buildJuryScoreCard(
                          context,
                          controller,
                          juryPosition,
                          judge,
                          isEditable: true,
                          showScore: true,
                          isMobile: isMobile,
                        );
                      }),
                    ),
                ],
              );
            }
            // Judges don't see jury scores section - they only use tasks
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildJuryScoreCard(
    BuildContext context,
    ScoringController controller,
    int juryPosition,
    JudgeModel? judge, {
    bool isEditable = true,
    bool showScore = true,
    bool isMobile = false,
  }) {
    final scoreController = controller.juryScoreControllers[juryPosition];
    return Obx(() {
      final participant = controller.participant.value;
      final existingScore = participant?.juryScores?['jury$juryPosition'];

      // Admin can see all scores, judge can only see/edit their own
      final canSeeScore = controller.isAdmin;
      final canEdit =
          controller.isAdmin || (controller.isJudge && juryPosition == 1);

      return Container(
        margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
          border: Border.all(
            color: existingScore != null
                ? Colors.green.withOpacity(0.3)
                : Colors.grey[300]!,
            width: existingScore != null ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 10 : 12,
                      vertical: isMobile ? 5 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                    ),
                    child: Text(
                      controller.isJudge
                          ? 'Your Score'
                          : (judge != null
                                ? 'Jury $juryPosition: ${judge.name}'
                                : 'Jury $juryPosition'),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 12 : 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Show existing score only if admin or if it's judge's own score
                if (canSeeScore && existingScore != null) ...[
                  SizedBox(width: isMobile ? 8 : 12),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 6 : 8,
                      vertical: isMobile ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(isMobile ? 5 : 6),
                    ),
                    child: Text(
                      'Current: ${existingScore.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontSize: isMobile ? 11 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: isMobile ? 10 : 12),
            // Show editable field if user can edit this jury position
            // Admin can edit all, judge can only edit their own
            if (canEdit && scoreController != null)
              TextField(
                controller: scoreController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Enter Score',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.edit),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (_) => controller.calculateGrandTotal(),
              )
            else if (controller.isAdmin)
              // Admin view: Show existing score from other judges (read-only display)
              // This shouldn't happen since admin can edit all, but safety check
              if (existingScore != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.visibility, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Score: ${existingScore.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    'No score entered',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
          ],
        ),
      );
    });
  }

  Widget _buildGrandTotalCard(ScoringController controller, bool isMobile) {
    return Obx(
      () => Container(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'GRAND TOTAL',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 16 : 20,
                fontWeight: FontWeight.bold,
                letterSpacing: isMobile ? 0.8 : 1.2,
              ),
            ),
            Text(
              controller.grandTotal.value.toStringAsFixed(2),
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 24 : 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(
    BuildContext context,
    ScoringController controller,
    bool isMobile,
  ) {
    final participantController = Get.find<ParticipantController>();
    return Obx(
      () => SizedBox(
        height: isMobile ? 50 : 56,
        child: ElevatedButton(
          onPressed: participantController.isLoading.value
              ? null
              : () => controller.saveScores(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            ),
            elevation: 4,
          ),
          child: participantController.isLoading.value
              ? SizedBox(
                  height: isMobile ? 20 : 24,
                  width: isMobile ? 20 : 24,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.save,
                      color: Colors.white,
                      size: isMobile ? 20 : 24,
                    ),
                    SizedBox(width: isMobile ? 6 : 8),
                    Text(
                      'Save Scores',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildParticipantSelection(
    BuildContext context,
    ScoringController controller,
  ) {
    final participantController = Get.find<ParticipantController>();
    return Obx(() {
      if (participantController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final participants = participantController.participants;

      if (participants.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No participants found',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Please register participants first',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
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
                Icon(Icons.info_outline, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Select a participant to add scores',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final participant = participants[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      radius: 24,
                      child: Text(
                        participant.participantName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      participant.participantName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${participant.schoolName} • ${participant.standard}',
                        ),
                        if (participant.juryScores != null &&
                            participant.juryScores!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Chip(
                              label: Text(
                                'Score: ${participant.calculateGrandTotal().toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.green[100],
                              padding: EdgeInsets.zero,
                            ),
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => controller.selectParticipant(participant),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}
