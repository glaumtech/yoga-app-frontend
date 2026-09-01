import 'competition_grade_model.dart';

/// Per-category Asanas / Challenge configuration (mirrors backend CompetitionCategoryConfigDto).
class CompetitionCategoryConfigModel {
  final String draftId;
  int? categoryId;
  String categoryName;
  /// ASANAS | CHALLENGE
  String format;
  /// ONLINE | OFFLINE
  String mode;
  /// COUNT | VIDEO | empty when unset (online challenge type).
  String submissionType;
  bool configured;
  String? summary;

  String stageNaming; // alphabet | stages | other
  int stageCount;
  List<String> stageNames;

  String groupType; // STUDY | AGE | LEVEL | MIXED
  List<String> selectedGroups;
  Map<String, List<String>> stageAllotment;

  int? participantsPerStage;
  int? minimumMarks;
  int? maximumMarks;
  bool skippedAsanaEnabled;
  int skippedAsanaCount;
  int skippedAsanaMarks;

  int juriesPerStage;
  int compulsoryAsanas;
  int ownChoiceAsanas;
  int eachAsanaTimeMinutes;
  /// Challenge duration in days.
  int? durationDays;
  /// How many times the asana should be performed.
  int? howManyTimes;
  bool increaseCountEnabled;
  /// Ranges such as 1 to 40 = 50 when [increaseCountEnabled] is true.
  List<IncreaseCountRangeModel> increaseCountRanges;

  bool bendForward;
  bool bendBackward;
  bool bendHandBalance;
  bool bendLegBalance;
  bool bendTwisting;
  /// Extra bend labels beyond the five built-in flags.
  List<String> customBendTypes;

  int prizesBoysTop;
  int prizesGirlsTop;
  int prizesOthersTop;
  /// When true, prizes use one overall top-N (ignore gender/group splits).
  bool prizesCommon;
  /// Top-N when [prizesCommon] is true.
  int prizesCommonTop;
  /// Selected genders for prizes (e.g. Male, Female, Others, custom).
  List<String> selectedGenders;
  /// Top-N prize count keyed by gender label.
  Map<String, int> prizeTopsByGender;
  /// Grade ranges when scoringMethod is GRADING.
  List<CompetitionGradeModel> grades;

  String scoringMethod;
  int? upgradeTop;
  int? upgradeToCategoryId;
  String? upgradeToCategoryName;
  String? minTime;
  String? maxTime;

  List<VivaQuestionModel> vivaQuestions;
  List<String> topCompliments;
  List<String> nonTopCompliments;

  double feeAmount;
  /// Spot registration fee; when unset/0 and online fee is set, UI may mirror online.
  double spotFeeAmount;
  bool includeFeeInRegistration;

  /// When true, prize ties can be resolved via a one-asana tie-breaker round.
  bool tieBreakerEnabled;

