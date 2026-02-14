import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/school_controller.dart';
import '../../widgets/custom_loader.dart';
import '../../../data/models/school_model.dart';

class SchoolListScreen extends StatelessWidget {
  const SchoolListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SchoolController>();

    // Load schools on first build - defer to avoid build phase error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.schools.isEmpty && !controller.isLoading.value) {
        controller.loadSchools();
      }
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Card(
      elevation: 4,
      margin: EdgeInsets.all(isMobile ? 16 : 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Generation Section
            _buildReportGenerationSection(
              context,
              controller,
              isMobile,
              isTablet,
            ),
            SizedBox(height: isMobile ? 24 : 32),

            // Search Section
            _buildSearchSection(context, controller, isMobile, isTablet),
            SizedBox(height: isMobile ? 16 : 24),

            // Schools List
            Expanded(
              child: Obx(
                () =>
                    _buildSchoolsList(context, controller, isMobile, isTablet),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportGenerationSection(
    BuildContext context,
    SchoolController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Report Generation',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 18 : 20,
          ),
        ),
        SizedBox(height: isMobile ? 16 : 20),

        // District and State Selection
        Obx(
          () => isMobile
              ? Column(
                  children: [
                    _buildReportDropdown(
                      context,
                      label: 'Select State :',
                      value: controller.reportState.value,
                      items: SchoolController.states,
                      onChanged: (value) {
                        controller.reportState.value = value ?? '';
                        controller.reportDistrict.value = '';
                      },
                      isMobile: isMobile,
                    ),
                    SizedBox(height: isMobile ? 16 : 20),
                    _buildReportDropdown(
                      context,
                      label: 'Select District :',
                      value: controller.reportDistrict.value,
                      items: controller.reportState.value.isNotEmpty
                          ? controller.getDistrictsForState(
                              controller.reportState.value,
                            )
                          : [],
                      onChanged: (value) =>
                          controller.reportDistrict.value = value ?? '',
                      isMobile: isMobile,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildReportDropdown(
                        context,
                        label: 'Select State :',
                        value: controller.reportState.value,
                        items: SchoolController.states,
                        onChanged: (value) {
                          controller.reportState.value = value ?? '';
                          controller.reportDistrict.value = '';
                        },
                        isMobile: isMobile,
                      ),
                    ),
                    SizedBox(width: isTablet ? 16 : 20),
                    Expanded(
                      child: _buildReportDropdown(
                        context,
                        label: 'Select District :',
                        value: controller.reportDistrict.value,
                        items: controller.reportState.value.isNotEmpty
                            ? controller.getDistrictsForState(
                                controller.reportState.value,
                              )
                            : [],
                        onChanged: (value) =>
                            controller.reportDistrict.value = value ?? '',
                        isMobile: isMobile,
                      ),
                    ),
                  ],
                ),
        ),
        SizedBox(height: isMobile ? 20 : 24),

        // Report Links
        Wrap(
          spacing: isMobile ? 12 : 16,
          runSpacing: isMobile ? 12 : 16,
          children: [
            _buildReportLink(
              context,
              label: 'Private Schools',
              onTap: () => controller.generateReport('private_schools'),
              isMobile: isMobile,
            ),
            _buildReportLink(
              context,
              label: 'Govt / Govt Aided Schools',
              onTap: () => controller.generateReport('govt_schools'),
              isMobile: isMobile,
            ),
            _buildReportLink(
              context,
              label: 'Private Colleges',
              onTap: () => controller.generateReport('private_colleges'),
              isMobile: isMobile,
            ),
            _buildReportLink(
              context,
              label: 'Govt / Govt Aided Colleges',
              onTap: () => controller.generateReport('govt_colleges'),
              isMobile: isMobile,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportDropdown(
    BuildContext context, {
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value.isNotEmpty ? value : null,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          hint: Text('Select', style: TextStyle(fontSize: isMobile ? 14 : 16)),
          style: TextStyle(fontSize: isMobile ? 14 : 16),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: TextStyle(fontSize: isMobile ? 14 : 16)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildReportLink(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
    required bool isMobile,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              color: Colors.purple,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(Printable PDF Format)',
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(
    BuildContext context,
    SchoolController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return TextField(
      onChanged: (value) => controller.searchQuery.value = value,
      decoration: InputDecoration(
        hintText: 'Search by name, address, district, or state...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: Obx(() {
          if (controller.searchQuery.value.isNotEmpty) {
            return IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => controller.searchQuery.value = '',
            );
          }
          return const SizedBox.shrink();
        }),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildSchoolsList(
    BuildContext context,
    SchoolController controller,
    bool isMobile,
    bool isTablet,
  ) {
    if (controller.isLoading.value) {
      return const Center(child: CustomLoader());
    }

    final filteredSchools = controller.getFilteredSchools();

    if (filteredSchools.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              controller.searchQuery.value.isNotEmpty
                  ? 'No schools found matching your search'
                  : 'No schools found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (isMobile) {
      return _buildMobileList(context, filteredSchools, controller);
    } else {
      return _buildDesktopTable(context, filteredSchools, controller, isTablet);
    }
  }

  Widget _buildMobileList(
    BuildContext context,
    List<SchoolModel> schools,
    SchoolController controller,
  ) {
    return RefreshIndicator(
      onRefresh: () => controller.loadSchools(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: schools.length,
        itemBuilder: (context, index) {
          final school = schools[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildSchoolIcon(school, 50),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              school.institutionName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildInstitutionTypeChip(school.institutionType),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildSchoolInfoRow('Address', school.address),
                  _buildSchoolInfoRow('District', school.district),
                  _buildSchoolInfoRow('State', school.state),
                  _buildSchoolInfoRow('Pincode', school.pincode),
                  if (school.createdAt != null)
                    _buildSchoolInfoRow(
                      'Created',
                      DateFormat('MMM dd, yyyy').format(school.createdAt!),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopTable(
    BuildContext context,
    List<SchoolModel> schools,
    SchoolController controller,
    bool isTablet,
  ) {
    return RefreshIndicator(
      onRefresh: () => controller.loadSchools(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = constraints.maxWidth - 32;
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: tableWidth,
                child: Table(
                  border: TableBorder.all(color: Colors.grey[300]!, width: 1),
                  columnWidths: {
                    0: const FixedColumnWidth(80),
                    1: FlexColumnWidth(2.5),
                    2: FlexColumnWidth(2.5),
                    3: FlexColumnWidth(1.5),
                    4: FlexColumnWidth(1.5),
                    5: FlexColumnWidth(1.0),
                    6: FlexColumnWidth(2.0),
                  },
                  children: [
                    // Header Row
                    TableRow(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                      ),
                      children: [
                        _buildTableCell('ICON', isHeader: true),
                        _buildTableCell('INSTITUTION NAME', isHeader: true),
                        _buildTableCell('ADDRESS', isHeader: true),
                        _buildTableCell('DISTRICT', isHeader: true),
                        _buildTableCell('STATE', isHeader: true),
                        _buildTableCell('PINCODE', isHeader: true),
                        _buildTableCell('TYPE', isHeader: true),
                      ],
                    ),
                    // Data Rows
                    ...schools.map((school) {
                      return TableRow(
                        children: [
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Center(
                                child: _buildSchoolIcon(school, 40),
                              ),
                            ),
                          ),
                          _buildTableCell(school.institutionName),
                          _buildTableCell(school.address),
                          _buildTableCell(school.district),
                          _buildTableCell(school.state),
                          _buildTableCell(school.pincode),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Center(
                                child: _buildInstitutionTypeChip(
                                  school.institutionType,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 14 : 13,
        ),
        softWrap: true,
        maxLines: null,
      ),
    );
  }

  Widget _buildSchoolIcon(SchoolModel school, double size) {
    final firstLetter =
        (school.institutionName.isNotEmpty ? school.institutionName[0] : 'S')
            .toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          firstLetter,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInstitutionTypeChip(String type) {
    Color chipColor;
    if (type.contains('Private')) {
      chipColor = Colors.blue;
    } else if (type.contains('Govt')) {
      chipColor = Colors.green;
    } else {
      chipColor = Colors.grey;
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.5)),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: chipColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSchoolInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
