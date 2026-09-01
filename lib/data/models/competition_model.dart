import 'package:flutter/material.dart';

import 'category_config_model.dart';
import 'competition_grade_model.dart';

class CompetitionModel {
  final String? id;
  final String competitionName;
  final String description;
  final String address;
  final DateTime eventStartDate;
  final String? eventStartTime;
  final DateTime eventEndDate;
  final String? eventEndTime;
  final bool publishResultNow;
  final DateTime? resultsPublishDate;
  final String? resultsPublishTime;
  final DateTime? displayAdFrom;
  final bool spotRegistration;
  final int? participantsPerStage; // 1-5
  final int? minimumMarks;
  final int? maximumMarks;
  /// Mark applied when jury selects skipped asana (typically 0).
  final int? skippedAsanaMarks;
  /// Schools with at least this many participants qualify for Best School Award in reports.
  final int? bestSchoolAwardMinParticipants;
  final List<String>?
  prizes; // e.g., ["1st", "2nd", "3rd"] - for display/parsing
  final List<int>? prizeIds; // e.g., [1, 2, 3] - for API submission
  final List<String>?
  categories; // e.g., ["COMMON", "SPECIAL", "CHAMPIONS"] - for display/parsing
  final List<int>? categoryIds; // e.g., [1, 2, 3] - for API submission
  final Map<String, double>?
  categoryAmounts; // e.g., {"1": 500.0, "2": 600.0} - key is category ID as string
  /// Spot registration fee per category (same key style as [categoryAmounts]).
  final Map<String, double>? categorySpotAmounts;
  /// Per-category: when true, amount already includes gateway/platform fees.
  final Map<String, bool>? categoryExtraFeeIncluded;
  final List<String>? stages; // e.g., ["A", "B", "C"] - for display/parsing
  final List<int>? stageIds; // e.g., [1, 2, 3] - for API submission
  final Map<String, List<int>>?
  stageGroups; // e.g., {"1": [1, 2], "2": [3, 4]} - key is stage ID as string, value is list of group IDs
  /// Display map from API `stageGroups`: stage name -> group names.
  final Map<String, List<String>>? stageGroupLabels;
  final String? brochureUrl;
  final String? registrationUrl;
  /// SEPARATE_CATEGORY or FROM_FIRST_PLACE_WINNERS
  final String? championshipStyle;
  /// ONLINE or OFFLINE
  final String? competitionMode;
  /// Organizer Google Drive folder link for participant video uploads.
  final String? googleDriveFolderUrl;
  final String? googleDriveFolderId;
  final String? googleDriveServiceAccountEmail;
  final bool googleDriveConfigured;
  final List<CompetitionCategoryConfigModel>? categoryConfigs;
  final List<CompetitionGradeModel>? grades;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;