  CompetitionCategoryConfigModel({
    String? draftId,
    this.categoryId,
    required this.categoryName,
    this.format = 'ASANAS',
    this.mode = 'OFFLINE',
    this.submissionType = '',
    this.configured = false,
    this.summary,
    this.stageNaming = 'alphabet',
    this.stageCount = 4,
    List<String>? stageNames,
    this.groupType = 'STUDY',
    List<String>? selectedGroups,
    Map<String, List<String>>? stageAllotment,
    this.participantsPerStage = 5,
    this.minimumMarks = 1,
    this.maximumMarks = 10,
    this.skippedAsanaEnabled = true,
    this.skippedAsanaCount = 1,
    this.skippedAsanaMarks = 0,
    this.juriesPerStage = 3,
    this.compulsoryAsanas = 4,
    this.ownChoiceAsanas = 2,
    this.eachAsanaTimeMinutes = 1,
    this.durationDays,
    this.howManyTimes,
    this.increaseCountEnabled = false,
    List<IncreaseCountRangeModel>? increaseCountRanges,
    this.bendForward = true,
    this.bendBackward = true,
    this.bendHandBalance = true,
    this.bendLegBalance = false,
    this.bendTwisting = true,
    List<String>? customBendTypes,
    this.prizesBoysTop = 3,
    this.prizesGirlsTop = 3,
    this.prizesOthersTop = 1,
    this.prizesCommon = false,
    this.prizesCommonTop = 3,
    List<String>? selectedGenders,
    Map<String, int>? prizeTopsByGender,
    List<CompetitionGradeModel>? grades,
    this.scoringMethod = 'MARKS',
    this.upgradeTop,
    this.upgradeToCategoryId,
    this.upgradeToCategoryName,
    this.minTime,
    this.maxTime,
    this.tieBreakerEnabled = false,
    List<VivaQuestionModel>? vivaQuestions,
    List<String>? topCompliments,
    List<String>? nonTopCompliments,
    this.feeAmount = 0,
    this.spotFeeAmount = 0,
    this.includeFeeInRegistration = true,
  })  : draftId = draftId ??
            'draft-${DateTime.now().microsecondsSinceEpoch}-'
                '${identityHashCode(categoryName)}',
        stageNames = stageNames ?? <String>[],
        selectedGroups = selectedGroups ??
            <String>['LKG', 'UKG', 'I', 'II', 'III', 'IV', 'V'],
        stageAllotment = stageAllotment ?? <String, List<String>>{},
        customBendTypes = customBendTypes ?? <String>[],
        increaseCountRanges =
            increaseCountRanges ?? <IncreaseCountRangeModel>[],
        selectedGenders = selectedGenders ??
            <String>['Male', 'Female', 'Others'],
        prizeTopsByGender = prizeTopsByGender ??
            <String, int>{
              'Male': prizesBoysTop,
              'Female': prizesGirlsTop,
              'Others': prizesOthersTop,
            },
        grades = grades ?? <CompetitionGradeModel>[],
        vivaQuestions = vivaQuestions ?? <VivaQuestionModel>[],
        topCompliments = topCompliments ??
            <String>['e-Certificate', 'Certificate', 'Medal', 'Trophy'],
        nonTopCompliments =
            nonTopCompliments ?? <String>['e-Certificate', 'Certificate'];

  /// Brand-new category — never copies another category's wizard values.
  factory CompetitionCategoryConfigModel.freshAsanas({
    required String categoryName,
    int? categoryId,
    String format = 'ASANAS',
    String mode = 'OFFLINE',
  }) {
    final draft = CompetitionCategoryConfigModel(
      categoryId: categoryId,
      categoryName: categoryName.trim().toUpperCase(),
      format: format.toUpperCase() == 'CHALLENGE' ? 'CHALLENGE' : 'ASANAS',
      mode: mode.trim().toUpperCase() == 'ONLINE' ? 'ONLINE' : 'OFFLINE',
      submissionType: '',
      configured: false,
      stageNaming: 'alphabet',
      stageCount: 4,
      groupType: 'STUDY',
      selectedGroups: <String>['LKG', 'UKG', 'I', 'II', 'III', 'IV', 'V'],
      stageAllotment: <String, List<String>>{},
      participantsPerStage: 5,
      minimumMarks: 1,
      maximumMarks: 10,
      skippedAsanaEnabled: true,
      skippedAsanaCount: 1,
      skippedAsanaMarks: 0,
      juriesPerStage: 3,
      compulsoryAsanas: 4,
      ownChoiceAsanas: 2,
      eachAsanaTimeMinutes: 1,
      durationDays: null,
      howManyTimes: null,
      increaseCountEnabled: false,
      increaseCountRanges: <IncreaseCountRangeModel>[],
      bendForward: true,
      bendBackward: true,
      bendHandBalance: true,
      bendLegBalance: false,
      bendTwisting: true,
      customBendTypes: <String>[],
      prizesBoysTop: 3,
      prizesGirlsTop: 3,
      prizesOthersTop: 1,
      prizesCommon: false,
      prizesCommonTop: 3,
      selectedGenders: <String>['Male', 'Female', 'Others'],
      prizeTopsByGender: <String, int>{
        'Male': 3,
        'Female': 3,
        'Others': 1,
      },
      grades: <CompetitionGradeModel>[],
      scoringMethod: 'MARKS',
      vivaQuestions: <VivaQuestionModel>[],
      topCompliments: <String>[
        'e-Certificate',
        'Certificate',
        'Medal',
        'Trophy',
      ],
      nonTopCompliments: <String>['e-Certificate', 'Certificate'],
      feeAmount: 0,
      spotFeeAmount: 0,
      includeFeeInRegistration: true,
      tieBreakerEnabled: false,
    );
    draft.syncGeneratedStages();
    return draft;
  }

