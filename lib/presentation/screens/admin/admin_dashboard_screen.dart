import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../../controllers/competition_controller.dart';
import '../../widgets/section_header.dart';
import '../../widgets/admin_sidebar_layout.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  CompetitionController _competitionController() {
    return Get.isRegistered<CompetitionController>()
        ? Get.find<CompetitionController>()
        : Get.put(CompetitionController());
  }

  @override
  void initState() {
    super.initState();
    // Never call loadCompetitions from build(): it updates Rx (isLoading, etc.)
    // and can finish in the same frame on web, causing
    // "setState/markNeedsBuild called during build" on Obx ancestors.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final c = _competitionController();
      if (c.competitions.isEmpty && !c.isLoading.value) {
        c.loadCompetitions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final competitionController = _competitionController();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return AdminSidebarLayout(
      title: 'Admin Dashboard',
      child: Container(
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
                            'Manage your championship',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: AppTheme.primaryColor),
                      onPressed: () => competitionController.loadCompetitions(),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ),
              // Body Section
              Expanded(
                child: Obx(() {
                  if (competitionController.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return RefreshIndicator(
                    onRefresh: () => competitionController.loadCompetitions(),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Overview Cards
                          SectionHeader(title: 'Overview', showDivider: false),
                          const SizedBox(height: 16),
                          Obx(() {
                            final competitions =
                                competitionController.competitions;
                            final totalEventsCount = competitions.length;
                            final now = DateTime.now();
                            final activeEventsCount = competitions
                                .where((c) {
                                  final start = DateTime(
                                    c.eventStartDate.year,
                                    c.eventStartDate.month,
                                    c.eventStartDate.day,
                                  );
                                  final end = DateTime(
                                    c.eventEndDate.year,
                                    c.eventEndDate.month,
                                    c.eventEndDate.day,
                                    23,
                                    59,
                                    59,
                                  );
                                  return !now.isBefore(start) &&
                                      !now.isAfter(end);
                                })
                                .length;

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
                                  'Total Competitions',
                                  totalEventsCount.toString(),
                                  Icons.event,
                                  AppTheme.primaryColor,
                                ),
                                _buildStatCard(
                                  context,
                                  'Active Competitions',
                                  activeEventsCount.toString(),
                                  Icons.event_available,
                                  AppTheme.secondaryColor,
                                ),
                              ],
                            );
                          }),
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
                                    'Competitions',
                                    Icons.emoji_events,
                                    AppTheme.primaryColor,
                                    () => _openCompetitionsList(context),
                                  ),
                                  _buildActionCard(
                                    context,
                                    'Users',
                                    Icons.people,
                                    Colors.teal,
                                    () => context.push(
                                      AppRoutes.userManagement,
                                    ),
                                  ),
                                  _buildActionCard(
                                    context,
                                    'Participants',
                                    Icons.groups,
                                    Colors.orange,
                                    () => context.push(
                                      AppRoutes.participantManagement,
                                    ),
                                  ),
                                  _buildActionCard(
                                    context,
                                    'View Scores',
                                    Icons.score,
                                    Colors.purple,
                                    () => context.push(AppRoutes.reports),
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

  /// Opens [CreateCompetitionScreen] with the competitions list tab selected.
  void _openCompetitionsList(BuildContext context) {
    final cc = Get.isRegistered<CompetitionController>()
        ? Get.find<CompetitionController>()
        : Get.put(CompetitionController());
    cc.isListView.value = true;
    context.push(AppRoutes.createCompetition);
  }
}
