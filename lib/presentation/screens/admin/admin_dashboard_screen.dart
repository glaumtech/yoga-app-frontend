import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/event_controller.dart';
import '../../widgets/section_header.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminController = Get.find<AdminController>();
    final authController = Get.find<AuthController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.05),
              Colors.white,
              AppTheme.secondaryColor.withOpacity(0.03),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.dashboard,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Dashboard',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                          ),
                          Text(
                            'Manage your championship',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: AppTheme.primaryColor),
                      onPressed: () => adminController.refreshDashboard(),
                      tooltip: 'Refresh',
                    ),
                    IconButton(
                      icon: Icon(Icons.logout, color: AppTheme.primaryColor),
                      onPressed: () async {
                        await authController.signOut();
                        context.go(AppRoutes.login);
                      },
                      tooltip: 'Logout',
                    ),
                  ],
                ),
              ),
              // Body Section
              Expanded(
                child: Obx(() {
                  if (adminController.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return RefreshIndicator(
                    onRefresh: () => adminController.refreshDashboard(),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Overview Cards
                          SectionHeader(title: 'Overview', showDivider: false),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = isMobile
                                  ? 1
                                  : isTablet
                                  ? 2
                                  : 4;
                              final padding = isMobile ? 8.0 : 12.0;

                              return GridView.count(
                                crossAxisCount: crossAxisCount,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: padding,
                                mainAxisSpacing: padding,
                                childAspectRatio: isMobile ? 2.0 : 1.3,
                                children: [
                                  _buildStatCard(
                                    context,
                                    'Total Events',
                                    adminController.totalEvents.value
                                        .toString(),
                                    Icons.event,
                                    AppTheme.primaryColor,
                                  ),
                                  _buildStatCard(
                                    context,
                                    'Active Events',
                                    adminController.activeEvents.value
                                        .toString(),
                                    Icons.event_available,
                                    AppTheme.secondaryColor,
                                  ),
                                  _buildStatCard(
                                    context,
                                    'Total Registrations',
                                    adminController.totalRegistrations.value
                                        .toString(),
                                    Icons.people,
                                    Colors.blue,
                                  ),
                                  _buildStatCard(
                                    context,
                                    'Pending',
                                    adminController.pendingRegistrations.value
                                        .toString(),
                                    Icons.pending,
                                    Colors.orange,
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // Quick Actions
                          SectionHeader(
                            title: 'Quick Actions',
                            showDivider: false,
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = isMobile
                                  ? 1
                                  : isTablet
                                  ? 2
                                  : 4;
                              final padding = isMobile ? 8.0 : 12.0;

                              return GridView.count(
                                crossAxisCount: crossAxisCount,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: padding,
                                mainAxisSpacing: padding,
                                childAspectRatio: isMobile ? 2.5 : 1.5,
                                children: [
                                  _buildActionCard(
                                    context,
                                    'Manage Events',
                                    Icons.event,
                                    AppTheme.primaryColor,
                                    () =>
                                        context.push(AppRoutes.eventManagement),
                                  ),
                                  _buildActionCard(
                                    context,
                                    'Manage Judges',
                                    Icons.gavel,
                                    Colors.teal,
                                    () =>
                                        context.push(AppRoutes.judgeManagement),
                                  ),
                                  _buildActionCard(
                                    context,
                                    'Schedule Management',
                                    Icons.schedule,
                                    Colors.orange,
                                    () => context.push(
                                      AppRoutes.scheduleManagement,
                                    ),
                                  ),
                                  _buildActionCard(
                                    context,
                                    'View Scores',
                                    Icons.score,
                                    Colors.purple,
                                    () => _showEventSelectionDialog(context),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, color.withOpacity(0.05)],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: isMobile ? 24 : 28),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: isMobile ? 24 : 28,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: isMobile ? 12 : 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, color.withOpacity(0.05)],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: isMobile ? 28 : 32),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 13 : 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEventSelectionDialog(BuildContext context) {
    final eventController = Get.find<EventController>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Event'),
        content: SizedBox(
          width: double.maxFinite,
          child: Obx(() {
            if (eventController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (eventController.events.isEmpty) {
              return const Text('No events available');
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: eventController.events.length,
              itemBuilder: (context, index) {
                final event = eventController.events[index];
                return ListTile(
                  leading: Icon(Icons.event, color: AppTheme.primaryColor),
                  title: Text(event.title),
                  subtitle: Text(
                    '${event.startDate.day}/${event.startDate.month}/${event.startDate.year}',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(
                      AppRoutes.participantScoresList.replaceAll(
                        ':eventId',
                        event.id ?? '',
                      ),
                    );
                  },
                );
              },
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