  /// Reset wizard fields to defaults while keeping identity (id/name/format).
  void resetWizardFieldsToDefaults() {
    stageNaming = 'alphabet';
    stageCount = 4;
    groupType = 'STUDY';
    selectedGroups = <String>['LKG', 'UKG', 'I', 'II', 'III', 'IV', 'V'];
    stageAllotment = <String, List<String>>{};
    submissionType = '';
    participantsPerStage = 5;
    minimumMarks = 1;
    maximumMarks = 10;
    skippedAsanaEnabled = true;
    skippedAsanaCount = 1;
    skippedAsanaMarks = 0;
    juriesPerStage = 3;
    compulsoryAsanas = 4;
    ownChoiceAsanas = 2;
    eachAsanaTimeMinutes = 1;
    durationDays = null;
    howManyTimes = null;
    increaseCountEnabled = false;
    increaseCountRanges = <IncreaseCountRangeModel>[];
    bendForward = true;
    bendBackward = true;
    bendHandBalance = true;
    bendLegBalance = false;
    bendTwisting = true;
    customBendTypes = <String>[];
    prizesBoysTop = 3;
    prizesGirlsTop = 3;
    prizesOthersTop = 1;
    prizesCommon = false;
    prizesCommonTop = 3;
    selectedGenders = <String>['Male', 'Female', 'Others'];
    prizeTopsByGender = <String, int>{
      'Male': 3,
      'Female': 3,
      'Others': 1,
    };
    grades = <CompetitionGradeModel>[];
    scoringMethod = 'MARKS';
    upgradeTop = null;
    upgradeToCategoryId = null;
    upgradeToCategoryName = null;
    minTime = null;
    maxTime = null;
    vivaQuestions = <VivaQuestionModel>[];
    topCompliments = <String>[
      'e-Certificate',
      'Certificate',
      'Medal',
      'Trophy',
    ];
    nonTopCompliments = <String>['e-Certificate', 'Certificate'];
    feeAmount = 0;
    spotFeeAmount = 0;
    includeFeeInRegistration = true;
    tieBreakerEnabled = false;
    summary = null;
    syncGeneratedStages();
  }

  bool get isChallenge => format.toUpperCase() == 'CHALLENGE';
  bool get isAsanas => !isChallenge;
  bool get isOnlineMode => mode.toUpperCase() == 'ONLINE';
  String get modeLabel => isOnlineMode ? 'Online' : 'Offline';
  String get submissionTypeNormalized => submissionType.trim().toUpperCase();
  bool get isCountSubmission => submissionTypeNormalized == 'COUNT';
  bool get isVideoSubmission => submissionTypeNormalized == 'VIDEO';
  bool get hasSubmissionType => isCountSubmission || isVideoSubmission;

  bool get isGradingScoring => scoringMethodNormalized == 'GRADING';

  String get scoringMethodNormalized {
    final raw = scoringMethod.toUpperCase().trim();
    if (raw.contains('TIMED') && raw.contains('SCORING')) {
      return 'TIMED_PLUS_SCORING';
    }
    if (raw == 'MARKS' || raw.contains('MARK')) return 'MARKS';
    if (raw == 'GRADING' || raw.contains('GRAD')) return 'GRADING';
    if (raw == 'TIMED' || raw.contains('TIME')) return 'TIMED';
    if (raw == 'NONE') return 'NONE';
    return raw.replaceAll(' ', '_');
  }

