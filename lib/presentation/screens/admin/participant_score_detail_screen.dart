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
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWidePage = constraints.maxWidth >= 900;

            Widget buildParticipantCard() {
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 36,
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
                              style: TextStyle(
                                fontSize: isWidePage ? 20 : 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[900],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (participantScore.participantCode != null)
                                  _buildInfoChip(
                                    label: 'Code',
                                    value:
                                        participantScore.participantCode ?? '',
                                  ),
                                if (participantScore.schoolName != null &&
                                    participantScore.schoolName!.isNotEmpty)
                                  _buildInfoChip(
                                    label: 'School',
                                    value: participantScore.schoolName!,
                                  ),
                                if (participantScore.age > 0)
                                  _buildInfoChip(
                                    label: 'Age',
                                    value: participantScore.age.toString(),
                                  ),
                                if (participantScore.gender.isNotEmpty)
                                  _buildInfoChip(
                                    label: 'Gender',
                                    value: participantScore.gender,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: participantScore.categories.map((
                                category,
                              ) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondaryColor.withOpacity(
                                      0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
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
                      const SizedBox(width: 16),
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
                              fontSize: isWidePage ? 26 : 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }

            Widget buildCategoriesSection() {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  if (commonCategories.isNotEmpty ||
                      specialCategories.isNotEmpty)
                    LayoutBuilder(
                      builder: (context, innerConstraints) {
                        final isWide = innerConstraints.maxWidth > 700;
                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (commonCategories.isNotEmpty)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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

                        // Stacked layout for narrow screens
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
              );
            }

            // Single-column layout for all screen sizes:
            // Participant card on top, categories section below.
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildParticipantCard(),
                  const SizedBox(height: 8),
                  buildCategoriesSection(),
                ],
              ),
            );
          },
        ),
      );
    });
  }

  /// Small helper chip for participant info (age, gender, etc.)
  Widget _buildInfoChip({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    CategoryScoreModel category,
    int categoryIndex,
  ) {
    // Slightly different accent color for special vs common
    final bool isSpecial =
        category.category.toLowerCase() ==
        AppConstants.categorySpecial.toLowerCase();
    final Color accentColor = isSpecial
        ? AppTheme.secondaryColor
        : AppTheme.primaryColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Category pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.category, size: 16, color: accentColor),
                      const SizedBox(width: 6),
                      Text(
                        category.category,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Category total
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Category Total',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category.grandTotal.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey[200]),
            const SizedBox(height: 8),
            Text(
              'Yoga Poses (Asanas)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            ...category.asanas.asMap().entries.map((entry) {
              final index = entry.key;
              final asana = entry.value;
              return _buildAsanaCard(
                context,
                asana,
                index + 1,
                accentColor: accentColor,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAsanaCard(
    BuildContext context,
    AsanaScoreModel asana,
    int index, {
    Color? accentColor,
  }) {
    final Color color = accentColor ?? AppTheme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Asana chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Asana $index',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    asana.asanaName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(
                    'Subtotal: ${asana.subtotal.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Jury Marks
            Text(
              'Jury Marks',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 6),
            ...asana.juryMarks.map((juryMark) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.gavel, size: 18, color: color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        juryMark.juryName != null &&
                                juryMark.juryName!.trim().isNotEmpty
                            ? '${juryMark.juryName} (Jury ${juryMark.juryId})'
                            : 'Jury ${juryMark.juryId}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      juryMark.score.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
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

  // Old implementation kept for reference (not used anymore)
  /*
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
  */
}
