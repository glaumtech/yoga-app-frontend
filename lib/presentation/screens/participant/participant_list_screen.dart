import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/participant_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../data/models/participant_model.dart';

class ParticipantListScreen extends StatelessWidget {
  const ParticipantListScreen({super.key});

  Widget _buildMoreOptionsMenu(
    BuildContext context,
    ParticipantModel participant,
    ParticipantController participantController, {
    required bool isAdmin,
    required bool isJudge,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: PopupMenuButton(
        icon: Icon(Icons.more_vert, color: Colors.grey.shade700, size: 20),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        itemBuilder: (context) {
          final items = <PopupMenuItem<String>>[];

          // Edit option - only for admin
          if (isAdmin) {
            items.add(
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 12),
                    Text('Edit'),
                  ],
                ),
              ),
            );
          }

          // Scores option - for both admin and judge
          if (isAdmin || isJudge) {
            items.add(
              const PopupMenuItem(
                value: 'scores',
                child: Row(
                  children: [
                    Icon(Icons.score, size: 20),
                    SizedBox(width: 12),
                    Text('Add Scores'),
                  ],
                ),
              ),
            );
          }

          // Delete option - only for admin
          if (isAdmin) {
            items.add(
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            );
          }

          return items;
        },
        onSelected: (value) {
          if (value == 'edit') {
            context.push(AppRoutes.registrationForm, extra: participant);
          } else if (value == 'scores') {
            context.push(AppRoutes.adminScoring, extra: participant);
          } else if (value == 'delete') {
            _showDeleteDialog(context, participantController, participant.id!);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final participantController = Get.find<ParticipantController>();
    final authController = Get.find<AuthController>();
    final isAdmin = authController.isAdmin;
    final isJudge =
        authController.currentUser.value?.roleName.toUpperCase().contains(
          'JUDGE',
        ) ??
        false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Participants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, participantController),
            tooltip: 'Filter',
          ),
          Obx(() {
            final hasActiveFilter =
                participantController.currentFilter.value.participant != null &&
                    participantController
                        .currentFilter
                        .value
                        .participant!
                        .isNotEmpty ||
                participantController.currentFilter.value.status != null &&
                    participantController
                        .currentFilter
                        .value
                        .status!
                        .isNotEmpty;
            if (hasActiveFilter) {
              return IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  participantController.resetFilter();
                  // TODO: This screen needs eventId to load participants
                  // participantController.loadParticipantsByEventId(eventId, resetPage: true);
                  Get.snackbar(
                    'Info',
                    'Please select an event to view participants',
                  );
                },
                tooltip: 'Clear Filter',
              );
            }
            return const SizedBox.shrink();
          }),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // TODO: This screen needs eventId - participants can only be loaded by event
                Get.snackbar(
                  'Info',
                  'Participants can only be viewed by event. Please navigate to an event details page.',
                );
              },
            ),
        ],
      ),
      body: Obx(() {
        if (participantController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (participantController.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  participantController.errorMessage.value,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // TODO: This screen needs eventId - participants can only be loaded by event
                    Get.snackbar(
                      'Info',
                      'Participants can only be viewed by event. Please navigate to an event details page.',
                    );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (participantController.participants.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No participants registered yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          // TODO: This screen needs eventId - participants can only be loaded by event
          onRefresh: () async {
            Get.snackbar(
              'Info',
              'Participants can only be viewed by event. Please navigate to an event details page.',
            );
          },
          child: Column(
            children: [
              // Filter info and pagination info
              Obx(() {
                if (participantController.totalItems.value > 0) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.grey[100],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total: ${participantController.totalItems.value} | '
                          'Page ${participantController.currentPage.value}/'
                          '${participantController.totalPages.value}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (participantController
                                    .currentFilter
                                    .value
                                    .participant !=
                                null ||
                            participantController.currentFilter.value.status !=
                                null)
                          Chip(
                            label: const Text('Filtered'),
                            avatar: const Icon(Icons.filter_alt, size: 16),
                            onDeleted: () {
                              participantController.resetFilter();
                              // TODO: This screen needs eventId - participants can only be loaded by event
                              Get.snackbar(
                                'Info',
                                'Participants can only be filtered by event. Please navigate to an event details page.',
                              );
                            },
                          ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              // Participants list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      participantController.participants.length +
                      (participantController.hasMorePages.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == participantController.participants.length) {
                      // Load more button
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: ElevatedButton(
                            onPressed: participantController.isLoading.value
                                ? null
                                : () {
                                    // TODO: This screen needs eventId - participants can only be loaded by event
                                    Get.snackbar(
                                      'Info',
                                      'Participants can only be viewed by event. Please navigate to an event details page.',
                                    );
                                  },
                            child: const Text('Load More'),
                          ),
                        ),
                      );
                    }
                    final participant =
                        participantController.participants[index];

                    // Determine background color and border color based on status
                    Color cardColor;
                    Color borderColor;
                    if (participant.status == 'accepted') {
                      cardColor = Colors.green.shade50;
                      borderColor = Colors.green.shade200;
                    } else if (participant.status == 'rejected') {
                      cardColor = Colors.red.shade50;
                      borderColor = Colors.red.shade200;
                    } else if (participant.status?.toLowerCase() ==
                            'requested' ||
                        participant.status == 'pending') {
                      cardColor = Colors.white;
                      borderColor = Colors.orange.shade200;
                    } else {
                      cardColor = Colors.white;
                      borderColor = Colors.grey.shade300;
                    }

                    // Status badge color
                    Color statusBadgeColor;
                    if (participant.status == 'accepted') {
                      statusBadgeColor = Colors.green;
                    } else if (participant.status == 'rejected') {
                      statusBadgeColor = Colors.red;
                    } else if (participant.status?.toLowerCase() ==
                            'requested' ||
                        participant.status == 'pending') {
                      statusBadgeColor = Colors.orange;
                    } else {
                      statusBadgeColor = Colors.grey;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: borderColor, width: 1.5),
                      ),
                      color: cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            Container(
                              margin: const EdgeInsets.only(right: 16),
                              child: CircleAvatar(
                                radius: 35,
                                backgroundColor: borderColor.withOpacity(0.2),
                                child: participant.photoUrl != null
                                    ? ClipOval(
                                        child: Image.network(
                                          participant.photoUrl!,
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Text(
                                                  participant
                                                          .participantName
                                                          .isNotEmpty
                                                      ? participant
                                                            .participantName[0]
                                                            .toUpperCase()
                                                      : '?',
                                                  style: const TextStyle(
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                );
                                              },
                                        ),
                                      )
                                    : Text(
                                        participant.participantName.isNotEmpty
                                            ? participant.participantName[0]
                                                  .toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: borderColor,
                                        ),
                                      ),
                              ),
                            ),
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Name Row (Status badge removed - now in action buttons column)
                                  Text(
                                    participant.participantName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Details
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Age: ${participant.age} | ${participant.gender}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.school_outlined,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Standard: ${participant.standard}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          participant.schoolName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (participant.grandTotal != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.star,
                                            size: 16,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Grand Total: ${participant.grandTotal!.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Action Buttons
                            if (isAdmin)
                              Container(
                                margin: const EdgeInsets.only(left: 12),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    // Accept/Reject buttons - only show if status is 'Requested'
                                    if (participant.status?.toLowerCase() ==
                                            'requested' ||
                                        (participant.status == null ||
                                            participant.status ==
                                                'pending')) ...[
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.green.shade300,
                                                width: 2,
                                              ),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                                size: 22,
                                              ),
                                              onPressed: () {
                                                participantController
                                                    .updateParticipantStatus(
                                                      participant.id!,
                                                      'accepted',
                                                    );
                                              },
                                              tooltip: 'Accept',
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.red.shade300,
                                                width: 2,
                                              ),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.cancel,
                                                color: Colors.red,
                                                size: 22,
                                              ),
                                              onPressed: () {
                                                participantController
                                                    .updateParticipantStatus(
                                                      participant.id!,
                                                      'rejected',
                                                    );
                                              },
                                              tooltip: 'Reject',
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // More options menu for requested status
                                          _buildMoreOptionsMenu(
                                            context,
                                            participant,
                                            participantController,
                                            isAdmin: isAdmin,
                                            isJudge: isJudge,
                                          ),
                                        ],
                                      ),
                                      // Status badge below action buttons for requested/pending status
                                      if (participant.status != null &&
                                          participant.status != 'accepted' &&
                                          participant.status != 'rejected') ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusBadgeColor,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: statusBadgeColor
                                                    .withOpacity(0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            participant.status!.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                    // More options menu for accepted/rejected status
                                    if (participant.status != null &&
                                        (participant.status == 'accepted' ||
                                            participant.status == 'rejected'))
                                      _buildMoreOptionsMenu(
                                        context,
                                        participant,
                                        participantController,
                                        isAdmin: isAdmin,
                                        isJudge: isJudge,
                                      ),
                                    // Status badge below action buttons for accepted/rejected
                                    if (participant.status != null &&
                                        (participant.status == 'accepted' ||
                                            participant.status ==
                                                'rejected')) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusBadgeColor,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: statusBadgeColor
                                                  .withOpacity(0.3),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          participant.status!.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(AppRoutes.registrationForm);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    ParticipantController controller,
    String participantId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Participant'),
        content: const Text(
          'Are you sure you want to delete this participant?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await controller.deleteParticipant(participantId);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Participant deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(
    BuildContext context,
    ParticipantController controller,
  ) {
    final nameController = TextEditingController(
      text: controller.currentFilter.value.participant ?? '',
    );
    final pageSizeController = TextEditingController(
      text: controller.currentFilter.value.size.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Get initial values and validate them
            String? initialStatus = controller.currentFilter.value.status;
            String? initialSortBy = controller.currentFilter.value.sortBy;
            String initialSortDirection =
                controller.currentFilter.value.sortDirection ?? 'asc';

            // Validate status - ensure it's one of the valid options or null
            final validStatuses = ['accepted', 'pending', 'rejected'];
            String? selectedStatus = validStatuses.contains(initialStatus)
                ? initialStatus
                : null;

            // Validate sortBy - ensure it's one of the valid options or null
            final validSortBy = [
              'schoolName',
              'participantName',
              'createdAt',
              'grandTotal',
            ];
            String? selectedSortBy = validSortBy.contains(initialSortBy)
                ? initialSortBy
                : null;

            // Validate sortDirection - ensure it's 'asc' or 'desc'
            String selectedSortDirection =
                (initialSortDirection == 'asc' ||
                    initialSortDirection == 'desc')
                ? initialSortDirection
                : 'asc';

            return AlertDialog(
              title: const Text('Filter Participants'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Participant Name
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Participant Name',
                        hintText: 'Enter name to search',
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
                          value: 'accepted',
                          child: Text('Accepted'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'pending',
                          child: Text('Pending'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'rejected',
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

                    // Sort By
                    DropdownButtonFormField<String?>(
                      value: selectedSortBy,
                      decoration: const InputDecoration(
                        labelText: 'Sort By',
                        prefixIcon: Icon(Icons.sort),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('None'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'schoolName',
                          child: Text('School Name'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'participantName',
                          child: Text('Participant Name'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'createdAt',
                          child: Text('Created Date'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'grandTotal',
                          child: Text('Grand Total'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedSortBy = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Sort Direction
                    DropdownButtonFormField<String>(
                      value: selectedSortDirection,
                      decoration: const InputDecoration(
                        labelText: 'Sort Direction',
                        prefixIcon: Icon(Icons.arrow_upward),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'asc',
                          child: Text('Ascending'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'desc',
                          child: Text('Descending'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedSortDirection = value ?? 'asc';
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Page Size
                    TextField(
                      controller: pageSizeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Page Size',
                        hintText: '10',
                        prefixIcon: Icon(Icons.list),
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
                      selectedSortBy = null;
                      selectedSortDirection = 'asc';
                      pageSizeController.text = '10';
                    });
                  },
                  child: const Text('Clear'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: This screen needs eventId - participants can only be loaded by event
                    Get.snackbar(
                      'Info',
                      'Participants can only be filtered by event. Please navigate to an event details page.',
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
