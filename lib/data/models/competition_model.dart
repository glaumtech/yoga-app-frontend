class CompetitionModel {
  final String? id;
  final String competitionName;
  final String description;
  final String address;
  final DateTime eventStartDate;
  final DateTime eventEndDate;
  final DateTime? displayAdFrom;
  final bool spotRegistration;
  final int? participantsPerStage; // 1-5
  final int? minimumMarks;
  final int? maximumMarks;
  final List<String>?
  prizes; // e.g., ["1st", "2nd", "3rd"] - for display/parsing
  final List<int>? prizeIds; // e.g., [1, 2, 3] - for API submission
  final List<String>?
  categories; // e.g., ["COMMON", "SPECIAL", "CHAMPIONS"] - for display/parsing
  final List<int>? categoryIds; // e.g., [1, 2, 3] - for API submission
  final Map<String, double>?
  categoryAmounts; // e.g., {"1": 500.0, "2": 600.0} - key is category ID as string
  final List<String>? stages; // e.g., ["A", "B", "C"] - for display/parsing
  final List<int>? stageIds; // e.g., [1, 2, 3] - for API submission
  final Map<String, List<int>>?
  stageGroups; // e.g., {"1": [1, 2], "2": [3, 4]} - key is stage ID as string, value is list of group IDs
  final String? brochureUrl;
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
    required this.eventEndDate,
    this.displayAdFrom,
    this.spotRegistration = false,
    this.participantsPerStage,
    this.minimumMarks,
    this.maximumMarks,
    this.prizes,
    this.prizeIds,
    this.categories,
    this.categoryIds,
    this.categoryAmounts,
    this.stages,
    this.stageIds,
    this.stageGroups,
    this.brochureUrl,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  factory CompetitionModel.fromJson(Map<String, dynamic> json) {
    return CompetitionModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      competitionName:
          json['competitionName']?.toString() ??
          json['competition_name']?.toString() ??
          '',
      description: json['description']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      eventStartDate: json['eventStartDate'] != null
          ? (json['eventStartDate'] is String
                ? DateTime.parse(json['eventStartDate'])
                : json['eventStartDate'] is int
                ? DateTime.fromMillisecondsSinceEpoch(json['eventStartDate'])
                : DateTime.now())
          : DateTime.now(),
      eventEndDate: json['eventEndDate'] != null
          ? (json['eventEndDate'] is String
                ? DateTime.parse(json['eventEndDate'])
                : json['eventEndDate'] is int
                ? DateTime.fromMillisecondsSinceEpoch(json['eventEndDate'])
                : DateTime.now())
          : DateTime.now(),
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
      spotRegistration:
          json['spotRegistration'] ?? json['spot_registration'] ?? false,
      participantsPerStage:
          json['participantsPerStage'] ?? json['participants_per_stage'],
      minimumMarks: json['minimumMarks'] ?? json['minimum_marks'],
      maximumMarks: json['maximumMarks'] ?? json['maximum_marks'],
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
      brochureUrl:
          json['brochureUrl']?.toString() ?? json['brochure_url']?.toString(),
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
      'eventEndDate': formatDate(eventEndDate),
      if (displayAdFrom != null) 'displayAdFrom': formatDate(displayAdFrom!),
      'spotRegistration': spotRegistration,
      if (participantsPerStage != null)
        'participantsPerStage': participantsPerStage,
      if (minimumMarks != null) 'minimumMarks': minimumMarks,
      if (maximumMarks != null) 'maximumMarks': maximumMarks,
      // Send IDs for API submission
      if (prizeIds != null && prizeIds!.isNotEmpty) 'prizeIds': prizeIds,
      if (categoryIds != null && categoryIds!.isNotEmpty)
        'categoryIds': categoryIds,
      if (categoryAmounts != null && categoryAmounts!.isNotEmpty)
        'categoryAmounts': categoryAmounts,
      if (stageIds != null && stageIds!.isNotEmpty) 'stageIds': stageIds,
      if (stageGroups != null && stageGroups!.isNotEmpty)
        'stageGroups': stageGroups,
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
    DateTime? eventEndDate,
    DateTime? displayAdFrom,
    bool? spotRegistration,
    int? participantsPerStage,
    int? minimumMarks,
    int? maximumMarks,
    List<String>? prizes,
    List<int>? prizeIds,
    List<String>? categories,
    List<int>? categoryIds,
    Map<String, double>? categoryAmounts,
    List<String>? stages,
    List<int>? stageIds,
    Map<String, List<int>>? stageGroups,
    String? brochureUrl,
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
      eventEndDate: eventEndDate ?? this.eventEndDate,
      displayAdFrom: displayAdFrom ?? this.displayAdFrom,
      spotRegistration: spotRegistration ?? this.spotRegistration,
      participantsPerStage: participantsPerStage ?? this.participantsPerStage,
      minimumMarks: minimumMarks ?? this.minimumMarks,
      maximumMarks: maximumMarks ?? this.maximumMarks,
      prizes: prizes ?? this.prizes,
      prizeIds: prizeIds ?? this.prizeIds,
      categories: categories ?? this.categories,
      categoryIds: categoryIds ?? this.categoryIds,
      categoryAmounts: categoryAmounts ?? this.categoryAmounts,
      stages: stages ?? this.stages,
      stageIds: stageIds ?? this.stageIds,
      stageGroups: stageGroups ?? this.stageGroups,
      brochureUrl: brochureUrl ?? this.brochureUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
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
  final String? displayAdFrom;
  final List<String> categories;
  final Map<String, double> categoryAmounts;
  final String? brochureUrl;
  final String? brochureFilePath;
  final String status;

  HomeCompetitionModel({
    this.id,
    required this.competitionName,
    this.description = '',
    this.address = '',
    this.eventStartDate,
    this.eventEndDate,
    this.displayAdFrom,
    this.categories = const [],
    this.categoryAmounts = const {},
    this.brochureUrl,
    this.brochureFilePath,
    this.status = 'upcoming',
  });

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
      displayAdFrom: json['displayAdFrom']?.toString(),
      categories: json['categories'] != null
          ? List<String>.from(json['categories'])
          : [],
      categoryAmounts: amounts,
      brochureUrl: json['brochureUrl']?.toString(),
      brochureFilePath: json['brochureFilePath']?.toString(),
      status: json['status']?.toString() ?? 'upcoming',
    );
  }

  String? get idStr => id?.toString();
}
