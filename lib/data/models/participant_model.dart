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

  /// Server storage path for bonafied certificate (e.g. certificates/abc.pdf).
  final String? bonafiedCertificate;
  final String? participantCode; // Participant code like 'MEM0006'
  final String? registrationNo; // Registration number like 'CGA001'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final Map<String, double>?
  juryScores; // {'jury1': score, 'jury2': score, ...}
  final double? grandTotal;
  final String? status; // 'accepted', 'pending', 'rejected'
  final String? group; // Group/Standard value
  final Map<String, String>?
  categoryStatusMap; // {'common': 'Un Assigned', 'special': 'Scored'}
  final String? eventId; // Event ID
  final bool isSpotRegistration;
  final bool optForECertificate;
  final int? stageId;
  final int? categoryId;
  final int? groupId;
  final String? paymentMode;
  final String? paymentProofPath;
  final String? paymentStatus;
  final double? amount;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? competitionName;
  final String? competitionAddress;
  final String? competitionEventDateDisplay;
  final String? competitionEventTimeDisplay;
  final String? venueMapsUrl;
  final String? venueMapPreviewUrl;

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
    this.bonafiedCertificate,
    this.participantCode,
    this.registrationNo,
    DateTime? createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.juryScores,
    this.grandTotal,
    this.status,
    this.group,
    this.categoryStatusMap,
    this.eventId,
    this.isSpotRegistration = false,
    this.optForECertificate = false,
    this.stageId,
    this.categoryId,
    this.groupId,
    this.paymentMode,
    this.paymentProofPath,
    this.paymentStatus,
    this.amount,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.competitionName,
    this.competitionAddress,
    this.competitionEventDateDisplay,
    this.competitionEventTimeDisplay,
    this.venueMapsUrl,
    this.venueMapPreviewUrl,
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
      yogaMasterName: (json['yogaMasterName'] ??
              json['yoga_master_name'] ??
              json['yogaTeacherName'])
          ?.toString() ??
          '',
      yogaMasterContact: (json['yogaMasterContact'] ??
              json['yoga_master_contact'] ??
              json['yogaTeacherCell'])
          ?.toString() ??
          '',
      photoUrl: (json['photoUrl'] ?? json['photo_url'] ?? json['photo'])
          ?.toString(),
      bonafiedCertificate:
          (json['bonafiedCertificate'] ??
                  json['bonafied_certificate'] ??
                  json['bonafideCertificate'])
              ?.toString(),
      participantCode: (json['participantCode'] ?? json['participant_code'])
          ?.toString(),
      registrationNo:
          (json['registrationNo'] ??
                  json['registration_no'] ??
                  json['registrationNumber'] ??
                  json['registration_number'])
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
      createdBy: json['createdBy']?.toString(),
      updatedBy: json['updatedBy']?.toString(),
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
      isSpotRegistration:
          _parseBool(json['isSpotRegistration']) ??
          _parseBool(json['is_spot_registration']) ??
          _parseBool(json['spotRegistration']) ??
          _parseBool(json['spot_registration']) ??
          false,
      optForECertificate:
          _parseBool(json['optForECertificate']) ??
          _parseBool(json['opt_for_e_certificate']) ??
          false,
      stageId: _parseInt(json['stageId'] ?? json['stage_id']),
      categoryId: _parseInt(json['categoryId'] ?? json['category_id']),
      groupId: _parseInt(json['groupId'] ?? json['group_id']),
      paymentMode: json['paymentMode']?.toString(),
      paymentProofPath: json['paymentProofPath']?.toString(),
      paymentStatus:
          (json['paymentStatus'] ?? json['payment_status'])?.toString(),
      amount: _parseAmount(json['amount']),
      razorpayOrderId: (json['razorpayOrderId'] ?? json['razorpay_order_id'])
          ?.toString(),
      razorpayPaymentId:
          (json['razorpayPaymentId'] ?? json['razorpay_payment_id'])
              ?.toString(),
      competitionName: json['competitionName']?.toString(),
      competitionAddress: json['competitionAddress']?.toString(),
      competitionEventDateDisplay:
          json['competitionEventDateDisplay']?.toString(),
      competitionEventTimeDisplay:
          json['competitionEventTimeDisplay']?.toString(),
      venueMapsUrl: json['venueMapsUrl']?.toString(),
      venueMapPreviewUrl: json['venueMapPreviewUrl']?.toString(),
    );
  }

  /// Maps `ParticipantRegistrationDto` from POST /participant-registration.
  factory ParticipantModel.fromRegistrationResponse(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    normalized.putIfAbsent('gender', () => normalized['sex']);
    normalized.putIfAbsent('category', () => normalized['categoryName']);
    normalized.putIfAbsent('standard', () => normalized['groupName']);
    normalized.putIfAbsent('schoolName', () => normalized['institutionName']);
    normalized.putIfAbsent(
      'yogaMasterName',
      () => normalized['yogaTeacherName'],
    );
    normalized.putIfAbsent(
      'yogaMasterContact',
      () => normalized['yogaTeacherCell'],
    );
    return ParticipantModel.fromJson(normalized);
  }

  static double? _parseAmount(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return null;
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
      if (bonafiedCertificate != null)
        'bonafiedCertificate': bonafiedCertificate,
      if (participantCode != null) 'participantCode': participantCode,
      if (registrationNo != null) 'registrationNo': registrationNo,
      if (includeCreatedAt) 'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (juryScores != null) 'juryScores': juryScores,
      if (grandTotal != null) 'grandTotal': grandTotal,
      if (status != null) 'status': status,
      if (group != null) 'group': group,
      if (categoryStatusMap != null) 'categoryStatusMap': categoryStatusMap,
      if (eventId != null) 'eventId': eventId,
      'isSpotRegistration': isSpotRegistration,
      'optForECertificate': optForECertificate,
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
    String? bonafiedCertificate,
    String? participantCode,
    String? registrationNo,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    Map<String, double>? juryScores,
    double? grandTotal,
    String? status,
    String? group,
    Map<String, String>? categoryStatusMap,
    String? eventId,
    bool? isSpotRegistration,
    bool? optForECertificate,
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
      bonafiedCertificate: bonafiedCertificate ?? this.bonafiedCertificate,
      participantCode: participantCode ?? this.participantCode,
      registrationNo: registrationNo ?? this.registrationNo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      juryScores: juryScores ?? this.juryScores,
      grandTotal: grandTotal ?? this.grandTotal,
      status: status ?? this.status,
      group: group ?? this.group,
      categoryStatusMap: categoryStatusMap ?? this.categoryStatusMap,
      eventId: eventId ?? this.eventId,
      isSpotRegistration: isSpotRegistration ?? this.isSpotRegistration,
      optForECertificate: optForECertificate ?? this.optForECertificate,
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
