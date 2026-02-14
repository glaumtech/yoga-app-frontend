import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/user_management_controller.dart';
import '../../controllers/event_controller.dart';
import '../../widgets/custom_loader.dart';
import '../../../data/models/user_management_model.dart';

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserManagementController>();
    final eventController = Get.find<EventController>();

    // Load events if empty
    if (eventController.events.isEmpty && !eventController.isLoading.value) {
      eventController.loadEvents();
    }

    // Load users on first build
    if (userController.users.isEmpty && !userController.isLoading.value) {
      userController.loadUsers();
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
              userController,
              eventController,
              isMobile,
              isTablet,
            ),
            SizedBox(height: isMobile ? 16 : 24),
            // Users List
            Expanded(
              child: Obx(() {
                if (userController.isLoading.value) {
                  return const Center(child: CustomLoader());
                }

                if (userController.errorMessage.value.isNotEmpty) {
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
                          userController.errorMessage.value,
                          style: TextStyle(color: Colors.red[700]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            final eventId =
                                userController.selectedEventId.value.isNotEmpty
                                ? int.tryParse(
                                    userController.selectedEventId.value,
                                  )
                                : null;
                            userController.loadUsers(eventId: eventId);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final filteredUsers = userController.filteredUsers;

                if (filteredUsers.isEmpty) {
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
                          userController.searchQuery.value.isNotEmpty
                              ? 'No users found matching your search'
                              : 'No users found',
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
                    filteredUsers,
                    userController,
                  );
                } else {
                  return _buildDesktopTable(
                    context,
                    filteredUsers,
                    userController,
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
    UserManagementController controller,
    EventController eventController,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      children: [
        // Search Bar
        TextField(
          onChanged: (value) => controller.searchQuery.value = value,
          decoration: InputDecoration(
            hintText: 'Search by name, type, or competition...',
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown and Refresh Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(
                  () => isMobile
                      ? Expanded(
                          child: DropdownButtonFormField<int?>(
                            value: controller.selectedEventId.value.isNotEmpty
                                ? int.tryParse(controller.selectedEventId.value)
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
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text(
                                  'All Competitions',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              ...eventController.events
                                  .where((event) => event.id != null)
                                  .map((event) {
                                    return DropdownMenuItem<int?>(
                                      value: int.tryParse(event.id!),
                                      child: Text(
                                        event.title,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                controller.selectedEventId.value = value
                                    .toString();
                              } else {
                                controller.selectedEventId.value = '';
                              }
                              controller.loadUsers(eventId: value);
                            },
                          ),
                        )
                      : SizedBox(
                          width: isTablet ? 320 : 360,
                          child: DropdownButtonFormField<int?>(
                            value: controller.selectedEventId.value.isNotEmpty
                                ? int.tryParse(controller.selectedEventId.value)
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
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text(
                                  'All Competitions',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              ...eventController.events
                                  .where((event) => event.id != null)
                                  .map((event) {
                                    return DropdownMenuItem<int?>(
                                      value: int.tryParse(event.id!),
                                      child: Text(
                                        event.title,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                controller.selectedEventId.value = value
                                    .toString();
                              } else {
                                controller.selectedEventId.value = '';
                              }
                              controller.loadUsers(eventId: value);
                            },
                          ),
                        ),
                ),
                SizedBox(width: isMobile ? 8 : 12),
                // Refresh Button
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    final eventId = controller.selectedEventId.value.isNotEmpty
                        ? int.tryParse(controller.selectedEventId.value)
                        : null;
                    controller.loadUsers(eventId: eventId);
                  },
                  tooltip: 'Refresh',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileList(
    BuildContext context,
    List<UserManagementModel> users,
    UserManagementController controller,
  ) {
    return RefreshIndicator(
      onRefresh: () {
        final eventId = controller.selectedEventId.value.isNotEmpty
            ? int.tryParse(controller.selectedEventId.value)
            : null;
        return controller.loadUsers(eventId: eventId);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
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
                      // Photo
                      _buildUserPhoto(user, 50),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildTypeChip(user.type),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildUserInfoRow('Competition', user.eventName ?? 'N/A'),
                  if (user.volunteerNo != null)
                    _buildUserInfoRow('Volunteer No', user.volunteerNo!),
                  if (user.cell != null) _buildUserInfoRow('Cell', user.cell!),
                  if (user.permissions.isNotEmpty)
                    _buildUserInfoRow(
                      'Permissions',
                      user.permissions.join(', '),
                    ),
                  if (user.stages.isNotEmpty)
                    _buildUserInfoRow('Stages', user.stages.join(', ')),
                  if (user.categories.isNotEmpty)
                    _buildUserInfoRow('Categories', user.categories.join(', ')),
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
    List<UserManagementModel> users,
    UserManagementController controller,
    bool isTablet,
  ) {
    return RefreshIndicator(
      onRefresh: () {
        final eventId = controller.selectedEventId.value.isNotEmpty
            ? int.tryParse(controller.selectedEventId.value)
            : null;
        return controller.loadUsers(eventId: eventId);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = constraints.maxWidth - 32; // Account for padding
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
                    2: FlexColumnWidth(1.5),
                    3: FlexColumnWidth(2.5),
                    4: FlexColumnWidth(1.5),
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
                        _buildTableCell('TYPE', isHeader: true),
                        _buildTableCell('COMPETITION', isHeader: true),
                        _buildTableCell('CELL', isHeader: true),
                      ],
                    ),
                    // Data Rows
                    ...users.map((user) {
                      return TableRow(
                        children: [
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Center(child: _buildUserPhoto(user, 40)),
                            ),
                          ),
                          _buildTableCell(user.name),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Center(child: _buildTypeChip(user.type)),
                            ),
                          ),
                          _buildTableCell(user.eventName ?? 'N/A'),
                          _buildTableCell(user.cell ?? 'N/A'),
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

  Widget _buildUserPhoto(UserManagementModel user, double size) {
    final firstLetter = (user.name.isNotEmpty ? user.name[0] : 'U')
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

  Widget _buildTypeChip(String type) {
    Color chipColor;
    switch (type.toUpperCase()) {
      case 'SUB ADMIN':
        chipColor = Colors.blue;
        break;
      case 'SPOT REG ADMIN(S)':
        chipColor = Colors.orange;
        break;
      case 'JURY(S)':
        chipColor = Colors.purple;
        break;
      case 'VOLUNTEERS':
        chipColor = Colors.green;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.5)),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildUserInfoRow(String label, String value) {
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
