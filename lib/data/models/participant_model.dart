class ParticipantModel {
  final String? id;
  final String participantName;
  final DateTime dateOfBirth;
  final int age;
  final String gender; // 'Male' or 'Female'
  final String category; // 'Common' or 'Special'
  final String standard; // 'II, III', 'IV, V', etc.
  final String schoolName;
  final String address;
  final String yogaMasterName;
  final String yogaMasterContact;
  final String? photoUrl;
  final String? participantCode; // Participant code like 'MEM0006'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, double>?
  juryScores; // {'jury1': score, 'jury2': score, ...}
  final double? grandTotal;
  final String? status; // 'accepted', 'pending', 'rejected'
  final String? group; // Group/Standard value
  final Map<String, String>?
  categoryStatusMap; // {'common': 'Un Assigned', 'special': 'Scored'}
  final String? eventId; // Event ID

  ParticipantModel({
    this.id,
    required this.participantName,
    required this.dateOfBirth,
    required this.age,
    required this.gender,
    required this.category,
    required this.standard,
    required this.schoolName,
    required this.address,
    required this.yogaMasterName,
    required this.yogaMasterContact,
    this.photoUrl,
    this.participantCode,
    DateTime? createdAt,
    this.updatedAt,
    this.juryScores,
    this.grandTotal,
    this.status,
    this.group,
    this.categoryStatusMap,
    this.eventId,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse int
    int safeParseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }

    return ParticipantModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      participantName:
          (json['participantName'] ?? json['participant_name'])?.toString() ??
          '',
      dateOfBirth: () {
        final dateValue = json['dateOfBirth'] ?? json['date_of_birth'];
        if (dateValue == null) return DateTime.now();
        if (dateValue is String) return DateTime.parse(dateValue);
        if (dateValue is int)
          return DateTime.fromMillisecondsSinceEpoch(dateValue);
        return DateTime.now();
      }(),
      age: safeParseInt(json['age']),
      gender: (json['gender'] ?? json['gender'])?.toString() ?? '',
      category: (json['category'] ?? json['category'])?.toString() ?? '',
      standard: (json['standard'] ?? json['standard'])?.toString() ?? '',
      schoolName: (json['schoolName'] ?? json['school_name'])?.toString() ?? '',
      address: (json['address'] ?? json['address'])?.toString() ?? '',
      yogaMasterName:
          (json['yogaMasterName'] ?? json['yoga_master_name'])?.toString() ??
          '',
      yogaMasterContact:
          (json['yogaMasterContact'] ?? json['yoga_master_contact'])
              ?.toString() ??
          '',
      photoUrl: (json['photoUrl'] ?? json['photo_url'] ?? json['photo'])
          ?.toString(),
      participantCode: (json['participantCode'] ?? json['participant_code'])
          ?.toString(),
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
      juryScores: json['juryScores'] != null
          ? Map<String, double>.from(
              (json['juryScores'] as Map).map(
                (key, value) => MapEntry(
                  key.toString(),
                  (value is double
                      ? value
                      : (value is int ? value.toDouble() : 0.0)),
                ),
              ),
            )
          : null,
      grandTotal: json['grandTotal'] != null
          ? (json['grandTotal'] is double
                ? json['grandTotal']
                : json['grandTotal'] is int
                ? json['grandTotal'].toDouble()
                : double.tryParse(json['grandTotal'].toString()) ?? 0.0)
          : null,
      status: json['status']?.toString(),
      group: json['group']?.toString(),
      categoryStatusMap: json['categoryStatusMap'] != null
          ? Map<String, String>.from(
              (json['categoryStatusMap'] as Map).map(
                (key, value) =>
                    MapEntry(key.toString(), value?.toString() ?? ''),
              ),
            )
          : null,
      eventId: json['eventId']?.toString(),
    );
  }

  Map<String, dynamic> toJson({bool includeCreatedAt = false}) {
    return {
      if (id != null) 'id': id,
      'participantName': participantName,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'age': age,
      'gender': gender,
      'category': category,
      'standard': standard,
      'schoolName': schoolName,
      'address': address,
      'yogaMasterName': yogaMasterName,
      'yogaMasterContact': yogaMasterContact,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (participantCode != null) 'participantCode': participantCode,
      if (includeCreatedAt) 'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (juryScores != null) 'juryScores': juryScores,
      if (grandTotal != null) 'grandTotal': grandTotal,
      if (status != null) 'status': status,
      if (group != null) 'group': group,
      if (categoryStatusMap != null) 'categoryStatusMap': categoryStatusMap,
      if (eventId != null) 'eventId': eventId,
    };
  }

  ParticipantModel copyWith({
    String? id,
    String? participantName,
    DateTime? dateOfBirth,
    int? age,
    String? gender,
    String? category,
    String? standard,
    String? schoolName,
    String? address,
    String? yogaMasterName,
    String? yogaMasterContact,
    String? photoUrl,
    String? participantCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, double>? juryScores,
    double? grandTotal,
    String? status,
    String? group,
    Map<String, String>? categoryStatusMap,
    String? eventId,
  }) {
    return ParticipantModel(
      id: id ?? this.id,
      participantName: participantName ?? this.participantName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      category: category ?? this.category,
      standard: standard ?? this.standard,
      schoolName: schoolName ?? this.schoolName,
      address: address ?? this.address,
      yogaMasterName: yogaMasterName ?? this.yogaMasterName,
      yogaMasterContact: yogaMasterContact ?? this.yogaMasterContact,
      photoUrl: photoUrl ?? this.photoUrl,
      participantCode: participantCode ?? this.participantCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      juryScores: juryScores ?? this.juryScores,
      grandTotal: grandTotal ?? this.grandTotal,
      status: status ?? this.status,
      group: group ?? this.group,
      categoryStatusMap: categoryStatusMap ?? this.categoryStatusMap,
      eventId: eventId ?? this.eventId,
    );
  }

  double calculateGrandTotal() {
    if (juryScores == null || juryScores!.isEmpty) return 0.0;
    return juryScores!.values.fold(0.0, (sum, score) => sum + score);
  }
}

