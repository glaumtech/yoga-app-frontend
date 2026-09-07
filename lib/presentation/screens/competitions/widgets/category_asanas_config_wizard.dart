import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/category_config_model.dart';
import '../../../../data/models/competition_grade_model.dart';
import '../../../controllers/competition_controller.dart';
import '../../../models/competition_grade_entry.dart';
import '../../../models/increase_count_range_entry.dart';

/// Full-screen dialog wizard for Asanas / Challenge category configuration.
/// Offline: 12 steps (includes Stages + Stage Allotment).
/// Online Count: 10 steps (Groups → Type → Fees; scoring skipped).
/// Online Video: 11 steps (Groups → Type → Scoring → Fees).
class CategoryAsanasConfigWizard extends StatefulWidget {
  const CategoryAsanasConfigWizard({
    super.key,
    required this.initialConfig,
    required this.onSaved,
    this.onCancel,
    this.otherCategoryNames = const [],
    this.readOnly = false,
    this.competitionController,
  });

  final CompetitionCategoryConfigModel initialConfig;
  final ValueChanged<CompetitionCategoryConfigModel> onSaved;
  final VoidCallback? onCancel;
  final List<String> otherCategoryNames;
  final bool readOnly;
  final CompetitionController? competitionController;

  /// Opens the wizard as a dialog. Returns the saved config, or null if cancelled.
  static Future<CompetitionCategoryConfigModel?> show(
    BuildContext context, {
    required CompetitionCategoryConfigModel config,
    List<String> otherCategoryNames = const [],
    bool readOnly = false,
    CompetitionController? competitionController,
  }) {
    return showDialog<CompetitionCategoryConfigModel>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return CategoryAsanasConfigWizard(
          initialConfig: config,
          otherCategoryNames: otherCategoryNames,
          readOnly: readOnly,
          competitionController: competitionController,
          onSaved: (saved) => Navigator.of(ctx).pop(saved),
          onCancel: () => Navigator.of(ctx).pop(),
        );
      },
    );
  }

  @override
  State<CategoryAsanasConfigWizard> createState() =>
      _CategoryAsanasConfigWizardState();
}

enum _WizardStepId {
  stages,
  groups,
  allot,
  submissionType,
  scoring,
  gender,
  juries,
  asanas,
  bends,
  prizes,
  viva,
  gifts,
  fees,
}

class _WizardStepMeta {
  const _WizardStepMeta(this.id, this.label, this.short);
  final _WizardStepId id;
  final String label;
  final String short;
}

