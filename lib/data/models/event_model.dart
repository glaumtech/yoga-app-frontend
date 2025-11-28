import '../../core/constants/app_constants.dart' as constants;

class EventModel {
  final String? id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String venue;
  final String? venueAddress;
  final List<String> categories;
  final List<String> ageGroups;
  final Map<String, dynamic>? rules;
  final bool active;
  final bool current;
  final int? maxParticipants;
  final DateTime? registrationDeadline;
  final String? bannerUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  EventModel({
    this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.venue,
    this.venueAddress,
    this.categories = const [],
    this.ageGroups = const [],
    this.rules,
    this.active = true,
    this.current = false,
    this.maxParticipants,
    this.registrationDeadline,
    this.bannerUrl,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      startDate: json['startDate'] != null
          ? (json['startDate'] is String
                ? DateTime.parse(json['startDate'])
                : json['startDate'] is int
                ? DateTime.fromMillisecondsSinceEpoch(json['startDate'])
                : DateTime.now())
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? (json['endDate'] is String
                ? DateTime.parse(json['endDate'])
                : json['endDate'] is int
                ? DateTime.fromMillisecondsSinceEpoch(json['endDate'])
                : DateTime.now())
          : DateTime.now(),
      venue: json['venue']?.toString() ?? '',
      venueAddress: json['venueAddress']?.toString() ?? json['venue_address'],
      categories: json['categories'] != null
          ? List<String>.from(json['categories'])
          : [],
      ageGroups: json['ageGroups'] != null
          ? List<String>.from(json['ageGroups'])
          : json['age_groups'] != null
          ? List<String>.from(json['age_groups'])
          : [],
      rules: json['rules'] != null
          ? Map<String, dynamic>.from(json['rules'])
          : null,
      active: json['active'] ?? json['isActive'] ?? json['is_active'] ?? true,
      current:
          json['current'] ?? json['isCurrent'] ?? json['is_current'] ?? false,
      maxParticipants: json['maxParticipants'] ?? json['max_participants'],
      bannerUrl:
          json['bannerUrl']?.toString() ?? json['banner_url']?.toString(),
      registrationDeadline: json['registrationDeadline'] != null
          ? (json['registrationDeadline'] is String
                ? DateTime.parse(json['registrationDeadline'])
                : json['registrationDeadline'] is int
                ? DateTime.fromMillisecondsSinceEpoch(
                    json['registrationDeadline'],
                  )
                : null)
          : null,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is String
                ? DateTime.parse(json['createdAt'])
                : json['createdAt'] is int
                ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
                : DateTime.now())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is String
                ? DateTime.parse(json['updatedAt'])
                : json['updatedAt'] is int
                ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
                : null)
          : null,
    );
  }

  Map<String, dynamic> toJson({bool includeMetadata = false}) {
    // Format date as YYYY-MM-DD for API
    String formatDate(DateTime date) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

    return {
      if (id != null && includeMetadata) 'id': id,
      'title': title,
      'description': description,
      'startDate': formatDate(startDate),
      'endDate': formatDate(endDate),
      'venue': venue,
      if (venueAddress != null) 'venueAddress': venueAddress,
      if (categories.isNotEmpty) 'categories': categories,
      if (ageGroups.isNotEmpty) 'ageGroups': ageGroups,
      if (rules != null) 'rules': rules,
      'active': active,
      'current': current,
      if (maxParticipants != null) 'maxParticipants': maxParticipants,
      if (bannerUrl != null && includeMetadata) 'bannerUrl': bannerUrl,
      if (registrationDeadline != null)
        'registrationDeadline': formatDate(registrationDeadline!),
      if (includeMetadata) 'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null && includeMetadata)
        'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? venue,
    String? venueAddress,
    List<String>? categories,
    List<String>? ageGroups,
    Map<String, dynamic>? rules,
    bool? active,
    bool? current,
    int? maxParticipants,
    DateTime? registrationDeadline,
    String? bannerUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      venue: venue ?? this.venue,
      venueAddress: venueAddress ?? this.venueAddress,
      categories: categories ?? this.categories,
      ageGroups: ageGroups ?? this.ageGroups,
      rules: rules ?? this.rules,
      active: active ?? this.active,
      current: current ?? this.current,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get banner image URL using event ID
  /// Returns the API endpoint URL for the event banner image
  String? getBannerImageUrl() {
    if (id == null) return null;
    return '${constants.BaseUrl.baseUrl}${constants.EndPoints.eventImage(id!)}';
  }
}
