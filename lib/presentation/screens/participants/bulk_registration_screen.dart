import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../controllers/participant_controller.dart';
import '../../controllers/competition_controller.dart';
import '../../widgets/custom_loader.dart';
import '../../widgets/form_title.dart';
import '../../widgets/searchable_dropdown_field.dart';
import '../../widgets/form_label_with_hint.dart';
import '../../widgets/location/state_search_field.dart';
import '../../widgets/location/district_search_field.dart';
import '../../widgets/institution/institution_name_autocomplete_field.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/pinned_scroll_views.dart';
import '../../../core/utils/permission_store.dart';
import '../../../core/utils/photo_capture_service.dart';
import '../../../core/utils/photo_upload_processor.dart';
import '../../../data/models/competition_model.dart';
import '../../../data/models/district_model.dart';
import '../../../core/utils/registration_category_options.dart';
import '../../models/bulk_registration_row.dart';

List<({String groupName, String stageName})> _groupStageEntriesForBulk(
  CompetitionModel? competition,
  CompetitionController competitionController, {
  String? categoryName,
  String? categoryMode,
}) {
  if (competition == null) return const [];

  final selectedCategory = categoryName?.trim() ?? '';
  if (selectedCategory.isNotEmpty &&
      competition.categoryConfigs != null &&
      competition.categoryConfigs!.isNotEmpty) {
    final cfg = findCategoryConfig(
      configs: competition.categoryConfigs!,
      categoryName: selectedCategory,
      mode: categoryMode,
    );
    if (cfg != null) {
      final fromAllotment = <({String groupName, String stageName})>[];
      if (cfg.stageAllotment.isNotEmpty) {
        final stages = cfg.stageAllotment.keys.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        for (final stageName in stages) {
          final groups = _groupsInCreatedOrderForBulk(
            cfg.stageAllotment[stageName] ?? const [],
            selectedGroups: cfg.selectedGroups,
          );
          for (final groupName in groups) {
            fromAllotment.add((groupName: groupName, stageName: stageName));
          }
        }
        if (fromAllotment.isNotEmpty) return fromAllotment;
      }
      if (cfg.selectedGroups.isNotEmpty) {
        final stageByGroup = <String, String>{};
        final labels = competition.stageGroupLabels;
        if (labels != null) {
          for (final e in labels.entries) {
            for (final g in e.value) {
              stageByGroup[g.trim().toLowerCase()] = e.key;
            }
          }
        }
        final groups = _groupsInCreatedOrderForBulk(cfg.selectedGroups);
        for (final groupName in groups) {
          final stageName =
              stageByGroup[groupName.trim().toLowerCase()] ?? 'Stage';
          fromAllotment.add((groupName: groupName, stageName: stageName));
        }
        if (fromAllotment.isNotEmpty) return fromAllotment;
      }
    }
  }

  final entries = <({String groupName, String stageName})>[];

  if (competition.stageGroups != null && competition.stageGroups!.isNotEmpty) {
    final sortedStageIds =
        competition.stageGroups!.keys
            .map((id) => int.tryParse(id))
            .whereType<int>()
            .toList()
          ..sort((a, b) {
            final stageA =
                competitionController.getStageNameById(a)?.toLowerCase() ?? '';
            final stageB =
                competitionController.getStageNameById(b)?.toLowerCase() ?? '';
            return stageA.compareTo(stageB);
          });

    for (final stageId in sortedStageIds) {
      final stageName = competitionController.getStageNameById(stageId);
      if (stageName == null) continue;

      final groupIds = List<int>.from(
        competition.stageGroups![stageId.toString()] ?? const [],
      );

      for (final groupId in groupIds) {
        final groupName = competitionController.getGroupNameById(groupId);
        if (groupName != null) {
          entries.add((groupName: groupName, stageName: stageName));
        }
      }
    }
  }

  if (entries.isEmpty && competition.stageGroupLabels != null) {
    final sortedStages = competition.stageGroupLabels!.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    for (final stageName in sortedStages) {
      final groups = _groupsInCreatedOrderForBulk(
        competition.stageGroupLabels![stageName] ?? const [],
      );
      for (final groupName in groups) {
        entries.add((groupName: groupName, stageName: stageName));
      }
    }
  }

  return entries;
}

/// Registration group list in Challenge Config / created order, not A–Z.
List<String> _groupsInCreatedOrderForBulk(
  Iterable<String> groups, {
  List<String> selectedGroups = const [],
}) {
  final seen = <String>{};
  final result = <String>[];

  void add(String raw) {
    final name = raw.trim();
    if (name.isEmpty) return;
    if (seen.add(name.toLowerCase())) {
      result.add(name);
    }
  }

  if (selectedGroups.isNotEmpty) {
    final wanted = {
      for (final g in groups)
        if (g.trim().isNotEmpty) g.trim().toLowerCase(),
    };
    for (final g in selectedGroups) {
      if (wanted.contains(g.trim().toLowerCase())) add(g);
    }
  }
  for (final g in groups) {
    add(g);
  }
  return result;
}

