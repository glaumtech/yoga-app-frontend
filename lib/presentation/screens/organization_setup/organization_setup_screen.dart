import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../controllers/organization_setup_controller.dart';

class OrganizationSetupScreen extends StatelessWidget {
  const OrganizationSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(OrganizationSetupController());

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    InputDecoration deco({
      required String label,
      IconData? icon,
      String? hint,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null
            ? null
            : Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 20),
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      );
    }

    Widget sectionTitle(String title) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      );
    }

    Widget gridOrColumn({
      required List<Widget> children,
      int desktopColumns = 3,
      int tabletColumns = 2,
    }) {
      if (isMobile) {
        return Column(
          children:
              children.expand((w) => [w, const SizedBox(height: 16)]).toList()
                ..removeLast(),
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth >= 1100
              ? desktopColumns
              : (constraints.maxWidth >= 640 ? tabletColumns : 1);
          final itemWidth = constraints.maxWidth / crossAxisCount;
          const itemHeight = 78.0;
          final childAspectRatio = itemWidth / itemHeight;

          return GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
            children: children,
          );
        },
      );
    }

    Widget singleColumnFields({required List<Widget> children}) {
      return Column(
        children:
            children.expand((w) => [w, const SizedBox(height: 16)]).toList()
              ..removeLast(),
      );
    }

    Future<void> onSubmit() async {
      if (c.isLoading.value) return;
      final ok = await c.submitSetup();
      if (!context.mounted) return;

      if (ok) {
        final orgName = c.lastResult.value?.organization.organizationName ?? '';
        Get.snackbar(
          'Success',
          orgName.isEmpty
              ? 'Organization setup completed'
              : 'Organization setup completed for $orgName',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Failed',
          c.errorMessage.value.isEmpty ? 'Setup failed' : c.errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Organization Setup')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.12),
              AppTheme.secondaryColor.withOpacity(0.08),
              Colors.white,
              AppTheme.accentColor.withOpacity(0.08),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, viewport) => SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 10 : 0,
                vertical: isMobile ? 12 : 10,
              ),
              child: SizedBox(
                width: viewport.maxWidth,
                child: Form(
                  key: c.formKey,
                  child: Container(
                    width: viewport.maxWidth,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(isMobile ? 20 : 28),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 1100;

                    final detailsLeft = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        sectionTitle('Organization'),
                        gridOrColumn(
                          desktopColumns: 3,
                          tabletColumns: 2,
                          children: [
                            TextFormField(
                              controller: c.organizationNameController,
                              textInputAction: TextInputAction.next,
                              validator: (v) => c.requiredValidator(
                                v,
                                fieldName: 'Organization name',
                              ),
                              decoration: deco(
                                label: 'Organization Name',
                                icon: Icons.business_outlined,
                              ),
                            ),
                            TextFormField(
                              controller: c.organizationCodeController,
                              textInputAction: TextInputAction.next,
                              decoration: deco(
                                label: 'Organization Code (optional)',
                                icon: Icons.qr_code_2_outlined,
                              ),
                            ),
                          ],
                        ),
                        sectionTitle('Branch'),
                        gridOrColumn(
                          desktopColumns: 3,
                          tabletColumns: 3,
                          children: [
                            TextFormField(
                              controller: c.branchNameController,
                              textInputAction: TextInputAction.next,
                              validator: (v) => c.requiredValidator(
                                v,
                                fieldName: 'Branch name',
                              ),
                              decoration: deco(
                                label: 'Branch Name',
                                icon: Icons.account_tree_outlined,
                              ),
                            ),
                            TextFormField(
                              controller: c.branchCodeController,
                              textInputAction: TextInputAction.next,
                              decoration: deco(
                                label: 'Branch Code (optional)',
                                icon: Icons.qr_code_outlined,
                              ),
                            ),
                            TextFormField(
                              controller: c.commencingYearController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              decoration: deco(
                                label: 'Commencing Year (optional)',
                                icon: Icons.calendar_month_outlined,
                                hint: 'e.g. 2025',
                              ),
                            ),
                            TextFormField(
                              controller: c.emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: deco(
                                label: 'Email (optional)',
                                icon: Icons.email_outlined,
                              ),
                            ),
                            TextFormField(
                              controller: c.phoneNoController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              decoration: deco(
                                label: 'Phone No (optional)',
                                icon: Icons.phone_outlined,
                              ),
                            ),
                            TextFormField(
                              controller: c.mobileNoController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              decoration: deco(
                                label: 'Mobile No (optional)',
                                icon: Icons.smartphone_outlined,
                              ),
                            ),
                            TextFormField(
                              controller: c.websiteUrlController,
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.next,
                              decoration: deco(
                                label: 'Website URL (optional)',
                                icon: Icons.public_outlined,
                              ),
                            ),
                            TextFormField(
                              controller: c.countryController,
                              textInputAction: TextInputAction.next,
                              decoration: deco(
                                label: 'Country (optional)',
                                icon: Icons.flag_outlined,
                              ),
                            ),
                            TextFormField(
                              controller: c.stateIdController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              decoration: deco(
                                label: 'State ID (optional)',
                                icon: Icons.map_outlined,
                              ),
                            ),
                            TextFormField(
                              controller: c.cityIdController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              decoration: deco(
                                label: 'City ID (optional)',
                                icon: Icons.location_city_outlined,
                              ),
                            ),
                            TextFormField(
                              controller: c.pincodeController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              decoration: deco(
                                label: 'Pincode (optional)',
                                icon: Icons.pin_drop_outlined,
                              ),
                            ),
                            TextFormField(
                              controller: c.themeController,
                              textInputAction: TextInputAction.next,
                              decoration: deco(
                                label: 'Theme (optional)',
                                icon: Icons.palette_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: c.addressController,
                          textInputAction: TextInputAction.next,
                          maxLines: 3,
                          decoration: deco(
                            label: 'Address (optional)',
                            icon: Icons.home_outlined,
                          ),
                        ),
                      ],
                    );

                    final usersRight = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        sectionTitle('Branch logo (optional)'),
                        Obx(
                          () => Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1.2,
                                  ),
                                ),
                                child: c.logoBytes.value == null
                                    ? Icon(
                                        Icons.image_outlined,
                                        color: Colors.grey[500],
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.memory(
                                          c.logoBytes.value!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.logoFileName.value.isEmpty
                                          ? 'No logo selected'
                                          : c.logoFileName.value,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[800],
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: c.isLoading.value
                                              ? null
                                              : c.pickLogoFromGallery,
                                          icon: const Icon(Icons.upload_file),
                                          label: const Text('Choose'),
                                        ),
                                        TextButton(
                                          onPressed: c.isLoading.value
                                              ? null
                                              : c.clearLogo,
                                          child: const Text('Clear'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        sectionTitle('Organization Admin User'),
                        singleColumnFields(
                          children: [
                            TextFormField(
                              controller: c.orgAdminNameController,
                              textInputAction: TextInputAction.next,
                              validator: (v) => c.requiredValidator(
                                v,
                                fieldName: 'Org admin name',
                              ),
                              decoration: deco(
                                label: 'Name',
                                icon: Icons.person_outline,
                              ),
                            ),
                            TextFormField(
                              controller: c.orgAdminUserNameController,
                              textInputAction: TextInputAction.next,
                              validator: (v) => c.requiredValidator(
                                v,
                                fieldName: 'Org admin username',
                              ),
                              decoration: deco(
                                label: 'Username',
                                icon: Icons.badge_outlined,
                              ),
                            ),
                            TextFormField(
                              controller: c.orgAdminPasswordController,
                              textInputAction: TextInputAction.next,
                              obscureText: true,
                              validator: (v) => c.requiredValidator(
                                v,
                                fieldName: 'Org admin password',
                              ),
                              decoration: deco(
                                label: 'Password',
                                icon: Icons.lock_outline,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        sectionTitle('Branch Admin User'),
                        singleColumnFields(
                          children: [
                            TextFormField(
                              controller: c.branchAdminNameController,
                              textInputAction: TextInputAction.next,
                              validator: (v) => c.requiredValidator(
                                v,
                                fieldName: 'Branch admin name',
                              ),
                              decoration: deco(
                                label: 'Name',
                                icon: Icons.person_outline,
                              ),
                            ),
                            TextFormField(
                              controller: c.branchAdminUserNameController,
                              textInputAction: TextInputAction.next,
                              validator: (v) => c.requiredValidator(
                                v,
                                fieldName: 'Branch admin username',
                              ),
                              decoration: deco(
                                label: 'Username',
                                icon: Icons.badge_outlined,
                              ),
                            ),
                            TextFormField(
                              controller: c.branchAdminPasswordController,
                              textInputAction: TextInputAction.done,
                              obscureText: true,
                              validator: (v) => c.requiredValidator(
                                v,
                                fieldName: 'Branch admin password',
                              ),
                              decoration: deco(
                                label: 'Password',
                                icon: Icons.lock_outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );

                    final footer = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 22),
                        Obx(
                          () => c.errorMessage.value.isNotEmpty
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.error_outline_rounded,
                                          color: Colors.red.shade700,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          c.errorMessage.value,
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        Obx(
                          () => SizedBox(
                            height: 56,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: c.isLoading.value ? null : onSubmit,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                backgroundColor: AppTheme.primaryColor,
                              ),
                              child: c.isLoading.value
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Setup Organization',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Setup your organization and branch',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                        ),
                        Text(
                          'Fill details below and create admin users.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 15),
                        if (!isWide) ...[
                          detailsLeft,
                          const SizedBox(height: 24),
                          usersRight,
                          footer,
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 8, child: detailsLeft),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 4,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 440,
                                  ),
                                  child: usersRight,
                                ),
                              ),
                            ],
                          ),
                        if (isWide) footer,
                      ],
                    );
                  },
                ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
