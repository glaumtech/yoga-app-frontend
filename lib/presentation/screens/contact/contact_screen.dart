import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/footer_section.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final messageController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Contact Info Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppTheme.accentColor.withOpacity(0.3),
              child: Column(
                children: [
                  SectionHeader(
                    title: 'Get in Touch',
                    subtitle: 'We\'d love to hear from you',
                    showDivider: false,
                  ),
                  const SizedBox(height: 24),
                  _buildContactInfo(
                    context,
                    Icons.email,
                    'Email',
                    'info@yogachampionship.com',
                  ),
                  const SizedBox(height: 16),
                  _buildContactInfo(
                    context,
                    Icons.phone,
                    'Phone',
                    '+1 (555) 123-4567',
                  ),
                  const SizedBox(height: 16),
                  _buildContactInfo(
                    context,
                    Icons.location_on,
                    'Address',
                    '123 Yoga Street, Wellness City, 12345',
                  ),
                ],
              ),
            ),

            // Contact Form
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: 'Send us a Message', showDivider: false),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Your Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Your Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      prefixIcon: Icon(Icons.message),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Send Message',
                    icon: Icons.send,
                    onPressed: () {
                      // TODO: Implement send message functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Message sent successfully!'),
                        ),
                      );
                      nameController.clear();
                      emailController.clear();
                      messageController.clear();
                    },
                  ),
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

  Widget _buildContactInfo(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
