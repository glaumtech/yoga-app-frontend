import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/section_header.dart';
import '../../widgets/footer_section.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Competition')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.self_improvement, size: 80, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: 'About Us', showDivider: false),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to the Yoga Championship Event Management System. '
                    'We are dedicated to promoting the ancient art of yoga and '
                    'providing a platform for participants to showcase their skills '
                    'and dedication.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),

                  SectionHeader(title: 'Our Mission', showDivider: false),
                  const SizedBox(height: 16),
                  Text(
                    'To foster excellence in yoga practice, encourage healthy '
                    'competition, and celebrate the achievements of participants '
                    'across all age groups and categories.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),

                  SectionHeader(title: 'Event Categories', showDivider: false),
                  const SizedBox(height: 16),
                  _buildCategoryCard(
                    context,
                    'Common Category',
                    'Open to all participants meeting standard requirements.',
                    Icons.people,
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryCard(
                    context,
                    'Special Category',
                    'Designed for participants with special needs.',
                    Icons.accessibility_new,
                  ),
                  const SizedBox(height: 32),

                  SectionHeader(title: 'Age Groups', showDivider: false),
                  const SizedBox(height: 16),
                  ...AppConstants.standards.map((standard) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.school,
                            size: 20,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            standard,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Footer
            const FooterSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
