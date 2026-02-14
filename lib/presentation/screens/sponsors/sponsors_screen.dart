import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/admin_sidebar_layout.dart';
import '../../widgets/toggle_button_group.dart';
import '../../controllers/sponsor_controller.dart';
import 'sponsor_create_screen.dart';
import 'sponsor_list_screen.dart';

/// Sponsors Screen
/// Manages event sponsors
class SponsorsScreen extends StatelessWidget {
  const SponsorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SponsorController());

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return AdminSidebarLayout(
      title: 'SPONSORS',
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
              // Toggle Buttons
              Padding(
                padding: EdgeInsets.only(
                  top: isMobile ? 8 : 10,
                  bottom: 0,
                  left: isMobile ? 16 : 24,
                  right: isMobile ? 16 : 24,
                ),
                child: Obx(
                  () => ToggleButtonGroup(
                    options: const [
                      ToggleButtonOption(label: '+ CREATE'),
                      ToggleButtonOption(label: '≡ LIST'),
                    ],
                    selectedIndex: controller.isListView.value ? 1 : 0,
                    onTap: (index) => controller.toggleViewMode(index == 1),
                  ),
                ),
              ),
              // Content (Create Form or List View)
              Expanded(
                child: Obx(
                  () => controller.isListView.value
                      ? const SponsorListScreen()
                      : const SponsorCreateScreen(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
