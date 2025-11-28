import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/participant_controller.dart';
import '../../widgets/custom_loader.dart';
import '../../widgets/section_header.dart';

class MyRegistrationsScreen extends StatelessWidget {
  const MyRegistrationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final participantController = Get.find<ParticipantController>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Registrations')),
      body: Obx(() {
        if (participantController.isLoading.value) {
          return const CustomLoader(message: 'Loading registrations...');
        }

        if (participantController.myRegistrations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No registrations found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Register for an event to get started',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          // TODO: This screen needs eventId to load registrations
          // onRefresh: () => participantController.loadMyRegistrations(eventId),
          onRefresh: () async {
            Get.snackbar(
              'Info',
              'Please navigate to an event to view registrations',
            );
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionHeader(
                title: 'All Registrations',
                subtitle:
                    '${participantController.myRegistrations.length} total',
                showDivider: false,
              ),
              const SizedBox(height: 16),
              ...participantController.myRegistrations.map((registration) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        registration.participantName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      registration.participantName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${registration.category} • ${registration.standard}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (registration.grandTotal != null)
                          Text(
                            'Score: ${registration.grandTotal!.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow(
                              context,
                              'Date of Birth',
                              DateFormat(
                                'MMM dd, yyyy',
                              ).format(registration.dateOfBirth),
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              context,
                              'Age',
                              '${registration.age} years',
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              context,
                              'Gender',
                              registration.gender,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              context,
                              'School',
                              registration.schoolName,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              context,
                              'Address',
                              registration.address,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              context,
                              'Yoga Master',
                              registration.yogaMasterName,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              context,
                              'Master Contact',
                              registration.yogaMasterContact,
                            ),
                            if (registration.juryScores != null &&
                                registration.juryScores!.isNotEmpty) ...[
                              const Divider(),
                              const SizedBox(height: 8),
                              Text(
                                'Jury Scores',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ...registration.juryScores!.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                      Text(
                                        entry.value.toStringAsFixed(2),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