  bool get showsMarksLimits {
    final m = scoringMethodNormalized;
    return m == 'MARKS' || m == 'GRADING' || m == 'TIMED_PLUS_SCORING';
  }

  bool get showsTimeLimits {
    final m = scoringMethodNormalized;
    return m == 'TIMED' || m == 'TIMED_PLUS_SCORING';
  }

  int prizeTopFor(String gender) {
    final key = normalizeGenderLabel(gender);
    return prizeTopsByGender[key] ??
        prizeTopsByGender[gender] ??
        (key == 'Male'
            ? prizesBoysTop
            : key == 'Female'
                ? prizesGirlsTop
                : key == 'Others'
                    ? prizesOthersTop
                    : 1);
  }

  void setPrizeTop(String gender, int top) {
    final key = normalizeGenderLabel(gender);
    prizeTopsByGender[key] = top;
    if (key == 'Male') prizesBoysTop = top;
    if (key == 'Female') prizesGirlsTop = top;
    if (key == 'Others') prizesOthersTop = top;
  }

  void syncPrizeTopsFromGenderMap() {
    prizesBoysTop = prizeTopFor('Male');
    prizesGirlsTop = prizeTopFor('Female');
    prizesOthersTop = prizeTopFor('Others');
  }

  static String normalizeGenderLabel(String gender) {
    final g = gender.trim();
    if (g.toLowerCase() == 'boys' || g.toLowerCase() == 'boy') return 'Male';
    if (g.toLowerCase() == 'girls' || g.toLowerCase() == 'girl') {
      return 'Female';
    }
    return g;
  }

  static List<String> normalizeGenderLabels(List<String> genders) {
    final result = <String>[];
    for (final g in genders) {
      final n = normalizeGenderLabel(g);
      if (n.isEmpty) continue;
      if (!result.any((e) => e.toLowerCase() == n.toLowerCase())) {
        result.add(n);
      }
    }
    return result;
  }

  static Map<String, int> normalizePrizeTopKeys(Map<String, int> tops) {
    final result = <String, int>{};
    tops.forEach((key, value) {
      final n = normalizeGenderLabel(key);
      if (n.isEmpty) return;
      result[n] = value;
    });
    return result;
  }

  String get statusLabel {
    if (isChallenge) return 'Challenge';
    if (configured) return 'Asanas';
    return 'Not configured';
  }

  /// Body text for cards (groups / prizes) without the fee suffix.
  String get contentSummary {
    if (isGradingScoring && grades.isNotEmpty) {
      return grades
          .map((g) => '${g.gradeName} (${g.markRangeMin}-${g.markRangeMax})')
          .join(' · ');
    }

    final genders = _orderedGendersForSummary();
    return prizesCommon
        ? 'Common top $prizesCommonTop'
        : (genders.isEmpty
            ? 'Male top $prizesBoysTop · Female top $prizesGirlsTop · Others top $prizesOthersTop'
            : genders.map((g) => '$g top ${prizeTopFor(g)}').join(' · '));
  }

  /// Live card summary — always rebuilt from current config (not a frozen string).
  String get displaySummary {
    final body = contentSummary.trim();
    if (body.isEmpty) return feeSummaryLabel;
    return _withFee(body);
  }

  String get feeSummaryLabel {
    final online = feeAmount;
    final spot = spotFeeAmount > 0 ? spotFeeAmount : feeAmount;
    String fmt(double amount) => amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    if ((spot - online).abs() < 0.001) {
      return 'Fee ₹${fmt(online)}';
    }
    return 'Online ₹${fmt(online)} · Spot ₹${fmt(spot)}';
  }

  String _withFee(String base) {
    final trimmed = base.trim();
    if (trimmed.isEmpty) return feeSummaryLabel;
    return '$trimmed · $feeSummaryLabel';
  }

