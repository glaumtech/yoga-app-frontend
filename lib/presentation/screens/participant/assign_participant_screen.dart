import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/participant_assignment_controller.dart';

class AssignParticipantScreen extends StatefulWidget {
  final String eventId;

  const AssignParticipantScreen({super.key, required this.eventId});

  @override
  State<AssignParticipantScreen> createState() =>
      _AssignParticipantScreenState();
}

class _AssignParticipantScreenState extends State<AssignParticipantScreen> {
  late ParticipantAssignmentController controller;
  String? _filterName;
  String? _filterStatus;
  String? _filterSection;

  @override
  void initState() {
    super.initState();
    // Initialize controller
    if (!Get.isRegistered<ParticipantAssignmentController>()) {
      Get.put(ParticipantAssignmentController(), permanent: false);
    }
    controller = Get.find<ParticipantAssignmentController>();

    // Load teams and participants
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.loadTeams(widget.eventId);
      controller.loadParticipants(
        widget.eventId,
        resetPage: true,
        assignedStatus: 'Not Assigned',
        status: 'Accepted',
      );
    });
  }

  @override
  void dispose() {
    // Don't dispose controller here as it might be used elsewhere
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Participants'), elevation: 0),
      body: Obx(() {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Team Selection Section
                _buildTeamSelectionSection(),
                const SizedBox(height: 24),

                // Participants Section
                if (controller.selectedTeamId.value.isNotEmpty) ...[
                  _buildParticipantsSection(),
                ] else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.group_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Please select a team to assign participants',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
                // Assigned Participants Section
                _buildAssignedParticipantsSection(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTeamSelectionSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group, color: AppTheme.primaryColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Select Team',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (controller.isLoading.value)
              const Center(child: CircularProgressIndicator())
            else if (controller.teams.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No teams available for this event',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              Obx(() {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.teams.map((team) {
                    final isSelected =
                        controller.selectedTeamId.value == team.id;

                    // Get jury names from juryList if available
                    List<String> juryNames = [];
                    if (team.juryList != null && team.juryList!.isNotEmpty) {
                      juryNames = team.juryList!
                          .map((jury) => jury['name']?.toString() ?? '')
                          .where((name) => name.isNotEmpty)
                          .toList();
                    }

                    return InkWell(
                      onTap: () {
                        controller.selectTeam(team.id ?? '');
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.primaryColor.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  size: 18,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  team.teamName,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withOpacity(0.2)
                                        : AppTheme.primaryColor.withOpacity(
                                            0.1,
                                          ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    team.category,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.primaryColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Show jury names if available
                            if (juryNames.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: juryNames.take(3).map((name) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.15)
                                          : AppTheme.primaryColor.withOpacity(
                                              0.08,
                                            ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.white.withOpacity(0.3)
                                            : AppTheme.primaryColor.withOpacity(
                                                0.2,
                                              ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.person_outline,
                                          size: 10,
                                          color: isSelected
                                              ? Colors.white.withOpacity(0.9)
                                              : AppTheme.primaryColor
                                                    .withOpacity(0.7),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          name.length > 12
                                              ? '${name.substring(0, 12)}...'
                                              : name,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white.withOpacity(0.9)
                                                : AppTheme.primaryColor
                                                      .withOpacity(0.7),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                              // Show count if more than 3 juries
                              if (juryNames.length > 3)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '+${juryNames.length - 3} more',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.8)
                                          : AppTheme.primaryColor.withOpacity(
                                              0.6,
                                            ),
                                      fontSize: 9,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Filter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: AppTheme.primaryColor, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Available Participants',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Assign Button (shown when participants are selected)
                    Obx(() {
                      if (controller.selectedParticipantIds.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ElevatedButton.icon(
                            onPressed: controller.isLoading.value
                                ? null
                                : () async {
                                    final success = await controller
                                        .assignParticipants();
                                    if (success) {
                                      // Reload participants to update assigned status
                                      final selectedTeam =
                                          controller.selectedTeam.value;
                                      final category = selectedTeam?.category
                                          .toLowerCase();
                                      controller.selectedParticipantIds.clear();

                                      // Reload participants list
                                      controller.loadParticipants(
                                        widget.eventId,
                                        resetPage: true,
                                        participantName: _filterName,
                                        status: 'Accepted',
                                        section: _filterSection,
                                        category: category,
                                        assignedStatus: 'Not Assigned',
                                      );

                                      // Reload assigned participants
                                      controller.loadAssignedParticipants(
                                        widget.eventId,
                                      );
                                    }
                                  },
                            icon: controller.isLoading.value
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.person_add, size: 18),
                            label: Text(
                              controller.isLoading.value
                                  ? 'Assigning...'
                                  : 'Assign (${controller.selectedParticipantIds.length})',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    IconButton(
                      icon: Icon(
                        Icons.filter_list,
                        color:
                            (_filterName != null ||
                                _filterStatus != null ||
                                _filterSection != null)
                            ? AppTheme.primaryColor
                            : null,
                      ),
                      onPressed: () => _showFilterDialog(),
                      tooltip: 'Filter',
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        final selectedTeam = controller.selectedTeam.value;
                        final category = selectedTeam?.category.toLowerCase();
                        controller.loadParticipants(
                          widget.eventId,
                          resetPage: true,
                          participantName: _filterName,
                          status: 'Accepted',
                          section: _filterSection,
                          category: category,
                          assignedStatus: 'Not Assigned',
                        );
                      },
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ],
            ),

            // Active Filters
            if (_filterName != null ||
                _filterStatus != null ||
                _filterSection != null) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_filterName != null)
                    Chip(
                      label: Text('Name: $_filterName'),
                      backgroundColor: AppTheme.accentColor,
                      onDeleted: () {
                        setState(() {
                          _filterName = null;
                          final selectedTeam = controller.selectedTeam.value;
                          final category = selectedTeam?.category.toLowerCase();
                          controller.loadParticipants(
                            widget.eventId,
                            resetPage: true,
                            status: _filterStatus,
                            section: _filterSection,
                            category: category,
                            assignedStatus: 'Not Assigned',
                          );
                        });
                      },
                      deleteIcon: const Icon(Icons.close, size: 18),
                    ),
                  if (_filterStatus != null)
                    Chip(
                      label: Text('Status: ${_filterStatus!.toUpperCase()}'),
                      backgroundColor: AppTheme.accentColor,
                      onDeleted: () {
                        setState(() {
                          _filterStatus = null;
                          final selectedTeam = controller.selectedTeam.value;
                          final category = selectedTeam?.category.toLowerCase();
                          controller.loadParticipants(
                            widget.eventId,
                            resetPage: true,
                            participantName: _filterName,
                            section: _filterSection,
                            category: category,
                            assignedStatus: 'Not Assigned',
                          );
                        });
                      },
                      deleteIcon: const Icon(Icons.close, size: 18),
                    ),
                  if (_filterSection != null)
                    Chip(
                      label: Text('Section: $_filterSection'),
                      backgroundColor: AppTheme.accentColor,
                      onDeleted: () {
                        setState(() {
                          _filterSection = null;
                          final selectedTeam = controller.selectedTeam.value;
                          final category = selectedTeam?.category.toLowerCase();
                          controller.loadParticipants(
                            widget.eventId,
                            resetPage: true,
                            participantName: _filterName,
                            status: _filterStatus,
                            category: category,
                            assignedStatus: 'Not Assigned',
                          );
                        });
                      },
                      deleteIcon: const Icon(Icons.close, size: 18),
                    ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // Participants List
            if (controller.isLoadingParticipants.value)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (controller.participants.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No participants available',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  // Selection Info
                  if (controller.selectedParticipantIds.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${controller.selectedParticipantIds.length} participant(s) selected',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              controller.selectedParticipantIds.clear();
                            },
                            child: const Text('Clear Selection'),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Participants List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.participants.length,
                    itemBuilder: (context, index) {
                      final participant = controller.participants[index];
                      final isSelected = controller.isParticipantSelected(
                        participant.id ?? '',
                      );
                      final isAssigned = controller.isParticipantAssigned(
                        participant.id ?? '',
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isAssigned
                              ? Colors.grey[200]
                              : (isSelected
                                    ? AppTheme.primaryColor.withOpacity(0.1)
                                    : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.primaryColor.withOpacity(
                              0.2,
                            ),
                            child: Text(
                              participant.participantName.isNotEmpty
                                  ? participant.participantName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          title: Text(
                            participant.participantName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              decoration: isAssigned
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 12,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Age: ${participant.age} | ${participant.gender}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.school_outlined,
                                    size: 12,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Standard: ${participant.standard}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: isAssigned
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[400],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Assigned',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : Checkbox(
                                  value: isSelected,
                                  onChanged: (value) {
                                    if (participant.id != null) {
                                      controller.toggleParticipantSelection(
                                        participant.id!,
                                      );
                                    }
                                  },
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedParticipantsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.assignment_ind,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Assigned Participants',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    controller.loadAssignedParticipants(widget.eventId);
                  },
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (controller.isLoadingAssigned.value)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (controller.assignedParticipants.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No participants assigned to this team',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              Obx(() {
                return Column(
                  children: controller.assignmentGroups.map((group) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Team Name and Category Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.group,
                                        size: 16,
                                        color: AppTheme.primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        group.teamName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondaryColor.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    group.category.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                      color: AppTheme.secondaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Participants and Juries in Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Participants Section (Left)
                                Expanded(
                                  child: group.participants.isNotEmpty
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Participants',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: Colors.grey[700],
                                                  ),
                                            ),
                                            const SizedBox(height: 6),
                                            SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                children: group.participants.map((
                                                  participant,
                                                ) {
                                                  return Container(
                                                    width: 160,
                                                    margin:
                                                        const EdgeInsets.only(
                                                          right: 8,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 8,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme
                                                          .primaryColor
                                                          .withOpacity(0.05),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      border: Border.all(
                                                        color: AppTheme
                                                            .primaryColor
                                                            .withOpacity(0.2),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        CircleAvatar(
                                                          radius: 16,
                                                          backgroundColor:
                                                              AppTheme
                                                                  .primaryColor
                                                                  .withOpacity(
                                                                    0.2,
                                                                  ),
                                                          child: Text(
                                                            participant
                                                                    .participantName
                                                                    .isNotEmpty
                                                                ? participant
                                                                      .participantName[0]
                                                                      .toUpperCase()
                                                                : '?',
                                                            style: TextStyle(
                                                              color: AppTheme
                                                                  .primaryColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 13,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Text(
                                                                participant
                                                                    .participantName,
                                                                style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 12,
                                                                ),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              if (participant
                                                                          .age >
                                                                      0 ||
                                                                  participant
                                                                      .standard
                                                                      .isNotEmpty) ...[
                                                                const SizedBox(
                                                                  height: 2,
                                                                ),
                                                                Text(
                                                                  [
                                                                    if (participant
                                                                            .age >
                                                                        0)
                                                                      'Age: ${participant.age}',
                                                                    if (participant
                                                                        .standard
                                                                        .isNotEmpty)
                                                                      participant
                                                                          .standard,
                                                                  ].join(' • '),
                                                                  style:
                                                                      Theme.of(
                                                                        context,
                                                                      ).textTheme.bodySmall?.copyWith(
                                                                        fontSize:
                                                                            9,
                                                                      ),
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ],
                                        )
                                      : const SizedBox.shrink(),
                                ),

                                // Juries Section (Right)
                                if (group.juries.isNotEmpty) ...[
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Juries',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Colors.grey[700],
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: group.juries.map((jury) {
                                              final juryName =
                                                  jury['name']?.toString() ??
                                                  'Unknown';
                                              return Container(
                                                width: 160,
                                                margin: const EdgeInsets.only(
                                                  right: 8,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.secondaryColor
                                                      .withOpacity(0.05),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: AppTheme
                                                        .secondaryColor
                                                        .withOpacity(0.2),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 16,
                                                      backgroundColor: AppTheme
                                                          .secondaryColor
                                                          .withOpacity(0.2),
                                                      child: Icon(
                                                        Icons.gavel,
                                                        color: AppTheme
                                                            .secondaryColor,
                                                        size: 16,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        juryName.toUpperCase(),
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    final nameController = TextEditingController(text: _filterName ?? '');
    String? selectedStatus = _filterStatus;
    String? selectedSection = _filterSection;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter Participants'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Participant (Name or Code)
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Participant (Name or Code)',
                        hintText: 'Enter name or code to search',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status
                    DropdownButtonFormField<String?>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.info),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'Accepted',
                          child: Text('Accepted'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'Rejected',
                          child: Text('Rejected'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Section (Standard)
                    DropdownButtonFormField<String?>(
                      value: selectedSection,
                      decoration: const InputDecoration(
                        labelText: 'Section (Standard)',
                        prefixIcon: Icon(Icons.school),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Sections'),
                        ),
                        ...controller.getAvailableSections().map((section) {
                          return DropdownMenuItem<String?>(
                            value: section,
                            child: Text(section),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedSection = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      nameController.clear();
                      selectedStatus = null;
                      selectedSection = null;
                    });
                  },
                  child: const Text('Clear'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filterName = nameController.text.trim().isEmpty
                          ? null
                          : nameController.text.trim();
                      _filterStatus = selectedStatus;
                      _filterSection = selectedSection;
                    });

                    Navigator.pop(context);
                    final selectedTeam = controller.selectedTeam.value;
                    final category = selectedTeam?.category.toLowerCase();
                    controller.loadParticipants(
                      widget.eventId,
                      resetPage: true,
                      participantName: _filterName,
                      status: _filterStatus,
                      section: _filterSection,
                      category: category,
                      assignedStatus: 'Not Assigned',
                    );
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