  CompetitionModel({
    this.id,
    required this.competitionName,
    required this.description,
    required this.address,
    required this.eventStartDate,
    this.eventStartTime,
    required this.eventEndDate,
    this.eventEndTime,
    this.publishResultNow = false,
    this.resultsPublishDate,
    this.resultsPublishTime,
    this.displayAdFrom,
    this.spotRegistration = false,
    this.participantsPerStage,
    this.minimumMarks,
    this.maximumMarks,
    this.skippedAsanaMarks,
    this.bestSchoolAwardMinParticipants,
    this.prizes,
    this.prizeIds,
    this.categories,
    this.categoryIds,
    this.categoryAmounts,
    this.categorySpotAmounts,
    this.categoryExtraFeeIncluded,
    this.stages,
    this.stageIds,
    this.stageGroups,
    this.stageGroupLabels,
    this.brochureUrl,
    this.registrationUrl,
    this.championshipStyle,
    this.competitionMode,
    this.googleDriveFolderUrl,
    this.googleDriveFolderId,
    this.googleDriveServiceAccountEmail,
    this.googleDriveConfigured = false,
    this.categoryConfigs,
    this.grades,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  static String? formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return null;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static TimeOfDay? parseTime(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parts = value.trim().split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static bool parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().trim().toLowerCase();
    if (normalized.isEmpty) return defaultValue;
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  static bool? parseNullableBool(dynamic value) {
    if (value == null) return null;
    return parseBool(value);
  }

  static Map<String, bool> parseCategoryExtraFeeIncludedMap(dynamic raw) {
    if (raw is! Map) return {};
    final result = <String, bool>{};
    for (final entry in raw.entries) {
      final parsed = parseNullableBool(entry.value);
      if (parsed != null) {
        result[entry.key.toString()] = parsed;
      }
    }
    return result;
  }

  /// Handles null API values and hot-reload instances missing newer bool fields.
  bool get resolvedPublishResultNow {
    try {
      return parseBool(publishResultNow);
    } catch (_) {
      return false;
    }
  }

  bool get resolvedSpotRegistration {
    try {
      return parseBool(spotRegistration);
    } catch (_) {
      return false;
    }
  }

  static Map<String, List<String>>? _parseStageGroupLabelMap(dynamic raw) {
    if (raw is! Map) return null;
    final result = <String, List<String>>{};
    for (final entry in raw.entries) {
      final values = entry.value;
      if (values is! List || values.isEmpty) continue;
      final labels = <String>[];
      var hasNonNumericLabel = false;
      for (final item in values) {
        if (item is String) {
          final text = item.trim();
          if (text.isEmpty) continue;
          labels.add(text);
          hasNonNumericLabel = true;
        } else if (item is! int && int.tryParse(item.toString()) == null) {
          final text = item.toString().trim();
          if (text.isNotEmpty) {
            labels.add(text);
            hasNonNumericLabel = true;
          }
        }
      }
      if (hasNonNumericLabel && labels.isNotEmpty) {
        result[entry.key.toString()] = labels;
      }
    }
    return result.isEmpty ? null : result;
  }

  static DateTime _parseEventDate(dynamic raw, {required DateTime fallback}) {
    if (raw == null) return fallback;
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return fallback;
      return DateTime.parse(trimmed);
    }
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    return fallback;
  }

  static DateTime? _parseOptionalEventDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      return DateTime.tryParse(trimmed);
    }
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    return null;
  }

  static String? _timeFromDateTime(DateTime? value) {
    if (value == null) return null;
    if (value.hour == 0 && value.minute == 0 && value.second == 0) {
      return null;
    }
    return formatTimeOfDay(TimeOfDay(hour: value.hour, minute: value.minute));
  }

