class UserManagementModel {
  final String? id;
  final String name;
  final String? password;
  final String? photoUrl;
  final String? photo; // New API format
  final String
  type; // SUB ADMIN, SPOT REG ADMIN(S), JURY(S), VOLUNTEERS (for backward compatibility)
  final int?
  userTypeId; // New API format: 1=SUB ADMIN, 2=SPOT REG ADMIN, 3=JURY, 4=VOLUNTEERS
  final String? userTypeName; // New API format
  final int? eventId; // For backward compatibility
  final int? competitionId; // New API format
  final String? eventName; // For backward compatibility
  final String? competitionName; // New API format
  final List<String>
  permissions; // CREATE, EDIT, DELETE (for backward compatibility)
  final Map<String, bool>?
  permissionsObj; // New API format: {"CREATE": false, "EDIT": false, "READ": true, "DELETE": false}
  final List<String>
  stages; // STAGE 1, STAGE 2, etc. (for backward compatibility)
  final List<Map<String, dynamic>>?
  stagesObj; // New API format: [{"id": 1, "stageName": "A"}]
  final List<String>
  categories; // COMMON, SPECIAL, CHAMPIONS (for backward compatibility)
  final List<Map<String, dynamic>>?
  categoriesObj; // New API format: [{"id": 1, "categoryName": "COMMON"}]
  final String? cell; // Phone number for volunteers
  final String? volunteerNo; // Auto-generated for volunteers
  final List<Map<String, dynamic>>?
  volunteers; // New API format: array of volunteer objects

  UserManagementModel({
    this.id,
    required this.name,
    this.password,
    this.photoUrl,
    this.photo,
    this.type = '',
    this.userTypeId,
    this.userTypeName,
    this.eventId,
    this.competitionId,
    this.eventName,
    this.competitionName,
    this.permissions = const [],
    this.permissionsObj,
    this.stages = const [],
    this.stagesObj,
    this.categories = const [],
    this.categoriesObj,
    this.cell,
    this.volunteerNo,
    this.volunteers,
  });