class ParticipantFilterRequest {
  // Top level pagination and sorting
  final int page;
  final int size;
  final String? sortBy;
  final String? sortDirection; // 'asc' or 'desc'

  // Nested filter object
  final String? participant; // matches participantName OR participantCode
  final String? status; // optional: Approved, Rejected, Requested, etc.
  final String? category; // optional: common, special
  final String? group; // optional: IV, V, etc. (standard/age group)
  final String? assignmentStatus; // optional

  ParticipantFilterRequest({
    this.page = 0,
    this.size = 10,
    this.sortBy = 'participantCode',
    this.sortDirection = 'desc',
    this.participant,
    this.status,
    this.category,
    this.group,
    this.assignmentStatus,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {'page': page, 'size': size};

    if (sortBy != null && sortBy!.isNotEmpty) {
      json['sortBy'] = sortBy;
    }
    if (sortDirection != null && sortDirection!.isNotEmpty) {
      json['sortDirection'] = sortDirection;
    }

    // Build nested filter object (always include, even if empty)
    final Map<String, dynamic> filterMap = {};
    if (participant != null && participant!.isNotEmpty) {
      filterMap['participant'] = participant;
    }
    if (status != null && status!.isNotEmpty) {
      filterMap['status'] = status;
    }
    if (category != null && category!.isNotEmpty) {
      filterMap['category'] = category;
    }
    if (group != null && group!.isNotEmpty) {
      filterMap['group'] = group;
    }
    if (assignmentStatus != null && assignmentStatus!.isNotEmpty) {
      filterMap['assignmentStatus'] = assignmentStatus;
    }

    // Always include filter object (even if empty)
    json['filter'] = filterMap;

    return json;
  }

  ParticipantFilterRequest copyWith({
    int? page,
    int? size,
    String? sortBy,
    String? sortDirection,
    String? participant,
    String? status,
    String? category,
    String? group,
    String? assignmentStatus,
  }) {
    return ParticipantFilterRequest(
      page: page ?? this.page,
      size: size ?? this.size,
      sortBy: sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
      participant: participant ?? this.participant,
      status: status ?? this.status,
      category: category ?? this.category,
      group: group ?? this.group,
      assignmentStatus: assignmentStatus ?? this.assignmentStatus,
    );
  }
}

class ParticipantFilterData {
  final List<ParticipantModel> participants;
  final int currentPage;
  final int totalItems;
  final int totalPages;

  ParticipantFilterData({
    required this.participants,
    required this.currentPage,
    required this.totalItems,
    required this.totalPages,
  });

  factory ParticipantFilterData.fromJson(Map<String, dynamic> json) {
    // Handle new response structure: data contains users, totalItems, totalPages, currentPage
    List<ParticipantModel> participantsList = [];

    // Check for 'users' field (new structure)
    if (json['users'] != null && json['users'] is List) {
      participantsList = (json['users'] as List)
          .map(
            (user) => ParticipantModel.fromJson(user as Map<String, dynamic>),
          )
          .toList();
    }
    // Check for 'data' field (if data is a list directly)
    else if (json['data'] != null && json['data'] is List) {
      participantsList = (json['data'] as List)
          .map(
            (user) => ParticipantModel.fromJson(user as Map<String, dynamic>),
          )
          .toList();
    }
    // Check for 'participants' field (legacy structure)
    else if (json['participants'] != null && json['participants'] is List) {
      participantsList = (json['participants'] as List)
          .map(
            (user) => ParticipantModel.fromJson(user as Map<String, dynamic>),
          )
          .toList();
    }

    return ParticipantFilterData(
      participants: participantsList,
      currentPage: json['currentPage'] ?? json['page'] ?? 0,
      totalItems: json['totalItems'] ?? json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }
}
