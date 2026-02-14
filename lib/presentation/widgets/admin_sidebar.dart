import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../controllers/auth_controller.dart';

/// Admin and Sub-Admin persistent sidebar
/// Menu not needed for Juries
class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final currentUser = authController.currentUser.value;
    final currentLocation = GoRouterState.of(context).uri.path;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Container(
      width: isMobile ? double.infinity : (isTablet ? 120 : 250),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : (isTablet ? 12 : 16)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: isTablet
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.self_improvement,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Yogasana',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          (currentUser?.name ?? 'admin').toLowerCase(),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 10,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isMobile ? 10 : 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.self_improvement,
                            color: AppTheme.primaryColor,
                            size: isMobile ? 28 : 32,
                          ),
                        ),
                        SizedBox(width: isMobile ? 8 : 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Yogasana',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isMobile ? 18 : 20,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                (currentUser?.name ?? 'admin').toLowerCase(),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: isMobile ? 11 : 12,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    context,
                    title: 'USERS',
                    icon: Icons.person_add,
                    route: AppRoutes.userManagement,
                    currentLocation: currentLocation,
                    onTap: () {
                      context.push(AppRoutes.userManagement);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    title: 'CREATE COMPETITION',
                    icon: Icons.event,
                    route: AppRoutes.createCompetition,
                    currentLocation: currentLocation,
                    onTap: () {
                      context.push(AppRoutes.createCompetition);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    title: 'PARTICIPANT REGISTRATION',
                    icon: Icons.person_add_alt_1,
                    route: AppRoutes.participantManagement,
                    currentLocation: currentLocation,
                    onTap: () {
                      context.push(AppRoutes.participantManagement);
                    },
                  ),
                  // REGISTRATION menu item hidden for now
                  // _buildMenuItem(
                  //   context,
                  //   title: 'REGISTRATION',
                  //   icon: Icons.app_registration,
                  //   route: AppRoutes.events,
                  //   currentLocation: currentLocation,
                  //   onTap: () {
                  //     context.push(AppRoutes.events);
                  //   },
                  // ),
                  _buildMenuItem(
                    context,
                    title: 'SCHOOLS & COLLEGE LIST',
                    icon: Icons.school,
                    route: AppRoutes.schoolsList,
                    currentLocation: currentLocation,
                    onTap: () {
                      context.push(AppRoutes.schoolsList);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    title: 'REPORTS',
                    icon: Icons.assessment,
                    route: AppRoutes.reports,
                    currentLocation: currentLocation,
                    onTap: () {
                      context.push(AppRoutes.reports);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    title: 'SPONSORS',
                    icon: Icons.business,
                    route: AppRoutes.sponsors,
                    currentLocation: currentLocation,
                    onTap: () {
                      context.push(AppRoutes.sponsors);
                    },
                  ),
                ],
              ),
            ),

            // Logout Button
            Container(
              margin: const EdgeInsets.all(16),
              child: _buildLogoutButton(
                context,
                onTap: () async {
                  await authController.signOut();
                  if (context.mounted) {
                    context.go(AppRoutes.login);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String route,
    required String currentLocation,
    required VoidCallback onTap,
  }) {
    // Check if this menu item is active
    final isActive =
        currentLocation == route ||
        (route == AppRoutes.events &&
            (currentLocation.startsWith('/events') ||
                currentLocation.startsWith('/register'))) ||
        (route == AppRoutes.judgeManagement &&
            currentLocation.contains('/judges')) ||
        (route == AppRoutes.userManagement &&
            currentLocation.contains('/users')) ||
        (route == AppRoutes.participantManagement &&
            currentLocation.contains('/admin/participants')) ||
        (route == AppRoutes.eventManagement &&
            currentLocation.contains('/admin/events')) ||
        (route == AppRoutes.createCompetition &&
            currentLocation.contains('/admin/competitions')) ||
        (route == AppRoutes.schoolsList &&
            currentLocation.contains('/schools')) ||
        (route == AppRoutes.reports && currentLocation.contains('/reports')) ||
        (route == AppRoutes.sponsors && currentLocation.contains('/sponsors'));

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : (isTablet ? 8 : 16),
          vertical: isMobile ? 12 : (isTablet ? 10 : 14),
        ),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
        ),
        child: isTablet
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 6 : 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: isMobile ? 20 : 24,
                    ),
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        fontSize: isMobile ? 13 : 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      softWrap: true,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white.withOpacity(0.7),
                    size: isMobile ? 18 : 20,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLogoutButton(
    BuildContext context, {
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : (isTablet ? 8 : 16),
          vertical: isMobile ? 12 : (isTablet ? 10 : 14),
        ),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: isTablet
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.logout, color: Colors.white, size: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'LOGOUT',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 6 : 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: isMobile ? 18 : 20,
                    ),
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Expanded(
                    child: Text(
                      'LOGOUT',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        fontSize: isMobile ? 13 : 14,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white.withOpacity(0.7),
                    size: isMobile ? 18 : 20,
                  ),
                ],
              ),
      ),
    );
  }
}
