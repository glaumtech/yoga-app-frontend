import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/keyboard/keyboard_scroll_discovery.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/role_display_name.dart';
import '../controllers/user_management_controller.dart';
import 'admin_sidebar.dart';

/// Layout wrapper for admin screens with persistent sidebar
class AdminSidebarLayout extends StatelessWidget {
  final Widget child;
  final String? title;

  const AdminSidebarLayout({super.key, required this.child, this.title});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final userController = Get.isRegistered<UserManagementController>()
        ? Get.find<UserManagementController>()
        : Get.put(UserManagementController());

    return Scaffold(
      drawer: isMobile && userController.isAuthenticated
          ? Drawer(
              width: 280, // Reduced width for mobile drawer
              child: const KeyboardScrollDiscovery(child: AdminSidebar()),
            )
          : null,
      body: KeyboardScrollDiscovery(
        child: Row(
          children: [
            // Persistent Sidebar (hidden on mobile, shown on tablet/desktop)
            if (!isMobile && userController.isAuthenticated)
              const AdminSidebar(),
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                if (title != null)
                  Builder(
                    builder: (scaffoldContext) => Container(
                      width: double.infinity,
                      height: isMobile ? 56 : 60,
                      color: AppTheme.primaryColor,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Menu button for mobile
                          if (isMobile && userController.isAuthenticated)
                            Positioned(
                              left: 0,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.menu,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  Scaffold.of(scaffoldContext).openDrawer();
                                },
                              ),
                            ),
                          // Yoga icon when not logged in (no drawer)
                          if (isMobile && !userController.isAuthenticated)
                            const Positioned(
                              left: 8,
                              child: Icon(
                                Icons.self_improvement,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),

                          // Left-aligned title (leaves space for mobile menu button)
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: isMobile
                                      ? (userController.isAuthenticated
                                            ? 56
                                            : 44)
                                      : 16,
                                  right:
                                      120, // keep clear of right-side user info
                                ),
                                child: Text(
                                  title!,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isMobile ? 18 : 20,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ),
                          ),

                          // Right-side user info
                          Positioned(
                            right: 12,
                            child: Obx(() {
                              final u = userController.currentUser.value;
                              final name = (u?.name ?? '').trim();
                              final type = (u?.userTypeName ?? u?.type ?? '')
                                  .trim();
                              if (name.isEmpty && type.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: isMobile ? 140 : 220,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        if (name.isNotEmpty)
                                          Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        if (type.isNotEmpty)
                                          Text(
                                            displayRoleName(type),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                              fontWeight: FontWeight.w500,
                                              fontSize: 11,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 10),
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.16),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.25),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.person_outline,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Main Content
                Expanded(child: child),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}
