import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/admin_sidebar_layout.dart';
import '../../widgets/toggle_button_group.dart';
import '../../controllers/school_controller.dart';
import 'school_create_screen.dart';
import 'school_list_screen.dart';

/// Schools & Colleges Screen
/// Manages schools and colleges list
class SchoolsScreen extends StatelessWidget {
  const SchoolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SchoolController());

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return AdminSidebarLayout(
      title: 'SCHOOLS & COLLEGES LIST',
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
                    options: [
                      ToggleButtonOption(
                        label: controller.isEditMode.value ? 'EDIT' : '+ CREATE',
                      ),
                      const ToggleButtonOption(label: '≡ LIST'),
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
                      ? const SchoolListScreen()
                      : const SchoolCreateScreen(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

