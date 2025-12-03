import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:yoga_champ/data/models/judge_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/event_controller.dart';
import '../../controllers/participant_controller.dart';
import '../../controllers/team_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/judge_controller.dart';
import '../../widgets/event_banner_image.dart';
import '../../../data/models/participant_model.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  String? _filterName;
  String? _filterStatus;
  bool _hasLoadedParticipants = false;

  void _loadParticipants({bool resetPage = true}) {
    final participantController = Get.find<ParticipantController>();

    final filter = ParticipantFilterRequest(
      participant: _filterName?.isEmpty ?? true ? null : _filterName,
      status: _filterStatus,
      page: 0, // Controller handles page calculation internally
      size: 50, // Load more participants per page
    );

    participantController.loadParticipantsByEventId(
      widget.eventId,
      filter: filter,
      resetPage: resetPage,
    );
  }

  @override
  void initState() {
    super.initState();
    // Load participants and teams only once when screen is first initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasLoadedParticipants) {
        _loadParticipants(resetPage: true);
        _hasLoadedParticipants = true;
      }
      // Load teams for this event
      _loadTeams();
    });
  }

  void _loadTeams() {
    // Ensure TeamController is available
    if (!Get.isRegistered<TeamController>()) {
      Get.put(TeamController(), permanent: true);
    }
    final teamController = Get.find<TeamController>();
    teamController.loadTeamsByEventId(widget.eventId);
  }

  @override
  Widget build(BuildContext context) {
    final eventController = Get.find<EventController>();
    final participantController = Get.find<ParticipantController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Event Details'), elevation: 0),
      body: Obx(() {
        final event =
            eventController.selectedEvent.value ??
            eventController.events.firstWhereOrNull(
              (e) => e.id == widget.eventId,
            );

        if (event == null) {
          return const Center(child: Text('Event not found'));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isMobile = screenWidth < 600;

            return SingleChildScrollView(
              child: isMobile
                  ? // Mobile: Stack vertically
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Event Banner
                          if (event.id != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: EventBannerImage(
                                event: event,
                                height: 200,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                          const SizedBox(height: 16),
                          // Event Title and Status
                          _buildEventTitleCard(context, event),
                          const SizedBox(height: 16),
                          // Event Details Section
                          _buildEventDetailsSection(context, event, isMobile),
                          const SizedBox(height: 24),
                          // Participants Section
                          _buildParticipantsSection(
                            context,
                            participantController,
                            widget.eventId,
                          ),
                          // Teams Section (Admin Only)
                          Obx(() {
                            final authController = Get.find<AuthController>();
                            if (authController.isAdmin) {
                              return Column(
                                children: [
                                  const SizedBox(height: 24),
                                  _buildTeamsSection(context, widget.eventId),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          }),
                        ],
                      ),
                    )
                  : // Tablet/Desktop: Side by side layout
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Side: Banner + Event Details + Teams
                        Expanded(
                          flex: 1,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Event Banner
                                if (event.id != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: EventBannerImage(
                                      event: event,
                                      height: 300,
                                      fit: BoxFit.cover,
                                      borderRadius: BorderRadius.zero,
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                // Event Title and Status
                                _buildEventTitleCard(context, event),
                                const SizedBox(height: 16),
                                // Event Details Section
                                _buildEventDetailsSection(
                                  context,
                                  event,
                                  isMobile,
                                ),
                                // Teams Section (Admin Only)
                                Obx(() {
                                  final authController =
                                      Get.find<AuthController>();
                                  if (authController.isAdmin) {
                                    return Column(
                                      children: [
                                        const SizedBox(height: 24),
                                        _buildTeamsSection(
                                          context,
                                          widget.eventId,
                                        ),
                                      ],
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }),
                              ],
                            ),
                          ),
                        ),
                        // Right Side: Participants List
                        Expanded(
                          flex: 1,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildParticipantsSection(
                                  context,
                                  participantController,
                                  widget.eventId,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            );
          },
        );
      }),
    );
  }

  Widget _buildParticipantsSection(
    BuildContext context,
    ParticipantController controller,
    String eventId,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Obx(() {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Section Header with Filter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.people,
                              color: AppTheme.primaryColor,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Registered Participants',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    controller.totalItems.value > 0
                                        ? '${controller.participants.length} of ${controller.totalItems.value} registered'
                                        : '${controller.participants.length} registered',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isMobile)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_filterName != null || _filterStatus != null)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _filterName = null;
                                    _filterStatus = null;
                                    _loadParticipants(resetPage: true);
                                  });
                                },
                                tooltip: 'Clear Filter',
                              ),
                            IconButton(
                              icon: Icon(
                                Icons.filter_list,
                                color:
                                    (_filterName != null ||
                                        _filterStatus != null)
                                    ? AppTheme.primaryColor
                                    : null,
                              ),
                              onPressed: () => _showFilterDialog(
                                context,
                                controller,
                                widget.eventId,
                              ),
                              tooltip: 'Filter',
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () {
                                _loadParticipants(resetPage: true);
                              },
                              tooltip: 'Refresh',
                            ),
                          ],
                        )
                      else
                        PopupMenuButton(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (context) => [
                            if (_filterName != null || _filterStatus != null)
                              PopupMenuItem(
                                child: const Row(
                                  children: [
                                    Icon(Icons.clear, size: 20),
                                    SizedBox(width: 8),
                                    Text('Clear Filter'),
                                  ],
                                ),
                                onTap: () {
                                  Future.delayed(
                                    const Duration(milliseconds: 100),
                                    () {
                                      setState(() {
                                        _filterName = null;
                                        _filterStatus = null;
                                        _loadParticipants(resetPage: true);
                                      });
                                    },
                                  );
                                },
                              ),
                            PopupMenuItem(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.filter_list,
                                    size: 20,
                                    color:
                                        (_filterName != null ||
                                            _filterStatus != null)
                                        ? AppTheme.primaryColor
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Filter'),
                                ],
                              ),
                              onTap: () {
                                Future.delayed(
                                  const Duration(milliseconds: 100),
                                  () => _showFilterDialog(
                                    context,
                                    controller,
                                    widget.eventId,
                                  ),
                                );
                              },
                            ),
                            const PopupMenuItem(
                              child: Row(
                                children: [
                                  Icon(Icons.refresh, size: 20),
                                  SizedBox(width: 8),
                                  Text('Refresh'),
                                ],
                              ),
                              onTap: null,
                            ),
                          ],
                        ),
                    ],
                  ),
                  // Active Filter Chips
                  if (_filterName != null || _filterStatus != null) ...[
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
                                _loadParticipants(resetPage: true);
                              });
                            },
                            deleteIcon: const Icon(Icons.close, size: 18),
                          ),
                        if (_filterStatus != null)
                          Chip(
                            label: Text(
                              'Status: ${_filterStatus!.toUpperCase()}',
                            ),
                            backgroundColor: AppTheme.accentColor,
                            onDeleted: () {
                              setState(() {
                                _filterStatus = null;
                                _loadParticipants(resetPage: true);
                              });
                            },
                            deleteIcon: const Icon(Icons.close, size: 18),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Loading State
                  if (controller.isLoading.value)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  // Error State
                  else if (controller.errorMessage.value.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              controller.errorMessage.value,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                _loadParticipants(resetPage: true);
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  // Empty State
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
                              'No participants registered yet',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    )
                  // Participants List
                  else
                    Column(
                      children: [
                        // Pagination Info
                        if (controller.totalItems.value > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Page ${controller.currentPage.value}/'
                                    '${controller.totalPages.value} '
                                    '(${controller.totalItems.value} total)',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        // Participants List (Scrollable)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.participants.length,
                          itemBuilder: (context, index) {
                            final participant = controller.participants[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
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
                                  radius: isMobile ? 24 : 20,
                                  backgroundColor: AppTheme.primaryColor
                                      .withOpacity(0.2),
                                  child: Text(
                                    participant.participantName.isNotEmpty
                                        ? participant.participantName[0]
                                              .toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isMobile ? 18 : 16,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  participant.participantName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 16 : 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Participant Code
                                      if (participant.participantCode != null &&
                                          participant
                                              .participantCode!
                                              .isNotEmpty)
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.badge_outlined,
                                              size: 12,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                'Code: ${participant.participantCode}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppTheme.primaryColor,
                                                    ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (participant.participantCode != null &&
                                          participant
                                              .participantCode!
                                              .isNotEmpty)
                                        const SizedBox(height: 4),
                                      // Age and Gender
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person_outline,
                                            size: 12,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'Age: ${participant.age} | ${participant.gender}',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // Category
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.category_outlined,
                                            size: 12,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'Category: ${participant.category}',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // Standard
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.school_outlined,
                                            size: 12,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'Standard: ${participant.standard}',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // School Name
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 12,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'School: ${participant.schoolName}',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // Yoga Master Name
                                      if (participant.yogaMasterName.isNotEmpty)
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.person_outline,
                                              size: 12,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                'Yoga Master: ${participant.yogaMasterName}',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                                trailing: Obx(() {
                                  final authController =
                                      Get.find<AuthController>();
                                  final isAdmin = authController.isAdmin;
                                  final currentStatus = participant.status
                                      ?.toLowerCase();

                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Status Badge
                                      if (participant.status != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                              participant.status!,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _getStatusColor(
                                                  participant.status!,
                                                ).withOpacity(0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            participant.status!.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      // Accept/Reject Buttons (Admin Only)
                                      if (isAdmin &&
                                          participant.id != null) ...[
                                        // Accept Button (show if not already accepted)
                                        if (currentStatus?.toLowerCase() ==
                                            'requested')
                                          IconButton(
                                            icon: Icon(
                                              Icons.check_circle,
                                              size: 20,
                                              color: Colors.green,
                                            ),
                                            onPressed:
                                                controller.isLoading.value
                                                ? null
                                                : () async {
                                                    final confirmed = await showDialog<bool>(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        title: const Text(
                                                          'Accept Participant',
                                                        ),
                                                        content: Text(
                                                          'Are you sure you want to accept ${participant.participantName}?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  context,
                                                                  false,
                                                                ),
                                                            child: const Text(
                                                              'Cancel',
                                                            ),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  context,
                                                                  true,
                                                                ),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors.green,
                                                              foregroundColor:
                                                                  Colors.white,
                                                            ),
                                                            child: const Text(
                                                              'Accept',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );

                                                    if (confirmed == true) {
                                                      final success =
                                                          await controller
                                                              .updateParticipantStatus(
                                                                participant.id!,
                                                                'Accepted',
                                                              );
                                                      if (success && mounted) {
                                                        _loadParticipants(
                                                          resetPage: true,
                                                        );
                                                      }
                                                    }
                                                  },
                                            tooltip: 'Paid',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        // Reject Button (show if not already rejected or accepted)
                                        if (currentStatus?.toLowerCase() ==
                                            'requested')
                                          IconButton(
                                            icon: Icon(
                                              Icons.cancel,
                                              size: 20,
                                              color: Colors.red,
                                            ),
                                            onPressed:
                                                controller.isLoading.value
                                                ? null
                                                : () async {
                                                    final confirmed = await showDialog<bool>(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        title: const Text(
                                                          'Reject Participant',
                                                        ),
                                                        content: Text(
                                                          'Are you sure you want to reject ${participant.participantName}?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  context,
                                                                  false,
                                                                ),
                                                            child: const Text(
                                                              'Cancel',
                                                            ),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  context,
                                                                  true,
                                                                ),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors.red,
                                                              foregroundColor:
                                                                  Colors.white,
                                                            ),
                                                            child: const Text(
                                                              'Reject',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );

                                                    if (confirmed == true) {
                                                      final success =
                                                          await controller
                                                              .updateParticipantStatus(
                                                                participant.id!,
                                                                'Rejected',
                                                              );
                                                      if (success && mounted) {
                                                        _loadParticipants(
                                                          resetPage: true,
                                                        );
                                                      }
                                                    }
                                                  },
                                            tooltip: 'Not Paid',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        const SizedBox(width: 4),
                                      ],
                                      // Certificate Download Button (for accepted participants)
                                      if (participant.id != null &&
                                          (currentStatus?.toLowerCase() ==
                                              'scored')) ...[
                                        IconButton(
                                          icon: Icon(
                                            Icons.download,
                                            size: 20,
                                            color: AppTheme.primaryColor,
                                          ),
                                          onPressed: () {
                                            final participantController =
                                                Get.find<
                                                  ParticipantController
                                                >();
                                            participantController
                                                .downloadParticipantCertificate(
                                                  participant.id!.toString(),
                                                );
                                          },
                                          tooltip: 'Download Certificate',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      // Edit Button
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          size: 20,
                                          color: AppTheme.primaryColor,
                                        ),
                                        onPressed: () async {
                                          // Navigate to registration form with participant ID for editing
                                          // The form will fetch participant details using GET API
                                          await context.push(
                                            '/register/${widget.eventId}?participantId=${participant.id}',
                                          );
                                          // Reload participants when returning from edit
                                          // This ensures the list is updated with any changes
                                          if (mounted) {
                                            _loadParticipants(resetPage: true);
                                          }
                                        },
                                        tooltip: 'Edit Participant',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            );
                          },
                        ),
                        // Load More Button
                        if (controller.hasMorePages.value)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Center(
                              child: ElevatedButton.icon(
                                onPressed: controller.isLoading.value
                                    ? null
                                    : () {
                                        // Load next page (controller handles page increment)
                                        _loadParticipants(resetPage: false);
                                      },
                                icon: controller.isLoading.value
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.expand_more),
                                label: controller.isLoading.value
                                    ? const Text('Loading...')
                                    : const Text('Load More'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}

Color _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'accepted':
      return Colors.green;
    case 'rejected':
      return Colors.red;
    case 'pending':
    case 'requested':
      return Colors.orange;
    case 'scored':
      return Colors.blue;
    default:
      return Colors.grey;
  }
}

void _showEditTeamDialog(BuildContext context, String teamId, String eventId) {
  // Ensure TeamController is available
  if (!Get.isRegistered<TeamController>()) {
    Get.put(TeamController(), permanent: true);
  }
  final teamController = Get.find<TeamController>();

  // Ensure JudgeController is available and load judges
  if (!Get.isRegistered<JudgeController>()) {
    Get.put(JudgeController(), permanent: true);
  }
  final judgeController = Get.find<JudgeController>();
  // Always try to load judges if list is empty
  if (judgeController.judges.isEmpty) {
    judgeController.loadJudges();
  }

  // Find the team to edit
  final team = teamController.teams.firstWhereOrNull((t) => t.id == teamId);
  if (team == null) {
    Get.snackbar('Error', 'Team not found');
    return;
  }

  // Initialize form with team data
  teamController.initializeFormForEdit(team);
  final TextEditingController teamNameController = TextEditingController(
    text: team.teamName,
  );

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Obx(() {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Team',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          teamController.resetForm();
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Team Name Field
                  TextFormField(
                    controller: teamNameController,
                    decoration: InputDecoration(
                      labelText: 'Team Name *',
                      hintText: 'Enter team name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.group),
                    ),
                    onChanged: (value) {
                      // Value will be set when updating team
                    },
                  ),
                  const SizedBox(height: 20),
                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: teamController.selectedCategory.value.isEmpty
                        ? null
                        : teamController.selectedCategory.value,
                    decoration: InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.category),
                    ),
                    items: teamController.categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        teamController.selectedCategory.value = value;
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  // Jury Multi-Select
                  Text(
                    'Jury (Select Multiple) *',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Obx(() {
                      final judgeController = Get.find<JudgeController>();
                      final List<JudgeModel> judges = judgeController.judges
                          .toList();
                      if (judgeController.isLoading.value) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 8),
                                Text('Loading judges...'),
                              ],
                            ),
                          ),
                        );
                      }

                      if (judgeController.judges.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: Text('No judges available')),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: judges.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, thickness: 1),
                        itemBuilder: (context, index) {
                          final judge = judges[index];
                          return Obx(() {
                            final isSelected = teamController.isJurySelected(
                              judge.id ?? '',
                            );
                            return CheckboxListTile(
                              title: Text(judge.name),
                              subtitle: Text(judge.designation),
                              value: isSelected,
                              dense: true,
                              onChanged: (bool? value) {
                                if (judge.id != null) {
                                  teamController.toggleJurySelection(judge.id!);
                                }
                              },
                            );
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  // Error Message
                  if (teamController.errorMessage.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        teamController.errorMessage.value,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          teamController.resetForm();
                          Navigator.of(dialogContext).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: teamController.isLoading.value
                            ? null
                            : () async {
                                teamController.teamName.value =
                                    teamNameController.text;
                                final success = await teamController.updateTeam(
                                  teamId,
                                  eventId,
                                );
                                if (success && dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop();
                                  // Refresh teams list
                                  teamController.loadTeamsByEventId(eventId);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: teamController.isLoading.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Update Team'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      );
    },
  );
}

void _showCreateTeamDialog(BuildContext context, String eventId) {
  // Ensure TeamController is available
  if (!Get.isRegistered<TeamController>()) {
    Get.put(TeamController(), permanent: true);
  }
  final teamController = Get.find<TeamController>();

  // Ensure JudgeController is available and load judges
  if (!Get.isRegistered<JudgeController>()) {
    Get.put(JudgeController(), permanent: true);
  }
  final judgeController = Get.find<JudgeController>();
  // Always try to load judges if list is empty
  if (judgeController.judges.isEmpty) {
    judgeController.loadJudges();
  }

  final TextEditingController teamNameController = TextEditingController();

  // Reset form when dialog opens
  teamController.resetForm();

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Obx(() {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Create Team',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Team Name Field
                  TextFormField(
                    controller: teamNameController,
                    decoration: InputDecoration(
                      labelText: 'Team Name *',
                      hintText: 'Enter team name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.group),
                    ),
                    onChanged: (value) {
                      // Value will be set when creating team
                    },
                  ),
                  const SizedBox(height: 20),
                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: teamController.selectedCategory.value.isEmpty
                        ? null
                        : teamController.selectedCategory.value,
                    decoration: InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.category),
                    ),
                    items: teamController.categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        teamController.selectedCategory.value = value;
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  // Jury Multi-Select
                  Text(
                    'Jury (Select Multiple) *',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Obx(() {
                      final judgeController = Get.find<JudgeController>();
                      final List<JudgeModel> judges = judgeController.judges
                          .toList();
                      if (judgeController.isLoading.value) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 8),
                                Text('Loading judges...'),
                              ],
                            ),
                          ),
                        );
                      }

                      if (judgeController.judges.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: Text('No judges available')),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: judges.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, thickness: 1),
                        itemBuilder: (context, index) {
                          final judge = judges[index];
                          return Obx(() {
                            final isSelected = teamController.isJurySelected(
                              judge.id ?? '',
                            );
                            return CheckboxListTile(
                              title: Text(judge.name),
                              subtitle: Text(judge.designation),
                              value: isSelected,
                              dense: true,
                              onChanged: (bool? value) {
                                if (judge.id != null) {
                                  teamController.toggleJurySelection(judge.id!);
                                }
                              },
                            );
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  // Error Message
                  if (teamController.errorMessage.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        teamController.errorMessage.value,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          teamController.resetForm();
                          Navigator.of(dialogContext).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: teamController.isLoading.value
                            ? null
                            : () async {
                                teamController.teamName.value =
                                    teamNameController.text;
                                final success = await teamController.createTeam(
                                  eventId,
                                );
                                if (success && dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop();
                                  teamController.loadTeamsByEventId(eventId);
                                  // Refresh teams list - teams are already updated in controller
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: teamController.isLoading.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Create Team'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      );
    },
  );
}

void _showFilterDialog(
  BuildContext context,
  ParticipantController controller,
  String eventId,
) {
  final nameController = TextEditingController(
    text: controller.currentFilter.value.participant ?? '',
  );
  String? selectedStatus = controller.currentFilter.value.status;
  String? selectedCategory = controller.currentFilter.value.category;
  String? selectedGroup = controller.currentFilter.value.group;

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
                        value: 'Requested',
                        child: Text('Requested'),
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

                  // Category
                  DropdownButtonFormField<String?>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'common',
                        child: Text('Common'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'special',
                        child: Text('Special'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Group (Standard)
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        selectedGroup = value.isEmpty ? null : value;
                      });
                    },
                    controller: TextEditingController(
                      text: selectedGroup ?? '',
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Group (Standard)',
                      hintText: 'e.g., IV, V, VI',
                      prefixIcon: Icon(Icons.school),
                      border: OutlineInputBorder(),
                    ),
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
                    selectedCategory = null;
                    selectedGroup = null;
                  });
                },
                child: const Text('Clear'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    controller.currentFilter.value = controller
                        .currentFilter
                        .value
                        .copyWith(
                          participant: nameController.text.trim().isEmpty
                              ? null
                              : nameController.text.trim(),
                          status: selectedStatus,
                          category: selectedCategory,
                          group: selectedGroup,
                        );
                  });

                  Navigator.pop(context);
                  controller.loadParticipantsByEventId(
                    eventId,
                    resetPage: true,
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

Widget _buildEventTitleCard(BuildContext context, event) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppTheme.primaryColor.withOpacity(0.3),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 28,
            ),
          ),
          if (event.active) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Active',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Assign Participant Button (Admin Only)
                    Obx(() {
                      final authController = Get.find<AuthController>();
                      if (authController.isAdmin) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (event.id != null) {
                                    context.push(
                                      '/assign-participant/${event.id}',
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.assignment_ind,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Assign Participant',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.primaryColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (event.id != null) {
                                    context.pushNamed(
                                      'participant-scores-list',
                                      pathParameters: {'eventId': event.id!},
                                    );
                                  }
                                },
                                icon: const Icon(Icons.score, size: 18),
                                label: const Text(
                                  'View Scores',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.primaryColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push('/register/${event.id}');
                      },
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text(
                        'Register Now',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

Widget _buildEventDetailsSection(BuildContext context, event, bool isMobile) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildDateVenueCard(context, event),
      const SizedBox(height: 16),
      if (event.categories.isNotEmpty || event.ageGroups.isNotEmpty)
        _buildCategoriesCard(context, event),
      if (event.rules != null && event.rules!.isNotEmpty) ...[
        const SizedBox(height: 16),
        _buildRulesCard(context, event),
      ],
    ],
  );
}

Widget _buildDateVenueCard(BuildContext context, event) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date & Time Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Date & Time',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoItem(
            context,
            Icons.event,
            'Start Date',
            DateFormat('EEEE, MMMM dd, yyyy').format(event.startDate),
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            context,
            Icons.event_busy,
            'End Date',
            DateFormat('EEEE, MMMM dd, yyyy').format(event.endDate),
          ),
          const SizedBox(height: 24),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey[300]!,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Description Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.description,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            event.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.6,
              color: Colors.grey[700],
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey[300]!,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Venue Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Venue',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoItem(context, Icons.business, 'Location', event.venue),
          if (event.venueAddress != null) ...[
            const SizedBox(height: 16),
            _buildInfoItem(context, Icons.map, 'Address', event.venueAddress!),
          ],
        ],
      ),
    ),
  );
}

