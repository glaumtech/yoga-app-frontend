import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/permission_store.dart';
import '../../controllers/competition_controller.dart';
import '../../controllers/competitions_list_controller.dart';
import '../../widgets/custom_loader.dart';
import '../../../data/models/competition_model.dart';
import '../../widgets/competition_registration_qr_panel.dart';

class CompetitionsListScreen extends StatelessWidget {
  const CompetitionsListScreen({super.key});

  // Helper method to get prize names from competition (handles both IDs and names)
  String _getPrizeNames(
    CompetitionModel competition,
    CompetitionController controller,
  ) {
    // If names are available, use them
    if (competition.prizes != null && competition.prizes!.isNotEmpty) {
      return competition.prizes!.join(', ');
    }
    // If IDs are available, convert to names
    if (competition.prizeIds != null && competition.prizeIds!.isNotEmpty) {
      final names = competition.prizeIds!
          .map((id) => controller.getPrizeNameById(id))
          .where((name) => name != null)
          .cast<String>()
          .toList();
      return names.isNotEmpty ? names.join(', ') : 'N/A';
    }
    return 'N/A';
  }

  // Helper method to get category names from competition (handles both IDs and names)
  String _getCategoryNames(
    CompetitionModel competition,
    CompetitionController controller,
  ) {
    // If names are available, use them
    if (competition.categories != null && competition.categories!.isNotEmpty) {
      return competition.categories!.join(', ');
    }
    // If IDs are available, convert to names
    if (competition.categoryIds != null &&
        competition.categoryIds!.isNotEmpty) {
      final names = competition.categoryIds!
          .map((id) => controller.getCategoryNameById(id))
          .where((name) => name != null)
          .cast<String>()
          .toList();
      return names.isNotEmpty ? names.join(', ') : 'N/A';
    }
    return 'N/A';
  }

