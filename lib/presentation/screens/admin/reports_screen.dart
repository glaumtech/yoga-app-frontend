import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/admin_sidebar_layout.dart';

/// Reports Screen
/// Displays various reports and analytics
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminSidebarLayout(
      title: 'Reports',
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assessment, size: 64, color: AppTheme.primaryColor),
            SizedBox(height: 16),
            Text(
              'Reports',
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
