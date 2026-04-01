import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
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
      drawer: isMobile
          ? Drawer(
              width: 280, // Reduced width for mobile drawer
              child: const AdminSidebar(),
            )
          : null,
      body: Row(
        children: [
          // Persistent Sidebar (hidden on mobile, shown on tablet/desktop)
          if (!isMobile) const AdminSidebar(),
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
                          if (isMobile)
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

                          // Center title
                          Center(
                            child: Text(
                              title!,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 18 : 20,
                                  ),
                              textAlign: TextAlign.center,
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
                                            type.replaceAll('_', ' '),
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
    );
  }
}
