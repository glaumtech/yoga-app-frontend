import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/sponsor_controller.dart';
import '../../widgets/custom_loader.dart';
import '../../widgets/pinned_scroll_views.dart';
import '../../widgets/responsive_admin_table.dart';
import '../../../data/models/sponsor_model.dart';

class SponsorListScreen extends StatelessWidget {
  const SponsorListScreen({super.key});

  static const Map<int, TableColumnWidth> _desktopColumnWidths = {
    0: FixedColumnWidth(80),
    1: FlexColumnWidth(2.0),
    2: FlexColumnWidth(2.0),
    3: FlexColumnWidth(1.0),
    4: FlexColumnWidth(1.5),
    5: FlexColumnWidth(1.5),
  };

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SponsorController>();

    // Load sponsors on first build - defer to avoid build phase error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.sponsors.isEmpty && !controller.isLoading.value) {
        controller.loadSponsors();
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
            // Search Section
            _buildSearchSection(context, controller, isMobile, isTablet),
            SizedBox(height: isMobile ? 16 : 24),
            // Sponsors List
            Expanded(
              child: Obx(
                () =>
                    _buildSponsorsList(context, controller, isMobile, isTablet),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSponsorsList(
    BuildContext context,
    SponsorController controller,
    bool isMobile,
    bool isTablet,
  ) {
    if (controller.isLoading.value) {
      return const Center(child: CustomLoader());
    }

    final filteredSponsors = controller.getFilteredSponsors();

    if (filteredSponsors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_center_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              controller.searchQuery.value.isNotEmpty
                  ? 'No sponsors found matching your search'
                  : 'No sponsors found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (isMobile) {
      return _buildMobileList(context, filteredSponsors, controller);
    } else {
      return _buildDesktopTable(
        context,
        filteredSponsors,
        controller,
        isTablet,
      );
    }
  }

  Widget _buildSearchSection(
    BuildContext context,
    SponsorController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return TextField(
      onChanged: (value) => controller.searchQuery.value = value,
      decoration: InputDecoration(
        hintText: 'Search by name, competition, email, or phone...',
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

  Widget _buildMobileList(
    BuildContext context,
    List<SponsorModel> sponsors,
    SponsorController controller,
  ) {
    return RefreshIndicator(
      onRefresh: () => controller.loadSponsors(),
      child: PinnedListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: sponsors.length,
        itemBuilder: (context, index) {
          final sponsor = sponsors[index];
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
                      _buildSponsorPhoto(sponsor, 50),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sponsor.sponsorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (sponsor.paymentStatus != null)
                              _buildPaymentStatusChip(sponsor.paymentStatus!),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildSponsorInfoRow('Competition', sponsor.competitionName),
                  _buildSponsorInfoRow(
                    'Students',
                    '${sponsor.numberOfStudents} student${sponsor.numberOfStudents != 1 ? 's' : ''}',
                  ),
                  if (sponsor.email.isNotEmpty)
                    _buildSponsorInfoRow('Email', sponsor.email),
                  if (sponsor.cellPhone.isNotEmpty)
                    _buildSponsorInfoRow('Cell Phone', sponsor.cellPhone),
                  if (sponsor.whatsapp != null && sponsor.whatsapp!.isNotEmpty)
                    _buildSponsorInfoRow('WhatsApp', sponsor.whatsapp!),
                  if (sponsor.createdAt != null)
                    _buildSponsorInfoRow(
                      'Created',
                      DateFormat('MMM dd, yyyy').format(sponsor.createdAt!),
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
    List<SponsorModel> sponsors,
    SponsorController controller,
    bool isTablet,
  ) {
    return ResponsiveAdminTable.refreshable(
      onRefresh: () => controller.loadSponsors(),
      table: ResponsiveAdminTable(
        columnWidths: _desktopColumnWidths,
        rows: [
          // Header Row
          TableRow(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
            ),
            children: [
              _buildTableCell('PHOTO', isHeader: true),
              _buildTableCell('NAME', isHeader: true),
              _buildTableCell('COMPETITION', isHeader: true),
              _buildTableCell('STUDENTS', isHeader: true),
              _buildTableCell('EMAIL', isHeader: true),
              _buildTableCell('CELL PHONE', isHeader: true),
            ],
          ),
          // Data Rows
          ...sponsors.map((sponsor) {
            return TableRow(
              children: [
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Center(
                      child: _buildSponsorPhoto(sponsor, 40),
                    ),
                  ),
                ),
                _buildTableCell(sponsor.sponsorName),
                _buildTableCell(sponsor.competitionName),
                _buildTableCell('${sponsor.numberOfStudents}'),
                _buildTableCell(sponsor.email),
                _buildTableCell(sponsor.cellPhone),
              ],
            );
          }),
        ],
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

  Widget _buildSponsorPhoto(SponsorModel sponsor, double size) {
    final firstLetter =
        (sponsor.sponsorName.isNotEmpty ? sponsor.sponsorName[0] : 'S')
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

  Widget _buildPaymentStatusChip(String status) {
    Color chipColor;
    switch (status.toLowerCase()) {
      case 'paid':
        chipColor = Colors.green;
        break;
      case 'pending':
        chipColor = Colors.orange;
        break;
      default:
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
        status.toUpperCase(),
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSponsorInfoRow(String label, String value) {
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
