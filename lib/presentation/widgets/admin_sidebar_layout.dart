import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
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
                      child: Row(
                        children: [
                          // Menu button for mobile
                          if (isMobile)
                            IconButton(
                              icon: const Icon(Icons.menu, color: Colors.white),
                              onPressed: () {
                                Scaffold.of(scaffoldContext).openDrawer();
                              },
                            ),
                          Expanded(
                            child: Center(
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
                          ),
                          // Spacer for mobile menu button
                          if (isMobile) const SizedBox(width: 48),
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
