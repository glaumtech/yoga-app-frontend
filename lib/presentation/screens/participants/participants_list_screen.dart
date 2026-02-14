import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/participant_controller.dart';
import '../../controllers/competition_controller.dart';
import '../../widgets/custom_loader.dart';
import '../../../data/models/participant_model.dart';

class ParticipantsListScreen extends StatelessWidget {
  const ParticipantsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final participantController = Get.find<ParticipantController>();
    // Initialize CompetitionController if not already initialized
    final competitionController = Get.put(CompetitionController());

    // Load competitions if empty
    if (competitionController.competitions.isEmpty &&
        !competitionController.isLoading.value) {
      competitionController.loadCompetitions();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search and Filter Section
            _buildSearchSection(
              context,
              participantController,
              competitionController,
              isMobile,
              isTablet,
            ),
            SizedBox(height: isMobile ? 16 : 24),
            // Participants List
            Expanded(
              child: Obx(() {
                if (participantController.isLoading.value) {
                  return const Center(child: CustomLoader());
                }

                if (participantController.errorMessage.value.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          participantController.errorMessage.value,
                          style: TextStyle(color: Colors.red[700]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            final eventId =
                                participantController.selectedEventId.value;
                            if (eventId.isNotEmpty) {
                              participantController.loadParticipantsByEventId(
                                eventId,
                              );
                            }
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final participants = participantController.filteredParticipants;

                if (participants.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          participantController.searchQuery.value.isNotEmpty
                              ? 'No participants found matching your search'
                              : 'No participants found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (isMobile) {
                  return _buildMobileList(
                    context,
                    participants,
                    participantController,
                  );
                } else {
                  return _buildDesktopTable(
                    context,
                    participants,
                    participantController,
                    isTablet,
                  );
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection(
    BuildContext context,
    ParticipantController controller,
    CompetitionController competitionController,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      children: [
        // Search Bar
        TextField(
          onChanged: (value) => controller.searchQuery.value = value,
          decoration: InputDecoration(
            hintText: 'Search by name, category, or group...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: Obx(() {
              if (controller.searchQuery.value.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => controller.searchQuery.value = '',
                );
              }
              return const SizedBox.shrink();
            }),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        // Filter by Competition
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Obx(
              () => isMobile
                  ? Expanded(
                      child: DropdownButtonFormField<String>(
                        value: controller.selectedEventId.value.isNotEmpty
                            ? controller.selectedEventId.value
                            : null,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          isDense: true,
                        ),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text(
                              'All Competitions',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ...competitionController.competitions
                              .where((competition) => competition.id != null)
                              .map((competition) {
                                return DropdownMenuItem<String>(
                                  value: competition.id,
                                  child: Text(
                                    competition.competitionName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            controller.selectedEventId.value = value;
                            controller.loadParticipantsByEventId(value);
                          } else {
                            controller.selectedEventId.value = '';
                            controller.participants.clear();
                          }
                        },
                      ),
                    )
                  : SizedBox(
                      width: isTablet ? 320 : 360,
                      child: DropdownButtonFormField<String>(
                        value: controller.selectedEventId.value.isNotEmpty
                            ? controller.selectedEventId.value
                            : null,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          isDense: true,
                        ),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text(
                              'All Competitions',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ...competitionController.competitions
                              .where((competition) => competition.id != null)
                              .map((competition) {
                                return DropdownMenuItem<String>(
                                  value: competition.id,
                                  child: Text(
                                    competition.competitionName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            controller.selectedEventId.value = value;
                            controller.loadParticipantsByEventId(value);
                          } else {
                            controller.selectedEventId.value = '';
                            controller.participants.clear();
                          }
                        },
                      ),
                    ),
            ),
            SizedBox(width: isMobile ? 8 : 12),
            // Refresh Button
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                final eventId = controller.selectedEventId.value;
                if (eventId.isNotEmpty) {
                  controller.loadParticipantsByEventId(eventId);
                }
              },
              tooltip: 'Refresh',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileList(
    BuildContext context,
    List<ParticipantModel> participants,
    ParticipantController controller,
  ) {
    return RefreshIndicator(
      onRefresh: () {
        final eventId = controller.selectedEventId.value;
        if (eventId.isNotEmpty) {
          return controller.loadParticipantsByEventId(eventId);
        }
        return Future.value();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: participants.length,
        itemBuilder: (context, index) {
          final participant = participants[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildParticipantPhoto(participant, 50),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              participant.participantName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Age: ${participant.age} | ${participant.gender}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildInfoRow('Category', participant.category),
                  _buildInfoRow('Group', participant.standard),
                  _buildInfoRow('Institution', participant.schoolName),
                  _buildInfoRow('Yoga Teacher', participant.yogaMasterName),
                  if (participant.yogaMasterContact.isNotEmpty)
                    _buildInfoRow(
                      'Teacher Cell',
                      participant.yogaMasterContact,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopTable(
    BuildContext context,
    List<ParticipantModel> participants,
    ParticipantController controller,
    bool isTablet,
  ) {
    return RefreshIndicator(
      onRefresh: () {
        final eventId = controller.selectedEventId.value;
        if (eventId.isNotEmpty) {
          return controller.loadParticipantsByEventId(eventId);
        }
        return Future.value();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = constraints.maxWidth - 32;
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: tableWidth,
                child: Table(
                  border: TableBorder.all(color: Colors.grey[300]!, width: 1),
                  columnWidths: {
                    0: const FixedColumnWidth(80),
                    1: FlexColumnWidth(2.0),
                    2: FlexColumnWidth(1.0),
                    3: FlexColumnWidth(1.0),
                    4: FlexColumnWidth(1.5),
                    5: FlexColumnWidth(1.5),
                    6: FlexColumnWidth(2.0),
                    7: FlexColumnWidth(1.5),
                  },
                  children: [
                    // Header Row
                    TableRow(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                      ),
                      children: [
                        _buildTableCell('PHOTO', isHeader: true),
                        _buildTableCell('NAME', isHeader: true),
                        _buildTableCell('AGE', isHeader: true),
                        _buildTableCell('GENDER', isHeader: true),
                        _buildTableCell('CATEGORY', isHeader: true),
                        _buildTableCell('GROUP', isHeader: true),
                        _buildTableCell('INSTITUTION', isHeader: true),
                        _buildTableCell('YOGA TEACHER', isHeader: true),
                      ],
                    ),
                    // Data Rows
                    ...participants.map((participant) {
                      return TableRow(
                        children: [
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Center(
                                child: _buildParticipantPhoto(participant, 40),
                              ),
                            ),
                          ),
                          _buildTableCell(participant.participantName),
                          _buildTableCell(participant.age.toString()),
                          _buildTableCell(participant.gender),
                          _buildTableCell(participant.category),
                          _buildTableCell(participant.standard),
                          _buildTableCell(participant.schoolName),
                          _buildTableCell(participant.yogaMasterName),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 14 : 13,
        ),
        softWrap: true,
        maxLines: null,
      ),
    );
  }

  Widget _buildParticipantPhoto(ParticipantModel participant, double size) {
    final firstLetter =
        (participant.participantName.isNotEmpty
                ? participant.participantName[0]
                : 'P')
            .toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          firstLetter,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