class BulkRegistrationScreen extends StatelessWidget {
  const BulkRegistrationScreen({super.key});

  static const double _kBulkTableFieldHeight = 48;

  static InputDecoration _bulkTableFieldDecoration({
    Widget? suffixIcon,
    String? hintText,
  }) {
    return InputDecoration(
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      isDense: false,
      suffixIcon: suffixIcon,
      hintText: hintText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final participantController = Get.find<ParticipantController>();
    final competitionController = Get.put(CompetitionController());

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    // Load branch/org-scoped competitions for the dropdown.
    if (!competitionController.isLoadingHomeCompetitions.value &&
        !competitionController.isLoading.value) {
      competitionController.ensureRegistrationCompetitionChoicesLoaded();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      participantController.ensureInstitutionSearchFiltersLoaded();
      participantController.applySpotRegistrationRulesForSelectedEvent();
      final eventId = participantController.selectedEventId.value;
      if (eventId.isNotEmpty) {
        competitionController.ensureCompetitionLoadedForRegistration(eventId);
      }
    });

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : (isTablet ? 20 : 24)),
        child: Form(
          key: participantController.formKey,
          // Per-field `autovalidateMode` — Form-level `onUserInteraction` validates all fields.
          autovalidateMode: AutovalidateMode.disabled,
          child: PinnedVerticalScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                FormTitle(
                  text: 'BULK REGISTRATION',
                  isMobile: isMobile,
                  isTablet: isTablet,
                ),

                // Common Fields Section
                _buildCommonFieldsSection(
                  context,
                  participantController,
                  competitionController,
                  isMobile,
                  isTablet,
                ),
                SizedBox(height: isMobile ? 24 : 32),

                // Participants Table
                _buildParticipantsTable(
                  context,
                  participantController,
                  competitionController,
                  isMobile,
                  isTablet,
                ),
                SizedBox(height: isMobile ? 24 : 32),

                // Error Message
                Obx(() {
                  if (participantController.errorMessage.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            participantController.errorMessage.value,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                SizedBox(height: isMobile ? 16 : 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompetitionField(
    BuildContext context,
    ParticipantController controller,
    CompetitionController competitionController,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMPETITION :',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => SearchableDropdownField(
            selectedValue: controller.selectedEventId.value.isNotEmpty
                ? controller.selectedEventId.value
                : null,
            hintText: 'Select Competition',
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: 12,
            ),
            isDense: isMobile,
            items: competitionController.competitions
                .where((c) => c.id != null)
                .map(
                  (competition) => SearchableDropdownItem(
                    value: competition.id!,
                    label: competition.competitionName,
                  ),
                )
                .toList(),
            onChanged: (value) {
              controller.selectedEventId.value = value;
              competitionController.ensureCompetitionLoadedForRegistration(
                value,
              );
              for (final row in controller.bulkRegistrationRows) {
                if (row.isRegistered.value) continue;
                row.category.value = '';
                row.categoryMode.value = '';
                row.group.value = '';
                row.stage.value = '';
              }
              controller.applySpotRegistrationRulesForSelectedEvent();
              controller.validateRegistrationFormOnFieldChange();
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a competition';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCommonFieldsSection(
    BuildContext context,
    ParticipantController controller,
    CompetitionController competitionController,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCompetitionField(
          context,
          controller,
          competitionController,
          isMobile,
          isTablet,
        ),
        SizedBox(height: isMobile ? 20 : 24),
        _buildRegistrationTypeField(context, controller, isMobile, isTablet),
        Obx(() {
          final institutional = controller.isInstitutionalRegistrationCategory;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (institutional) ...[
                SizedBox(height: isMobile ? 20 : 24),
                _buildInstitutionFilterSection(
                  context,
                  controller,
                  isMobile,
                  isTablet,
                ),
              ],
              SizedBox(height: isMobile ? 20 : 24),
              isMobile
                  ? Column(
                      children: [
                        _buildTextField(
                          context,
                          label: institutional
                              ? 'Yoga Teacher Name :'
                              : 'Yoga Teacher Name (optional) :',
                          controller: controller.bulkYogaTeacherNameController,
                          participantController: controller,
                          isRequired: institutional,
                          isMobile: isMobile,
                          isTablet: isTablet,
                        ),
                        SizedBox(height: isMobile ? 20 : 24),
                        _buildYogaTeacherCellField(
                          context,
                          controller,
                          isMobile,
                          isTablet,
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildTextField(
                            context,
                            label: institutional
                                ? 'Yoga Teacher Name :'
                                : 'Yoga Teacher Name (optional) :',
                            controller:
                                controller.bulkYogaTeacherNameController,
                            participantController: controller,
                            isRequired: institutional,
                            isMobile: isMobile,
                            isTablet: isTablet,
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 20),
                        Expanded(
                          child: _buildYogaTeacherCellField(
                            context,
                            controller,
                            isMobile,
                            isTablet,
                          ),
                        ),
                      ],
                    ),
            ],
          );
        }),
        SizedBox(height: isMobile ? 20 : 24),
        _buildEcoCertificateOptInField(context, controller, isMobile),
        SizedBox(height: isMobile ? 20 : 24),
        _buildSpotRegistrationSection(
          context,
          controller,
          competitionController,
          isMobile,
          isTablet,
        ),
      ],
    );
  }

  bool _isSpotRegistrationOptionVisible(
    PermissionStore permissionStore,
    ParticipantController participantController,
    CompetitionController competitionController,
  ) {
    if (!permissionStore.has('SHOW_SPOT_REGISTRATION_OPTION')) {
      return false;
    }
    if (competitionController.competitions.isEmpty) {
      return false;
    }
    return participantController.isSpotRegistrationOptionVisible;
  }

  Widget _buildSpotRegistrationSection(
    BuildContext context,
    ParticipantController participantController,
    CompetitionController competitionController,
    bool isMobile,
    bool isTablet,
  ) {
    return Obx(() {
      final permissionStore = Get.isRegistered<PermissionStore>()
          ? Get.find<PermissionStore>()
          : Get.put(PermissionStore());
      final _ = competitionController.competitions.length;
      final visible = _isSpotRegistrationOptionVisible(
        permissionStore,
        participantController,
        competitionController,
      );
      if (!visible) {
        return const SizedBox.shrink();
      }
      return _buildSpotRegistrationField(
        context,
        participantController,
        isMobile,
        isTablet,
      );
    });
  }

  Widget _buildSpotRegistrationField(
    BuildContext context,
    ParticipantController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(label: 'Spot Registration :', bottomSpacing: 8),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('No'),
                  value: false,
                  groupValue: controller.isSpotRegistration.value,
                  onChanged: (value) {
                    if (value != null) {
                      controller.isSpotRegistration.value = value;
                      controller.validateRegistrationFormOnFieldChange();
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Yes'),
                  value: true,
                  groupValue: controller.isSpotRegistration.value,
                  onChanged: (value) {
                    if (value != null) {
                      controller.isSpotRegistration.value = value;
                      controller.validateRegistrationFormOnFieldChange();
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationTypeField(
    BuildContext context,
    ParticipantController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(label: 'Registration Type :', bottomSpacing: 8),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: Text(
                    'Institutional Category',
                    style: TextStyle(fontSize: isMobile ? 13 : 14),
                  ),
                  value: 'INSTITUTIONAL',
                  groupValue: controller.registrationCategory.value,
                  onChanged: (value) {
                    if (value != null) {
                      controller.setRegistrationCategory(value);
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: Text(
                    'Open Category',
                    style: TextStyle(fontSize: isMobile ? 13 : 14),
                  ),
                  value: 'OPEN',
                  groupValue: controller.registrationCategory.value,
                  onChanged: (value) {
                    if (value != null) {
                      controller.setRegistrationCategory(value);
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEcoCertificateOptInField(
    BuildContext context,
    ParticipantController controller,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormLabelWithHint(label: 'E-Certificate :', bottomSpacing: 8),
        CheckboxListTile(
          value: true,
          onChanged: null,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: Colors.green,
          title: Text(
            'Save Trees. Go Green. Opt for a Downloadable E-Certificate',
            style: TextStyle(fontSize: isMobile ? 12 : 13),
          ),
        ),
      ],
    );
  }

  Widget _buildYogaTeacherCellField(
    BuildContext context,
    ParticipantController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(
          () => FormLabelWithHint(
            label: controller.isInstitutionalRegistrationCategory
                ? 'Yoga Teacher Cell :'
                : 'Yoga Teacher Cell (optional) :',
            hintText: '(Without +91)',
            bottomSpacing: 5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          controller: controller.bulkYogaTeacherCellController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          onChanged: (_) => controller.validateRegistrationFormOnFieldChange(),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            counterText: '',
          ),
          validator: (value) {
            final requiredField = controller.isInstitutionalRegistrationCategory;
            final cell = value?.trim() ?? '';
            if (cell.isEmpty) {
              return requiredField ? 'Yoga teacher cell is required' : null;
            }
            if (cell.length != 10) {
              return 'Cell number must be 10 digits';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required ParticipantController participantController,
    bool isRequired = false,
    bool isMobile = false,
    bool isTablet = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          autovalidateMode: isRequired
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          controller: controller,
          onChanged: (_) =>
              participantController.validateRegistrationFormOnFieldChange(),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildInstitutionFilterSection(
    BuildContext context,
    ParticipantController controller,
    bool isMobile,
    bool isTablet,
  ) {
    final rowGap = isTablet ? 16.0 : 20.0;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormLabelWithHint(
            label: 'Filter institution',
            hintText: 'Optional state & district before search',
            bottomSpacing: 8,
          ),
          _buildStateDistrictColumn(context, controller, isMobile, isTablet),
          SizedBox(height: isMobile ? 20 : 24),
          _buildInstitutionField(context, controller, isMobile, isTablet),
        ],
      );
    }

    // Match competition/category row: filters on the left, institution on the right
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormLabelWithHint(
                label: 'Filter institution',
                hintText: 'Optional state & district before search',
                bottomSpacing: 8,
              ),
              _buildStateDistrictColumn(
                context,
                controller,
                isMobile,
                isTablet,
              ),
            ],
          ),
        ),
        SizedBox(width: rowGap),
        Expanded(
          child: _buildInstitutionField(
            context,
            controller,
            isMobile,
            isTablet,
          ),
        ),
      ],
    );
  }

  /// State and district on the same horizontal line.
  Widget _buildStateDistrictColumn(
    BuildContext context,
    ParticipantController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Obx(() {
      controller.ensureInstitutionSearchFiltersLoaded();

      InputDecoration filterDecoration({Widget? suffixIcon}) {
        return InputDecoration(
          labelText: null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: suffixIcon,
        );
      }

      final loadingLocations =
          controller.isLoadingInstitutionSearchLocations.value;
      final stateId = controller.institutionSearchFilterStateId.value;
      final loadingDistricts =
          controller.isLoadingInstitutionSearchDistricts.value;
      final districtListVersion = controller.institutionSearchDistricts.length;

      final stateField = loadingLocations
          ? TextFormField(
              readOnly: true,
              style: TextStyle(fontSize: isMobile ? 14 : 16),
              decoration: filterDecoration(
                suffixIcon: const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ).copyWith(hintText: 'Loading states...'),
            )
          : StateSearchField(
              textEditingController:
                  controller.institutionFilterStateTextController,
              focusNode: controller.institutionFilterStateFocusNode,
              states: List.from(controller.institutionSearchStates),
              decorationBuilder: ({Widget? suffixIcon}) => filterDecoration(
                suffixIcon: suffixIcon,
              ).copyWith(labelText: 'State'),
              isMobile: isMobile,
              hintText: 'Filter by State',
              onStateId: controller.setInstitutionSearchFilterState,
            );

      final districtField = loadingDistricts
          ? TextFormField(
              readOnly: true,
              style: TextStyle(fontSize: isMobile ? 14 : 16),
              decoration: filterDecoration(
                suffixIcon: const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ).copyWith(hintText: 'Loading districts...'),
            )
          : (stateId <= 0
                ? TextFormField(
                    readOnly: true,
                    style: TextStyle(fontSize: isMobile ? 14 : 16),
                    decoration: filterDecoration().copyWith(
                      labelText: 'District',
                      hintText: 'Select state first',
                    ),
                  )
                : DistrictSearchField(
                    key: ValueKey(
                      'bulk_district_${stateId}_$districtListVersion',
                    ),
                    textEditingController:
                        controller.institutionFilterDistrictTextController,
                    focusNode: controller.institutionFilterDistrictFocusNode,
                    districts: List<DistrictModel>.from(
                      controller.institutionSearchDistricts,
                    ),
                    decorationBuilder: ({Widget? suffixIcon}) =>
                        filterDecoration(
                          suffixIcon: suffixIcon,
                        ).copyWith(labelText: 'District'),
                    isMobile: isMobile,
                    hintText: 'Filter by District',
                  ));

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: stateField),
          SizedBox(width: isMobile ? 12 : (isTablet ? 16 : 20)),
          Expanded(child: districtField),
        ],
      );
    });
  }

  Widget _buildInstitutionField(
    BuildContext context,
    ParticipantController controller,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Institution Name :',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => InstitutionNameAutocompleteField(
            autocompleteKey:
                'bulk-institution-${controller.selectedEventId.value}-${controller.bulkInstitutionNameController.text.length}',
            formTextController: controller.bulkInstitutionNameController,
            onSearch: (q) => controller.searchInstitutions(q),
            suggestions: controller.institutionSuggestions,
            isLoading: controller.isLoadingInstitutions,
            onInstitutionSelected: controller.selectInstitution,
            onClear: () {
              controller.selectedInstitutionId.value = null;
              controller.selectedInstitution.value = null;
              controller.validateRegistrationFormOnFieldChange();
            },
            onValueChanged: controller.validateRegistrationFormOnFieldChange,
            isViewMode: controller.isViewMode,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Institution name is required';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRowCategoryField(
    ParticipantController controller,
    CompetitionController competitionController,
    BulkRegistrationRow row, {
    required bool isMobile,
  }) {
    return Obx(() {
      final readOnly = row.isRegistered.value;
      final selectedCompetition = competitionController.competitions
          .firstWhereOrNull((c) => c.id == controller.selectedEventId.value);
      final options = buildRegistrationCategoryOptions(
        configs: selectedCompetition?.categoryConfigs,
        categoryNames: selectedCompetition?.categories,
        competitionMode: selectedCompetition?.competitionMode,
      );
      final selectedName = row.category.value;
      final selectedMode = row.categoryMode.value;
      final selectedValue = options
          .firstWhereOrNull(
            (o) =>
                o.categoryName == selectedName &&
                (selectedMode.isEmpty || o.mode == selectedMode),
          )
          ?.valueKey;

      return DropdownButtonFormField<String>(
        value: selectedValue,
        isExpanded: true,
        style: const TextStyle(fontSize: 12, color: Colors.black),
        decoration: isMobile
            ? const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              )
            : BulkRegistrationScreen._bulkTableFieldDecoration(
                hintText: 'Select',
              ),
        hint: const Text('Select', style: TextStyle(fontSize: 12)),
        items: options.map((option) {
          return DropdownMenuItem<String>(
            value: option.valueKey,
            child: Text(
              option.displayLabel,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          );
        }).toList(),
        onChanged: readOnly
            ? null
            : (value) {
                final option = RegistrationCategoryOption.tryParse(value);
                if (option == null) return;
                final changed = option.categoryName != row.category.value ||
                    option.mode != row.categoryMode.value;
                row.category.value = option.categoryName;
                row.categoryMode.value = option.mode;
                if (changed) {
                  row.group.value = '';
                  row.stage.value = '';
                }
              },
      );
    });
  }

  Widget _buildParticipantsTable(
    BuildContext context,
    ParticipantController controller,
    CompetitionController competitionController,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table Header
        if (!isMobile)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'NAME',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'PHONE',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Expanded(
                  child: Text(
                    'D.O.B',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Expanded(
                  child: Text(
                    'SEX',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'CATEGORY',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Expanded(
                  child: Text(
                    'GROUP',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Expanded(
                  child: Text(
                    'PHOTO *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
        // Table Rows
        Obx(
          () => Column(
            children: [
              ...controller.bulkRegistrationRows.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                return _buildTableRow(
                  context,
                  controller,
                  competitionController,
                  index,
                  row,
                  isMobile,
                  isTablet,
                );
              }).toList(),
            ],
          ),
        ),
        // Register current row and prepare next entry
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Align(
            alignment: Alignment.center,
            child: Obx(
              () => controller.isLoading.value
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CustomLoader(size: 24),
                    )
                  : Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: controller.addBulkRegistrationRow,
                          icon: const Icon(Icons.add),
                          label: const Text('Add row'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            controller.errorMessage.value = '';
                            await controller.registerCurrentBulkParticipant(
                              competitionController: competitionController,
                            );
                          },
                          icon: const Icon(Icons.how_to_reg_outlined),
                          label: Text(
                            _bulkRegisterPaysNow(
                                  controller,
                                  competitionController,
                                )
                                ? 'Pay & Register'
                                : 'Register',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        _buildAmountAndPaymentSection(
          context,
          controller,
          competitionController,
          isMobile,
        ),
      ],
    );
  }

  Widget _buildAmountAndPaymentSection(
    BuildContext context,
    ParticipantController controller,
    CompetitionController competitionController,
    bool isMobile,
  ) {
    return Obx(() {
      competitionController.competitions.length;
      competitionController.categoryIncludeFee.length;
      final payOnline =
          competitionController.organizationPaymentModel.value
              .trim()
              .toUpperCase() ==
          'PAY_PER_PARTICIPANT';
      final eventId = controller.selectedEventId.value;
      final spot = controller.isSpotRegistration.value;
      final lines = <_BulkFeeLine>[];
      for (final row in controller.bulkRegistrationRows) {
        if (row.isRegistered.value) continue;
        final line = _feeLineForRow(
          controller,
          competitionController,
          row,
          eventId: eventId,
          spot: spot,
        );
        if (line != null) lines.add(line);
      }
      final total = lines.fold<double>(0, (sum, line) => sum + line.paidPayable);
      final saved = lines.fold<double>(0, (sum, line) => sum + line.saved);
      final paidGroups = _groupFeeAmounts(lines.map((line) => line.paidPayable));
      final savedByOffer = <String, List<_BulkFeeLine>>{};
      for (final line in lines) {
        if (line.saved <= 0.009) continue;
        savedByOffer.putIfAbsent(line.offerLabel, () => []).add(line);
      }

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lines.isEmpty)
              const Text(
                'Select a category on each row to see the fee.',
                style: TextStyle(fontSize: 13),
              )
            else ...[
              Text(
                'Total amount: ${_feeProductText(paidGroups, total)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (saved > 0.009)
                ...savedByOffer.entries.map((entry) {
                  final offerLines = entry.value;
                  final offerSaved = offerLines.fold<double>(
                    0,
                    (sum, line) => sum + line.saved,
                  );
                  final offerGroups = _groupFeeAmounts(
                    offerLines.map((line) => line.saved),
                  );
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: entry.key,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.green.shade800,
                              backgroundColor: Colors.green.shade50,
                            ),
                          ),
                          TextSpan(
                            text:
                                ' applied. You save: ${_feeProductText(offerGroups, offerSaved)}',
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
            const SizedBox(height: 12),
            Text(
              'Payment',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 15 : 16,
              ),
            ),
            const SizedBox(height: 4),
            if (payOnline)
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.payment, color: Colors.green),
                title: Text('Online payment'),
                subtitle: Text(
                  'This competition accepts online payment only. Pay & Register collects the total for every pending participant.',
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('GPay'),
                      value: 'GPAY',
                      groupValue: controller.selectedPaymentMode.value,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        if (value != null) {
                          controller.selectedPaymentMode.value = value;
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Cash'),
                      value: 'CASH',
                      groupValue: controller.selectedPaymentMode.value,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        if (value != null) {
                          controller.selectedPaymentMode.value = value;
                        }
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    });
  }

  Widget _buildTableRow(
    BuildContext context,
    ParticipantController controller,
    CompetitionController competitionController,
    int index,
    BulkRegistrationRow row,
    bool isMobile,
    bool isTablet,
  ) {
    if (isMobile) {
      return Obx(() {
        final readOnly = row.isRegistered.value;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: readOnly ? AppTheme.primaryColor.withOpacity(0.06) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (readOnly)
                      Text(
                        'Registered',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Remove entry',
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          controller.removeBulkRegistrationRow(index),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                  ],
                ),
                _buildMobileField(
                  'NAME',
                  TextFormField(
                    controller: row.nameController,
                    readOnly: readOnly,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMobileField(
                  'PHONE',
                  TextFormField(
                    controller: row.phoneController,
                    readOnly: readOnly,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 10,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      counterText: '',
                      hintText: '10 digits',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMobileField(
                  'D.O.B',
                  InkWell(
                    onTap: readOnly ? null : () => _selectDate(context, row),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                        isDense: true,
                      ),
                      child: Obx(
                        () => Text(
                          row.dateOfBirth.value != null
                              ? DateFormat(
                                  'yyyy-MM-dd',
                                ).format(row.dateOfBirth.value!)
                              : 'Select date',
                          style: TextStyle(
                            color: row.dateOfBirth.value != null
                                ? Colors.black
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMobileField(
                  'SEX',
                  Obx(
                    () => DropdownButtonFormField<String>(
                      value: row.gender.value.isNotEmpty
                          ? row.gender.value
                          : null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: ['Male', 'Female'].map((gender) {
                        return DropdownMenuItem<String>(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      onChanged: readOnly
                          ? null
                          : (value) {
                              if (value != null) {
                                row.gender.value = value;
                              }
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMobileField(
                  'CATEGORY',
                  _buildRowCategoryField(
                    controller,
                    competitionController,
                    row,
                    isMobile: true,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMobileField(
                  'GROUP',
                  _buildGroupDropdown(
                    context,
                    controller,
                    competitionController,
                    row,
                    isMobile,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMobileField(
                  'PHOTO *',
                  _buildPhotoField(context, controller, row, isMobile),
                ),
              ],
            ),
          ),
        );
      });
    }

    return Obx(() {
      final readOnly = row.isRegistered.value;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: readOnly ? AppTheme.primaryColor.withOpacity(0.06) : null,
          border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Row(
          children: [
            // NAME
            Expanded(
              flex: 2,
              child: SizedBox(
                height: _kBulkTableFieldHeight,
                child: TextFormField(
                  controller: row.nameController,
                  readOnly: readOnly,
                  style: const TextStyle(fontSize: 12),
                  decoration: _bulkTableFieldDecoration(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // PHONE
            Expanded(
              flex: 2,
              child: SizedBox(
                height: _kBulkTableFieldHeight,
                child: TextFormField(
                  controller: row.phoneController,
                  readOnly: readOnly,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 10,
                  style: const TextStyle(fontSize: 12),
                  decoration: _bulkTableFieldDecoration(
                    hintText: '10 digits',
                  ).copyWith(counterText: ''),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // D.O.B
            Expanded(
              child: SizedBox(
                height: _kBulkTableFieldHeight,
                child: InkWell(
                  onTap: readOnly ? null : () => _selectDate(context, row),
                  child: InputDecorator(
                    decoration: _bulkTableFieldDecoration(
                      suffixIcon: const Icon(Icons.calendar_today, size: 18),
                      hintText: 'Select',
                    ),
                    child: Obx(
                      () => Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          row.dateOfBirth.value != null
                              ? DateFormat(
                                  'dd/MM/yyyy',
                                ).format(row.dateOfBirth.value!)
                              : 'Select',
                          style: TextStyle(
                            fontSize: 12,
                            color: row.dateOfBirth.value != null
                                ? Colors.black
                                : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // SEX
            Expanded(
              child: SizedBox(
                height: _kBulkTableFieldHeight,
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    value: row.gender.value.isNotEmpty
                        ? row.gender.value
                        : null,
                    isExpanded: true,
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                    decoration: _bulkTableFieldDecoration(hintText: 'Select'),
                    items: ['Male', 'Female'].map((gender) {
                      return DropdownMenuItem<String>(
                        value: gender,
                        child: Text(
                          gender,
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                    onChanged: readOnly
                        ? null
                        : (value) {
                            if (value != null) {
                              row.gender.value = value;
                            }
                          },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: _kBulkTableFieldHeight,
                child: _buildRowCategoryField(
                  controller,
                  competitionController,
                  row,
                  isMobile: false,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // GROUP
            Expanded(
              child: SizedBox(
                height: _kBulkTableFieldHeight,
                child: _buildGroupDropdown(
                  context,
                  controller,
                  competitionController,
                  row,
                  isMobile,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // PHOTO
            Expanded(
              child: _buildPhotoField(context, controller, row, isMobile),
            ),
            IconButton(
              tooltip: 'Remove entry',
              visualDensity: VisualDensity.compact,
              onPressed: () => controller.removeBulkRegistrationRow(index),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMobileField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 4),
        field,
      ],
    );
  }

  Widget _buildGroupDropdown(
    BuildContext context,
    ParticipantController controller,
    CompetitionController competitionController,
    BulkRegistrationRow row,
    bool isMobile,
  ) {
    return Obx(() {
      final selectedCompetition = competitionController.competitions
          .firstWhereOrNull((c) => c.id == controller.selectedEventId.value);
      final selectedCategory = row.category.value;
      final selectedCategoryMode = row.categoryMode.value;

      final groupStageEntries = _groupStageEntriesForBulk(
        selectedCompetition,
        competitionController,
        categoryName: selectedCategory,
        categoryMode: selectedCategoryMode,
      );

      final allGroupsWithStage = groupStageEntries
          .map((e) => '${e.groupName} (GROUP ${e.stageName})')
          .toList();

      final readOnly = row.isRegistered.value;

      String? currentValue;
      if (row.group.value.isNotEmpty) {
        final stage = row.stage.value.isNotEmpty
            ? row.stage.value
            : controller.selectedStage.value;
        if (stage.isNotEmpty) {
          final formatted = '${row.group.value} (GROUP $stage)';
          currentValue = allGroupsWithStage.contains(formatted)
              ? formatted
              : allGroupsWithStage.firstWhereOrNull(
                  (item) => item.startsWith('${row.group.value} (GROUP'),
                );
        } else {
          currentValue = allGroupsWithStage.firstWhereOrNull(
            (item) => item.startsWith('${row.group.value} (GROUP'),
          );
        }
      }

      return DropdownButtonFormField<String>(
        key: ValueKey('bulk-group-${selectedCategory}-${row.hashCode}'),
        value: currentValue,
        isExpanded: true,
        style: TextStyle(fontSize: isMobile ? 12 : 12, color: Colors.black),
        decoration: isMobile
            ? const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                isDense: true,
              )
            : _bulkTableFieldDecoration(hintText: 'Select'),
        hint: Text('Select', style: TextStyle(fontSize: isMobile ? 12 : 12)),
        menuMaxHeight: 320,
        items: allGroupsWithStage.map((formattedGroup) {
          return DropdownMenuItem<String>(
            value: formattedGroup,
            child: Text(
              formattedGroup,
              style: TextStyle(fontSize: isMobile ? 12 : 12),
            ),
          );
        }).toList(),
        onChanged: readOnly
            ? null
            : (value) {
                if (value != null) {
                  final groupName = value.split(' (GROUP').first.trim();
                  final stagePart = value
                      .split('GROUP ')
                      .last
                      .replaceAll(')', '')
                      .trim();
                  row.group.value = groupName;
                  row.stage.value = stagePart;
                  controller.selectedStage.value = stagePart;
                }
              },
      );
    });
  }

  Widget _buildPhotoField(
    BuildContext context,
    ParticipantController controller,
    BulkRegistrationRow row,
    bool isMobile,
  ) {
    return Obx(
      () => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            onPressed: row.isRegistered.value
                ? null
                : () => _pickPhoto(context, controller, row),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 12,
                vertical: isMobile ? 6 : 8,
              ),
              minimumSize: const Size(0, 32),
            ),
            child: const Text('BROWSE', style: TextStyle(fontSize: 12)),
          ),
          if (row.photoFile.value != null ||
              row.photoXFile.value != null ||
              row.photoBytes.value != null) ...[
            const SizedBox(height: 4),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: kIsWeb
                    ? (row.photoBytes.value != null
                          ? Image.memory(
                              row.photoBytes.value!,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.image, size: 20))
                    : (row.photoFile.value != null &&
                              row.photoFile.value!.existsSync()
                          ? Image.file(row.photoFile.value!, fit: BoxFit.cover)
                          : const Icon(Icons.image, size: 20)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    BulkRegistrationRow row,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: row.dateOfBirth.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      row.dateOfBirth.value = picked;
      row.dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
      Get.find<ParticipantController>().validateRegistrationFormOnFieldChange();
    }
  }

  Future<void> _pickPhoto(
    BuildContext context,
    ParticipantController controller,
    BulkRegistrationRow row,
  ) async {
    try {
      final XFile? image = await PhotoCaptureService.pickImage(
        source: ImageSource.gallery,
        context: context,
        imageQuality: 85,
      );

      if (image != null) {
        final processed = await PhotoUploadProcessor.processXFile(image);
        if (processed == null) return;

        row.photoXFile.value = processed.xFile;
        if (kIsWeb) {
          row.photoBytes.value = processed.bytes;
        } else {
          row.photoFile.value = processed.file;
        }
      }
    } on PhotoUploadException catch (e) {
      controller.errorMessage.value = e.message;
    } catch (e) {
      controller.errorMessage.value = 'Error picking image: ${e.toString()}';
    }
  }
}

class _BulkFeeLine {
  const _BulkFeeLine({
    required this.offerLabel,
    required this.normalPayable,
    required this.paidPayable,
  });

  final String offerLabel;
  final double normalPayable;
  final double paidPayable;

  bool get hasDiscount => paidPayable + 0.009 < normalPayable;

  double get saved => hasDiscount ? normalPayable - paidPayable : 0;
}

String _inr(double value) => '₹${value.toStringAsFixed(2)}';

List<({int count, double unit})> _groupFeeAmounts(Iterable<double> amounts) {
  final groups = <String, ({int count, double unit})>{};
  for (final amount in amounts) {
    final key = amount.toStringAsFixed(2);
    final current = groups[key];
    groups[key] = (count: (current?.count ?? 0) + 1, unit: amount);
  }
  return groups.values.toList();
}

String _feeProductText(List<({int count, double unit})> groups, double total) {
  if (groups.length == 1) {
    final group = groups.first;
    return '${group.count} × ${_inr(group.unit)} = ${_inr(total)}';
  }
  final parts = groups
      .map((group) => '${group.count} × ${_inr(group.unit)}')
      .join(' + ');
  return '$parts = ${_inr(total)}';
}

bool _bulkRegisterPaysNow(
  ParticipantController controller,
  CompetitionController competitionController,
) {
  competitionController.competitions.length;
  if (competitionController.organizationPaymentModel.value
          .trim()
          .toUpperCase() !=
      'PAY_PER_PARTICIPANT') {
    return false;
  }
  final eventId = controller.selectedEventId.value;
  final spot = controller.isSpotRegistration.value;
  for (final row in controller.bulkRegistrationRows) {
    if (row.isRegistered.value) continue;
    final line = _feeLineForRow(
      controller,
      competitionController,
      row,
      eventId: eventId,
      spot: spot,
    );
    if (line != null && (line.paidPayable * 100).round() >= 100) {
      return true;
    }
  }
  return false;
}

_BulkFeeLine? _feeLineForRow(
  ParticipantController controller,
  CompetitionController competitionController,
  BulkRegistrationRow row, {
  required String eventId,
  required bool spot,
}) {
  final categoryName = row.category.value.trim();
  if (eventId.isEmpty || categoryName.isEmpty) return null;
  final categoryId = competitionController.getCategoryIdByName(categoryName);
  if (categoryId == null) return null;

  final mode = row.categoryMode.value;
  final count = controller.filledBulkCountForCategory(row);
  final normalPayable = competitionController.resolveCategoryPayableFeeRupees(
    eventId,
    categoryId,
    spotRegistration: spot,
    categoryMode: mode,
    applyOffers: false,
  );
  final earlyPayable = competitionController.resolveCategoryPayableFeeRupees(
    eventId,
    categoryId,
    spotRegistration: spot,
    categoryMode: mode,
  );
  final paidPayable = competitionController.resolveCategoryPayableFeeRupees(
    eventId,
    categoryId,
    spotRegistration: spot,
    bulkCategoryCount: count,
    categoryMode: mode,
  );
  if (normalPayable <= 0 && paidPayable <= 0) return null;

  String offer = 'Online';
  if (spot) {
    offer = 'Spot';
  } else if (paidPayable + 0.009 < earlyPayable) {
    offer = 'Group discount';
  } else if (earlyPayable + 0.009 < normalPayable) {
    offer = 'Early Bird';
  }

  return _BulkFeeLine(
    offerLabel: offer,
    normalPayable: normalPayable,
    paidPayable: paidPayable,
  );
}