  /// Prefer Male → Female → Others, then any custom genders in selection order.
  List<String> _orderedGendersForSummary() {
    if (selectedGenders.isEmpty) {
      return const ['Male', 'Female', 'Others'];
    }
    const preferred = ['Male', 'Female', 'Others'];
    final result = <String>[];
    for (final g in preferred) {
      if (selectedGenders.any((s) => s.toLowerCase() == g.toLowerCase())) {
        final match = selectedGenders.firstWhere(
          (s) => s.toLowerCase() == g.toLowerCase(),
        );
        result.add(match);
      }
    }
    for (final g in selectedGenders) {
      if (!result.any((r) => r.toLowerCase() == g.toLowerCase())) {
        result.add(g);
      }
    }
    return result;
  }

  List<String> generateStageNames() {
    final count = stageCount.clamp(1, 26);
    final list = <String>[];
    for (var i = 0; i < count; i++) {
      if (stageNaming == 'stages') {
        list.add('Stage ${i + 1}');
      } else if (stageNaming == 'other') {
        list.add('Zone ${i + 1}');
      } else {
        list.add('Stage ${String.fromCharCode(65 + i)}');
      }
    }
    return list;
  }

  /// Align [stageNames] / allotment with [stageCount].
  /// When [regenerateNames] is false, keeps existing custom names and only
  /// adds/removes slots as the count changes.
  void syncGeneratedStages({bool regenerateNames = true}) {
    final count = stageCount.clamp(1, 26);
    stageCount = count;
    if (regenerateNames || stageNames.isEmpty) {
      stageNames = generateStageNames();
    } else {
      final defaults = generateStageNames();
      final next = <String>[];
      for (var i = 0; i < count; i++) {
        final existing = i < stageNames.length ? stageNames[i].trim() : '';
        next.add(existing.isNotEmpty ? existing : defaults[i]);
      }
      stageNames = next;
    }
    final allotment = <String, List<String>>{};
    for (final name in stageNames) {
      allotment[name] = List<String>.from(stageAllotment[name] ?? const []);
    }
    stageAllotment = allotment;
  }

  /// Rename a stage chip; updates allotment keys. Returns false if invalid/duplicate.
  bool renameStageAt(int index, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || index < 0 || index >= stageNames.length) {
      return false;
    }
    final duplicate = stageNames.asMap().entries.any(
      (e) =>
          e.key != index &&
          e.value.trim().toLowerCase() == trimmed.toLowerCase(),
    );
    if (duplicate) return false;

    final oldName = stageNames[index];
    if (oldName == trimmed) return true;

