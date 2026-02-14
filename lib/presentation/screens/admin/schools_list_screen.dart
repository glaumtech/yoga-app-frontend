import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/admin_sidebar_layout.dart';

/// Schools & College List Screen
/// Displays list of registered schools and colleges
class SchoolsListScreen extends StatelessWidget {
  const SchoolsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminSidebarLayout(
      title: 'Schools & College List',
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 64, color: AppTheme.primaryColor),
            SizedBox(height: 16),
            Text(
              'Schools & College List',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This feature will be available soon',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
