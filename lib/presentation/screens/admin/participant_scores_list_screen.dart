import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../../controllers/scoring_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../../data/models/score_response_model.dart';

class ParticipantScoresListScreen extends StatelessWidget {
  final String eventId;

  const ParticipantScoresListScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ScoringController>();
    final authController = Get.find<AuthController>();

    // Check if user is admin
    if (!authController.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppRoutes.home);
        Get.snackbar(
          'Access Denied',
          'Only admins can view participant scores',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      });
    }

    // Load scores on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.eventId.value != eventId ||
          controller.scoreResponse.value == null) {
        controller.loadScoresByEventId(eventId);
      }
    });

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
          'Participant Scores',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              controller.loadScoresByEventId(eventId);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingScores.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.scoreErrorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  controller.scoreErrorMessage.value,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    controller.loadScoresByEventId(eventId);
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
          );
        }

        final scoreResponse = controller.scoreResponse.value;
        if (scoreResponse == null || scoreResponse.participants.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.score_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No scores available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scores will appear here once judges submit them',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: scoreResponse.participants.length,
          itemBuilder: (context, index) {
            final participantScore = scoreResponse.participants[index];
            return _buildParticipantScoreCard(
              context,
              participantScore,
              index + 1,
            );
          },
        );
      }),
    );
  }

  Widget _buildParticipantScoreCard(
    BuildContext context,
    ParticipantScoreModel participantScore,
    int index,
  ) {
    // Calculate total score across all categories
    double totalScore = 0.0;
    for (final category in participantScore.categories) {
      totalScore += category.grandTotal;
    }

    // Count total asanas across all categories
    int totalAsanas = 0;
    for (final category in participantScore.categories) {
      totalAsanas += category.asanas.length;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          context.pushNamed(
            'participant-score-detail',
            pathParameters: {
              'eventId': eventId,
              'participantId': participantScore.participantId.toString(),
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Participant number badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '#$index',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Participant info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participantScore.participantName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          participantScore.participantCode ?? 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${participantScore.categories.length} Categories',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$totalAsanas Asanas',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Total score
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalScore.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
