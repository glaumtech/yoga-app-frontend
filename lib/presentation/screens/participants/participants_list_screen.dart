import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
    final competitionController = Get.isRegistered<CompetitionController>()
        ? Get.find<CompetitionController>()
        : Get.put(CompetitionController());

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

                if (participantController.listErrorMessage.value.isNotEmpty) {
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
                          participantController.listErrorMessage.value,
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
                  return Column(
                    children: [
                      Expanded(
                        child: _buildMobileList(
                          context,
                          participants,
                          participantController,
                        ),
                      ),
                      _buildPaginationControls(
                        context,
                        participantController,
                        isMobile,
                        isTablet,
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Expanded(
                        child: _buildDesktopTable(
                          context,
                          participants,
                          participantController,
                          isTablet,
                        ),
                      ),
                      // Pagination Controls
                      _buildPaginationControls(
                        context,
                        participantController,
                        isMobile,
                        isTablet,
                      ),
                    ],
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
    if (isMobile) {
      return Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (value) {
              controller.searchQuery.value = value;
              // Debounce search - reload after user stops typing
              Future.delayed(const Duration(milliseconds: 500), () {
                if (controller.searchQuery.value == value) {
                  final eventId = controller.selectedEventId.value;
                  if (eventId.isNotEmpty) {
                    controller.loadParticipantsByEventId(
                      eventId,
                      resetPage: true,
                    );
                  }
                }
              });
            },
            decoration: InputDecoration(
              hintText: 'Search by name, category, or group...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Obx(() {
                if (controller.searchQuery.value.isNotEmpty) {
                  return IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.searchQuery.value = '';
                      final eventId = controller.selectedEventId.value;
                      if (eventId.isNotEmpty) {
                        controller.loadParticipantsByEventId(
                          eventId,
                          resetPage: true,
                        );
                      }
                    },
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
          // Competition Dropdown and Refresh
          Row(
            children: [
              Expanded(
                child: Obx(() {
                  // Get the first competition ID as default if none selected
                  final defaultCompetitionId =
                      competitionController.competitions
                          .where((c) => c.id != null)
                          .isNotEmpty
                      ? competitionController.competitions
                            .where((c) => c.id != null)
                            .first
                            .id
                      : null;

                  final selectedValue =
                      controller.selectedEventId.value.isNotEmpty
                      ? controller.selectedEventId.value
                      : defaultCompetitionId;

                  return DropdownButtonFormField<String>(
                    key: const ValueKey('mobile-competition-dropdown'),
                    value: selectedValue,
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
                    items: competitionController.competitions
                        .where((competition) => competition.id != null)
                        .map((competition) {
                          return DropdownMenuItem<String>(
                            value: competition.id,
                            child: Text(
                              competition.competitionName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        })
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        controller.selectedEventId.value = value;
                        controller.loadParticipantsByEventId(value);
                      }
                    },
                  );
                }),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () =>
                    _refreshParticipantsList(controller, competitionController),
                tooltip: 'Refresh',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Desktop/Tablet: All in one row
    return Row(
      children: [
        // Search Bar
        Expanded(
          child: TextField(
            onChanged: (value) {
              controller.searchQuery.value = value;
              // Debounce search - reload after user stops typing
              Future.delayed(const Duration(milliseconds: 500), () {
                if (controller.searchQuery.value == value) {
                  final eventId = controller.selectedEventId.value;
                  if (eventId.isNotEmpty) {
                    controller.loadParticipantsByEventId(
                      eventId,
                      resetPage: true,
                    );
                  }
                }
              });
            },
            decoration: InputDecoration(
              hintText: 'Search by name, category, or group...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Obx(() {
                if (controller.searchQuery.value.isNotEmpty) {
                  return IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.searchQuery.value = '';
                      final eventId = controller.selectedEventId.value;
                      if (eventId.isNotEmpty) {
                        controller.loadParticipantsByEventId(
                          eventId,
                          resetPage: true,
                        );
                      }
                    },
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
        ),
        SizedBox(width: isTablet ? 12 : 16),
        // Competition Dropdown
        Obx(() {
          // Get the first competition ID as default if none selected
          final defaultCompetitionId =
              competitionController.competitions
                  .where((c) => c.id != null)
                  .isNotEmpty
              ? competitionController.competitions
                    .where((c) => c.id != null)
                    .first
                    .id
              : null;

          final selectedValue = controller.selectedEventId.value.isNotEmpty
              ? controller.selectedEventId.value
              : defaultCompetitionId;

          return SizedBox(
            width: isTablet ? 240 : 280,
            child: DropdownButtonFormField<String>(
              key: const ValueKey('desktop-competition-dropdown'),
              value: selectedValue,
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
              items: competitionController.competitions
                  .where((competition) => competition.id != null)
                  .map((competition) {
                    return DropdownMenuItem<String>(
                      value: competition.id,
                      child: Text(
                        competition.competitionName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  })
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.selectedEventId.value = value;
                  controller.loadParticipantsByEventId(value);
                }
              },
            ),
          );
        }),
        SizedBox(width: isTablet ? 8 : 12),
        // Refresh Button
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () =>
              _refreshParticipantsList(controller, competitionController),
          tooltip: 'Refresh',
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[100],
            padding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  void _refreshParticipantsList(
    ParticipantController controller,
    CompetitionController competitionController,
  ) {
    controller.ensureParticipantsListLoaded(
      competitionController,
      forceReload: true,
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
                            if (participant.registrationNo != null &&
                                participant.registrationNo!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Reg. No: ${participant.registrationNo}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    'Category / Group',
                    '${participant.category} / ${participant.standard}',
                  ),
                  _buildInfoRow(
                    'Spot Reg',
                    participant.isSpotRegistration ? 'Yes' : 'No',
                  ),
                  _buildInfoRow('Institution', participant.schoolName),
                  _buildInfoRow('Yoga Teacher', participant.yogaMasterName),
                  if (participant.yogaMasterContact.isNotEmpty)
                    _buildInfoRow(
                      'Teacher Cell',
                      participant.yogaMasterContact,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed:
                            participant.id == null || participant.id!.isEmpty
                            ? null
                            : () => controller
                                  .downloadParticipantRegistrationDetails(
                                    participant.id!,
                                  ),
                        icon: Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 16,
                          color: Colors.blue.shade800,
                        ),
                        label: Text(
                          'PDF',
                          style: TextStyle(color: Colors.blue.shade800),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          controller.initializeFormFromModel(participant);
                          controller.toggleViewMode(false);
                        },
                        icon: Icon(
                          Icons.edit,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        label: Text(
                          'Edit',
                          style: TextStyle(color: AppTheme.primaryColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          if (participant.id != null) {
                            _showDeleteDialog(context, controller, participant);
                          }
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
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
                    2: FlexColumnWidth(1.3), // AGE & GENDER combined
                    3: FlexColumnWidth(1.2), // CATEGORY / GROUP combined
                    4: FlexColumnWidth(2.0),
                    5: FlexColumnWidth(1.5),
                    6: FlexColumnWidth(1.4),
                    7: FlexColumnWidth(1.4),
                    8: const FixedColumnWidth(80), // SPOT REG
                    9: const FixedColumnWidth(140),
                  },
                  children: [
                    // Header Row
                    TableRow(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                      ),
                      children: [
                        _buildTableCell('PHOTO', isHeader: true),
                        _buildSortableHeader(
                          'NAME',
                          'participantName',
                          controller,
                        ),
                        _buildSortableHeader('AGE & GENDER', 'age', controller),
                        _buildTableCell('CATEGORY / GROUP', isHeader: true),
                        _buildSortableHeader(
                          'INSTITUTION',
                          'institutionName',
                          controller,
                          isSortable: false,
                        ),
                        _buildSortableHeader(
                          'YOGA TEACHER',
                          'yogaTeacherName',
                          controller,
                          isSortable: false,
                        ),
                        _buildSortableHeader(
                          'CREATED',
                          'createdAt',
                          controller,
                        ),
                        _buildSortableHeader(
                          'UPDATED',
                          'updatedAt',
                          controller,
                        ),
                        _buildTableCell('SPOT REG', isHeader: true),
                        _buildCenteredTableHeaderCell('ACTIONS'),
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
                          _buildClickableNameCell(
                            context,
                            participant.participantName,
                            participant,
                            controller,
                          ),
                          _buildTableCell(
                            '${participant.age} | ${participant.gender}',
                          ),
                          _buildTableCell(
                            '${participant.category} / ${participant.standard}',
                          ),
                          _buildTableCell(participant.schoolName),
                          _buildTableCell(participant.yogaMasterName),
                          _buildCreatedCellWidget(participant),
                          _buildUpdatedCellWidget(participant),
                          _buildTableCell(
                            participant.isSpotRegistration ? 'Yes' : 'No',
                          ),
                          _buildActionCell(context, participant, controller),
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

  Widget _buildCenteredTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          textAlign: TextAlign.center,
        ),
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

  Widget _buildCreatedCellWidget(ParticipantModel participant) {
    final dateTime = DateFormat(
      'MMM dd, yyyy hh:mm a',
    ).format(participant.createdAt);
    if (participant.createdBy != null && participant.createdBy!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dateTime,
              style: const TextStyle(fontSize: 13),
              softWrap: true,
            ),
            Text(
              'by ${participant.createdBy}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              softWrap: true,
            ),
          ],
        ),
      );
    }
    return _buildTableCell(dateTime);
  }

  Widget _buildUpdatedCellWidget(ParticipantModel participant) {
    if (participant.updatedAt == null) {
      return _buildTableCell('-');
    }
    final dateTime = DateFormat(
      'MMM dd, yyyy hh:mm a',
    ).format(participant.updatedAt!);
    if (participant.updatedBy != null && participant.updatedBy!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dateTime,
              style: const TextStyle(fontSize: 13),
              softWrap: true,
            ),
            Text(
              'by ${participant.updatedBy}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              softWrap: true,
            ),
          ],
        ),
      );
    }
    return _buildTableCell(dateTime);
  }

  Widget _buildClickableNameCell(
    BuildContext context,
    String name,
    ParticipantModel participant,
    ParticipantController controller,
  ) {
    return InkWell(
      onTap: () {
        // Navigate to participant registration form in view mode (non-editable)
        // Use existing participant data without API call
        controller.initializeFormForView(participant);
        // Switch to registration form view
        controller.toggleViewMode(false);
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primaryColor,
                decoration: TextDecoration.underline,
                decorationColor: AppTheme.primaryColor,
              ),
              softWrap: true,
              maxLines: null,
            ),
            if (participant.registrationNo != null &&
                participant.registrationNo!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Reg. No: ${participant.registrationNo}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionCell(
    BuildContext context,
    ParticipantModel participant,
    ParticipantController controller,
  ) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 18,
                  color: Colors.blue.shade800,
                ),
                onPressed: participant.id == null || participant.id!.isEmpty
                    ? null
                    : () => controller.downloadParticipantRegistrationDetails(
                        participant.id!,
                      ),
                tooltip: 'Download registration details',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.edit,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
                onPressed: () {
                  controller.initializeFormFromModel(participant);
                  controller.toggleViewMode(false);
                },
                tooltip: 'Edit',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () {
                  if (participant.id != null) {
                    _showDeleteDialog(context, controller, participant);
                  }
                },
                tooltip: 'Delete',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    ParticipantController controller,
    ParticipantModel participant,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Participant'),
        content: Text(
          'Are you sure you want to delete ${participant.participantName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (participant.id != null) {
                try {
                  final success = await controller.deleteParticipant(
                    participant.id!,
                  );
                  if (success) {
                    // Reload participants list
                    final eventId = controller.selectedEventId.value;
                    if (eventId.isNotEmpty) {
                      controller.loadParticipantsByEventId(
                        eventId,
                        resetPage: true,
                      );
                    }
                    Get.snackbar(
                      'Success',
                      'Participant deleted successfully',
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  } else {
                    Get.snackbar(
                      'Error',
                      controller.errorMessage.value.isNotEmpty
                          ? controller.errorMessage.value
                          : 'Failed to delete participant',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                } catch (e) {
                  Get.snackbar(
                    'Error',
                    'Failed to delete participant: ${e.toString()}',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildSortableHeader(
    String label,
    String sortField,
    ParticipantController controller, {
    bool isSortable = true,
  }) {
    return Obx(() {
      final isActive = isSortable && controller.sortBy.value == sortField;
      final isAscending = controller.sortOrder.value == 'asc';

      return InkWell(
        onTap: isSortable
            ? () {
                // Toggle sort order if same field, otherwise set to desc
                final newOrder = isActive && !isAscending ? 'asc' : 'desc';
                controller.setSorting(sortField, newOrder);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isActive ? AppTheme.primaryColor : Colors.black87,
                  ),
                  softWrap: true,
                  maxLines: null,
                ),
              ),
              if (isSortable) ...[
                const SizedBox(width: 4),
                Icon(
                  isActive
                      ? (isAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward)
                      : Icons.unfold_more,
                  size: 16,
                  color: isActive ? AppTheme.primaryColor : Colors.grey[600],
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPaginationControls(
    BuildContext context,
    ParticipantController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Obx(() {
      // Only show pagination if there are pages
      if (controller.totalPages.value <= 0) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border(top: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Page info and items per page
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Page ${controller.currentPage.value} of ${controller.totalPages.value}',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total: ${controller.totalItems.value} participants',
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            // Pagination buttons
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: controller.currentPage.value > 1
                      ? () => controller.previousPage()
                      : null,
                  tooltip: 'Previous page',
                ),
                // Page numbers (show limited on mobile)
                if (!isMobile) ...[
                  ...List.generate(
                    controller.totalPages.value > 5
                        ? 5
                        : controller.totalPages.value,
                    (index) {
                      int pageNum;
                      if (controller.totalPages.value > 5) {
                        // Show current page and 2 pages on each side
                        final current = controller.currentPage.value;
                        final total = controller.totalPages.value;
                        if (current <= 3) {
                          pageNum = index + 1;
                        } else if (current >= total - 2) {
                          pageNum = total - 4 + index;
                        } else {
                          pageNum = current - 2 + index;
                        }
                      } else {
                        pageNum = index + 1;
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextButton(
                          onPressed: () => controller.goToPage(pageNum),
                          style: TextButton.styleFrom(
                            backgroundColor:
                                controller.currentPage.value == pageNum
                                ? AppTheme.primaryColor
                                : null,
                            foregroundColor:
                                controller.currentPage.value == pageNum
                                ? Colors.white
                                : Colors.grey[700],
                            minimumSize: const Size(40, 40),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text('$pageNum'),
                        ),
                      );
                    },
                  ),
                ] else
                  Text(
                    '${controller.currentPage.value} / ${controller.totalPages.value > 0 ? controller.totalPages.value : 1}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed:
                      controller.currentPage.value < controller.totalPages.value
                      ? () => controller.nextPage()
                      : null,
                  tooltip: 'Next page',
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
