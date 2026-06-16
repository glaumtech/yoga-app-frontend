import '../../core/utils/role_display_name.dart';

class UserManagementModel {
  final String? id;
  final String name;

  /// Display name stored as `user_name` on the server (optional).
  final String? userName;
  final int? branchId; // New API: branch scope
  final String? password;
  final String? photoUrl;
  final String? photo; // New API format
  final String
  type; // SUB ADMIN, SPOT REG ADMIN(S), JURY(S), VOLUNTEERS (for backward compatibility)
  final int?
  userTypeId; // New API format: 1=SUB ADMIN, 2=SPOT REG ADMIN, 3=JURY, 4=VOLUNTEERS
  final String? userTypeName; // New API format
  final String? themeColor; // Role accent from user_types.theme_color
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
  final bool? male;
  final bool? female;
  final String? cell; // Phone number for volunteers
  final String? volunteerNo; // Auto-generated for volunteers
  final List<Map<String, dynamic>>?
  volunteers; // New API format: array of volunteer objects
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? confirmPassword;

  UserManagementModel({
    this.id,
    required this.name,
    this.userName,
    this.branchId,
    this.password,
    this.photoUrl,
    this.photo,
    this.type = '',
    this.userTypeId,
    this.userTypeName,
    this.themeColor,
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
    this.male,
    this.female,
    this.cell,
    this.volunteerNo,
    this.volunteers,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.confirmPassword,
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

    final branchId = json['branchId'] is int
        ? json['branchId'] as int
        : int.tryParse(json['branchId']?.toString() ?? '');

    return UserManagementModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      name: json['name']?.toString() ?? json['username']?.toString() ?? '',
      userName: json['userName']?.toString() ?? json['user_name']?.toString(),
      branchId: branchId,
      password: json['password']?.toString(),
      photoUrl:
          json['photoUrl']?.toString() ??
          json['photo_url']?.toString() ??
          json['photo']?.toString(),
      photo: json['photo']?.toString(),
      type: type,
      userTypeId: userTypeId,
      userTypeName: userTypeName,
      themeColor: json['themeColor']?.toString(),
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
      male: json['male'] is bool ? json['male'] as bool : null,
      female: json['female'] is bool ? json['female'] as bool : null,
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
      confirmPassword: json['confirmPassword']?.toString(),
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
      // New API format (always send so display name can be cleared on update)
      json['userName'] = userName?.trim() ?? '';
      if (branchId != null) json['branchId'] = branchId;
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
      if (male != null) json['male'] = male;
      if (female != null) json['female'] = female;

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
    String? userName,
    int? branchId,
    String? password,
    String? photoUrl,
    String? photo,
    String? type,
    int? userTypeId,
    String? userTypeName,
    String? themeColor,
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
    bool? male,
    bool? female,
    String? cell,
    String? volunteerNo,
    List<Map<String, dynamic>>? volunteers,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? confirmPassword,
  }) {
    return UserManagementModel(
      id: id ?? this.id,
      name: name ?? this.name,
      userName: userName ?? this.userName,
      branchId: branchId ?? this.branchId,
      password: password ?? this.password,
      photoUrl: photoUrl ?? this.photoUrl,
      photo: photo ?? this.photo,
      type: type ?? this.type,
      userTypeId: userTypeId ?? this.userTypeId,
      userTypeName: userTypeName ?? this.userTypeName,
      themeColor: themeColor ?? this.themeColor,
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
      male: male ?? this.male,
      female: female ?? this.female,
      cell: cell ?? this.cell,
      volunteerNo: volunteerNo ?? this.volunteerNo,
      volunteers: volunteers ?? this.volunteers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      confirmPassword: confirmPassword ?? this.confirmPassword,
    );
  }

  /// Shown in lists when [userName] is set; otherwise the login [name].
  String get displayName => (userName != null && userName!.trim().isNotEmpty)
      ? userName!.trim()
      : name;

  // Helper getters for backward compatibility
  String get displayType => displayRoleName(userTypeName ?? type);
  int? get displayEventId => competitionId ?? eventId;
  String? get displayEventName => competitionName ?? eventName;
  String? get displayPhotoUrl => photo ?? photoUrl;
}