  factory CompetitionModel.fromJson(Map<String, dynamic> json) {
    final startDatetimeRaw =
        json['eventStartDatetime'] ?? json['event_start_datetime'];
    final endDatetimeRaw = json['eventEndDatetime'] ?? json['event_end_datetime'];
    final resultsPublishDatetimeRaw =
        json['resultsPublishDatetime'] ?? json['results_publish_datetime'];
    final parsedStartDatetime = startDatetimeRaw != null
        ? _parseEventDate(startDatetimeRaw, fallback: DateTime.now())
        : null;
    final parsedEndDatetime = endDatetimeRaw != null
        ? _parseEventDate(endDatetimeRaw, fallback: DateTime.now())
        : null;
    final parsedResultsPublishDatetime = resultsPublishDatetimeRaw != null
        ? _parseOptionalEventDate(resultsPublishDatetimeRaw)
        : null;

    return CompetitionModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      competitionName:
          json['competitionName']?.toString() ??
          json['competition_name']?.toString() ??
          '',
      description: json['description']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      eventStartDate: parsedStartDatetime ??
          _parseEventDate(
            json['eventStartDate'] ?? json['event_start_date'],
            fallback: DateTime.now(),
          ),
      eventEndDate: parsedEndDatetime ??
          _parseEventDate(
            json['eventEndDate'] ?? json['event_end_date'],
            fallback: DateTime.now(),
          ),
      eventStartTime: _timeFromDateTime(parsedStartDatetime) ??
          json['eventStartTime']?.toString() ??
          json['event_start_time']?.toString(),
      eventEndTime: _timeFromDateTime(parsedEndDatetime) ??
          json['eventEndTime']?.toString() ??
          json['event_end_time']?.toString(),
      publishResultNow: parseBool(
        json['publishResultNow'] ?? json['publish_result_now'],
      ),
      resultsPublishDate: _parseOptionalEventDate(
            json['resultsPublishDate'] ?? json['results_publish_date'],
          ) ??
          (parsedResultsPublishDatetime != null
              ? DateTime(
                  parsedResultsPublishDatetime.year,
                  parsedResultsPublishDatetime.month,
                  parsedResultsPublishDatetime.day,
                )
              : null),
      resultsPublishTime: _timeFromDateTime(parsedResultsPublishDatetime) ??
          json['resultsPublishTime']?.toString() ??
          json['results_publish_time']?.toString(),
      displayAdFrom: json['displayAdFrom'] != null
          ? (json['displayAdFrom'] is String
                ? DateTime.parse(json['displayAdFrom'])
                : json['displayAdFrom'] is int
                ? DateTime.fromMillisecondsSinceEpoch(json['displayAdFrom'])
                : null)
          : json['display_ad_from'] != null
          ? (json['display_ad_from'] is String
                ? DateTime.parse(json['display_ad_from'])
                : null)
          : null,
      spotRegistration: parseBool(
        json['spotRegistration'] ?? json['spot_registration'],
      ),
      participantsPerStage:
          json['participantsPerStage'] ?? json['participants_per_stage'],
      minimumMarks: json['minimumMarks'] ?? json['minimum_marks'],
      maximumMarks: json['maximumMarks'] ?? json['maximum_marks'],
      skippedAsanaMarks:
          json['skippedAsanaMarks'] ?? json['skipped_asana_marks'],
      bestSchoolAwardMinParticipants:
          json['bestSchoolAwardMinParticipants'] ??
          json['best_school_award_min_participants'],
      prizes: json['prizes'] != null ? List<String>.from(json['prizes']) : null,
      prizeIds: json['prizeIds'] != null
          ? (json['prizeIds'] as List)
                .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
                .where((e) => e > 0)
                .toList()
          : null,
      categories: json['categories'] != null
          ? List<String>.from(json['categories'])
          : null,
      categoryIds: json['categoryIds'] != null
          ? (json['categoryIds'] as List)
                .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
                .where((e) => e > 0)
                .toList()
          : null,
      stages: json['stages'] != null ? List<String>.from(json['stages']) : null,
      stageIds: json['stageIds'] != null
          ? (json['stageIds'] as List)
                .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
                .where((e) => e > 0)
                .toList()
          : null,
      stageGroups: json['stageGroupsById'] != null
          ? Map<String, List<int>>.from(
              (json['stageGroupsById'] as Map).map(
                (key, value) => MapEntry(
                  key.toString(),
                  value is List
                      ? value
                            .map(
                              (e) => e is int
                                  ? e
                                  : int.tryParse(e.toString()) ?? 0,
                            )
                            .where((e) => e > 0)
                            .toList()
                      : [],
                ),
              ),
            )
          : json['stageGroups'] != null
          ? Map<String, List<int>>.from(
              (json['stageGroups'] as Map).map(
                (key, value) => MapEntry(
                  key.toString(),
                  value is List
                      ? value
                            .map(
                              (e) => e is int
                                  ? e
                                  : int.tryParse(e.toString()) ?? 0,
                            )
                            .where((e) => e > 0)
                            .toList()
                      : [],
                ),
              ),
            )
          : json['stage_groups'] != null
          ? Map<String, List<int>>.from(
              (json['stage_groups'] as Map).map(
                (key, value) => MapEntry(
                  key.toString(),
                  value is List
                      ? value
                            .map((e) {
                              // Handle both string and int values
                              if (e is int) return e;
                              if (e is String) {
                                // Try to parse as int, if fails return 0
                                return int.tryParse(e) ?? 0;
                              }
                              return int.tryParse(e.toString()) ?? 0;
                            })
                            .where((e) => e > 0)
                            .toList()
                      : [],
                ),
              ),
            )
          : null,
      stageGroupLabels: _parseStageGroupLabelMap(json['stageGroups']),
      categoryAmounts: json['categoryAmounts'] != null
          ? Map<String, double>.from(
              (json['categoryAmounts'] as Map).map(
                (key, value) => MapEntry(
                  key.toString(),
                  (value is num)
                      ? value.toDouble()
                      : double.tryParse(value.toString()) ?? 0.0,
                ),
              ),
            )
          : json['category_amounts'] != null
          ? Map<String, double>.from(
              (json['category_amounts'] as Map).map(
                (key, value) => MapEntry(
                  key.toString(),
                  (value is num)
                      ? value.toDouble()
                      : double.tryParse(value.toString()) ?? 0.0,
                ),
              ),
            )
          : null,
      categorySpotAmounts: json['categorySpotAmounts'] != null
          ? Map<String, double>.from(
              (json['categorySpotAmounts'] as Map).map(
                (key, value) => MapEntry(
                  key.toString(),
                  (value is num)
                      ? value.toDouble()
                      : double.tryParse(value.toString()) ?? 0.0,
                ),
              ),
            )
          : json['categorySpotAmountsById'] != null
          ? Map<String, double>.from(
              (json['categorySpotAmountsById'] as Map).map(
                (key, value) => MapEntry(
                  key.toString(),
                  (value is num)
                      ? value.toDouble()
                      : double.tryParse(value.toString()) ?? 0.0,
                ),
              ),
            )
          : null,
      categoryExtraFeeIncluded: parseCategoryExtraFeeIncludedMap(
        json['categoryExtraFeeIncluded'] ??
            json['categoryExtraFeeIncludedById'] ??
            json['category_extra_fee_included'],
      ).isEmpty
          ? null
          : parseCategoryExtraFeeIncludedMap(
              json['categoryExtraFeeIncluded'] ??
                  json['categoryExtraFeeIncludedById'] ??
                  json['category_extra_fee_included'],
            ),
      brochureUrl:
          json['brochureUrl']?.toString() ?? json['brochure_url']?.toString(),
      registrationUrl: json['registrationUrl']?.toString(),
      championshipStyle:
          json['championshipStyle']?.toString() ??
          json['championship_style']?.toString(),
      competitionMode:
          json['competitionMode']?.toString() ??
          json['competition_mode']?.toString() ??
          'OFFLINE',
      googleDriveFolderUrl:
          json['googleDriveFolderUrl']?.toString() ??
          json['google_drive_folder_url']?.toString(),
      googleDriveFolderId:
          json['googleDriveFolderId']?.toString() ??
          json['google_drive_folder_id']?.toString(),
      googleDriveServiceAccountEmail:
          json['googleDriveServiceAccountEmail']?.toString(),
      googleDriveConfigured: parseBool(json['googleDriveConfigured']),
      categoryConfigs: json['categoryConfigs'] != null
          ? (json['categoryConfigs'] as List)
                .whereType<Map>()
                .map(
                  (item) => CompetitionCategoryConfigModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : null,
      grades: json['grades'] != null
          ? (json['grades'] as List)
                .whereType<Map>()
                .map(
                  (item) => CompetitionGradeModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : null,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is String
                ? DateTime.parse(json['createdAt'])
                : json['createdAt'] is int
                ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
                : null)
          : null,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is String
                ? DateTime.parse(json['updatedAt'])
                : json['updatedAt'] is int
                ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
                : null)
          : null,
      createdBy: json['createdBy']?.toString(),
      updatedBy: json['updatedBy']?.toString(),
    );
  }

  Map<String, dynamic> toJson({bool includeMetadata = false}) {
    String formatDate(DateTime date) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

    return {
      if (id != null && includeMetadata) 'id': id,
      'competitionName': competitionName,
      'description': description,
      'address': address,
      'eventStartDate': formatDate(eventStartDate),
      if (eventStartTime != null && eventStartTime!.trim().isNotEmpty)
        'eventStartTime': eventStartTime,
      'eventEndDate': formatDate(eventEndDate),
      if (eventEndTime != null && eventEndTime!.trim().isNotEmpty)
        'eventEndTime': eventEndTime,
      'publishResultNow': publishResultNow,
      if (resultsPublishDate != null)
        'resultsPublishDate': formatDate(resultsPublishDate!),
      if (resultsPublishTime != null && resultsPublishTime!.trim().isNotEmpty)
        'resultsPublishTime': resultsPublishTime,
      if (displayAdFrom != null) 'displayAdFrom': formatDate(displayAdFrom!),
      'spotRegistration': spotRegistration,
      if (participantsPerStage != null)
        'participantsPerStage': participantsPerStage,
      if (minimumMarks != null) 'minimumMarks': minimumMarks,
      if (maximumMarks != null) 'maximumMarks': maximumMarks,
      if (skippedAsanaMarks != null) 'skippedAsanaMarks': skippedAsanaMarks,
      'bestSchoolAwardMinParticipants': bestSchoolAwardMinParticipants,
      // Send IDs for API submission
      if (prizeIds != null && prizeIds!.isNotEmpty) 'prizeIds': prizeIds,
      if (categoryIds != null && categoryIds!.isNotEmpty)
        'categoryIds': categoryIds,
      if (categoryAmounts != null && categoryAmounts!.isNotEmpty)
        'categoryAmounts': categoryAmounts,
      if (categorySpotAmounts != null && categorySpotAmounts!.isNotEmpty)
        'categorySpotAmounts': categorySpotAmounts,
      if (categoryExtraFeeIncluded != null &&
          categoryExtraFeeIncluded!.isNotEmpty)
        'categoryExtraFeeIncluded': categoryExtraFeeIncluded,
      if (stageIds != null && stageIds!.isNotEmpty) 'stageIds': stageIds,
      if (stageGroups != null && stageGroups!.isNotEmpty)
        'stageGroups': stageGroups,
      if (championshipStyle != null && championshipStyle!.trim().isNotEmpty)
        'championshipStyle': championshipStyle!.trim(),
      if (competitionMode != null && competitionMode!.trim().isNotEmpty)
        'competitionMode': competitionMode!.trim(),
      'googleDriveFolderUrl': googleDriveFolderUrl?.trim() ?? '',
      if (categoryConfigs != null && categoryConfigs!.isNotEmpty)
        'categoryConfigs':
            categoryConfigs!.map((c) => c.toJson()).toList(),
      'grades': (grades ?? const <CompetitionGradeModel>[])
          .map((grade) => grade.toJson())
          .toList(),
      // Also include names for backward compatibility/display
      if (prizes != null && prizes!.isNotEmpty && includeMetadata)
        'prizes': prizes,
      if (categories != null && categories!.isNotEmpty && includeMetadata)
        'categories': categories,
      if (stages != null && stages!.isNotEmpty && includeMetadata)
        'stages': stages,
      if (brochureUrl != null && includeMetadata) 'brochureUrl': brochureUrl,
      if (includeMetadata && createdAt != null)
        'createdAt': createdAt!.toIso8601String(),
      if (includeMetadata && updatedAt != null)
        'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  CompetitionModel copyWith({
    String? id,
    String? competitionName,
    String? description,
    String? address,
    DateTime? eventStartDate,
    String? eventStartTime,
    DateTime? eventEndDate,
    String? eventEndTime,
    bool? publishResultNow,
    DateTime? resultsPublishDate,
    String? resultsPublishTime,
    DateTime? displayAdFrom,
    bool? spotRegistration,
    int? participantsPerStage,
    int? minimumMarks,
    int? maximumMarks,
    int? skippedAsanaMarks,
    int? bestSchoolAwardMinParticipants,
    List<String>? prizes,
    List<int>? prizeIds,
    List<String>? categories,
    List<int>? categoryIds,
    Map<String, double>? categoryAmounts,
    Map<String, double>? categorySpotAmounts,
    Map<String, bool>? categoryExtraFeeIncluded,
    List<String>? stages,
    List<int>? stageIds,
    Map<String, List<int>>? stageGroups,
    Map<String, List<String>>? stageGroupLabels,
    String? brochureUrl,
    String? registrationUrl,
    String? championshipStyle,
    String? competitionMode,
    String? googleDriveFolderUrl,
    String? googleDriveFolderId,
    String? googleDriveServiceAccountEmail,
    bool? googleDriveConfigured,
    List<CompetitionCategoryConfigModel>? categoryConfigs,
    List<CompetitionGradeModel>? grades,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return CompetitionModel(
      id: id ?? this.id,
      competitionName: competitionName ?? this.competitionName,
      description: description ?? this.description,
      address: address ?? this.address,
      eventStartDate: eventStartDate ?? this.eventStartDate,
      eventStartTime: eventStartTime ?? this.eventStartTime,
      eventEndDate: eventEndDate ?? this.eventEndDate,
      eventEndTime: eventEndTime ?? this.eventEndTime,
      publishResultNow: publishResultNow ?? resolvedPublishResultNow,
      resultsPublishDate: resultsPublishDate ?? this.resultsPublishDate,
      resultsPublishTime: resultsPublishTime ?? this.resultsPublishTime,
      displayAdFrom: displayAdFrom ?? this.displayAdFrom,
      spotRegistration: spotRegistration ?? resolvedSpotRegistration,
      participantsPerStage: participantsPerStage ?? this.participantsPerStage,
      minimumMarks: minimumMarks ?? this.minimumMarks,
      maximumMarks: maximumMarks ?? this.maximumMarks,
      skippedAsanaMarks: skippedAsanaMarks ?? this.skippedAsanaMarks,
      bestSchoolAwardMinParticipants: bestSchoolAwardMinParticipants ??
          this.bestSchoolAwardMinParticipants,
      prizes: prizes ?? this.prizes,
      prizeIds: prizeIds ?? this.prizeIds,
      categories: categories ?? this.categories,
      categoryIds: categoryIds ?? this.categoryIds,
      categoryAmounts: categoryAmounts ?? this.categoryAmounts,
      categorySpotAmounts: categorySpotAmounts ?? this.categorySpotAmounts,
      categoryExtraFeeIncluded:
          categoryExtraFeeIncluded ?? this.categoryExtraFeeIncluded,
      stages: stages ?? this.stages,
      stageIds: stageIds ?? this.stageIds,
      stageGroups: stageGroups ?? this.stageGroups,
      stageGroupLabels: stageGroupLabels ?? this.stageGroupLabels,
      brochureUrl: brochureUrl ?? this.brochureUrl,
      registrationUrl: registrationUrl ?? this.registrationUrl,
      championshipStyle: championshipStyle ?? this.championshipStyle,
      competitionMode: competitionMode ?? this.competitionMode,
      googleDriveFolderUrl: googleDriveFolderUrl ?? this.googleDriveFolderUrl,
      googleDriveFolderId: googleDriveFolderId ?? this.googleDriveFolderId,
      googleDriveServiceAccountEmail:
          googleDriveServiceAccountEmail ?? this.googleDriveServiceAccountEmail,
      googleDriveConfigured:
          googleDriveConfigured ?? this.googleDriveConfigured,
      categoryConfigs: categoryConfigs ?? this.categoryConfigs,
      grades: grades ?? this.grades,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  /// Whether [date] (calendar day) falls within [eventStartDate]..[eventEndDate].
  bool containsEventDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final start = DateTime(
      eventStartDate.year,
      eventStartDate.month,
      eventStartDate.day,
    );
    final end = DateTime(
      eventEndDate.year,
      eventEndDate.month,
      eventEndDate.day,
    );
    return !day.isBefore(start) && !day.isAfter(end);
  }

  /// True when today's date is on or between event start and end (inclusive).
  bool get isEventOngoing => containsEventDate(DateTime.now());

  /// Event end as a single [DateTime] (uses [eventEndTime] when set, else end of day).
  DateTime get eventEndDateTime {
    final endTime = parseTime(eventEndTime);
    if (endTime != null) {
      return DateTime(
        eventEndDate.year,
        eventEndDate.month,
        eventEndDate.day,
        endTime.hour,
        endTime.minute,
      );
    }
    return DateTime(
      eventEndDate.year,
      eventEndDate.month,
      eventEndDate.day,
      23,
      59,
      59,
    );
  }

  /// Scheduled results publish as a single [DateTime] (uses event end date when date unset).
  DateTime? get resultsPublishDateTime {
    if (resolvedPublishResultNow) return null;
    final publishTime = parseTime(resultsPublishTime);
    if (publishTime == null) return null;
    final date = resultsPublishDate ?? eventEndDate;
    return DateTime(
      date.year,
      date.month,
      date.day,
      publishTime.hour,
      publishTime.minute,
    );
  }

  /// E-certificates may be downloaded when results are published early or the scheduled time has passed.
  bool get areCertificatesAvailable {
    if (resolvedPublishResultNow) return true;
    final publishAt = resultsPublishDateTime;
    if (publishAt != null) {
      return !DateTime.now().isBefore(publishAt);
    }
    return !DateTime.now().isBefore(eventEndDateTime);
  }
}

/// Lightweight model for public competition list (home screen).
/// Matches GET /competition/public response.
class HomeCompetitionModel {
  final int? id;
  final String competitionName;
  final String description;
  final String address;
  final String? eventStartDate;
  final String? eventEndDate;
  final String? eventEndTime;
  final bool publishResultNow;
  final String? resultsPublishDate;
  final String? resultsPublishTime;
  final String? displayAdFrom;
  final List<String> categories;
  final Map<String, double> categoryAmounts;
  /// Per-category Online/Offline rows from the public competition API.
  final List<CategoryModeSummary> categoryModes;
  final Map<String, bool> categoryExtraFeeIncluded;
  final String? brochureUrl;
  final String? brochureFilePath;
  final String status;
  final String? registrationUrl;
  final String? participantsUrl;
  final String? paymentModel;
  final List<String> allowedPaymentModes;
  final String? manualPaymentUpiId;
  final String? manualPaymentQrUrl;
  final bool maintenanceFeePaid;
  final bool registrationOpen;

  HomeCompetitionModel({
    this.id,
    required this.competitionName,
    this.description = '',
    this.address = '',
    this.eventStartDate,
    this.eventEndDate,
    this.eventEndTime,
    this.publishResultNow = false,
    this.resultsPublishDate,
    this.resultsPublishTime,
    this.displayAdFrom,
    this.categories = const [],
    this.categoryAmounts = const {},
    this.categoryModes = const [],
    this.categoryExtraFeeIncluded = const {},
    this.brochureUrl,
    this.brochureFilePath,
    this.status = 'upcoming',
    this.registrationUrl,
    this.participantsUrl,
    this.paymentModel,
    this.allowedPaymentModes = const [],
    this.manualPaymentUpiId,
    this.manualPaymentQrUrl,
    this.maintenanceFeePaid = true,
    this.registrationOpen = true,
  });

  bool get isPayPerParticipant => paymentModel == 'PAY_PER_PARTICIPANT';
  bool get isManualPaymentModel =>
      paymentModel == 'ORG_SUBSCRIPTION' ||
      paymentModel == 'USER_PACK_SUBSCRIPTION';

  factory HomeCompetitionModel.fromJson(Map<String, dynamic> json) {
    Map<String, double> amounts = {};
    if (json['categoryAmounts'] != null && json['categoryAmounts'] is Map) {
      for (final e in (json['categoryAmounts'] as Map).entries) {
        final v = e.value;
        amounts[e.key.toString()] = v is int
            ? v.toDouble()
            : (v is double ? v : double.tryParse(v.toString()) ?? 0);
      }
    }
    return HomeCompetitionModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      competitionName: json['competitionName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      eventStartDate: json['eventStartDate']?.toString(),
      eventEndDate: json['eventEndDate']?.toString(),
      eventEndTime:
          json['eventEndTime']?.toString() ?? json['event_end_time']?.toString(),
      publishResultNow: CompetitionModel.parseBool(
        json['publishResultNow'] ?? json['publish_result_now'],
      ),
      resultsPublishDate: json['resultsPublishDate']?.toString() ??
          json['results_publish_date']?.toString(),
      resultsPublishTime: json['resultsPublishTime']?.toString() ??
          json['results_publish_time']?.toString(),
      displayAdFrom: json['displayAdFrom']?.toString(),
      categories: json['categories'] != null
          ? List<String>.from(json['categories'])
          : [],
      categoryAmounts: amounts,
      categoryModes: CategoryModeSummary.listFromJson(json['categoryModes']),
      categoryExtraFeeIncluded: CompetitionModel.parseCategoryExtraFeeIncludedMap(
        json['categoryExtraFeeIncluded'] ??
            json['categoryExtraFeeIncludedById'] ??
            json['category_extra_fee_included'],
      ),
      brochureUrl: json['brochureUrl']?.toString(),
      brochureFilePath: json['brochureFilePath']?.toString(),
      status: json['status']?.toString() ?? 'upcoming',
      registrationUrl: json['registrationUrl']?.toString(),
      participantsUrl: json['participantsUrl']?.toString(),
      paymentModel: json['paymentModel']?.toString(),
      allowedPaymentModes: json['allowedPaymentModes'] != null
          ? List<String>.from(json['allowedPaymentModes'])
          : const [],
      manualPaymentUpiId: json['manualPaymentUpiId']?.toString(),
      manualPaymentQrUrl: json['manualPaymentQrUrl']?.toString(),
      maintenanceFeePaid: json['maintenanceFeePaid'] == true,
      registrationOpen: json['registrationOpen'] != false,
    );
  }

  String? get idStr => id?.toString();

  DateTime? get eventEndDateTime {
    final endDateRaw = eventEndDate?.trim();
    if (endDateRaw == null || endDateRaw.isEmpty) return null;
    final parsedDate = DateTime.tryParse(endDateRaw);
    if (parsedDate == null) return null;

    final endTime = CompetitionModel.parseTime(eventEndTime);
    if (endTime != null) {
      return DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        endTime.hour,
        endTime.minute,
      );
    }
    return DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      23,
      59,
      59,
    );
  }

  DateTime? get resultsPublishDateTime {
    if (publishResultNow) return null;
    final publishTime = CompetitionModel.parseTime(resultsPublishTime);
    if (publishTime == null) return null;
    final dateRaw = resultsPublishDate?.trim().isNotEmpty == true
        ? resultsPublishDate
        : eventEndDate;
    if (dateRaw == null || dateRaw.trim().isEmpty) return null;
    final parsedDate = DateTime.tryParse(dateRaw);
    if (parsedDate == null) return null;
    return DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      publishTime.hour,
      publishTime.minute,
    );
  }

  /// E-certificates are available after scheduled publish time or when results are published early.
  bool get areCertificatesAvailable {
    if (publishResultNow) return true;
    final publishAt = resultsPublishDateTime;
    if (publishAt != null) {
      return !DateTime.now().isBefore(publishAt);
    }
    final end = eventEndDateTime;
    if (end != null) {
      return !DateTime.now().isBefore(end);
    }
    return status.toLowerCase() == 'completed';
  }

  /// Alias used by competition cards navigating to the public participants list.
  bool get areResultsAvailable => areCertificatesAvailable;
}

class CategoryModeSummary {
  final String categoryName;
  final String mode;
  final double feeAmount;
  final double spotFeeAmount;

  const CategoryModeSummary({
    required this.categoryName,
    required this.mode,
    this.feeAmount = 0,
    this.spotFeeAmount = 0,
  });

  bool get isOnline => mode.toUpperCase() == 'ONLINE';

  double get displayFee {
    if (isOnline) return feeAmount;
    return spotFeeAmount > 0 ? spotFeeAmount : feeAmount;
  }

  factory CategoryModeSummary.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return CategoryModeSummary(
      categoryName: json['categoryName']?.toString() ?? '',
      mode: json['mode']?.toString() ?? 'OFFLINE',
      feeAmount: parseAmount(json['feeAmount']),
      spotFeeAmount: parseAmount(json['spotFeeAmount']),
    );
  }

  static List<CategoryModeSummary> listFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => CategoryModeSummary.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.categoryName.trim().isNotEmpty)
        .toList();
  }
}