Widget _buildCategoriesCard(BuildContext context, event) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.categories.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.category,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Categories',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: event.categories.map((category) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.1),
                        AppTheme.primaryColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
            ),
            if (event.ageGroups.isNotEmpty) const SizedBox(height: 28),
          ],
          if (event.ageGroups.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.group,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Age Groups',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: event.ageGroups.map((ageGroup) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.1),
                        AppTheme.primaryColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    ageGroup,
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    ),
  );
}

Widget _buildRulesCard(BuildContext context, event) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.rule, color: AppTheme.primaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Text(
                'Rules & Guidelines',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...event.rules!.entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(color: AppTheme.primaryColor, width: 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: Colors.grey[700],
                      fontSize: 14,
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

Widget _buildInfoItem(
  BuildContext context,
  IconData icon,
  String label,
  String value,
) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[200]!, width: 1),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 22, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.grey[900],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildTeamsSection(BuildContext context, String eventId) {
  // Ensure TeamController is available
  if (!Get.isRegistered<TeamController>()) {
    Get.put(TeamController(), permanent: true);
  }
  final teamController = Get.find<TeamController>();
  final judgeController = Get.find<JudgeController>();

  return LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 600;

      return Obx(() {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.group,
                          color: AppTheme.primaryColor,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Teams',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                            ),
                            Text(
                              '${teamController.teams.length} team${teamController.teams.length != 1 ? 's' : ''}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Create Team Button (Admin Only)
                        Obx(() {
                          final authController = Get.find<AuthController>();
                          if (authController.isAdmin) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final eventController =
                                      Get.find<EventController>();
                                  final event =
                                      eventController.selectedEvent.value ??
                                      eventController.events.firstWhereOrNull(
                                        (e) => e.id == eventId,
                                      );
                                  if (event != null && event.id != null) {
                                    _showCreateTeamDialog(context, event.id!);
                                  }
                                },
                                icon: const Icon(Icons.group_add, size: 18),
                                label: const Text(
                                  'Create Team',
                                  style: TextStyle(
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
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            // Ensure TeamController is available
                            if (!Get.isRegistered<TeamController>()) {
                              Get.put(TeamController(), permanent: true);
                            }
                            final teamController = Get.find<TeamController>();
                            teamController.loadTeamsByEventId(eventId);
                          },
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Loading State
                if (teamController.isLoading.value)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                // Error State
                else if (teamController.errorMessage.value.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            teamController.errorMessage.value,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Ensure TeamController is available
                              if (!Get.isRegistered<TeamController>()) {
                                Get.put(TeamController(), permanent: true);
                              }
                              final teamController = Get.find<TeamController>();
                              teamController.loadTeamsByEventId(eventId);
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                // Empty State
                else if (teamController.teams.isEmpty)
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
                            'No teams created yet',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                // Teams List
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: teamController.teams.length,
                    itemBuilder: (context, index) {
                      final team = teamController.teams[index];
                      // Get judge names for this team
                      // First try to use juryList from API if available
                      List<String> judgeNames = [];
                      if (team.juryList != null && team.juryList!.isNotEmpty) {
                        judgeNames = team.juryList!
                            .map(
                              (jury) => jury['name']?.toString() ?? 'Unknown',
                            )
                            .where((name) => name.isNotEmpty)
                            .toList();
                      } else {
                        // Fallback to looking up by juryIds
                        judgeNames = team.juryIds.map((juryId) {
                          final judge = judgeController.judges.firstWhereOrNull(
                            (j) => j.id == juryId,
                          );
                          return judge?.name ?? 'Unknown';
                        }).toList();
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
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
                            radius: isMobile ? 24 : 20,
                            backgroundColor: AppTheme.primaryColor.withOpacity(
                              0.2,
                            ),
                            child: team.teamName.isNotEmpty
                                ? Text(
                                    team.teamName[0].toUpperCase(),
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isMobile ? 18 : 16,
                                    ),
                                  )
                                : Icon(
                                    Icons.group,
                                    color: AppTheme.primaryColor,
                                    size: isMobile ? 20 : 18,
                                  ),
                          ),
                          title: Text(
                            team.teamName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 16 : 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.category,
                                      size: 12,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Category: ${team.category}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (judgeNames.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.gavel,
                                        size: 12,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: judgeNames.map((name) {
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryColor
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: AppTheme.primaryColor
                                                      .withOpacity(0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                name,
                                                style: TextStyle(
                                                  color: AppTheme.primaryColor,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          trailing: Obx(() {
                            final authController = Get.find<AuthController>();
                            if (authController.isAdmin) {
                              return IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: AppTheme.primaryColor,
                                ),
                                onPressed: () {
                                  if (team.id != null) {
                                    _showEditTeamDialog(
                                      context,
                                      team.id!,
                                      eventId,
                                    );
                                  }
                                },
                                tooltip: 'Edit Team',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              );
                            }
                            return const SizedBox.shrink();
                          }),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      });
    },
  );
}