  factory UserManagementModel.fromJson(Map<String, dynamic> json) {
    // Handle new API format
    final userTypeId = json['userTypeId'] is int
        ? json['userTypeId'] as int
        : int.tryParse(json['userTypeId']?.toString() ?? '');

    final userTypeName = json['userTypeName']?.toString();

    // Map userTypeId to type string for backward compatibility
    String type = '';
    if (userTypeId != null) {
      switch (userTypeId) {
        case 1:
          type = 'SUB ADMIN';
          break;
        case 2:
          type = 'SPOT REG ADMIN(S)';
          break;
        case 3:
          type = 'JURY(S)';
          break;
        case 4:
          type = 'VOLUNTEERS';
          break;
      }
    } else {
      // Fallback to old format
      type =
          json['type']?.toString() ??
          json['role']?.toString() ??
          json['userType']?.toString() ??
          '';
    }

    // Handle permissions - new format is object, old format is array
    Map<String, bool>? permissionsObj;
    List<String> permissions = [];
    if (json['permissions'] is Map) {
      permissionsObj = Map<String, bool>.from(json['permissions'] as Map);
      // Convert to list for backward compatibility
      permissionsObj.forEach((key, value) {
        if (value == true) {
          permissions.add(key);
        }
      });
    } else if (json['permissions'] is List) {
      permissions = (json['permissions'] as List)
          .map((e) => e.toString())
          .toList();
    }

    // Handle stages - new format is array of objects, old format is array of strings
    List<Map<String, dynamic>>? stagesObj;
    List<String> stages = [];
    if (json['stages'] is List) {
      final stagesList = json['stages'] as List;
      if (stagesList.isNotEmpty && stagesList.first is Map) {
        stagesObj = stagesList
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        stages = stagesObj
            .map((e) => e['stageName']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      } else {
        stages = stagesList.map((e) => e.toString()).toList();
      }
    }

    // Handle categories - new format is array of objects, old format is array of strings
    List<Map<String, dynamic>>? categoriesObj;
    List<String> categories = [];
    if (json['categories'] is List) {
      final categoriesList = json['categories'] as List;
      if (categoriesList.isNotEmpty && categoriesList.first is Map) {
        categoriesObj = categoriesList
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        categories = categoriesObj
            .map((e) => e['categoryName']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      } else {
        categories = categoriesList.map((e) => e.toString()).toList();
      }
    }

    // Handle competition/event ID
    final competitionId = json['competitionId'] is int
        ? json['competitionId'] as int
        : int.tryParse(json['competitionId']?.toString() ?? '');
    final eventId = json['eventId'] is int
        ? json['eventId'] as int
        : int.tryParse(json['eventId']?.toString() ?? '');

    return UserManagementModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      name: json['name']?.toString() ?? json['username']?.toString() ?? '',
      password: json['password']?.toString(),
      photoUrl:
          json['photoUrl']?.toString() ??
          json['photo_url']?.toString() ??
          json['photo']?.toString(),
      photo: json['photo']?.toString(),
      type: type,
      userTypeId: userTypeId,
      userTypeName: userTypeName,
      eventId: eventId ?? competitionId,
      competitionId: competitionId ?? eventId,
      eventName:
          json['eventName']?.toString() ??
          json['event_name']?.toString() ??
          json['competitionName']?.toString(),
      competitionName:
          json['competitionName']?.toString() ?? json['eventName']?.toString(),
      permissions: permissions,
      permissionsObj: permissionsObj,
      stages: stages,
      stagesObj: stagesObj,
      categories: categories,
      categoriesObj: categoriesObj,
      cell:
          json['cell']?.toString() ??
          json['phone']?.toString() ??
          json['phoneNo']?.toString(),
      volunteerNo:
          json['volunteerNo']?.toString() ?? json['volunteer_no']?.toString(),
      volunteers: json['volunteers'] is List
          ? (json['volunteers'] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson({
    bool includePassword = false,
    bool useNewFormat = true,
  }) {
    final json = <String, dynamic>{
      if (id != null && !useNewFormat) 'id': id,
      'name': name,
    };

    if (useNewFormat) {
      // New API format
      if (competitionId != null) json['competitionId'] = competitionId;
      if (userTypeId != null) json['userTypeId'] = userTypeId;

      // Convert stages from strings to IDs (if we have stage IDs)
      if (stagesObj != null && stagesObj!.isNotEmpty) {
        json['stages'] = stagesObj!
            .map((s) => s['id'])
            .whereType<int>()
            .toList();
      } else if (stages.isNotEmpty) {
        // For now, we'll need to map stage names to IDs in the controller
        // This is a placeholder - actual implementation should map names to IDs
        json['stages'] = [];
      }

      // Convert categories from strings to IDs
      if (categoriesObj != null && categoriesObj!.isNotEmpty) {
        json['categories'] = categoriesObj!
            .map((c) => c['id'])
            .whereType<int>()
            .toList();
      } else if (categories.isNotEmpty) {
        // For now, we'll need to map category names to IDs in the controller
        json['categories'] = [];
      }

      // Include volunteers array if present
      if (volunteers != null && volunteers!.isNotEmpty) {
        json['volunteers'] = volunteers;
      }
    } else {
      // Old format for backward compatibility
      json['type'] = type;
      if (eventId != null) json['eventId'] = eventId;
      if (eventName != null) json['eventName'] = eventName;
      if (permissions.isNotEmpty) json['permissions'] = permissions;
      if (stages.isNotEmpty) json['stages'] = stages;
      if (categories.isNotEmpty) json['categories'] = categories;
      if (cell != null && cell!.isNotEmpty) json['cell'] = cell;
      if (volunteerNo != null) json['volunteerNo'] = volunteerNo;
    }

    if (includePassword && password != null && password!.isNotEmpty) {
      json['password'] = password;
    }

    return json;
  }

  UserManagementModel copyWith({
    String? id,
    String? name,
    String? password,
    String? photoUrl,
    String? photo,
    String? type,
    int? userTypeId,
    String? userTypeName,
    int? eventId,
    int? competitionId,
    String? eventName,
    String? competitionName,
    List<String>? permissions,
    Map<String, bool>? permissionsObj,
    List<String>? stages,
    List<Map<String, dynamic>>? stagesObj,
    List<String>? categories,
    List<Map<String, dynamic>>? categoriesObj,
    String? cell,
    String? volunteerNo,
    List<Map<String, dynamic>>? volunteers,
  }) {
    return UserManagementModel(
      id: id ?? this.id,
      name: name ?? this.name,
      password: password ?? this.password,
      photoUrl: photoUrl ?? this.photoUrl,
      photo: photo ?? this.photo,
      type: type ?? this.type,
      userTypeId: userTypeId ?? this.userTypeId,
      userTypeName: userTypeName ?? this.userTypeName,
      eventId: eventId ?? this.eventId,
      competitionId: competitionId ?? this.competitionId,
      eventName: eventName ?? this.eventName,
      competitionName: competitionName ?? this.competitionName,
      permissions: permissions ?? this.permissions,
      permissionsObj: permissionsObj ?? this.permissionsObj,
      stages: stages ?? this.stages,
      stagesObj: stagesObj ?? this.stagesObj,
      categories: categories ?? this.categories,
      categoriesObj: categoriesObj ?? this.categoriesObj,
      cell: cell ?? this.cell,
      volunteerNo: volunteerNo ?? this.volunteerNo,
      volunteers: volunteers ?? this.volunteers,
    );
  }

  // Helper getters for backward compatibility
  String get displayType => userTypeName ?? type;
  int? get displayEventId => competitionId ?? eventId;
  String? get displayEventName => competitionName ?? eventName;
  String? get displayPhotoUrl => photo ?? photoUrl;
}