class _CategoryAsanasConfigWizardState
    extends State<CategoryAsanasConfigWizard> {
  static const List<_WizardStepMeta> _offlineSteps = [
    _WizardStepMeta(_WizardStepId.stages, 'Stages', 'Stages'),
    _WizardStepMeta(_WizardStepId.groups, 'Group Types', 'Groups'),
    _WizardStepMeta(_WizardStepId.allot, 'Stage Allotment', 'Allot'),
    _WizardStepMeta(_WizardStepId.scoring, 'Scoring', 'Scoring'),
    _WizardStepMeta(_WizardStepId.gender, 'Gender', 'Gender'),
    _WizardStepMeta(_WizardStepId.juries, 'Juries', 'Juries'),
    _WizardStepMeta(_WizardStepId.asanas, 'Asanas', 'Asanas'),
    _WizardStepMeta(_WizardStepId.bends, 'Bend Types', 'Bends'),
    _WizardStepMeta(_WizardStepId.prizes, 'Prizes', 'Prizes'),
    _WizardStepMeta(_WizardStepId.viva, 'Viva Voce', 'Viva'),
    _WizardStepMeta(_WizardStepId.gifts, 'Compliments', 'Gifts'),
    _WizardStepMeta(_WizardStepId.fees, 'Fees', 'Fees'),
  ];

  static const List<_WizardStepMeta> _onlineAfterTypeSteps = [
    _WizardStepMeta(_WizardStepId.gender, 'Gender', 'Gender'),
    _WizardStepMeta(_WizardStepId.juries, 'Juries', 'Juries'),
    _WizardStepMeta(_WizardStepId.asanas, 'Asanas', 'Asanas'),
    _WizardStepMeta(_WizardStepId.bends, 'Bend Types', 'Bends'),
    _WizardStepMeta(_WizardStepId.prizes, 'Prizes', 'Prizes'),
    _WizardStepMeta(_WizardStepId.viva, 'Viva Voce', 'Viva'),
    _WizardStepMeta(_WizardStepId.gifts, 'Compliments', 'Gifts'),
    _WizardStepMeta(_WizardStepId.fees, 'Fees', 'Fees'),
  ];

  List<_WizardStepMeta> get _visibleSteps {
    if (!_config.isOnlineMode) return _offlineSteps;
    return [
      _WizardStepMeta(_WizardStepId.groups, 'Group Types', 'Groups'),
      _WizardStepMeta(
        _WizardStepId.submissionType,
        'Daily Count',
        'Count',
      ),
      if (_config.isVideoSubmission)
        _WizardStepMeta(_WizardStepId.scoring, 'Scoring', 'Scoring'),
      ..._onlineAfterTypeSteps,
    ];
  }

  int get _totalSteps => _visibleSteps.length;

  static const List<String> _defaultGenderOptions = [
    'Male',
    'Female',
    'Others',
  ];

  static const List<String> _defaultBendOptions = [
    'Forward Bend',
    'Backward Bend',
    'Hand Balance',
    'Leg Balance',
    'Twisting',
  ];

  static const List<String> _defaultStudyOptions = [
    'LKG',
    'UKG',
    'I',
    'II',
    'III',
    'IV',
    'V',
    'VI',
    'VII',
    'VIII',
    'IX',
    'X',
    'XI',
    'XII',
    'UG',
    'PG',
    'Diploma',
  ];

  static const List<String> _defaultAgeOptions = [
    'Below 5',
    '5-8',
    '9-12',
    '13-16',
    '18-25 Years',
    '26-35 Years',
    '36-40 Years',
    'Above 41 Years',
  ];

  static const List<String> _defaultLevelOptions = [
    'Level 1',
    'Level 2',
    'Level 3',
    'Level 4',
    'Level 5',
  ];

  static const List<String> _defaultComplimentOptions = [
    'e-Certificate',
    'Certificate',
    'Medal',
    'Trophy',
    'Memento',
  ];

  static const List<({String value, String label})> _scoringMethods = [
    (value: 'NONE', label: 'NONE'),
    (value: 'MARKS', label: 'Marks'),
    (value: 'GRADING', label: 'Grading'),
    (value: 'TIMED', label: 'Timed'),
    (value: 'TIMED_PLUS_SCORING', label: 'Timed + Scoring'),
  ];

  late CompetitionCategoryConfigModel _config;
  int _currentStep = 1;

  late List<String> _studyOptions;
  late List<String> _ageOptions;
  late List<String> _levelOptions;
  late List<String> _complimentOptions;
  late List<String> _genderOptions;

  late TextEditingController _feeController;
  late TextEditingController _spotFeeController;
  late TextEditingController _minTimeController;
  late TextEditingController _maxTimeController;
  late TextEditingController _stageCountController;
  late TextEditingController _durationDaysController;
  late TextEditingController _howManyTimesController;

  /// When false, Upgrade Top / Upgrade To Category stay hidden and cleared.
  late bool _upgradeEnabled;

  late List<CompetitionGradeEntry> _gradeEntries;
  late List<IncreaseCountRangeEntry> _increaseCountEntries;

  bool get _readOnly => widget.readOnly;
  bool get _isGradingScoring => _config.isGradingScoring;
  bool get _isSingleDayDuration => _config.durationDays == 1;

  String _numberedTitle(String label) => '$_currentStep. $label';

  int _stepNumberOf(_WizardStepId id) {
    final i = _visibleSteps.indexWhere((s) => s.id == id);
    return i >= 0 ? i + 1 : 0;
  }

  /// Online categories skip Stages / Allotment — keep a single implicit stage
  /// so scoring, juries, and group mapping still have a valid backend shape.
  void _applyImplicitOnlineStage() {
    if (!_config.isOnlineMode) return;
    _config.stageCount = 1;
    if (_config.stageNames.isEmpty) {
      _config.stageNaming = 'alphabet';
      _config.syncGeneratedStages();
    } else if (_config.stageNames.length != 1) {
      _config.stageNames = [_config.stageNames.first];
      _config.syncGeneratedStages(regenerateNames: false);
    } else {
      _config.syncGeneratedStages(regenerateNames: false);
    }
    final stage = _config.stageNames.first;
    _config.stageAllotment = {
      stage: List<String>.from(_config.selectedGroups),
    };
  }

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig.clone();

    // New / not-yet-saved categories must start from defaults — never inherit
    // leftover groups/stages/fees from a previously configured category.
    if (!_config.configured) {
      _config.resetWizardFieldsToDefaults();
    }

    if (!_config.isOnlineMode) {
      if (_config.stageNames.isEmpty) {
        _config.syncGeneratedStages();
      } else {
        _config.syncGeneratedStages(regenerateNames: false);
      }
    }

    _initGroupOptionLists();
    _ensureSelectedGroupsSeeded();
    _refreshGroupTypeFromSelection();
    if (_config.isOnlineMode) {
      _applyImplicitOnlineStage();
      // Temporarily Count-only: hide Video and default Count as selected.
      if (!_config.isCountSubmission) {
        _config.submissionType = 'COUNT';
        _config.scoringMethod = 'NONE';
      }
    }

    _complimentOptions = _mergeOptions(
      _defaultComplimentOptions,
      [..._config.topCompliments, ..._config.nonTopCompliments],
    );
    _genderOptions = _mergeOptions(
      _defaultGenderOptions,
      CompetitionCategoryConfigModel.normalizeGenderLabels(
        _config.selectedGenders,
      ),
    );
    _config.selectedGenders =
        CompetitionCategoryConfigModel.normalizeGenderLabels(
      _config.selectedGenders.isEmpty
          ? _defaultGenderOptions
          : _config.selectedGenders,
    );
    _config.prizeTopsByGender =
        CompetitionCategoryConfigModel.normalizePrizeTopKeys(
      _config.prizeTopsByGender,
    );
    for (final g in _config.selectedGenders) {
      _config.prizeTopsByGender.putIfAbsent(g, () => _config.prizeTopFor(g));
    }

    final hasUpgradeTarget =
        (_config.upgradeToCategoryName?.trim().isNotEmpty ?? false) ||
            _config.upgradeToCategoryId != null;
    _upgradeEnabled = _config.upgradeTop != null || hasUpgradeTarget;

    _gradeEntries = _config.grades.isEmpty
        ? [CompetitionGradeEntry()]
        : _config.grades.map(CompetitionGradeEntry.fromModel).toList();
    _increaseCountEntries = _config.increaseCountRanges.isEmpty
        ? (_config.increaseCountEnabled
            ? [IncreaseCountRangeEntry()]
            : <IncreaseCountRangeEntry>[])
        : _config.increaseCountRanges
            .map(IncreaseCountRangeEntry.fromModel)
            .toList();

    _feeController = TextEditingController(
      text: _config.feeAmount == 0
          ? '0'
          : _config.feeAmount.toStringAsFixed(
              _config.feeAmount.truncateToDouble() == _config.feeAmount
                  ? 0
                  : 2,
            ),
    );
    final initialSpot =
        _config.spotFeeAmount > 0 ? _config.spotFeeAmount : _config.feeAmount;
    _spotFeeController = TextEditingController(
      text: initialSpot == 0
          ? '0'
          : initialSpot.toStringAsFixed(
              initialSpot.truncateToDouble() == initialSpot ? 0 : 2,
            ),
    );
    _minTimeController =
        TextEditingController(text: _config.minTime ?? '01:00');
    _maxTimeController =
        TextEditingController(text: _config.maxTime ?? '03:00');
    _stageCountController =
        TextEditingController(text: '${_config.stageCount.clamp(1, 26)}');
    _durationDaysController = TextEditingController(
      text: _config.durationDays == null ? '' : '${_config.durationDays}',
    );
    _howManyTimesController = TextEditingController(
      text: _config.howManyTimes == null ? '' : '${_config.howManyTimes}',
    );
  }

  @override
  void dispose() {
    _feeController.dispose();
    _spotFeeController.dispose();
    _minTimeController.dispose();
    _maxTimeController.dispose();
    _stageCountController.dispose();
    _durationDaysController.dispose();
    _howManyTimesController.dispose();
    for (final entry in _gradeEntries) {
      entry.dispose();
    }
    for (final entry in _increaseCountEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  List<String> _mergeOptions(List<String> defaults, List<String> extras) {
    final result = List<String>.from(defaults);
    for (final e in extras) {
      if (e.trim().isEmpty) continue;
      if (!result.contains(e)) result.add(e);
    }
    return result;
  }

  bool _isAgeGroupLabel(String raw) {
    final g = raw.trim();
    if (g.isEmpty) return false;
    if (_defaultAgeOptions.contains(g)) return true;
    final s = g.toLowerCase();
    if (s.contains('year') || s.contains('yrs') || s.contains(' age')) {
      return true;
    }
    if (RegExp(r'\d+\s*[-–to]+\s*\d+').hasMatch(s)) return true;
    if (RegExp(r'^(below|above|under|over)\s*\d+').hasMatch(s)) return true;
    return false;
  }

  bool _isLevelGroupLabel(String raw) {
    final g = raw.trim();
    if (g.isEmpty) return false;
    if (_defaultLevelOptions.contains(g)) return true;
    return g.toLowerCase().startsWith('level');
  }

  String _classifyGroupLabel(String g) {
    if (_isLevelGroupLabel(g)) return 'LEVEL';
    if (_isAgeGroupLabel(g)) return 'AGE';
    return 'STUDY';
  }

  List<String> _defaultSelectedForGroupType(String groupType) {
    switch (groupType.toUpperCase()) {
      case 'AGE':
        return <String>['18-25 Years', '26-35 Years', '36-40 Years'];
      case 'LEVEL':
        return <String>['Level 1', 'Level 2'];
      case 'MIXED':
        return <String>['LKG', 'UKG', 'I', 'II', 'III', 'IV', 'V'];
      default:
        return <String>['LKG', 'UKG', 'I', 'II', 'III', 'IV', 'V'];
    }
  }

  void _initGroupOptionLists() {
    _studyOptions = List<String>.from(_defaultStudyOptions);
    _ageOptions = List<String>.from(_defaultAgeOptions);
    _levelOptions = List<String>.from(_defaultLevelOptions);

    for (final g in _config.selectedGroups) {
      _addCustomToMatchingOptionList(g);
    }
  }

  void _addCustomToMatchingOptionList(String raw) {
    final g = raw.trim();
    if (g.isEmpty) return;
    switch (_classifyGroupLabel(g)) {
      case 'AGE':
        if (!_ageOptions.contains(g)) {
          _ageOptions = [..._ageOptions, g];
        }
        break;
      case 'LEVEL':
        if (!_levelOptions.contains(g)) {
          _levelOptions = [..._levelOptions, g];
        }
        break;
      default:
        if (!_studyOptions.contains(g)) {
          _studyOptions = [..._studyOptions, g];
        }
    }
  }

  /// Keep all selected Study + Age + Level groups; seed study defaults if empty.
  void _ensureSelectedGroupsSeeded() {
    if (_config.selectedGroups.isEmpty) {
      final seeded = _defaultSelectedForGroupType('STUDY');
      for (final g in seeded) {
        _addCustomToMatchingOptionList(g);
      }
      _config.selectedGroups = List<String>.from(seeded);
    }
  }

  void _refreshGroupTypeFromSelection() {
    final hasStudy = _config.selectedGroups.any((g) => _classifyGroupLabel(g) == 'STUDY');
    final hasAge = _config.selectedGroups.any((g) => _classifyGroupLabel(g) == 'AGE');
    final hasLevel =
        _config.selectedGroups.any((g) => _classifyGroupLabel(g) == 'LEVEL');
    final kinds = [hasStudy, hasAge, hasLevel].where((e) => e).length;
    if (kinds > 1) {
      _config.groupType = 'MIXED';
    } else if (hasAge) {
      _config.groupType = 'AGE';
    } else if (hasLevel) {
      _config.groupType = 'LEVEL';
    } else {
      _config.groupType = 'STUDY';
    }
  }

  void _toggleGroupSelection(String opt, bool selected) {
    if (selected) {
      if (!_config.selectedGroups.contains(opt)) {
        _config.selectedGroups = [..._config.selectedGroups, opt];
      }
    } else {
      _config.selectedGroups =
          _config.selectedGroups.where((e) => e != opt).toList();
      for (final key in _config.stageAllotment.keys.toList()) {
        _config.stageAllotment[key] = _config.stageAllotment[key]!
            .where((g) => g != opt)
            .toList();
      }
    }
    _refreshGroupTypeFromSelection();
  }

  void _setSectionGroupsSelected(List<String> options, bool selected) {
    for (final opt in options) {
      _toggleGroupSelection(opt, selected);
    }
  }

  Future<void> _addCustomGroupChip(String section) async {
    final custom = await _promptText(
      title: section == 'AGE'
          ? 'Add age range'
          : section == 'LEVEL'
              ? 'Add level'
              : 'Add study group',
      hint: section == 'AGE'
          ? 'e.g. 40-50 Years'
          : section == 'LEVEL'
              ? 'e.g. Level 6'
              : 'e.g. Nursery',
    );
    if (custom == null) return;
    final label = custom.trim();
    if (label.isEmpty) return;
    setState(() {
      switch (section) {
        case 'AGE':
          if (!_ageOptions.contains(label)) {
            _ageOptions = [..._ageOptions, label];
          }
          break;
        case 'LEVEL':
          if (!_levelOptions.contains(label)) {
            _levelOptions = [..._levelOptions, label];
          }
          break;
        default:
          if (!_studyOptions.contains(label)) {
            _studyOptions = [..._studyOptions, label];
          }
      }
      _toggleGroupSelection(label, true);
    });
  }

  Future<void> _editGroupChip(String section, String current) async {
    final edited = await _promptText(
      title: 'Edit group',
      hint: 'Group name',
      initial: current,
    );
    if (edited == null) return;
    final next = edited.trim();
    if (next.isEmpty || next == current) return;

    setState(() {
      List<String> replaceIn(List<String> list) =>
          list.map((e) => e == current ? next : e).toList();

      switch (section) {
        case 'AGE':
          if (_ageOptions.contains(next) && next != current) {
            // Merge into existing label: drop old, keep next selected.
            _ageOptions = _ageOptions.where((e) => e != current).toList();
          } else {
            _ageOptions = replaceIn(_ageOptions);
          }
          break;
        case 'LEVEL':
          if (_levelOptions.contains(next) && next != current) {
            _levelOptions = _levelOptions.where((e) => e != current).toList();
          } else {
            _levelOptions = replaceIn(_levelOptions);
          }
          break;
        default:
          if (_studyOptions.contains(next) && next != current) {
            _studyOptions = _studyOptions.where((e) => e != current).toList();
          } else {
            _studyOptions = replaceIn(_studyOptions);
          }
      }

      final wasSelected = _config.selectedGroups.contains(current);
      _config.selectedGroups = _config.selectedGroups
          .map((e) => e == current ? next : e)
          .toSet()
          .toList();
      if (wasSelected && !_config.selectedGroups.contains(next)) {
        _config.selectedGroups = [..._config.selectedGroups, next];
      }

      for (final key in _config.stageAllotment.keys.toList()) {
        _config.stageAllotment[key] = _config.stageAllotment[key]!
            .map((e) => e == current ? next : e)
            .toSet()
            .toList();
      }
      _refreshGroupTypeFromSelection();
    });
  }

  void _deleteGroupChip(String section, String label) {
    setState(() {
      switch (section) {
        case 'AGE':
          _ageOptions = _ageOptions.where((e) => e != label).toList();
          break;
        case 'LEVEL':
          _levelOptions = _levelOptions.where((e) => e != label).toList();
          break;
        default:
          _studyOptions = _studyOptions.where((e) => e != label).toList();
      }
      _toggleGroupSelection(label, false);
    });
  }

  List<String> get _activeGroupOptions {
    // Used by allotment / legacy helpers — all selected-capable options.
    return [..._studyOptions, ..._ageOptions, ..._levelOptions];
  }

  bool get _isTimedScoring => _config.showsTimeLimits;
  bool get _showsMarksLimits => _config.showsMarksLimits;

  void _goToStep(int step) {
    if (step < 1 || step > _totalSteps) return;
    setState(() => _currentStep = step);
  }

  void _previous() {
    if (_currentStep > 1) _goToStep(_currentStep - 1);
  }

  void _next() {
    if (_currentStep >= _totalSteps) return;
    final current = _visibleSteps[_currentStep - 1];
    if (current.id == _WizardStepId.submissionType &&
        !_config.hasSubmissionType) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select Count to continue.')),
      );
      return;
    }
    _goToStep(_currentStep + 1);
  }

  void _cancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  bool _saving = false;

  void _save() {
    if (_readOnly) {
      _cancel();
      return;
    }
    if (_saving) return;
    _saveAsync();
  }

  Future<void> _saveAsync() async {
    if (_config.isOnlineMode && !_config.hasSubmissionType) {
      final typeIndex = _visibleSteps.indexWhere(
        (s) => s.id == _WizardStepId.submissionType,
      );
      if (typeIndex >= 0) _goToStep(typeIndex + 1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select Count to continue.')),
        );
      }
      return;
    }
    if (!_upgradeEnabled) {
      _config.upgradeTop = null;
      _config.upgradeToCategoryId = null;
      _config.upgradeToCategoryName = null;
    }
    if (_config.isOnlineMode && _config.isCountSubmission) {
      _config.scoringMethod = 'NONE';
    }
    _config.grades = _gradeEntries
        .map((e) => e.toModel())
        .whereType<CompetitionGradeModel>()
        .toList();
    if (_config.isAsanas) {
      _config.durationDays = null;
      _config.howManyTimes = null;
      _config.increaseCountEnabled = false;
      _config.increaseCountRanges = <IncreaseCountRangeModel>[];
    } else {
      _config.durationDays = int.tryParse(_durationDaysController.text.trim());
      if (_config.durationDays == 1) {
        _config.howManyTimes =
            int.tryParse(_howManyTimesController.text.trim());
        _config.increaseCountEnabled = false;
        _config.increaseCountRanges = <IncreaseCountRangeModel>[];
      } else {
        _config.howManyTimes = null;
        _config.increaseCountRanges = _config.increaseCountEnabled
            ? _increaseCountEntries
                .map((e) => e.toModel())
                .whereType<IncreaseCountRangeModel>()
                .toList()
            : <IncreaseCountRangeModel>[];
      }
    }
    _config.minTime = _minTimeController.text.trim().isEmpty
        ? null
        : _minTimeController.text.trim();
    _config.maxTime = _maxTimeController.text.trim().isEmpty
        ? null
        : _maxTimeController.text.trim();
    _config.feeAmount =
        double.tryParse(_feeController.text.trim()) ?? _config.feeAmount;
    if (_config.isOnlineMode) {
      _config.spotFeeAmount = _config.feeAmount;
    } else {
      _config.spotFeeAmount =
          double.tryParse(_spotFeeController.text.trim()) ??
              (_config.spotFeeAmount > 0
                  ? _config.spotFeeAmount
                  : _config.feeAmount);
    }
    _config.configured = true;
    _refreshGroupTypeFromSelection();
    if (_config.isOnlineMode) {
      _applyImplicitOnlineStage();
    } else {
      _config.syncGeneratedStages(regenerateNames: false);
    }
    _config.summary = _config.displaySummary;

    final controller = widget.competitionController ??
        (Get.isRegistered<CompetitionController>()
            ? Get.find<CompetitionController>()
            : null);

    if (controller == null) {
      widget.onSaved(_config);
      return;
    }

    setState(() => _saving = true);
    try {
      final persisted = await controller.persistCategoryConfigDraft(
        _config,
        showFeedback: true,
      );
      if (!mounted) return;
      if (persisted == null) return;
      widget.onSaved(persisted);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<String?> _promptText({
    required String title,
    String? hint,
    String initial = '',
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _PromptTextDialog(
        title: title,
        hint: hint,
        initial: initial,
      ),
    );
    if (result == null || result.isEmpty) return null;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor;
    final stepMeta = _visibleSteps[_currentStep - 1];
    final progress = _currentStep / _totalSteps;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 920,
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: Column(
          children: [
            _buildHeader(primary, stepMeta, progress),
            Expanded(
              child: ColoredBox(
                color: Colors.grey.shade50,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildStepBody(primary),
                ),
              ),
            ),
            _buildFooter(primary),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    Color primary,
    _WizardStepMeta stepMeta,
    double progress,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _badge(
                          'Full Config',
                          bg: primary.withValues(alpha: 0.12),
                          fg: primary,
                          border: primary.withValues(alpha: 0.35),
                        ),
                        _badge(
                          _config.modeLabel,
                          bg: _config.isOnlineMode
                              ? const Color(0xFF0369A1).withValues(alpha: 0.12)
                              : const Color(0xFF0F766E).withValues(alpha: 0.12),
                          fg: _config.isOnlineMode
                              ? const Color(0xFF0369A1)
                              : const Color(0xFF0F766E),
                          border: (_config.isOnlineMode
                                  ? const Color(0xFF0369A1)
                                  : const Color(0xFF0F766E))
                              .withValues(alpha: 0.35),
                        ),
                        _badge(
                          'Step $_currentStep of $_totalSteps',
                          bg: Colors.white,
                          fg: primary,
                          border: primary.withValues(alpha: 0.25),
                        ),
                        if (_readOnly)
                          _badge(
                            'Read only',
                            bg: Colors.amber.shade50,
                            fg: Colors.amber.shade900,
                            border: Colors.amber.shade200,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                        children: [
                          TextSpan(
                            text: _config.isChallenge
                                ? 'Challenge Config — '
                                : 'Asanas Config — ',
                          ),
                          TextSpan(
                            text: _config.categoryName,
                            style: TextStyle(color: primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stepMeta.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: _cancel,
                icon: const Icon(Icons.close, size: 20),
                style: IconButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              color: primary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < _visibleSteps.length; i++)
                _buildStepChip(
                  primary: primary,
                  label: _visibleSteps[i].short,
                  display: i + 1,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepChip({
    required Color primary,
    required String label,
    required int display,
  }) {
    final active = display == _currentStep;
    final done = display < _currentStep;
    return InkWell(
      onTap: () => _goToStep(display),
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? primary
              : done
                  ? primary.withValues(alpha: 0.08)
                  : Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: active || done
                ? primary.withValues(alpha: active ? 1 : 0.35)
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          '$display. $label',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: active
                ? Colors.white
                : done
                    ? primary
                    : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _badge(
    String text, {
    required Color bg,
    required Color fg,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildFooter(Color primary) {
    final status = Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        children: [
          const TextSpan(text: 'Configuring: '),
          TextSpan(
            text: _config.categoryName,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: primary,
            ),
          ),
          TextSpan(
            text: '  ·  Step $_currentStep of $_totalSteps',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
    final buttons = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _cancel,
          child: const Text('Cancel'),
        ),
        if (_currentStep > 1)
          OutlinedButton.icon(
            onPressed: _previous,
            icon: const Icon(Icons.chevron_left, size: 18),
            label: const Text('Previous'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: BorderSide(color: primary.withValues(alpha: 0.4)),
              backgroundColor: primary.withValues(alpha: 0.06),
            ),
          ),
        if (_currentStep < _totalSteps)
          FilledButton.icon(
            onPressed: _next,
            icon: const Icon(Icons.chevron_right, size: 18),
            label: const Text('Next'),
            style: FilledButton.styleFrom(backgroundColor: primary),
          )
        else
          FilledButton.icon(
            onPressed: (_readOnly || _saving)
                ? (_readOnly ? _cancel : null)
                : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(_readOnly ? Icons.close : Icons.check, size: 18),
            label: Text(
              _readOnly
                  ? 'Close'
                  : (_saving ? 'Saving...' : 'Save Configuration'),
            ),
            style: FilledButton.styleFrom(backgroundColor: primary),
          ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 640;
          if (wide) {
            return Row(
              children: [
                Expanded(child: status),
                const SizedBox(width: 12),
                buttons,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              status,
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: buttons,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stepCard({
    required Color primary,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStepBody(Color primary) {
    switch (_visibleSteps[_currentStep - 1].id) {
      case _WizardStepId.stages:
        return _buildStagesStep(primary);
      case _WizardStepId.groups:
        return _buildGroupTypesStep(primary);
      case _WizardStepId.allot:
        return _buildStageAllotmentStep(primary);
      case _WizardStepId.submissionType:
        return _buildSubmissionTypeStep(primary);
      case _WizardStepId.scoring:
        return _buildScoringStep(primary);
      case _WizardStepId.gender:
        return _buildGenderStep(primary);
      case _WizardStepId.juries:
        return _buildJuriesStep(primary);
      case _WizardStepId.asanas:
        return _buildAsanasStep(primary);
      case _WizardStepId.bends:
        return _buildBendTypesStep(primary);
      case _WizardStepId.prizes:
        return _buildPrizesStep(primary);
      case _WizardStepId.viva:
        return _buildVivaStep(primary);
      case _WizardStepId.gifts:
        return _buildComplimentsStep(primary);
      case _WizardStepId.fees:
        return _buildFeesStep(primary);
    }
  }

  // ─── Step 1: Stages ───────────────────────────────────────────────────────

  Widget _buildStagesStep(Color primary) {
    _config.syncGeneratedStages(regenerateNames: false);
    return _stepCard(
      primary: primary,
      title: _numberedTitle('STAGES CONFIGURATION'),
      icon: Icons.grid_view_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 480;
              final naming = _namingSegment(primary);
              final count = _labeledField(
                label: 'How many stages?',
                child: TextFormField(
                  controller: _stageCountController,
                  enabled: !_readOnly,
                  decoration: _compactDecoration(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) {
                    if (_readOnly) return;
                    final n = int.tryParse(v) ?? 1;
                    setState(() {
                      _config.stageCount = n.clamp(1, 26);
                      // Keep custom names; only add/remove slots.
                      _config.syncGeneratedStages(regenerateNames: false);
                    });
                  },
                ),
              );
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: naming),
                    const SizedBox(width: 16),
                    Expanded(child: count),
                  ],
                );
              }
              return Column(
                children: [
                  naming,
                  const SizedBox(height: 12),
                  count,
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.grey.shade100),
          const SizedBox(height: 8),
          Text(
            _readOnly
                ? 'STAGE CHIPS PREVIEW:'
                : 'STAGE CHIPS (TAP EDIT TO RENAME):',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade500,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _config.stageNames.length; i++)
                _buildEditableStageChip(
                  primary: primary,
                  index: i,
                  name: _config.stageNames[i],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableStageChip({
    required Color primary,
    required int index,
    required String name,
  }) {
    return Material(
      color: primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _readOnly ? null : () => _editStageName(index, name),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.only(
            left: 12,
            right: _readOnly ? 12 : 6,
            top: 6,
            bottom: 6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
              if (!_readOnly) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Edit name',
                  child: InkWell(
                    onTap: () => _editStageName(index, name),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editStageName(int index, String current) async {
    final edited = await _promptText(
      title: 'Edit stage name',
      hint: 'e.g. Zone 1, Arena A, Final Round',
      initial: current,
    );
    if (edited == null) return;
    final next = edited.trim();
    if (next.isEmpty || next == current) return;

    final ok = _config.renameStageAt(index, next);
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stage name must be unique and non-empty'),
        ),
      );
      return;
    }
    setState(() {});
  }

  Widget _namingSegment(Color primary) {
    return _labeledField(
      label: 'Naming Format',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            _segmentBtn('alphabet', 'A–Z', primary),
            _segmentBtn('stages', 'Stages', primary),
            _segmentBtn('other', 'Other', primary),
          ],
        ),
      ),
    );
  }

  Widget _segmentBtn(String value, String label, Color primary) {
    final selected = _config.stageNaming == value;
    return Expanded(
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        elevation: selected ? 1 : 0,
        child: InkWell(
          onTap: _readOnly
              ? null
              : () {
                  setState(() {
                    _config.stageNaming = value;
                    _config.syncGeneratedStages();
                  });
                },
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? primary : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Step 2: Group Types ──────────────────────────────────────────────────

  Widget _buildGroupTypesStep(Color primary) {
    return _stepCard(
      primary: primary,
      title: _numberedTitle('SELECT GROUPS'),
      icon: Icons.groups_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGroupSection(
            primary: primary,
            sectionKey: 'STUDY',
            title: 'Study Groups',
            subtitle: 'School / college classes',
            icon: Icons.school_outlined,
            options: _studyOptions,
          ),
          const SizedBox(height: 14),
          _buildGroupSection(
            primary: primary,
            sectionKey: 'AGE',
            title: 'Age Groups',
            subtitle: 'Age ranges (can combine with Study)',
            icon: Icons.cake_outlined,
            options: _ageOptions,
          ),
          const SizedBox(height: 14),
          _buildGroupSection(
            primary: primary,
            sectionKey: 'LEVEL',
            title: 'Level Groups',
            subtitle: 'Difficulty levels (optional)',
            icon: Icons.stairs_outlined,
            options: _levelOptions,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSection({
    required Color primary,
    required String sectionKey,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> options,
  }) {
    final selectedInSection =
        options.where(_config.selectedGroups.contains).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: primary),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: selectedInSection > 0
                      ? primary.withValues(alpha: 0.12)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$selectedInSection selected',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: selectedInSection > 0
                        ? primary
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          if (!_readOnly) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                _groupSelectAction(
                  label: 'Select all',
                  enabled: options.isNotEmpty &&
                      selectedInSection < options.length,
                  onTap: () => setState(
                    () => _setSectionGroupsSelected(options, true),
                  ),
                ),
                _groupSelectAction(
                  label: 'Deselect',
                  enabled: selectedInSection > 0,
                  onTap: () => setState(
                    () => _setSectionGroupsSelected(options, false),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...options.map((opt) {
                final sel = _config.selectedGroups.contains(opt);
                return _HoverEditableGroupChip(
                  label: opt,
                  selected: sel,
                  primary: primary,
                  readOnly: _readOnly,
                  onToggle: (v) => setState(() => _toggleGroupSelection(opt, v)),
                  onEdit: () => _editGroupChip(sectionKey, opt),
                  onDelete: () => _deleteGroupChip(sectionKey, opt),
                );
              }),
              if (!_readOnly)
                ActionChip(
                  avatar: Icon(Icons.add, size: 14, color: primary),
                  label: Text(
                    'Add',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                  backgroundColor: primary.withValues(alpha: 0.06),
                  side: BorderSide(
                    color: primary.withValues(alpha: 0.35),
                  ),
                  onPressed: () => _addCustomGroupChip(sectionKey),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _groupSelectAction({
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return TextButton(
      onPressed: enabled ? onTap : null,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: AppTheme.primaryColor,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  // ─── Step 3: Stage Allotment ──────────────────────────────────────────────

  Widget _buildStageAllotmentStep(Color primary) {
    _config.syncGeneratedStages(regenerateNames: false);
    final stages = _config.stageNames;
    final groups = _config.selectedGroups;

    /// Groups already mapped to any other stage (exclusive allotment).
    Set<String> groupsUsedElsewhere(String currentStage) {
      final used = <String>{};
      for (final entry in _config.stageAllotment.entries) {
        if (entry.key == currentStage) continue;
        used.addAll(entry.value);
      }
      return used;
    }

    return _stepCard(
      primary: primary,
      title: _numberedTitle('ALLOT STAGES & MAPPED GROUPS'),
      icon: Icons.merge_type_rounded,
      child: groups.isEmpty
          ? Text(
              'Select at least one group in Step ${_stepNumberOf(_WizardStepId.groups)} first.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth >= 560 ? 2 : 1;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: stages.map((stage) {
                    final allotted =
                        List<String>.from(_config.stageAllotment[stage] ?? []);
                    final usedElsewhere = groupsUsedElsewhere(stage);
                    // Study first, then Age, then Level — matches brochure style.
                    final orderedGroups = [
                      ...groups.where((g) => _classifyGroupLabel(g) == 'STUDY'),
                      ...groups.where((g) => _classifyGroupLabel(g) == 'AGE'),
                      ...groups.where((g) => _classifyGroupLabel(g) == 'LEVEL'),
                    ];
                    final visibleGroups = orderedGroups
                        .where(
                          (g) =>
                              allotted.contains(g) || !usedElsewhere.contains(g),
                        )
                        .toList();
                    return SizedBox(
                      width: cols == 2
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    stage.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: primary,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Mapped Groups',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (visibleGroups.isEmpty)
                              Text(
                                'All groups are mapped to other stages.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              )
                            else
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: visibleGroups.map((g) {
                                  final sel = allotted.contains(g);
                                  return FilterChip(
                                    label: Text(
                                      g,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: sel
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                    selected: sel,
                                    showCheckmark: false,
                                    selectedColor: primary,
                                    backgroundColor: Colors.white,
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    side: BorderSide(
                                      color: sel
                                          ? primary
                                          : Colors.grey.shade300,
                                    ),
                                    onSelected: _readOnly
                                        ? null
                                        : (v) {
                                            setState(() {
                                              final next = List<String>.from(
                                                _config.stageAllotment[stage] ??
                                                    const [],
                                              );
                                              if (v) {
                                                if (!next.contains(g)) {
                                                  next.add(g);
                                                }
                                              } else {
                                                next.remove(g);
                                              }
                                              _config.stageAllotment[stage] =
                                                  next;
                                            });
                                          },
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }

  // ─── Step: Select Type (online) ───────────────────────────────────────────

  Widget _buildSubmissionTypeStep(Color primary) {
    return _stepCard(
      primary: primary,
      title: _numberedTitle('PARTICIPANT SUBMISSION'),
      icon: Icons.numbers_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Participants submit a daily count for this online challenge.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primary.withValues(alpha: 0.22)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.numbers_rounded, color: primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Daily Count',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: primary,
                              ),
                            ),
                          ),
                          _badge(
                            'Active',
                            bg: primary.withValues(alpha: 0.14),
                            fg: primary,
                            border: primary.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Participants enter their count each day. Jury scoring is not used.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...[
            'Participants log count during the challenge period',
            'Daily entries are tracked automatically',
            'No video upload or jury scoring required',
          ].map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 4: Scoring Method & Limits ──────────────────────────────────────

  Widget _buildScoringStep(Color primary) {
    final otherNames = widget.otherCategoryNames
        .where((e) => e.trim().isNotEmpty)
        .map((e) => e.trim().toUpperCase())
        .where((e) => e != _config.categoryName.toUpperCase())
        .toSet()
        .toList()
      ..sort();

    final currentUpgrade = _config.upgradeToCategoryName?.trim().toUpperCase();
    final upgradeItems = <String?>[null, ...otherNames];
    if (currentUpgrade != null &&
        currentUpgrade.isNotEmpty &&
        !otherNames.contains(currentUpgrade)) {
      upgradeItems.add(currentUpgrade);
    }

    var scoringValue = _config.scoringMethod.toUpperCase();
    if (scoringValue.contains('TIMED') && scoringValue.contains('SCORING')) {
      scoringValue = 'TIMED_PLUS_SCORING';
    }
    if (!_scoringMethods.any((m) => m.value == scoringValue)) {
      scoringValue = 'MARKS';
    }

    return _stepCard(
      primary: primary,
      title: _numberedTitle('SCORING METHOD & LIMITS'),
      icon: Icons.track_changes_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main fields — Scoring + Participants (+ Upgrade when enabled)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _labeledField(
                  label: 'Scoring Method',
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('scoring-$scoringValue'),
                    initialValue: scoringValue,
                    isExpanded: true,
                    decoration: _compactDecoration(),
                    items: _scoringMethods
                        .map(
                          (m) => DropdownMenuItem(
                            value: m.value,
                            child: Text(
                              m.label,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _readOnly
                        ? null
                        : (v) {
                            if (v == null) return;
                            setState(() => _config.scoringMethod = v);
                          },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _intDropdown(
                  label: 'Participants / Stage',
                  value: _config.participantsPerStage ?? 5,
                  items: List.generate(10, (i) => i + 1),
                  onChanged: (v) => setState(
                    () => _config.participantsPerStage = v,
                  ),
                ),
              ),
              if (_upgradeEnabled) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _intDropdown(
                    label: 'Upgrade Top',
                    value: (_config.upgradeTop ?? 3).clamp(1, 10),
                    items: List.generate(10, (i) => i + 1),
                    onChanged: (v) => setState(() => _config.upgradeTop = v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _labeledField(
                    label: 'Upgrade To Category',
                    child: DropdownButtonFormField<String?>(
                      // Use `value` (controlled) — `initialValue` only applies on
                      // first mount, so changing selection never updated the UI.
                      value: currentUpgrade != null &&
                              currentUpgrade.isNotEmpty &&
                              upgradeItems.contains(currentUpgrade)
                          ? currentUpgrade
                          : null,
                      isExpanded: true,
                      decoration: _compactDecoration(),
                      items: upgradeItems
                          .map(
                            (name) => DropdownMenuItem<String?>(
                              value: name,
                              child: Text(
                                name ?? '— None —',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _readOnly
                          ? null
                          : (v) {
                              setState(() {
                                _config.upgradeToCategoryName = v;
                                // Always clear id when target changes so a stale
                                // id cannot keep pointing at the previous category.
                                _config.upgradeToCategoryId = null;
                              });
                            },
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Checkbox(
                value: _upgradeEnabled,
                onChanged: _readOnly
                    ? null
                    : (v) {
                        final enabled = v ?? false;
                        setState(() {
                          _upgradeEnabled = enabled;
                          if (enabled) {
                            _config.upgradeTop ??= 3;
                          } else {
                            _config.upgradeTop = null;
                            _config.upgradeToCategoryId = null;
                            _config.upgradeToCategoryName = null;
                          }
                        });
                      },
                activeColor: primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const Text(
                'Enable Upgrade',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 16),
              Checkbox(
                value: _config.tieBreakerEnabled,
                onChanged: _readOnly
                    ? null
                    : (v) {
                        setState(() {
                          _config.tieBreakerEnabled = v ?? false;
                        });
                      },
                activeColor: primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const Text(
                'Enable Tie Breaker',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (_showsMarksLimits) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _intDropdown(
                    label: 'Min Marks',
                    value: _config.minimumMarks ?? 1,
                    items: const [1, 2, 3, 4, 5, 10, 20],
                    onChanged: (v) =>
                        setState(() => _config.minimumMarks = v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _intDropdown(
                    label: 'Max Marks',
                    value: _config.maximumMarks ?? 10,
                    items: const [10, 20, 50, 100],
                    onChanged: (v) =>
                        setState(() => _config.maximumMarks = v),
                  ),
                ),
              ],
            ),
          ],
          if (_isTimedScoring) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _timePickerField(
                    label: 'Min Time',
                    value: _parseHhMm(_config.minTime ?? _minTimeController.text),
                    onPicked: (t) {
                      final formatted = _formatHhMm(t);
                      setState(() {
                        _config.minTime = formatted;
                        _minTimeController.text = formatted;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _timePickerField(
                    label: 'Max Time',
                    value: _parseHhMm(_config.maxTime ?? _maxTimeController.text),
                    onPicked: (t) {
                      final formatted = _formatHhMm(t);
                      setState(() {
                        _config.maxTime = formatted;
                        _maxTimeController.text = formatted;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade100),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 10,
            children: [
              FilterChip(
                label: const Text(
                  'Enable Skipped Asana',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                selected: _config.skippedAsanaEnabled,
                selectedColor: primary.withValues(alpha: 0.15),
                checkmarkColor: primary,
                onSelected: _readOnly
                    ? null
                    : (v) => setState(() => _config.skippedAsanaEnabled = v),
              ),
              if (_config.skippedAsanaEnabled) ...[
                SizedBox(
                  width: 140,
                  child: _intDropdown(
                    label: 'Skipped Count',
                    value: _config.skippedAsanaCount.clamp(1, 10),
                    items: List.generate(10, (i) => i + 1),
                    onChanged: (v) =>
                        setState(() => _config.skippedAsanaCount = v),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: _intDropdown(
                    label: 'Skipped Marks',
                    value: _config.skippedAsanaMarks,
                    items: const [0, 1, 2, 3, 4, 5, 10],
                    onChanged: (v) =>
                        setState(() => _config.skippedAsanaMarks = v),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  TimeOfDay _parseHhMm(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const TimeOfDay(hour: 1, minute: 0);
    }
    final parts = raw.trim().split(':');
    if (parts.length < 2) return const TimeOfDay(hour: 1, minute: 0);
    final h = int.tryParse(parts[0]) ?? 1;
    final m = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  String _formatHhMm(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatHhMmAmPm(TimeOfDay time) {
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final h = hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  Widget _timePickerField({
    required String label,
    required TimeOfDay value,
    required ValueChanged<TimeOfDay> onPicked,
  }) {
    final display = _formatHhMmAmPm(value);
    return _labeledField(
      label: label,
      child: InkWell(
        onTap: _readOnly
            ? null
            : () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: value,
                  builder: (context, child) {
                    return MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(alwaysUse24HourFormat: false),
                      child: child ?? const SizedBox.shrink(),
                    );
                  },
                );
                if (picked != null) onPicked(picked);
              },
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          decoration: _compactDecoration(
            hint: 'hh:mm AM/PM',
            suffixIcon: Icon(
              Icons.access_time,
              size: 18,
              color: AppTheme.primaryColor,
            ),
          ),
          child: Text(
            display,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Step 5: Gender ───────────────────────────────────────────────────────

  Widget _buildGenderStep(Color primary) {
    return _stepCard(
      primary: primary,
      title: _numberedTitle('GENDER SELECTION'),
      icon: Icons.people_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select genders that apply for this category. Prize tops will follow these selections.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._genderOptions.map((g) {
                final sel = _config.selectedGenders.contains(g);
                return FilterChip(
                  label: Text(
                    g,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                  selected: sel,
                  showCheckmark: false,
                  selectedColor: primary,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: sel ? primary : Colors.grey.shade300,
                  ),
                  onSelected: _readOnly
                      ? null
                      : (v) {
                          setState(() {
                            if (v) {
                              if (!_config.selectedGenders.contains(g)) {
                                _config.selectedGenders = [
                                  ..._config.selectedGenders,
                                  g,
                                ];
                              }
                              _config.prizeTopsByGender
                                  .putIfAbsent(g, () => 1);
                            } else {
                              _config.selectedGenders = _config.selectedGenders
                                  .where((e) => e != g)
                                  .toList();
                            }
                          });
                        },
                );
              }),
              if (!_readOnly)
                ActionChip(
                  avatar: Icon(Icons.add, size: 16, color: primary),
                  label: Text(
                    'Add',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                  backgroundColor: primary.withValues(alpha: 0.08),
                  side: BorderSide(color: primary.withValues(alpha: 0.35)),
                  onPressed: () async {
                    final added = await _promptText(
                      title: 'Add gender',
                      hint: 'e.g. Mixed, Open',
                    );
                    if (added == null) return;
                    final label = added
                        .split(' ')
                        .where((p) => p.isNotEmpty)
                        .map((p) =>
                            '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
                        .join(' ');
                    setState(() {
                      if (!_genderOptions.contains(label)) {
                        _genderOptions = [..._genderOptions, label];
                      }
                      if (!_config.selectedGenders.contains(label)) {
                        _config.selectedGenders = [
                          ..._config.selectedGenders,
                          label,
                        ];
                      }
                      _config.prizeTopsByGender.putIfAbsent(label, () => 1);
                    });
                  },
                ),
            ],
          ),
          if (_config.selectedGenders.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Select at least one gender.',
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Step 6: Juries ───────────────────────────────────────────────────────

  Widget _buildJuriesStep(Color primary) {
    return _stepCard(
      primary: primary,
      title: _numberedTitle('JURIES PER STAGE'),
      icon: Icons.verified_user_outlined,
      child: SizedBox(
        width: 280,
        child: _intDropdown(
          label: 'Juries per Stage',
          value: _config.juriesPerStage.clamp(1, 10),
          items: List.generate(10, (i) => i + 1),
          onChanged: (v) => setState(() => _config.juriesPerStage = v),
        ),
      ),
    );
  }

  // ─── Step 6: Asanas ───────────────────────────────────────────────────────

  Widget _buildAsanasStep(Color primary) {
    return _stepCard(
      primary: primary,
      title: _numberedTitle('ASANAS BREAKDOWN'),
      icon: Icons.list_alt_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 520;
              final fields = [
                _intDropdown(
                  label: 'Compulsory / From Chart',
                  value: _config.compulsoryAsanas.clamp(0, 10),
                  items: List.generate(11, (i) => i),
                  onChanged: (v) =>
                      setState(() => _config.compulsoryAsanas = v),
                ),
                _intDropdown(
                  label: 'Own Choice',
                  value: _config.ownChoiceAsanas.clamp(0, 10),
                  items: List.generate(11, (i) => i),
                  onChanged: (v) =>
                      setState(() => _config.ownChoiceAsanas = v),
                ),
                _intDropdown(
                  label: 'Each (Time in mins)',
                  value: _config.eachAsanaTimeMinutes.clamp(1, 10),
                  items: List.generate(10, (i) => i + 1),
                  itemLabel: (n) => '$n min',
                  onChanged: (v) =>
                      setState(() => _config.eachAsanaTimeMinutes = v),
                ),
              ];
              if (wide) {
                return Row(
                  children: fields
                      .map(
                        (f) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: f,
                          ),
                        ),
                      )
                      .toList(),
                );
              }
              return Column(
                children: fields
                    .map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: f,
                      ),
                    )
                    .toList(),
              );
            },
          ),
          if (_config.isChallenge) ...[
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 520;
                final daysField = _labeledField(
                  label: 'Duration (days)',
                  child: TextFormField(
                    controller: _durationDaysController,
                    enabled: !_readOnly,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _compactDecoration(hint: 'e.g. 40'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    onChanged: (v) {
                      setState(() {
                        _config.durationDays = int.tryParse(v.trim());
                        if (_config.durationDays == 1) {
                          _config.increaseCountEnabled = false;
                        }
                      });
                    },
                  ),
                );
                final timesField = _labeledField(
                  label: 'How many times',
                  child: TextFormField(
                    controller: _howManyTimesController,
                    enabled: !_readOnly,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _compactDecoration(hint: 'e.g. 50'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    onChanged: (v) {
                      setState(() {
                        _config.howManyTimes = int.tryParse(v.trim());
                      });
                    },
                  ),
                );
                final increaseCheckbox = Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _config.increaseCountEnabled,
                        onChanged: _readOnly
                            ? null
                            : (v) {
                                final enabled = v ?? false;
                                setState(() {
                                  _config.increaseCountEnabled = enabled;
                                  if (enabled &&
                                      _increaseCountEntries.isEmpty) {
                                    _increaseCountEntries.add(
                                      IncreaseCountRangeEntry(),
                                    );
                                  }
                                });
                              },
                        activeColor: primary,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Increase count',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tick this if the asana count should go up over the challenge days. '
                                'Then add day ranges with a count (e.g. days 1 to 40 = 50 times).',
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.35,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: daysField),
                      const SizedBox(width: 12),
                      if (_isSingleDayDuration)
                        Expanded(child: timesField)
                      else
                        Expanded(child: increaseCheckbox),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    daysField,
                    if (_isSingleDayDuration) ...[
                      const SizedBox(height: 12),
                      timesField,
                    ] else ...[
                      const SizedBox(height: 4),
                      increaseCheckbox,
                    ],
                  ],
                );
              },
            ),
            if (!_isSingleDayDuration && _config.increaseCountEnabled) ...[
              const SizedBox(height: 14),
              _buildIncreaseCountRanges(primary),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildIncreaseCountRanges(Color primary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add day ranges with a count. Example: 1 to 40 = 50 means days 1–40 are performed 50 times.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          ...List.generate(_increaseCountEntries.length, (index) {
            final entry = _increaseCountEntries[index];
            return Padding(
              key: ValueKey(entry.rowId),
              padding: EdgeInsets.only(
                bottom: index < _increaseCountEntries.length - 1 ? 10 : 0,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      child: TextFormField(
                        controller: entry.fromController,
                        enabled: !_readOnly,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _compactDecoration(hint: 'From'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        'to',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 72,
                      child: TextFormField(
                        controller: entry.toController,
                        enabled: !_readOnly,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _compactDecoration(hint: 'To'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '=',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        controller: entry.countController,
                        enabled: !_readOnly,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _compactDecoration(hint: 'Count'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (!_readOnly)
                      IconButton(
                        tooltip: 'Remove',
                        onPressed: () {
                          if (_increaseCountEntries.length <= 1) {
                            setState(() {
                              _increaseCountEntries[0].fromController.clear();
                              _increaseCountEntries[0].toController.clear();
                              _increaseCountEntries[0].countController.clear();
                            });
                            return;
                          }
                          final removed = _increaseCountEntries[index];
                          setState(() {
                            _increaseCountEntries.removeAt(index);
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            removed.dispose();
                          });
                        },
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade400,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
          if (!_readOnly) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _increaseCountEntries.add(IncreaseCountRangeEntry());
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add option'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Step 7: Bend Types ───────────────────────────────────────────────────

  Widget _buildBendTypesStep(Color primary) {
    final items = <({String label, bool value, ValueChanged<bool> onChanged})>[
      (
        label: 'Forward Bend',
        value: _config.bendForward,
        onChanged: (v) => setState(() => _config.bendForward = v),
      ),
      (
        label: 'Backward Bend',
        value: _config.bendBackward,
        onChanged: (v) => setState(() => _config.bendBackward = v),
      ),
      (
        label: 'Hand Balance',
        value: _config.bendHandBalance,
        onChanged: (v) => setState(() => _config.bendHandBalance = v),
      ),
      (
        label: 'Leg Balance',
        value: _config.bendLegBalance,
        onChanged: (v) => setState(() => _config.bendLegBalance = v),
      ),
      (
        label: 'Twisting',
        value: _config.bendTwisting,
        onChanged: (v) => setState(() => _config.bendTwisting = v),
      ),
    ];

    return _stepCard(
      primary: primary,
      title: _numberedTitle('BEND TYPES REQUIRED'),
      icon: Icons.check_box_outlined,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          ...items.map(
            (item) => FilterChip(
              label: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              selected: item.value,
              selectedColor: primary.withValues(alpha: 0.15),
              checkmarkColor: primary,
              backgroundColor: Colors.grey.shade50,
              side: BorderSide(color: Colors.grey.shade300),
              onSelected: _readOnly ? null : (v) => item.onChanged(v),
            ),
          ),
          ..._config.customBendTypes.map((label) {
            return FilterChip(
              label: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              selected: true,
              selectedColor: primary.withValues(alpha: 0.15),
              checkmarkColor: primary,
              backgroundColor: Colors.grey.shade50,
              side: BorderSide(color: Colors.grey.shade300),
              onSelected: _readOnly
                  ? null
                  : (_) {
                      setState(() {
                        _config.customBendTypes = _config.customBendTypes
                            .where((e) => e != label)
                            .toList();
                      });
                    },
            );
          }),
          if (!_readOnly)
            ActionChip(
              avatar: Icon(Icons.add, size: 16, color: primary),
              label: Text(
                'Add',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
              backgroundColor: primary.withValues(alpha: 0.08),
              side: BorderSide(color: primary.withValues(alpha: 0.35)),
              onPressed: () async {
                final added = await _promptText(
                  title: 'Add bend type',
                  hint: 'e.g. Side Bend, Inversion',
                );
                if (added == null) return;
                final label = added
                    .split(' ')
                    .where((p) => p.isNotEmpty)
                    .map((p) =>
                        '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
                    .join(' ');
                if (label.isEmpty) return;
                final isDefault = _defaultBendOptions.any(
                  (d) => d.toLowerCase() == label.toLowerCase(),
                );
                if (isDefault) return;
                setState(() {
                  if (!_config.customBendTypes.any(
                    (e) => e.toLowerCase() == label.toLowerCase(),
                  )) {
                    _config.customBendTypes = [
                      ..._config.customBendTypes,
                      label,
                    ];
                  }
                });
              },
            ),
        ],
      ),
    );
  }

  // ─── Step 9: Prizes (gender tops) or Grades (when Grading) ───────────────

  Widget _buildPrizesStep(Color primary) {
    if (_isGradingScoring) {
      return _buildGradingPrizesStep(primary);
    }
    final genders = _config.selectedGenders;
    return _stepCard(
      primary: primary,
      title: _numberedTitle('PRIZES APPLIES FOR TOP'),
      icon: Icons.emoji_events_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: _config.prizesCommon,
                onChanged: _readOnly
                    ? null
                    : (v) {
                        setState(() {
                          _config.prizesCommon = v ?? false;
                          if (_config.prizesCommon &&
                              (_config.prizesCommonTop < 1)) {
                            _config.prizesCommonTop = 1;
                          }
                        });
                      },
                activeColor: primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const Expanded(
                child: Text(
                  'Common (ignore gender & group for overall)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _config.prizesCommon
                ? 'One overall top-N ranking across all genders and groups.'
                : 'Award prize tops separately per selected gender.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          if (_config.prizesCommon)
            SizedBox(
              width: 140,
              child: _intDropdown(
                label: 'Common Top',
                value: _config.prizesCommonTop.clamp(1, 10),
                items: List.generate(10, (i) => i + 1),
                onChanged: (v) => setState(() {
                  _config.prizesCommonTop = v;
                }),
              ),
            )
          else if (genders.isEmpty)
            Text(
              'Select at least one gender in Step ${_stepNumberOf(_WizardStepId.gender)} to configure prize tops.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 520;
                final fields = genders
                    .map(
                      (g) => _intDropdown(
                        label: '$g Top',
                        value: _config.prizeTopFor(g).clamp(1, 10),
                        items: List.generate(10, (i) => i + 1),
                        onChanged: (v) => setState(() {
                          _config.setPrizeTop(g, v);
                        }),
                      ),
                    )
                    .toList();
                if (wide) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: fields
                        .map(
                          (f) => SizedBox(
                            width: fields.length == 1
                                ? constraints.maxWidth
                                : (constraints.maxWidth - 12) / 2,
                            child: f,
                          ),
                        )
                        .toList(),
                  );
                }
                return Column(
                  children: fields
                      .map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: f,
                        ),
                      )
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildGradingPrizesStep(Color primary) {
    return _stepCard(
      primary: primary,
      title: _numberedTitle('GRADES (NAME · MIN TO MAX)'),
      icon: Icons.emoji_events_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add grade names with mark ranges (e.g. A+ for 90–100).',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primary.withValues(alpha: 0.18)),
            ),
            child: Column(
              children: [
                ...List.generate(_gradeEntries.length, (index) {
                  final entry = _gradeEntries[index];
                  return Padding(
                    key: ValueKey(entry.rowId),
                    padding: EdgeInsets.only(
                      bottom: index < _gradeEntries.length - 1 ? 10 : 0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: entry.nameController,
                            enabled: !_readOnly,
                            decoration: _compactDecoration(hint: 'Grade name'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 72,
                          child: TextFormField(
                            controller: entry.minMarkController,
                            enabled: !_readOnly,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: _compactDecoration(hint: 'Min'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            'to',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 72,
                          child: TextFormField(
                            controller: entry.maxMarkController,
                            enabled: !_readOnly,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: _compactDecoration(hint: 'Max'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (!_readOnly)
                          IconButton(
                            tooltip: 'Remove',
                            onPressed: () {
                              if (_gradeEntries.length <= 1) {
                                setState(() {
                                  _gradeEntries[0].nameController.clear();
                                  _gradeEntries[0].minMarkController.clear();
                                  _gradeEntries[0].maxMarkController.clear();
                                });
                                return;
                              }
                              final removed = _gradeEntries[index];
                              setState(() {
                                _gradeEntries.removeAt(index);
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                removed.dispose();
                              });
                            },
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red.shade400,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                if (!_readOnly) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _gradeEntries.add(CompetitionGradeEntry());
                        });
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('+ Add More'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(color: primary),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 10: Viva Voce ───────────────────────────────────────────────────

  Widget _buildVivaStep(Color primary) {
    return _stepCard(
      primary: primary,
      title: _numberedTitle('VIVA VOCE QUESTION REPEATER'),
      icon: Icons.help_outline_rounded,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _readOnly
                ? const SizedBox.shrink()
                : TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _config.vivaQuestions = [
                          ..._config.vivaQuestions,
                          VivaQuestionModel(
                            id: DateTime.now().microsecondsSinceEpoch +
                                _config.vivaQuestions.length,
                          ),
                        ];
                      });
                    },
                    icon: Icon(Icons.add, size: 16, color: primary),
                    label: Text(
                      'Add Question',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: primary.withValues(alpha: 0.1),
                    ),
                  ),
          ),
          if (_config.vivaQuestions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No viva questions yet. Tap Add Question to create one.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
          ...List.generate(_config.vivaQuestions.length, (idx) {
            final q = _config.vivaQuestions[idx];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Question #${idx + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const Spacer(),
                      if (!_readOnly)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _config.vivaQuestions = _config.vivaQuestions
                                  .where((e) => e.id != q.id)
                                  .toList();
                            });
                          },
                          icon: const Icon(Icons.delete_outline,
                              size: 16, color: Colors.red),
                          label: const Text(
                            'Remove',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 480;
                      final qField = TextFormField(
                        key: ValueKey('viva-q-${q.id}'),
                        initialValue: q.question,
                        enabled: !_readOnly,
                        decoration: _compactDecoration(
                          hint: 'Question textbox...',
                        ),
                        onChanged: (v) => q.question = v,
                      );
                      final aField = TextFormField(
                        key: ValueKey('viva-a-${q.id}'),
                        initialValue: q.answer,
                        enabled: !_readOnly,
                        decoration: _compactDecoration(
                          hint: 'Answer textbox...',
                        ),
                        onChanged: (v) => q.answer = v,
                      );
                      if (wide) {
                        return Row(
                          children: [
                            Expanded(child: qField),
                            const SizedBox(width: 8),
                            Expanded(child: aField),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          qField,
                          const SizedBox(height: 8),
                          aField,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        child: _intDropdown(
                          label: 'Min Marks',
                          value: q.minMarks.clamp(1, 5),
                          items: const [1, 2, 3, 4, 5],
                          onChanged: (v) => setState(() => q.minMarks = v),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: _intDropdown(
                          label: 'Max Marks',
                          value: q.maxMarks,
                          items: const [5, 10, 15, 20],
                          onChanged: (v) => setState(() => q.maxMarks = v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Step 11: Compliments ─────────────────────────────────────────────────

  Widget _buildComplimentsStep(Color primary) {
    return Column(
      children: [
        _stepCard(
          primary: primary,
          title: _numberedTitle('COMPLIMENTS FOR TOP PARTICIPANTS'),
          icon: Icons.card_giftcard_outlined,
          child: _complimentChipRow(
            primary: primary,
            selected: _config.topCompliments,
            onChanged: (list) => setState(() => _config.topCompliments = list),
          ),
        ),
        const SizedBox(height: 12),
        _stepCard(
          primary: primary,
          title: 'COMPLIMENTS FOR NON-TOP PARTICIPANTS',
          icon: Icons.sentiment_satisfied_alt_outlined,
          child: _complimentChipRow(
            primary: primary,
            selected: _config.nonTopCompliments,
            onChanged: (list) =>
                setState(() => _config.nonTopCompliments = list),
          ),
        ),
      ],
    );
  }

  Widget _complimentChipRow({
    required Color primary,
    required List<String> selected,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._complimentOptions.map((opt) {
          final sel = selected.contains(opt);
          return FilterChip(
            label: Text(
              opt,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: sel ? Colors.white : Colors.grey.shade700,
              ),
            ),
            selected: sel,
            showCheckmark: false,
            selectedColor: primary,
            backgroundColor: Colors.grey.shade100,
            side: BorderSide(color: sel ? primary : Colors.grey.shade300),
            onSelected: _readOnly
                ? null
                : (v) {
                    final next = List<String>.from(selected);
                    if (v) {
                      if (!next.contains(opt)) next.add(opt);
                    } else {
                      next.remove(opt);
                    }
                    onChanged(next);
                  },
          );
        }),
        if (!_readOnly)
          ActionChip(
            avatar: Icon(Icons.add, size: 14, color: Colors.grey.shade700),
            label: Text(
              'Add Custom',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
            backgroundColor: Colors.grey.shade200,
            side: BorderSide(color: Colors.grey.shade300),
            onPressed: () async {
              final custom = await _promptText(
                title: 'Add Custom Compliment',
                hint: 'e.g. Gold Coin',
              );
              if (custom == null) return;
              setState(() {
                if (!_complimentOptions.contains(custom)) {
                  _complimentOptions = [..._complimentOptions, custom];
                }
              });
              if (!selected.contains(custom)) {
                onChanged([...selected, custom]);
              }
            },
          ),
      ],
    );
  }

  // ─── Step 12: Fees ────────────────────────────────────────────────────────

  double _roundFeeMoney(double value) =>
      double.parse(value.toStringAsFixed(2));

  String _formatFeeInput(double value) {
    if (value == 0) return '';
    return value.truncateToDouble() == value
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  void _applyIncludeFeeToggleToAmount({
    required TextEditingController controller,
    required void Function(double) onAmountChanged,
    required bool include,
    required CompetitionController ctrl,
  }) {
    final stored = double.tryParse(controller.text.trim()) ?? 0;
    if (stored <= 0) return;
    final gatewayRate = ctrl.onDemandPaymentGatewayFeePercent.value / 100;
    final platformRate = ctrl.onDemandPlatformFeePercent.value / 100;
    final feeMultiplier = 1 + gatewayRate + platformRate;
    final next = include
        ? _roundFeeMoney(stored * feeMultiplier)
        : _roundFeeMoney(stored / feeMultiplier);
    controller.text = _formatFeeInput(next);
    onAmountChanged(next);
  }

  void _toggleIncludePlatformFee(bool include) {
    final ctrl = widget.competitionController;
    if (ctrl == null) {
      setState(() => _config.includeFeeInRegistration = include);
      return;
    }
    final oldInclude = _config.includeFeeInRegistration;
    if (include == oldInclude) return;

    _applyIncludeFeeToggleToAmount(
      controller: _feeController,
      onAmountChanged: (v) => _config.feeAmount = v,
      include: include,
      ctrl: ctrl,
    );
    if (!_config.isOnlineMode) {
      _applyIncludeFeeToggleToAmount(
        controller: _spotFeeController,
        onAmountChanged: (v) => _config.spotFeeAmount = v,
        include: include,
        ctrl: ctrl,
      );
    } else {
      _config.spotFeeAmount = _config.feeAmount;
    }
    setState(() => _config.includeFeeInRegistration = include);
  }

  Widget _buildFeeBreakdown({
    required Color primary,
    required CompetitionController feeCtrl,
    required double storedAmount,
    required bool includePlatformFee,
    required String title,
  }) {
    if (storedAmount <= 0) return const SizedBox.shrink();
    final breakdown = feeCtrl.breakdownCategoryAmount(
      storedAmount,
      includePlatformFee: includePlatformFee,
      categoryId: _config.categoryId,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          if (includePlatformFee) ...[
            Text(
              'Amount: ₹${breakdown.baseAmount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 2),
            Text(
              'Fee: ₹${breakdown.totalFee.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Total: ₹${breakdown.totalAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
          ] else ...[
            Text(
              'Total payable: ₹${breakdown.totalAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Fee: ₹${breakdown.totalFee.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeesStep(Color primary) {
    final ctrl = widget.competitionController;
    final isOnDemand = ctrl?.isOnDemandOrg.value ?? false;
    final onlineAmount =
        double.tryParse(_feeController.text.trim()) ?? _config.feeAmount;
    final spotAmount = double.tryParse(_spotFeeController.text.trim()) ??
        (_config.spotFeeAmount > 0 ? _config.spotFeeAmount : _config.feeAmount);
    final includePlatformFee = _config.includeFeeInRegistration;
    final showBreakdown = isOnDemand && ctrl != null;

    return _stepCard(
      primary: primary,
      title: _numberedTitle('CATEGORY REGISTRATION FEES'),
      icon: Icons.currency_rupee_rounded,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _labeledField(
              label: 'Online fee per participant',
              child: TextFormField(
                controller: _feeController,
                enabled: !_readOnly,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: _compactDecoration(prefixText: '₹ '),
                style: const TextStyle(fontWeight: FontWeight.w900),
                onChanged: (v) {
                  setState(() {
                    _config.feeAmount = double.tryParse(v.trim()) ?? 0;
                  });
                },
              ),
            ),
            if (showBreakdown)
              _buildFeeBreakdown(
                primary: primary,
                feeCtrl: ctrl,
                storedAmount: onlineAmount,
                includePlatformFee: includePlatformFee,
                title: 'Online calculation',
              ),
            if (!_config.isOnlineMode) ...[
              const SizedBox(height: 12),
              _labeledField(
                label: 'Spot fee per participant',
                child: TextFormField(
                  controller: _spotFeeController,
                  enabled: !_readOnly,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: _compactDecoration(prefixText: '₹ '),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                  onChanged: (v) {
                    setState(() {
                      _config.spotFeeAmount = double.tryParse(v.trim()) ?? 0;
                    });
                  },
                ),
              ),
              if (showBreakdown)
                _buildFeeBreakdown(
                  primary: primary,
                  feeCtrl: ctrl,
                  storedAmount: spotAmount,
                  includePlatformFee: includePlatformFee,
                  title: 'Spot calculation',
                ),
            ],
            if (isOnDemand) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: includePlatformFee,
                    onChanged: _readOnly
                        ? null
                        : (value) => _toggleIncludePlatformFee(value ?? false),
                    activeColor: primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const Text(
                    'INCLUDE FEE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
            if (showBreakdown) ...[
              const SizedBox(height: 4),
              Obx(() {
                final gatewayPct =
                    ctrl.onDemandPaymentGatewayFeePercent.value;
                final platformPct = ctrl.onDemandPlatformFeePercent.value;
                return Text(
                  'Platform ${platformPct.toStringAsFixed(1)}% + Gateway ${gatewayPct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Shared helpers ───────────────────────────────────────────────────────

  Widget _labeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _compactDecoration({
    String? hint,
    String? prefixText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefixText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade50,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _intDropdown({
    required String label,
    required int value,
    required List<int> items,
    required ValueChanged<int> onChanged,
    String Function(int)? itemLabel,
  }) {
    final safeValue = items.contains(value) ? value : items.first;
    return _labeledField(
      label: label,
      child: DropdownButtonFormField<int>(
        value: safeValue,
        decoration: _compactDecoration(),
        items: items
            .map(
              (n) => DropdownMenuItem(
                value: n,
                child: Text(
                  itemLabel?.call(n) ?? '$n',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: _readOnly
            ? null
            : (v) {
                if (v != null) onChanged(v);
              },
      ),
    );
  }
}

/// Group chip with click-to-reveal edit / delete actions.
class _HoverEditableGroupChip extends StatefulWidget {
  const _HoverEditableGroupChip({
    required this.label,
    required this.selected,
    required this.primary,
    required this.readOnly,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final String label;
  final bool selected;
  final Color primary;
  final bool readOnly;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_HoverEditableGroupChip> createState() =>
      _HoverEditableGroupChipState();
}

class _HoverEditableGroupChipState extends State<_HoverEditableGroupChip> {
  bool _actionsOpen = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final primary = widget.primary;
    final iconColor = selected ? Colors.white : primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: EdgeInsets.only(
        left: 10,
        right: widget.readOnly ? 10 : 2,
        top: 4,
        bottom: 4,
      ),
      decoration: BoxDecoration(
        color: selected ? primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? primary
              : (_actionsOpen ? primary.withValues(alpha: 0.55) : Colors.grey.shade300),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: widget.readOnly ? null : () => widget.onToggle(!selected),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          ),
          if (!widget.readOnly) ...[
            if (_actionsOpen) ...[
              _chipIconButton(
                icon: Icons.edit_outlined,
                tooltip: 'Edit',
                color: selected ? Colors.white : primary,
                onTap: () {
                  setState(() => _actionsOpen = false);
                  widget.onEdit();
                },
              ),
              _chipIconButton(
                icon: Icons.delete_outline,
                tooltip: 'Delete',
                color: selected ? Colors.white : Colors.redAccent,
                onTap: () {
                  setState(() => _actionsOpen = false);
                  widget.onDelete();
                },
              ),
              _chipIconButton(
                icon: Icons.close,
                tooltip: 'Close',
                color: iconColor,
                onTap: () => setState(() => _actionsOpen = false),
              ),
            ] else
              _chipIconButton(
                icon: Icons.more_horiz,
                tooltip: 'Edit / Delete',
                color: iconColor,
                onTap: () => setState(() => _actionsOpen = true),
              ),
          ],
        ],
      ),
    );
  }

  Widget _chipIconButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}

class _PromptTextDialog extends StatefulWidget {
  const _PromptTextDialog({
    required this.title,
    this.hint,
    this.initial = '',
  });

  final String title;
  final String? hint;
  final String initial;

  @override
  State<_PromptTextDialog> createState() => _PromptTextDialogState();
}

class _PromptTextDialogState extends State<_PromptTextDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: widget.hint),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