    stageNames = List<String>.from(stageNames)..[index] = trimmed;
    final groups = stageAllotment.remove(oldName) ?? <String>[];
    stageAllotment[trimmed] = List<String>.from(groups);
    return true;
  }

  factory CompetitionCategoryConfigModel.fromJson(Map<String, dynamic> json) {
    List<String> stringList(dynamic raw) {
      if (raw is! List) return [];
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }

    Map<String, List<String>> allotmentMap(dynamic raw) {
      if (raw is! Map) return {};
      final result = <String, List<String>>{};
      for (final e in raw.entries) {
        result[e.key.toString()] = stringList(e.value);
      }
      return result;
    }

    Map<String, int> intMap(dynamic raw) {
      if (raw is! Map) return {};
      final result = <String, int>{};
      for (final e in raw.entries) {
        final n = e.value is int
            ? e.value as int
            : int.tryParse(e.value.toString());
        if (n != null) result[e.key.toString()] = n;
      }
      return result;
    }

    final boysTop = json['prizesBoysTop'] is int
        ? json['prizesBoysTop'] as int
        : int.tryParse(json['prizesBoysTop']?.toString() ?? '') ?? 3;
    final girlsTop = json['prizesGirlsTop'] is int
        ? json['prizesGirlsTop'] as int
        : int.tryParse(json['prizesGirlsTop']?.toString() ?? '') ?? 3;
    final othersTop = json['prizesOthersTop'] is int
        ? json['prizesOthersTop'] as int
        : int.tryParse(json['prizesOthersTop']?.toString() ?? '') ?? 1;
    final commonTop = json['prizesCommonTop'] is int
        ? json['prizesCommonTop'] as int
        : int.tryParse(json['prizesCommonTop']?.toString() ?? '') ?? 3;

    var genders = normalizeGenderLabels(stringList(json['selectedGenders']));
    if (genders.isEmpty) {
      genders = <String>['Male', 'Female', 'Others'];
    }
    var tops = normalizePrizeTopKeys(intMap(json['prizeTopsByGender']));
    if (tops.isEmpty) {
      tops = {
        'Male': boysTop,
        'Female': girlsTop,
        'Others': othersTop,
      };
    }

    return CompetitionCategoryConfigModel(
      draftId: json['draftId']?.toString() ??
          (json['categoryId'] != null
              ? 'cat-${json['categoryId']}-${(json['mode'] ?? 'OFFLINE').toString().toUpperCase()}'
              : DateTime.now().millisecondsSinceEpoch.toString()),
      categoryId: json['categoryId'] is int
          ? json['categoryId'] as int
          : int.tryParse(json['categoryId']?.toString() ?? ''),
      categoryName: (json['categoryName'] ?? json['name'] ?? '').toString(),
      format: (json['format'] ?? 'ASANAS').toString().toUpperCase(),
      mode: () {
        final raw = (json['mode'] ?? json['competitionMode'] ?? 'OFFLINE')
            .toString()
            .trim()
            .toUpperCase();
        return raw == 'ONLINE' ? 'ONLINE' : 'OFFLINE';
      }(),
      submissionType: () {
        final raw = (json['submissionType'] ?? '').toString().trim().toUpperCase();
        return raw == 'COUNT' || raw == 'VIDEO' ? raw : '';
      }(),
      configured: json['configured'] == true,
      summary: json['summary']?.toString(),
      stageNaming: (json['stageNaming'] ?? 'alphabet').toString(),
      stageCount: json['stageCount'] is int
          ? json['stageCount'] as int
          : int.tryParse(json['stageCount']?.toString() ?? '') ?? 4,
      stageNames: stringList(json['stageNames']),
      groupType: (json['groupType'] ?? 'STUDY').toString().toUpperCase(),
      selectedGroups: stringList(json['selectedGroups']),
      stageAllotment: allotmentMap(json['stageAllotment']),
      participantsPerStage: json['participantsPerStage'] is int
          ? json['participantsPerStage'] as int
          : int.tryParse(json['participantsPerStage']?.toString() ?? ''),
      minimumMarks: json['minimumMarks'] is int
          ? json['minimumMarks'] as int
          : int.tryParse(json['minimumMarks']?.toString() ?? ''),
      maximumMarks: json['maximumMarks'] is int
          ? json['maximumMarks'] as int
          : int.tryParse(json['maximumMarks']?.toString() ?? ''),
      skippedAsanaEnabled: json['skippedAsanaEnabled'] != false,
      skippedAsanaCount: json['skippedAsanaCount'] is int
          ? json['skippedAsanaCount'] as int
          : int.tryParse(json['skippedAsanaCount']?.toString() ?? '') ?? 1,
      skippedAsanaMarks: json['skippedAsanaMarks'] is int
          ? json['skippedAsanaMarks'] as int
          : int.tryParse(json['skippedAsanaMarks']?.toString() ?? '') ?? 0,
      juriesPerStage: json['juriesPerStage'] is int
          ? json['juriesPerStage'] as int
          : int.tryParse(json['juriesPerStage']?.toString() ?? '') ?? 3,
      compulsoryAsanas: json['compulsoryAsanas'] is int
          ? json['compulsoryAsanas'] as int
          : int.tryParse(json['compulsoryAsanas']?.toString() ?? '') ?? 4,
      ownChoiceAsanas: json['ownChoiceAsanas'] is int
          ? json['ownChoiceAsanas'] as int
          : int.tryParse(json['ownChoiceAsanas']?.toString() ?? '') ?? 2,
      eachAsanaTimeMinutes: json['eachAsanaTimeMinutes'] is int
          ? json['eachAsanaTimeMinutes'] as int
          : int.tryParse(json['eachAsanaTimeMinutes']?.toString() ?? '') ?? 1,
      durationDays: json['durationDays'] is int
          ? json['durationDays'] as int
          : int.tryParse(json['durationDays']?.toString() ?? ''),
      howManyTimes: json['howManyTimes'] is int
          ? json['howManyTimes'] as int
          : int.tryParse(json['howManyTimes']?.toString() ?? ''),
      increaseCountEnabled: json['increaseCountEnabled'] == true,
      increaseCountRanges: json['increaseCountRanges'] is List
          ? (json['increaseCountRanges'] as List)
              .whereType<Map>()
              .map((e) => IncreaseCountRangeModel.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : <IncreaseCountRangeModel>[],
      bendForward: json['bendForward'] != false,
      bendBackward: json['bendBackward'] != false,
      bendHandBalance: json['bendHandBalance'] != false,
      bendLegBalance: json['bendLegBalance'] == true,
      bendTwisting: json['bendTwisting'] != false,
      customBendTypes: stringList(json['customBendTypes']),
      prizesBoysTop: boysTop,
      prizesGirlsTop: girlsTop,
      prizesOthersTop: othersTop,
      prizesCommon: json['prizesCommon'] == true,
      prizesCommonTop: commonTop,
      selectedGenders: genders,
      prizeTopsByGender: tops,
      grades: json['grades'] is List
          ? (json['grades'] as List)
              .whereType<Map>()
              .map((e) =>
                  CompetitionGradeModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : <CompetitionGradeModel>[],
      scoringMethod: (json['scoringMethod'] ?? 'MARKS').toString(),
      upgradeTop: json['upgradeTop'] is int
          ? json['upgradeTop'] as int
          : int.tryParse(json['upgradeTop']?.toString() ?? ''),
      upgradeToCategoryId: json['upgradeToCategoryId'] is int
          ? json['upgradeToCategoryId'] as int
          : int.tryParse(json['upgradeToCategoryId']?.toString() ?? ''),
      upgradeToCategoryName: json['upgradeToCategoryName']?.toString(),
      minTime: json['minTime']?.toString(),
      maxTime: json['maxTime']?.toString(),
      vivaQuestions: json['vivaQuestions'] is List
          ? (json['vivaQuestions'] as List)
              .whereType<Map>()
              .map((e) =>
                  VivaQuestionModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
      topCompliments: stringList(json['topCompliments']),
      nonTopCompliments: stringList(json['nonTopCompliments']),
      feeAmount: json['feeAmount'] is num
          ? (json['feeAmount'] as num).toDouble()
          : double.tryParse(json['feeAmount']?.toString() ?? '') ?? 0,
      spotFeeAmount: () {
        final online = json['feeAmount'] is num
            ? (json['feeAmount'] as num).toDouble()
            : double.tryParse(json['feeAmount']?.toString() ?? '') ?? 0;
        final spot = json['spotFeeAmount'] is num
            ? (json['spotFeeAmount'] as num).toDouble()
            : double.tryParse(json['spotFeeAmount']?.toString() ?? '');
        return spot ?? online;
      }(),
      includeFeeInRegistration: json['includeFeeInRegistration'] != false,
      tieBreakerEnabled: json['tieBreakerEnabled'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    // Preserve custom stage names; only resize / realign allotment keys.
    syncGeneratedStages(regenerateNames: false);
    syncPrizeTopsFromGenderMap();
    return {
      if (categoryId != null) 'categoryId': categoryId,
      'categoryName': categoryName.trim().toUpperCase(),
      'format': format.toUpperCase(),
      'mode': mode.trim().toUpperCase() == 'ONLINE' ? 'ONLINE' : 'OFFLINE',
      if (submissionTypeNormalized.isNotEmpty)
        'submissionType': submissionTypeNormalized,
      'configured': configured,
      'summary': displaySummary,
      'stageNaming': stageNaming,
      'stageCount': stageCount,
      'stageNames': stageNames,
      'groupType': groupType.toUpperCase(),
      'selectedGroups': selectedGroups,
      'stageAllotment': stageAllotment,
      'participantsPerStage': participantsPerStage,
      'minimumMarks': minimumMarks,
      'maximumMarks': maximumMarks,
      'skippedAsanaEnabled': skippedAsanaEnabled,
      'skippedAsanaCount': skippedAsanaCount,
      'skippedAsanaMarks': skippedAsanaMarks,
      'juriesPerStage': juriesPerStage,
      'compulsoryAsanas': compulsoryAsanas,
      'ownChoiceAsanas': ownChoiceAsanas,
      'eachAsanaTimeMinutes': eachAsanaTimeMinutes,
      'durationDays': durationDays,
      'howManyTimes': howManyTimes,
      'increaseCountEnabled': increaseCountEnabled,
      'increaseCountRanges':
          increaseCountRanges.map((e) => e.toJson()).toList(),
      'bendForward': bendForward,
      'bendBackward': bendBackward,
      'bendHandBalance': bendHandBalance,
      'bendLegBalance': bendLegBalance,
      'bendTwisting': bendTwisting,
      'customBendTypes': customBendTypes,
      'prizesBoysTop': prizesBoysTop,
      'prizesGirlsTop': prizesGirlsTop,
      'prizesOthersTop': prizesOthersTop,
      'prizesCommon': prizesCommon,
      'prizesCommonTop': prizesCommonTop,
      'selectedGenders': selectedGenders,
      'prizeTopsByGender': prizeTopsByGender,
      'grades': grades.map((e) => e.toJson()).toList(),
      'scoringMethod': scoringMethod,
      if (upgradeTop != null) 'upgradeTop': upgradeTop,
      if (upgradeToCategoryId != null)
        'upgradeToCategoryId': upgradeToCategoryId,
      if (upgradeToCategoryName != null &&
          upgradeToCategoryName!.trim().isNotEmpty)
        'upgradeToCategoryName': upgradeToCategoryName,
      if (minTime != null) 'minTime': minTime,
      if (maxTime != null) 'maxTime': maxTime,
      'vivaQuestions': vivaQuestions.map((e) => e.toJson()).toList(),
      'topCompliments': topCompliments,
      'nonTopCompliments': nonTopCompliments,
      'feeAmount': feeAmount,
      'spotFeeAmount': spotFeeAmount > 0 ? spotFeeAmount : feeAmount,
      'includeFeeInRegistration': includeFeeInRegistration,
      'tieBreakerEnabled': tieBreakerEnabled,
    };
  }

  CompetitionCategoryConfigModel clone({String? newDraftId}) {
    final json = toJson();
    json['draftId'] = newDraftId ?? draftId;
    return CompetitionCategoryConfigModel.fromJson(json);
  }
}

class IncreaseCountRangeModel {
  const IncreaseCountRangeModel({
    required this.from,
    required this.to,
    required this.count,
  });

  final int from;
  final int to;
  final int count;

  String get label => '$from to $to = $count';

  factory IncreaseCountRangeModel.fromJson(Map<String, dynamic> json) {
    return IncreaseCountRangeModel(
      from: _parseInt(json['from']) ?? 0,
      to: _parseInt(json['to']) ?? 0,
      count: _parseInt(json['count']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'count': count,
      };

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}

class VivaQuestionModel {
  final int id;
  String question;
  String answer;
  int minMarks;
  int maxMarks;

  VivaQuestionModel({
    int? id,
    this.question = '',
    this.answer = '',
    this.minMarks = 1,
    this.maxMarks = 5,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch;

  factory VivaQuestionModel.fromJson(Map<String, dynamic> json) {
    return VivaQuestionModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ??
              DateTime.now().millisecondsSinceEpoch,
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      minMarks: json['minMarks'] is int
          ? json['minMarks'] as int
          : int.tryParse(json['minMarks']?.toString() ?? '') ?? 1,
      maxMarks: json['maxMarks'] is int
          ? json['maxMarks'] as int
          : int.tryParse(json['maxMarks']?.toString() ?? '') ?? 5,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'answer': answer,
        'minMarks': minMarks,
        'maxMarks': maxMarks,
      };
}
