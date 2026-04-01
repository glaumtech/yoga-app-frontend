import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../controllers/user_management_controller.dart';
import '../../controllers/competition_controller.dart';
import '../../controllers/users_list_controller.dart';
import '../../widgets/custom_loader.dart';
import '../../../data/models/user_management_model.dart';

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Keep screen Stateless: initialization happens in UsersListController.onReady()
    Get.put(UsersListController());

    final userController = Get.find<UserManagementController>();
    final competitionController = Get.put(CompetitionController());

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
              competitionController,
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
                Obx(() {
                  final competitions = competitionController.competitions
                      .where((competition) => competition.id != null)
                      .toList();
                  final currentValue =
                      controller.selectedEventId.value.isNotEmpty
                      ? int.tryParse(controller.selectedEventId.value)
                      : (competitions.isNotEmpty
                            ? int.tryParse(competitions.first.id!)
                            : null);

                  return isMobile
                      ? Expanded(
                          child: DropdownButtonFormField<int>(
                            value: currentValue,
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
                            items: competitions.map((competition) {
                              return DropdownMenuItem<int>(
                                value: int.tryParse(competition.id!),
                                child: Text(
                                  competition.competitionName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                controller.selectedEventId.value = value
                                    .toString();
                                controller.loadUsers(eventId: value);
                              }
                            },
                          ),
                        )
                      : SizedBox(
                          width: isTablet ? 320 : 360,
                          child: DropdownButtonFormField<int>(
                            value: currentValue,
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
                            items: competitions.map((competition) {
                              return DropdownMenuItem<int>(
                                value: int.tryParse(competition.id!),
                                child: Text(
                                  competition.competitionName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                controller.selectedEventId.value = value
                                    .toString();
                                controller.loadUsers(eventId: value);
                              }
                            },
                          ),
                        );
                }),
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
                  _buildUserInfoRow(
                    'USER NAME',
                    (user.userName != null && user.userName!.trim().isNotEmpty)
                        ? user.userName!.trim()
                        : '—',
                  ),
                  _buildUserInfoRow('NAME', user.name),
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
                  if (user.createdAt != null)
                    _buildUserInfoRow('Created', _buildCreatedCell(user)),
                  if (user.updatedAt != null)
                    _buildUserInfoRow('Updated', _buildUpdatedCell(user)),
                  Obx(() {
                    final typeName =
                        (controller.currentUser.value?.userTypeName ??
                                controller.currentUser.value?.type ??
                                '')
                            .trim()
                            .toUpperCase()
                            .replaceAll(' ', '_');
                    final canViewPassword =
                        typeName == 'SUB_ADMIN' || typeName == 'BRANCH_ADMIN';

                    if (canViewPassword &&
                        (user.confirmPassword != null ||
                            user.password != null)) {
                      return _buildPasswordInfoRow(
                        context,
                        user.confirmPassword ?? user.password ?? 'N/A',
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  const SizedBox(height: 12),
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          controller.initializeFormForEdit(user);
                          controller.toggleViewMode(false);
                        },
                        icon: Icon(
                          Icons.edit,
                          size: 18,
                          color: AppTheme.primaryColor,
                        ),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          if (user.id != null) {
                            _showDeleteDialog(context, controller, user);
                          }
                        },
                        icon: const Icon(
                          Icons.delete,
                          size: 18,
                          color: Colors.red,
                        ),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
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

  void _showDeleteDialog(
    BuildContext context,
    UserManagementController controller,
    UserManagementModel user,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${user.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (user.id != null) {
                try {
                  final success = await controller.deleteUser(user.id!);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          controller.errorMessage.value.isNotEmpty
                              ? controller.errorMessage.value
                              : 'Failed to delete user',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete user: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
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

  /// API `userName` (`user_name`); em dash when unset.
  String _apiUserNameCell(UserManagementModel user) {
    final u = user.userName?.trim();
    if (u != null && u.isNotEmpty) return u;
    return '—';
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
                child: Obx(() {
                  final typeName =
                      (controller.currentUser.value?.userTypeName ??
                              controller.currentUser.value?.type ??
                              '')
                          .trim()
                          .toUpperCase()
                          .replaceAll(' ', '_');
                  final canViewPassword =
                      typeName == 'SUB_ADMIN' || typeName == 'BRANCH_ADMIN';

                  return Table(
                    border: TableBorder.all(color: Colors.grey[300]!, width: 1),
                    columnWidths: canViewPassword
                        ? {
                            0: const FixedColumnWidth(80),
                            1: FlexColumnWidth(1.8), // API userName
                            2: FlexColumnWidth(1.8), // API name
                            3: FlexColumnWidth(1.4),
                            4: FlexColumnWidth(2.2),
                            5: FlexColumnWidth(1.2), // Password
                            6: FlexColumnWidth(1.4), // Created
                            7: FlexColumnWidth(1.4), // Updated
                            8: const FixedColumnWidth(120),
                          }
                        : {
                            0: const FixedColumnWidth(80),
                            1: FlexColumnWidth(1.8), // API userName
                            2: FlexColumnWidth(1.8), // API name
                            3: FlexColumnWidth(1.4),
                            4: FlexColumnWidth(2.2),
                            5: FlexColumnWidth(1.4), // Created
                            6: FlexColumnWidth(1.4), // Updated
                            7: const FixedColumnWidth(120),
                          },
                    children: [
                      // Header Row
                      TableRow(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                        ),
                        children: canViewPassword
                            ? [
                                _buildTableCell('PHOTO', isHeader: true),
                                _buildTableCell('USER NAME', isHeader: true),
                                _buildTableCell('NAME', isHeader: true),
                                _buildTableCell('TYPE', isHeader: true),
                                _buildTableCell('COMPETITION', isHeader: true),
                                _buildTableCell('PASSWORD', isHeader: true),
                                _buildTableCell('CREATED', isHeader: true),
                                _buildTableCell('UPDATED', isHeader: true),
                                _buildTableCell('ACTIONS', isHeader: true),
                              ]
                            : [
                                _buildTableCell('PHOTO', isHeader: true),
                                _buildTableCell('USER NAME', isHeader: true),
                                _buildTableCell('NAME', isHeader: true),
                                _buildTableCell('TYPE', isHeader: true),
                                _buildTableCell('COMPETITION', isHeader: true),
                                _buildTableCell('CREATED', isHeader: true),
                                _buildTableCell('UPDATED', isHeader: true),
                                _buildTableCell('ACTIONS', isHeader: true),
                              ],
                      ),
                      // Data Rows
                      ...users.map((user) {
                        return TableRow(
                          children: canViewPassword
                              ? [
                                  TableCell(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Center(
                                        child: _buildUserPhoto(user, 40),
                                      ),
                                    ),
                                  ),
                                  _buildTableCell(_apiUserNameCell(user)),
                                  _buildTableCell(user.name),
                                  TableCell(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Center(
                                        child: _buildTypeChip(user.type),
                                      ),
                                    ),
                                  ),
                                  _buildTableCell(user.eventName ?? 'N/A'),
                                  _buildPasswordTableCell(
                                    context,
                                    user.confirmPassword ??
                                        user.password ??
                                        'N/A',
                                  ),
                                  _buildTableCell(_buildCreatedCell(user)),
                                  _buildTableCell(_buildUpdatedCell(user)),
                                  _buildActionCell(context, user, controller),
                                ]
                              : [
                                  TableCell(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Center(
                                        child: _buildUserPhoto(user, 40),
                                      ),
                                    ),
                                  ),
                                  _buildTableCell(_apiUserNameCell(user)),
                                  _buildTableCell(user.name),
                                  TableCell(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Center(
                                        child: _buildTypeChip(user.type),
                                      ),
                                    ),
                                  ),
                                  _buildTableCell(user.eventName ?? 'N/A'),
                                  _buildTableCell(_buildCreatedCell(user)),
                                  _buildTableCell(_buildUpdatedCell(user)),
                                  _buildActionCell(context, user, controller),
                                ],
                        );
                      }).toList(),
                    ],
                  );
                }),
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

  /// Password column with copy (super-admin table).
  Widget _buildPasswordTableCell(BuildContext context, String display) {
    final canCopy = display.trim().isNotEmpty && display != 'N/A';
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  display,
                  style: const TextStyle(fontSize: 13),
                  softWrap: true,
                  maxLines: null,
                ),
              ),
            ),
            if (canCopy)
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                tooltip: 'Copy password',
                onPressed: () =>
                    _copyPasswordToClipboard(context, display.trim()),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
          ],
        ),
      ),
    );
  }

  void _copyPasswordToClipboard(BuildContext context, String password) {
    Clipboard.setData(ClipboardData(text: password));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password copied to clipboard'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Mobile card password row with copy.
  Widget _buildPasswordInfoRow(BuildContext context, String password) {
    final canCopy = password.trim().isNotEmpty && password != 'N/A';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              'Password:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(child: Text(password, style: const TextStyle(fontSize: 14))),
          if (canCopy)
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              tooltip: 'Copy password',
              onPressed: () =>
                  _copyPasswordToClipboard(context, password.trim()),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
        ],
      ),
    );
  }

  Widget _buildUserPhoto(UserManagementModel user, double size) {
    final photoUrl = user.displayPhotoUrl;
    final firstLetter = (user.name.isNotEmpty ? user.name[0] : 'U')
        .toUpperCase();

    // Construct full photo URL if we have a user ID and photo path
    String? fullPhotoUrl;
    if (user.id != null && photoUrl != null && photoUrl.isNotEmpty) {
      // If photoUrl is already a full URL, use it; otherwise construct it
      if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
        fullPhotoUrl = photoUrl;
      } else {
        // Construct full URL using the user photo endpoint
        fullPhotoUrl = '${BaseUrl.baseUrl}${EndPoints.userPhoto(user.id!)}';
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
        border: Border.all(color: Colors.grey[400]!, width: 2),
      ),
      child: fullPhotoUrl != null && fullPhotoUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                fullPhotoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildInitialsAvatar(firstLetter, size);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                    ),
                  );
                },
              ),
            )
          : _buildInitialsAvatar(firstLetter, size),
    );
  }

  Widget _buildInitialsAvatar(String firstLetter, double size) {
    return Container(
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

  String _buildCreatedCell(UserManagementModel user) {
    if (user.createdAt == null) {
      return '-';
    }
    final dateTime = DateFormat('MMM dd, yyyy hh:mm a').format(user.createdAt!);
    if (user.createdBy != null && user.createdBy!.isNotEmpty) {
      return '$dateTime\nby ${user.createdBy}';
    }
    return dateTime;
  }

  String _buildUpdatedCell(UserManagementModel user) {
    if (user.updatedAt == null) {
      return '-';
    }
    final dateTime = DateFormat('MMM dd, yyyy hh:mm a').format(user.updatedAt!);
    if (user.updatedBy != null && user.updatedBy!.isNotEmpty) {
      return '$dateTime\nby ${user.updatedBy}';
    }
    return dateTime;
  }

  Widget _buildActionCell(
    BuildContext context,
    UserManagementModel user,
    UserManagementController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.edit, size: 18, color: AppTheme.primaryColor),
            onPressed: () {
              controller.initializeFormForEdit(user);
              controller.toggleViewMode(false);
            },
            tooltip: 'Edit',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
            onPressed: () {
              if (user.id != null) {
                _showDeleteDialog(context, controller, user);
              }
            },
            tooltip: 'Delete',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