  // Helper method to get stage names from competition (handles both IDs and names)
  String _getStageNames(
    CompetitionModel competition,
    CompetitionController controller,
  ) {
    // If names are available, use them
    if (competition.stages != null && competition.stages!.isNotEmpty) {
      return competition.stages!.join(', ');
    }
    // If IDs are available, convert to names
    if (competition.stageIds != null && competition.stageIds!.isNotEmpty) {
      final names = competition.stageIds!
          .map((id) => controller.getStageNameById(id))
          .where((name) => name != null)
          .cast<String>()
          .toList();
      return names.isNotEmpty ? names.join(', ') : 'N/A';
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    // Keep screen Stateless: initial load happens in CompetitionsListController.onReady()
    Get.put(CompetitionsListController());
    final controller = Get.put(CompetitionController());

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Container(
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
      child: Obx(
        () => _buildCompetitionsList(context, controller, isMobile, isTablet),
      ),
    );
  }

  Widget _buildSearchSection(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: isMobile
          ? Column(
              children: [
                // Search Bar
                TextField(
                  controller: controller.searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, description, or address...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Obx(() {
                      if (controller.searchQuery.value.isNotEmpty) {
                        return IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => controller.clearSearch(),
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
                ),
                SizedBox(height: isMobile ? 12 : 16),
                // Filter and Refresh in Row
                Row(
                  children: [
                    Expanded(
                      child: Obx(
                        () => DropdownButtonFormField<String>(
                          value: controller.selectedFilter.value.isNotEmpty
                              ? controller.selectedFilter.value
                              : null,
                          decoration: InputDecoration(
                            labelText: 'Filter by Status',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All Competitions'),
                            ),
                            const DropdownMenuItem<String>(
                              value: 'upcoming',
                              child: Text('Upcoming'),
                            ),
                            const DropdownMenuItem<String>(
                              value: 'ongoing',
                              child: Text('Ongoing'),
                            ),
                            const DropdownMenuItem<String>(
                              value: 'completed',
                              child: Text('Completed'),
                            ),
                          ],
                          onChanged: (value) {
                            controller.updateFilter(value ?? '');
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: isMobile ? 8 : 12),
                    // Refresh Button
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => controller.loadCompetitions(),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                // Search Bar
                Expanded(
                  child: TextField(
                    controller: controller.searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, description, or address...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: Obx(() {
                        if (controller.searchQuery.value.isNotEmpty) {
                          return IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => controller.clearSearch(),
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
                  ),
                ),
                SizedBox(width: isTablet ? 12 : 16),
                // Status Filter
                Obx(
                  () => SizedBox(
                    width: isTablet ? 280 : 320,
                    child: DropdownButtonFormField<String>(
                      value: controller.selectedFilter.value.isNotEmpty
                          ? controller.selectedFilter.value
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Filter by Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Competitions'),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'upcoming',
                          child: Text('Upcoming'),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'ongoing',
                          child: Text('Ongoing'),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'completed',
                          child: Text('Completed'),
                        ),
                      ],
                      onChanged: (value) {
                        controller.updateFilter(value ?? '');
                      },
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 8 : 12),
                // Refresh Button
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => controller.loadCompetitions(),
                  tooltip: 'Refresh',
                ),
              ],
            ),
    );
  }

  Widget _buildCompetitionsList(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Section
          _buildSearchSection(context, controller, isMobile, isTablet),

          // Competitions List Content
          Expanded(
            child: _buildListContent(context, controller, isMobile, isTablet),
          ),

          // Pagination Controls
          _buildPaginationControls(context, controller, isMobile, isTablet),
        ],
      ),
    );
  }

  Widget _buildListContent(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
    bool isTablet,
  ) {
    if (controller.isLoading.value) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(32.0), child: CustomLoader()),
      );
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                controller.errorMessage.value,
                style: TextStyle(color: Colors.red[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => controller.loadCompetitions(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredCompetitions = controller.filteredCompetitions;

    if (filteredCompetitions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                controller.searchQuery.value.isNotEmpty
                    ? 'No competitions found matching your search'
                    : 'No competitions found',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (isMobile) {
      return _buildMobileList(context, filteredCompetitions, controller);
    } else {
      return _buildDesktopTable(
        context,
        filteredCompetitions,
        controller,
        isTablet,
      );
    }
  }

  Widget _buildMobileList(
    BuildContext context,
    List<CompetitionModel> competitions,
    CompetitionController controller,
  ) {
    return RefreshIndicator(
      onRefresh: () => controller.loadCompetitions(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: competitions.length,
        itemBuilder: (context, index) {
          final competition = competitions[index];
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
                  Text(
                    competition.competitionName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Divider(height: 24),
                  _buildInfoRow('Description', competition.description),
                  _buildInfoRow('Address', competition.address),
                  _buildInfoRow(
                    'Start Date',
                    DateFormat('yyyy-MM-dd').format(competition.eventStartDate),
                  ),
                  _buildInfoRow(
                    'End Date',
                    DateFormat('yyyy-MM-dd').format(competition.eventEndDate),
                  ),
                  if (competition.displayAdFrom != null)
                    _buildInfoRow(
                      'Display Ad From',
                      DateFormat(
                        'yyyy-MM-dd',
                      ).format(competition.displayAdFrom!),
                    ),
                  if (competition.participantsPerStage != null)
                    _buildInfoRow(
                      'Participants Per Stage',
                      competition.participantsPerStage.toString(),
                    ),
                  _buildInfoRow(
                    'Prizes',
                    _getPrizeNames(competition, controller),
                  ),
                  _buildInfoRow(
                    'Categories',
                    _getCategoryNames(competition, controller),
                  ),
                  _buildInfoRow(
                    'Stages',
                    _getStageNames(competition, controller),
                  ),
                  if (competition.createdAt != null)
                    _buildInfoRow('Created', _buildCreatedCell(competition)),
                  if (competition.updatedAt != null)
                    _buildInfoRow('Updated', _buildUpdatedCell(competition)),
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
    List<CompetitionModel> competitions,
    CompetitionController controller,
    bool isTablet,
  ) {
    return RefreshIndicator(
      onRefresh: () => controller.loadCompetitions(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = constraints.maxWidth - 32; // Account for padding
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: tableWidth,
                child: Table(
                  border: TableBorder.all(color: Colors.grey[300]!, width: 1),
                  columnWidths: {
                    0: FlexColumnWidth(1.5),
                    1: FlexColumnWidth(2.0),
                    2: FlexColumnWidth(1.2),
                    3: FlexColumnWidth(1.2),
                    4: FlexColumnWidth(1.5),
                    5: FlexColumnWidth(1.5),
                    6: FlexColumnWidth(1.5),
                    7: FlexColumnWidth(1.5), // Created
                    8: FlexColumnWidth(1.5), // Updated
                    9: FlexColumnWidth(0.8), // Action column
                  },
                  children: [
                    // Header Row
                    TableRow(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                      ),
                      children: [
                        _buildSortableHeader(
                          'COMPETITION NAME',
                          'createdAt',
                          controller,
                          isSortable: false,
                        ),
                        _buildSortableHeader(
                          'ADDRESS',
                          'createdAt',
                          controller,
                          isSortable: false,
                        ),
                        _buildSortableHeader(
                          'START DATE',
                          'eventStartDate',
                          controller,
                        ),
                        _buildSortableHeader(
                          'END DATE',
                          'eventEndDate',
                          controller,
                        ),
                        _buildSortableHeader(
                          'PRIZES',
                          'createdAt',
                          controller,
                          isSortable: false,
                        ),
                        _buildSortableHeader(
                          'CATEGORIES',
                          'createdAt',
                          controller,
                          isSortable: false,
                        ),
                        _buildSortableHeader(
                          'STAGES',
                          'createdAt',
                          controller,
                          isSortable: false,
                        ),
                        _buildSortableHeader(
                          'CREATED',
                          'createdAt',
                          controller,
                        ),
                        _buildSortableHeader(
                          'UPDATED',
                          'updatedAt',
                          controller,
                        ),
                        _buildTableCell('ACTION', isHeader: true),
                      ],
                    ),
                    // Data Rows
                    ...competitions.map((competition) {
                      return TableRow(
                        children: [
                          _buildClickableCell(
                            context,
                            competition.competitionName,
                            competition,
                            controller,
                          ),
                          _buildTableCell(competition.address),
                          _buildTableCell(
                            DateFormat(
                              'yyyy-MM-dd',
                            ).format(competition.eventStartDate),
                          ),
                          _buildTableCell(
                            DateFormat(
                              'yyyy-MM-dd',
                            ).format(competition.eventEndDate),
                          ),
                          _buildTableCell(
                            _getPrizeNames(competition, controller),
                          ),
                          _buildTableCell(
                            _getCategoryNames(competition, controller),
                          ),
                          _buildTableCell(
                            _getStageNames(competition, controller),
                          ),
                          _buildTableCell(_buildCreatedCell(competition)),
                          _buildTableCell(_buildUpdatedCell(competition)),
                          _buildActionCell(context, competition, controller),
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

  Widget _buildClickableCell(
    BuildContext context,
    String text,
    CompetitionModel competition,
    CompetitionController controller,
  ) {
    return InkWell(
      onTap: () async {
        await controller.viewCompetition(context, competition);
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.primaryColor,
            decoration: TextDecoration.underline,
            decorationColor: AppTheme.primaryColor,
          ),
          softWrap: true,
          maxLines: null,
        ),
      ),
    );
  }

  Widget _buildActionCell(
    BuildContext context,
    CompetitionModel competition,
    CompetitionController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() {
            final permissionStore = Get.isRegistered<PermissionStore>()
                ? Get.find<PermissionStore>()
                : Get.put(PermissionStore());
            if (competition.id == null ||
                competition.id!.isEmpty ||
                !permissionStore.has('SHOW_COMP_QR_CODE_ON_ADMIN')) {
              return const SizedBox.shrink();
            }
            return IconButton(
              icon: Icon(
                Icons.qr_code_2,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              onPressed: () =>
                  showCompetitionRegistrationQrDialog(context, competition),
              tooltip: 'Registration QR',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            );
          }),
          IconButton(
            icon: Icon(Icons.edit, size: 18, color: AppTheme.primaryColor),
            onPressed: () async {
              await controller.editCompetition(context, competition);
            },
            tooltip: 'Edit',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          // IconButton(
          //   icon: const Icon(Icons.delete, size: 18, color: Colors.red),
          //   onPressed: () => controller.deleteCompetition(context, competition),
          //   tooltip: 'Delete',
          //   padding: EdgeInsets.zero,
          //   constraints: const BoxConstraints(),
          // ),
        ],
      ),
    );
  }

  Widget _buildSortableHeader(
    String label,
    String sortField,
    CompetitionController controller, {
    bool isSortable = true,
  }) {
    return Obx(() {
      final isActive = isSortable && controller.sortBy.value == sortField;
      final isAscending = controller.sortOrder.value == 'asc';

      return InkWell(
        onTap: isSortable
            ? () {
                // Toggle sort order if same field, otherwise set to desc
                final newOrder = isActive && !isAscending ? 'asc' : 'desc';
                controller.updateSort(sortField, newOrder);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isActive ? AppTheme.primaryColor : Colors.black87,
                  ),
                  softWrap: true,
                  maxLines: null,
                ),
              ),
              if (isSortable) ...[
                const SizedBox(width: 4),
                Icon(
                  isActive
                      ? (isAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward)
                      : Icons.unfold_more,
                  size: 16,
                  color: isActive ? AppTheme.primaryColor : Colors.grey[600],
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  String _buildCreatedCell(CompetitionModel competition) {
    if (competition.createdAt == null) {
      return '-';
    }
    final dateTime = DateFormat(
      'MMM dd, yyyy hh:mm a',
    ).format(competition.createdAt!);
    if (competition.createdBy != null && competition.createdBy!.isNotEmpty) {
      return '$dateTime\nby ${competition.createdBy}';
    }
    return dateTime;
  }

  String _buildUpdatedCell(CompetitionModel competition) {
    if (competition.updatedAt == null) {
      return '-';
    }
    final dateTime = DateFormat(
      'MMM dd, yyyy hh:mm a',
    ).format(competition.updatedAt!);
    if (competition.updatedBy != null && competition.updatedBy!.isNotEmpty) {
      return '$dateTime\nby ${competition.updatedBy}';
    }
    return dateTime;
  }

  Widget _buildPaginationControls(
    BuildContext context,
    CompetitionController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Obx(() {
      // Only show pagination if there are pages
      if (controller.totalPages.value <= 0) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border(top: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Page info
            Text(
              'Page ${controller.currentPage.value}',
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                color: Colors.grey[700],
              ),
            ),
            // Pagination buttons
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: controller.currentPage.value > 1
                      ? () => controller.previousPage()
                      : null,
                  tooltip: 'Previous page',
                ),
                // Page numbers (show limited on mobile)
                if (!isMobile) ...[
                  ...List.generate(
                    controller.totalPages.value > 5
                        ? 5
                        : controller.totalPages.value,
                    (index) {
                      int pageNum;
                      if (controller.totalPages.value > 5) {
                        // Show current page and 2 pages on each side
                        final current = controller.currentPage.value;
                        final total = controller.totalPages.value;
                        if (current <= 3) {
                          pageNum = index + 1;
                        } else if (current >= total - 2) {
                          pageNum = total - 4 + index;
                        } else {
                          pageNum = current - 2 + index;
                        }
                      } else {
                        pageNum = index + 1;
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextButton(
                          onPressed: () => controller.goToPage(pageNum),
                          style: TextButton.styleFrom(
                            backgroundColor:
                                controller.currentPage.value == pageNum
                                ? AppTheme.primaryColor
                                : null,
                            foregroundColor:
                                controller.currentPage.value == pageNum
                                ? Colors.white
                                : Colors.grey[700],
                            minimumSize: const Size(40, 40),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text('$pageNum'),
                        ),
                      );
                    },
                  ),
                ] else
                  Text(
                    '${controller.currentPage.value} / ${controller.totalPages.value > 0 ? controller.totalPages.value : 1}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed:
                      controller.currentPage.value < controller.totalPages.value
                      ? () => controller.nextPage()
                      : null,
                  tooltip: 'Next page',
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
