import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../controllers/scoring_controller.dart';
import '../../../data/models/score_response_model.dart';

class ParticipantScoreDetailScreen extends StatelessWidget {
  final String eventId;
  final String participantId;

  const ParticipantScoreDetailScreen({
    super.key,
    required this.eventId,
    required this.participantId,
  });

  @override
  Widget build(BuildContext context) {
    final scoreController = Get.find<ScoringController>();

    // Load participant score on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scoreController.singleParticipantScoreResponse.value == null ||
          scoreController
                  .singleParticipantScoreResponse
                  .value
                  ?.participant
                  .participantId
                  .toString() !=
              participantId) {
        scoreController.loadParticipantScoreDetail(eventId, participantId);
      }
    });

    return Obx(() {
      if (scoreController.isLoadingScores.value) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: AppTheme.primaryColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'Score Details',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      if (scoreController.scoreErrorMessage.value.isNotEmpty) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: AppTheme.primaryColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'Score Details',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  scoreController.scoreErrorMessage.value,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    scoreController.loadParticipantScoreDetail(
                      eventId,
                      participantId,
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final singleScoreResponse =
          scoreController.singleParticipantScoreResponse.value;
      if (singleScoreResponse == null) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: AppTheme.primaryColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'Score Details',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: const Center(child: Text('Participant score not found')),
        );
      }

      final participantScore = singleScoreResponse.participant;

      // Calculate total score across all categories
      double totalScore = 0.0;
      for (final category in participantScore.categories) {
        totalScore += category.grandTotal;
      }

      // Split categories into Common (left) and Special (right)
      final commonCategories = participantScore.categories
          .where(
            (c) =>
                c.category.toLowerCase() ==
                AppConstants.categoryCommon.toLowerCase(),
          )
          .toList();
      final specialCategories = participantScore.categories
          .where(
            (c) =>
                c.category.toLowerCase() ==
                AppConstants.categorySpecial.toLowerCase(),
          )
          .toList();

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
            'Score Details',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                scoreController.loadParticipantScoreDetail(
                  eventId,
                  participantId,
                );
              },
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Participant Info Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 32,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              participantScore.participantName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (participantScore.participantCode != null) ...[
                              Text(
                                'Code: ${participantScore.participantCode}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                            if (participantScore.schoolName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'School: ${participantScore.schoolName}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: participantScore.categories.map((
                                category,
                              ) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondaryColor.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    category.category,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.secondaryColor,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total Score',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            totalScore.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Categories header row
              Row(
                children: [
                  if (commonCategories.isNotEmpty)
                    Expanded(
                      child: Text(
                        'Common Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  if (specialCategories.isNotEmpty)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Special Category',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Categories Section laid out with Common on left and Special on right
              if (commonCategories.isNotEmpty || specialCategories.isNotEmpty)
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Two-column layout for wider screens, stacked for narrow
                    final isWide = constraints.maxWidth > 700;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (commonCategories.isNotEmpty)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: commonCategories
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => _buildCategoryCard(
                                        context,
                                        entry.value,
                                        entry.key,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          if (commonCategories.isNotEmpty &&
                              specialCategories.isNotEmpty)
                            const SizedBox(width: 16),
                          if (specialCategories.isNotEmpty)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: specialCategories
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => _buildCategoryCard(
                                        context,
                                        entry.value,
                                        entry.key,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                        ],
                      );
                    }

                    // Fallback stacked layout for narrow screens
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...commonCategories.asMap().entries.map(
                          (entry) => _buildCategoryCard(
                            context,
                            entry.value,
                            entry.key,
                          ),
                        ),
                        ...specialCategories.asMap().entries.map(
                          (entry) => _buildCategoryCard(
                            context,
                            entry.value,
                            entry.key,
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCategoryCard(
    BuildContext context,
    CategoryScoreModel category,
    int categoryIndex,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
                    category.category,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Category Total',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.grandTotal.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Yoga Poses (Asanas)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            ...category.asanas.asMap().entries.map((entry) {
              final index = entry.key;
              final asana = entry.value;
              return _buildAsanaCard(context, asana, index + 1);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAsanaCard(
    BuildContext context,
    AsanaScoreModel asana,
    int index,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
                    'Asana $index',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    asana.asanaName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'Subtotal: ${asana.subtotal.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            // Jury Marks
            Text(
              'Jury Marks',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            ...asana.juryMarks.map((juryMark) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.gavel, size: 20, color: AppTheme.secondaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        juryMark.juryName != null
                            ? '${juryMark.juryName} (Jury ${juryMark.juryId})'
                            : 'Jury ${juryMark.juryId}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      juryMark.score.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
