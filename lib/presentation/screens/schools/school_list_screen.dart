import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/permission_store.dart';
import '../../controllers/school_controller.dart';
import '../../widgets/custom_loader.dart';
import '../../widgets/location/state_search_field.dart';
import '../../../data/models/district_model.dart';
import '../../../data/models/school_model.dart';

class SchoolListScreen extends StatelessWidget {
  const SchoolListScreen({super.key});

  /// Minimum width so date/action columns are not squeezed (sidebar layouts).
  static const double _kMinInstitutionTableWidth = 1120;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SchoolController>();

    // Load schools on first build - defer to avoid build phase error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.schools.isEmpty && !controller.isLoading.value) {
        controller.loadSchools();
      }
      // Load institution types for filter dropdown
      if (controller.institutionTypes.isEmpty) {
        controller.loadInstitutionTypes();
      }
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
            SizedBox(height: 10),

            // Search and Sort Section
            _buildSearchAndSortSection(context, controller, isMobile, isTablet),
            SizedBox(height: 10),

            // Schools List
            Expanded(
              child: Obx(
                () =>
                    _buildSchoolsList(context, controller, isMobile, isTablet),
              ),
            ),

            // Pagination Controls
            _buildPaginationControls(context, controller, isMobile, isTablet),
          ],
        ),
      ),
    );
  }

  InputDecoration _schoolListFilterDecoration(
    bool isMobile,
    String labelText, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: 12,
      ),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildSchoolListStateFilter(
    SchoolController controller,
    bool isMobile,
  ) {
    return Obx(() {
      if (controller.isLoadingStates.value) {
        return TextFormField(
          readOnly: true,
          style: TextStyle(fontSize: isMobile ? 14 : 16),
          decoration: _schoolListFilterDecoration(
            isMobile,
            'Filter by State',
            suffixIcon: const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ).copyWith(hintText: 'Loading...'),
        );
      }
      return StateSearchField(
        textEditingController: controller.listFilterStateTextController,
        focusNode: controller.listFilterStateFocusNode,
        states: List.from(controller.states),
        decorationBuilder: ({Widget? suffixIcon}) =>
            _schoolListFilterDecoration(
              isMobile,
              'Filter by State',
              suffixIcon: suffixIcon,
            ),
        isMobile: isMobile,
        hintText: 'Search state',
        onStateId: controller.setListFilterState,
      );
    });
  }

  Widget _buildSchoolListDistrictFilter(
    SchoolController controller,
    bool isMobile,
  ) {
    return Obx(() {
      if (controller.isLoadingStateDistricts.value) {
        return TextFormField(
          readOnly: true,
          style: TextStyle(fontSize: isMobile ? 14 : 16),
          decoration: _schoolListFilterDecoration(
            isMobile,
            'Filter by District',
            suffixIcon: const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ).copyWith(hintText: 'Loading...'),
        );
      }
      if (controller.reportState.value.isEmpty) {
        return TextFormField(
          readOnly: true,
          style: TextStyle(fontSize: isMobile ? 14 : 16),
          decoration: _schoolListFilterDecoration(
            isMobile,
            'Filter by District',
          ).copyWith(hintText: 'Select state first'),
        );
      }
      final districts = List<DistrictModel>.from(controller.stateDistrictList);

      return Autocomplete<DistrictModel>(
        displayStringForOption: (d) => d.districtName,
        optionsBuilder: (TextEditingValue value) {
          final q = value.text.trim().toLowerCase();
          if (q.isEmpty) return districts;
          return districts.where(
            (d) => d.districtName.toLowerCase().contains(q),
          );
        },
        onSelected: (value) =>
            controller.setListFilterDistrict(value.districtName),
        fieldViewBuilder:
            (context, textController, focusNode, onFieldSubmitted) {
              if (controller.listFilterCityTextController.text !=
                  textController.text) {
                textController.value = TextEditingValue(
                  text: controller.listFilterCityTextController.text,
                  selection: TextSelection.collapsed(
                    offset: controller.listFilterCityTextController.text.length,
                  ),
                );
              }
              return TextFormField(
                controller: textController,
                focusNode: focusNode,
                style: TextStyle(fontSize: isMobile ? 14 : 16),
                decoration: _schoolListFilterDecoration(
                  isMobile,
                  'Filter by District',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      controller.setListFilterDistrict(textController.text);
                    },
                  ),
                ),
                onChanged: (value) {
                  controller.listFilterCityTextController.text = value;
                  if (value.trim().isEmpty) {
                    controller.setListFilterDistrict('');
                  }
                },
                onFieldSubmitted: (_) =>
                    controller.setListFilterDistrict(textController.text),
              );
            },
        optionsViewBuilder: (context, onSelected, options) {
          final opts = options.toList(growable: false);
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 240,
                  minWidth: 280,
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: opts.length,
                  itemBuilder: (context, index) {
                    final option = opts[index];
                    return ListTile(
                      dense: true,
                      title: Text(option.districtName),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildReportGenerationSection(
    BuildContext context,
    SchoolController controller,
    bool isMobile,
    bool isTablet,
  ) {
    // Do not wrap this whole section in Obx: the layout only uses non-reactive
    // `isMobile` / `isTablet`. State/city/type each use their own Obx where
    // `.obs` values are read (GetX requires every Obx builder to touch an observable).
    return isMobile
        ? Column(
            children: [
              _buildSchoolListStateFilter(controller, isMobile),
              SizedBox(height: isMobile ? 12 : 16),
              _buildSchoolListDistrictFilter(controller, isMobile),
              SizedBox(height: isMobile ? 12 : 16),
              Obx(() {
                String? currentValue;
                if (controller.reportInstitutionTypeId.value > 0) {
                  final selectedType = controller.institutionTypes
                      .firstWhereOrNull(
                        (t) => t.id == controller.reportInstitutionTypeId.value,
                      );
                  currentValue = selectedType?.displayName;
                }

                return _buildStringDropdown(
                  value: currentValue,
                  items: controller.institutionTypes
                      .map((t) => t.displayName)
                      .toList(),
                  hint: 'Select Institution Type',
                  selectAllLabel: 'Select Type',
                  labelText: 'Filter by Type',
                  onChanged: (value) {
                    if (value == null || value.isEmpty) {
                      controller.reportInstitutionTypeId.value = 0;
                    } else {
                      final selectedType = controller.institutionTypes
                          .firstWhereOrNull((t) => t.displayName == value);
                      controller.reportInstitutionTypeId.value =
                          selectedType?.id ?? 0;
                    }
                    controller.loadSchools(resetPage: true);
                  },
                  isMobile: isMobile,
                  isLoading: controller.isLoadingInstitutionTypes.value,
                );
              }),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: _buildSchoolListStateFilter(controller, isMobile),
              ),
              SizedBox(width: isTablet ? 12 : 16),
              Expanded(
                child: _buildSchoolListDistrictFilter(controller, isMobile),
              ),
              SizedBox(width: isTablet ? 12 : 16),
              Expanded(
                child: Obx(() {
                  String? currentValue;
                  if (controller.reportInstitutionTypeId.value > 0) {
                    final selectedType = controller.institutionTypes
                        .firstWhereOrNull(
                          (t) =>
                              t.id == controller.reportInstitutionTypeId.value,
                        );
                    currentValue = selectedType?.displayName;
                  }

                  return _buildStringDropdown(
                    value: currentValue,
                    items: controller.institutionTypes
                        .map((t) => t.displayName)
                        .toList(),
                    hint: 'Select Institution Type',
                    selectAllLabel: 'Select Type',
                    labelText: 'Filter by Type',
                    onChanged: (value) {
                      if (value == null || value.isEmpty) {
                        controller.reportInstitutionTypeId.value = 0;
                      } else {
                        final selectedType = controller.institutionTypes
                            .firstWhereOrNull((t) => t.displayName == value);
                        controller.reportInstitutionTypeId.value =
                            selectedType?.id ?? 0;
                      }
                      controller.loadSchools(resetPage: true);
                    },
                    isMobile: isMobile,
                    isLoading: controller.isLoadingInstitutionTypes.value,
                  );
                }),
              ),
            ],
          );
  }

  /// Reusable string-based dropdown
  Widget _buildStringDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required String selectAllLabel,
    required String labelText,
    required Function(String?) onChanged,
    required bool isMobile,
    bool isLoading = false,
  }) {
    if (isLoading) {
      return DropdownButtonFormField<String>(
        value: null,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: 12,
          ),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        hint: Text(
          'Loading...',
          style: TextStyle(fontSize: isMobile ? 14 : 16),
        ),
        items: [],
        onChanged: null,
      );
    }

    // Add select all option at the beginning
    final allItems = [selectAllLabel, ...items];

    return DropdownButtonFormField<String>(
      value: value != null && value.isNotEmpty ? value : null,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: 12,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      hint: Text(hint, style: TextStyle(fontSize: isMobile ? 14 : 16)),
      style: TextStyle(fontSize: isMobile ? 14 : 16),
      menuMaxHeight: 250,
      items: allItems.map((item) {
        final isSelectAll = item == selectAllLabel;
        return DropdownMenuItem<String>(
          value: isSelectAll ? '' : item,
          child: Text(
            item,
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: isSelectAll ? FontWeight.bold : FontWeight.normal,
              color: isSelectAll ? Colors.blue : null,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSearchAndSortSection(
    BuildContext context,
    SchoolController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      children: [
        // Search Field with Refresh Icon
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller.searchController,
                onChanged: (value) {
                  controller.searchQuery.value = value;
                  // Debounce search - reload after user stops typing
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (controller.searchQuery.value == value) {
                      controller.loadSchools(resetPage: true);
                    }
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by name, address, district, or state...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Obx(() {
                    if (controller.searchQuery.value.isNotEmpty) {
                      return IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.searchQuery.value = '';
                          controller.searchController.clear();
                          FocusScope.of(context).unfocus();
                          controller.loadSchools(resetPage: true);
                        },
                        tooltip: 'Clear',
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
            Obx(() {
              final permissionStore = Get.isRegistered<PermissionStore>()
                  ? Get.find<PermissionStore>()
                  : Get.put(PermissionStore());
              final busy = controller.isLoading.value;
              final showPostalPdf = permissionStore.has(
                'SHOW_INSTITUTION_POSTAL_PDF_ICON',
              );

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showPostalPdf) ...[
                    SizedBox(width: isMobile ? 8 : 12),
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      onPressed: busy
                          ? null
                          : () => _showPostalDownloadDialog(context, controller),
                      tooltip: 'Download institution list PDF (postal format)',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                  SizedBox(width: isMobile ? 8 : 12),
                  IconButton(
                    icon: const Icon(Icons.print),
                    onPressed: busy
                        ? null
                        : () => controller.generateReport('all'),
                    tooltip: 'Download / print institutions report',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              );
            }),
            SizedBox(width: isMobile ? 8 : 12),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // Reset all filter options
                controller.reportState.value = '';
                controller.reportDistrictId.value = 0;
                controller.reportInstitutionTypeId.value = 0;
                controller.selectedStateId.value = 0;
                controller.cities.clear();
                controller.stateDistrictList.clear();
                controller.listFilterStateTextController.clear();
                controller.listFilterCityTextController.clear();
                controller.searchQuery.value = '';
                controller.searchController.clear();
                // Reload schools with cleared filters
                controller.loadSchools(resetPage: true);
              },
              tooltip: 'Refresh',
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[100],
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ],
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

    // Use schools directly from API (already filtered)
    final schools = controller.schools;

    if (schools.isEmpty) {
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
      return _buildMobileList(context, schools, controller);
    } else {
      return _buildDesktopTable(context, schools, controller, isTablet);
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSchoolIcon(school, 50),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
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
                  if (school.institutionShortName != null &&
                      school.institutionShortName!.isNotEmpty)
                    _buildSchoolInfoRow(
                      'Short Name',
                      school.institutionShortName!,
                    ),
                  _buildSchoolInfoRow(
                    'Address & Location',
                    _buildAddressLocationText(school),
                  ),
                  _buildSchoolInfoRow(
                    'Type & Category',
                    _buildTypeAndCategoryText(school),
                  ),
                  if (school.email != null && school.email!.isNotEmpty)
                    _buildSchoolInfoRow('Email ID', school.email!),
                  if (school.createdAt != null)
                    _buildSchoolInfoRow('Created', _buildCreatedText(school)),
                  if (school.updatedAt != null)
                    _buildSchoolInfoRow('Updated', _buildUpdatedText(school)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          if (school.id != null) {
                            controller.loadSchoolForEdit(school.id!);
                          }
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          if (school.id != null) {
                            _showDeleteDialog(context, controller, school.id!);
                          }
                        },
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
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
          var viewportWidth = constraints.maxWidth;
          if (!viewportWidth.isFinite || viewportWidth <= 0) {
            viewportWidth = MediaQuery.sizeOf(context).width;
          }
          final tableWidth = math.max(
            _kMinInstitutionTableWidth,
            viewportWidth,
          );
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Table(
                  border: TableBorder.all(color: Colors.grey[300]!, width: 1),
                  columnWidths: const {
                    0: FixedColumnWidth(80),
                    1: FlexColumnWidth(2.5),
                    2: FlexColumnWidth(2.5),
                    3: FlexColumnWidth(1.5),
                    4: FlexColumnWidth(1.5),
                    5: FixedColumnWidth(190),
                    6: FixedColumnWidth(190),
                    7: FixedColumnWidth(108),
                  },
                  children: [
                    // Header Row
                    TableRow(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                      ),
                      children: [
                        _buildTableCell('ICON', isHeader: true),
                        _buildSortableHeader(
                          'INSTITUTION NAME',
                          'institutionName',
                          controller,
                        ),
                        _buildSortableHeader(
                          'ADDRESS & LOCATION',
                          'address',
                          controller,
                          isSortable: false,
                        ),
                        _buildSortableHeader(
                          'TYPE & CATEGORY',
                          'institutionType',
                          controller,
                          isSortable: false,
                        ),
                        _buildSortableHeader(
                          'EMAIL ID',
                          'email',
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
                        _buildTableCell('ACTIONS', isHeader: true),
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
                          _buildTableCell(
                            _buildInstitutionNameWithShortName(school),
                          ),
                          _buildTableCell(_buildAddressLocationText(school)),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Center(
                                child: _buildTypeAndCategoryChip(school),
                              ),
                            ),
                          ),
                          _buildTableCell(school.email ?? '-'),
                          _buildCreatedCellWidget(school),
                          _buildUpdatedCellWidget(school),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    color: Colors.blue,
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                    onPressed: () {
                                      if (school.id != null) {
                                        controller.loadSchoolForEdit(
                                          school.id!,
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18),
                                    color: Colors.red,
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                    onPressed: () {
                                      if (school.id != null) {
                                        _showDeleteDialog(
                                          context,
                                          controller,
                                          school.id!,
                                        );
                                      }
                                    },
                                  ),
                                ],
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
        softWrap: !isHeader,
        overflow: isHeader ? TextOverflow.visible : null,
        maxLines: isHeader ? 1 : null,
      ),
    );
  }

  Widget _buildCreatedCellWidget(SchoolModel school) {
    if (school.createdAt == null) {
      return _buildTableCell('-');
    }
    final dateTime = DateFormat(
      'MMM dd, yyyy hh:mm a',
    ).format(school.createdAt!);
    if (school.createdBy != null && school.createdBy!.isNotEmpty) {
      return _buildTableCell('$dateTime by ${school.createdBy}');
    }
    return _buildTableCell(dateTime);
  }

  Widget _buildUpdatedCellWidget(SchoolModel school) {
    if (school.updatedAt == null) {
      return _buildTableCell('-');
    }
    final dateTime = DateFormat(
      'MMM dd, yyyy hh:mm a',
    ).format(school.updatedAt!);
    if (school.updatedBy != null && school.updatedBy!.isNotEmpty) {
      return _buildTableCell('$dateTime by ${school.updatedBy}');
    }
    return _buildTableCell(dateTime);
  }

  String _buildCreatedText(SchoolModel school) {
    if (school.createdAt == null) {
      return '-';
    }
    final dateTime = DateFormat(
      'MMM dd, yyyy hh:mm a',
    ).format(school.createdAt!);
    if (school.createdBy != null && school.createdBy!.isNotEmpty) {
      return '$dateTime by ${school.createdBy}';
    }
    return dateTime;
  }

  String _buildUpdatedText(SchoolModel school) {
    if (school.updatedAt == null) {
      return '-';
    }
    final dateTime = DateFormat(
      'MMM dd, yyyy hh:mm a',
    ).format(school.updatedAt!);
    if (school.updatedBy != null && school.updatedBy!.isNotEmpty) {
      return '$dateTime by ${school.updatedBy}';
    }
    return dateTime;
  }

  Widget _buildSortableHeader(
    String label,
    String sortField,
    SchoolController controller, {
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
                controller.setSorting(sortField, newOrder);
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
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
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

  String _buildInstitutionNameWithShortName(SchoolModel school) {
    if (school.institutionShortName != null &&
        school.institutionShortName!.isNotEmpty) {
      return '${school.institutionName}\n(${school.institutionShortName})';
    }
    return school.institutionName;
  }

  String _buildTypeAndCategoryText(SchoolModel school) {
    // Use display names from API if available
    String displayType = school.institutionTypeDisplayName ?? '';
    String displayCategory = school.institutionCategoryDisplayName ?? '';

    // If display names are not available, parse from institutionType
    if (displayType.isEmpty) {
      final type = school.institutionType;
      if (type.contains('|')) {
        final parts = type.split('|');
        final baseType = parts[0].replaceAll('_', ' ');
        displayType = baseType
            .replaceAll('GOVT', 'Govt')
            .replaceAll('AIDED', 'Aided')
            .replaceAll('PRIVATE', 'Private')
            .replaceAll('SCHOOL', 'School')
            .replaceAll('COLLEGE', 'College')
            .replaceAll('YOGA', 'Yoga')
            .replaceAll('CENTER', 'Center');
      } else {
        displayType = type
            .replaceAll('_', ' ')
            .replaceAll('GOVT', 'Govt')
            .replaceAll('AIDED', 'Aided')
            .replaceAll('PRIVATE', 'Private')
            .replaceAll('SCHOOL', 'School')
            .replaceAll('COLLEGE', 'College')
            .replaceAll('YOGA', 'Yoga')
            .replaceAll('CENTER', 'Center');
      }
    }

    // If category display name is not available but we have category ID
    if (displayCategory.isEmpty && school.institutionType.contains('|')) {
      final parts = school.institutionType.split('|');
      if (parts.length > 1) {
        displayCategory = 'Category ID: ${parts[1]}';
      }
    }

    if (displayCategory.isNotEmpty) {
      return '$displayType\n$displayCategory';
    }
    return displayType.isNotEmpty ? displayType : '-';
  }

  String _buildAddressLocationText(SchoolModel school) {
    final parts = <String>[];
    if (school.address.isNotEmpty) {
      parts.add(school.address);
    }

    // Location line: district, city, village (when present), state, pincode
    final locationParts = <String>[];
    for (final part in [school.districtName, school.cityName, school.village]) {
      if (part != null && part.trim().isNotEmpty) {
        final t = part.trim();
        if (locationParts.isEmpty || locationParts.last != t) {
          locationParts.add(t);
        }
      }
    }
    if (school.stateName != null && school.stateName!.isNotEmpty) {
      locationParts.add(school.stateName!);
    } else if (school.state != null && school.state!.isNotEmpty) {
      locationParts.add(school.state!);
    }
    if (school.pincode.isNotEmpty) {
      locationParts.add(school.pincode);
    }

    if (locationParts.isNotEmpty) {
      parts.add(locationParts.join(', '));
    }

    return parts.join('\n');
  }

  Widget _buildTypeAndCategoryChip(SchoolModel school) {
    // Use display names from API if available, otherwise parse from institutionType
    String displayType = school.institutionTypeDisplayName ?? '';
    String displayCategory = school.institutionCategoryDisplayName ?? '';

    // If display names are not available, parse from institutionType
    if (displayType.isEmpty) {
      final type = school.institutionType;
      if (type.contains('|')) {
        final parts = type.split('|');
        final baseType = parts[0].replaceAll('_', ' ');
        displayType = baseType
            .replaceAll('GOVT', 'Govt')
            .replaceAll('AIDED', 'Aided')
            .replaceAll('PRIVATE', 'Private')
            .replaceAll('SCHOOL', 'School')
            .replaceAll('COLLEGE', 'College')
            .replaceAll('YOGA', 'Yoga')
            .replaceAll('CENTER', 'Center');
      } else {
        displayType = type
            .replaceAll('_', ' ')
            .replaceAll('GOVT', 'Govt')
            .replaceAll('AIDED', 'Aided')
            .replaceAll('PRIVATE', 'Private')
            .replaceAll('SCHOOL', 'School')
            .replaceAll('COLLEGE', 'College')
            .replaceAll('YOGA', 'Yoga')
            .replaceAll('CENTER', 'Center');
      }
    }

    // If category display name is not available but we have category ID
    if (displayCategory.isEmpty && school.institutionType.contains('|')) {
      final parts = school.institutionType.split('|');
      if (parts.length > 1) {
        displayCategory = 'Category ID: ${parts[1]}';
      }
    }

    Color chipColor;
    final typeString = school.institutionType;
    if (typeString.contains('Private') || typeString.contains('PRIVATE')) {
      chipColor = Colors.blue;
    } else if (typeString.contains('Govt') || typeString.contains('GOVT')) {
      chipColor = Colors.green;
    } else if (typeString.contains('Yoga') || typeString.contains('YOGA')) {
      chipColor = Colors.purple;
    } else {
      chipColor = Colors.grey;
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayType,
            style: TextStyle(
              color: chipColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (displayCategory.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              displayCategory,
              style: TextStyle(
                color: chipColor.withOpacity(0.8),
                fontSize: 9,
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstitutionTypeChip(String type) {
    if (type.trim().isEmpty) return const SizedBox.shrink();

    // Format the type for display (handle sub-categories)
    String displayType = type;
    if (type.contains('|')) {
      final parts = type.split('|');
      final baseType = parts[0].replaceAll('_', ' ');
      final subCategory = parts.length > 1 ? parts[1].replaceAll('_', ' ') : '';
      displayType = subCategory.isNotEmpty
          ? '$baseType - $subCategory'
          : baseType;
    } else {
      // Convert API format to readable format
      displayType = type
          .replaceAll('_', ' ')
          .replaceAll('GOVT', 'Govt')
          .replaceAll('AIDED', 'Aided')
          .replaceAll('PRIVATE', 'Private')
          .replaceAll('SCHOOL', 'School')
          .replaceAll('COLLEGE', 'College')
          .replaceAll('YOGA', 'Yoga')
          .replaceAll('CENTER', 'Center');
    }

    if (displayType.trim().isEmpty) return const SizedBox.shrink();

    Color chipColor;
    if (type.contains('Private') || type.contains('PRIVATE')) {
      chipColor = Colors.blue;
    } else if (type.contains('Govt') || type.contains('GOVT')) {
      chipColor = Colors.green;
    } else if (type.contains('Yoga') || type.contains('YOGA')) {
      chipColor = Colors.purple;
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
        displayType,
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

  void _showPostalDownloadDialog(
    BuildContext context,
    SchoolController controller,
  ) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Download Postal List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Optional: enter a recipient name to print on every address.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              maxLength: 35,
              decoration: const InputDecoration(
                labelText: 'Name of the person',
                hintText: 'Optional',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              Navigator.pop(dialogContext);
              controller.downloadPostalList(
                recipientName: name.isEmpty ? null : name,
              );
            },
            child: const Text('Download'),
          ),
        ],
      ),
    ).whenComplete(nameController.dispose);
  }

  void _showDeleteDialog(
    BuildContext context,
    SchoolController controller,
    String id,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Institution'),
        content: const Text(
          'Are you sure you want to delete this institution? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deleteSchool(id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(
    BuildContext context,
    SchoolController controller,
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
            // Page info and items per page
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Page ${controller.currentPage.value} of ${controller.totalPages.value}',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total: ${controller.totalItems.value} institutions',
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
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
