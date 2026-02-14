class UserManagementModel {
  final String? id;
  final String name;
  final String? password;
  final String? photoUrl;
  final String type; // SUB ADMIN, SPOT REG ADMIN(S), JURY(S), VOLUNTEERS
  final int? eventId;
  final String? eventName;
  final List<String> permissions; // CREATE, EDIT, DELETE
  final List<String> stages; // STAGE 1, STAGE 2, etc.
  final List<String> categories; // COMMON, SPECIAL, CHAMPIONS
  final String? cell; // Phone number for volunteers
  final String? volunteerNo; // Auto-generated for volunteers

  UserManagementModel({
    this.id,
    required this.name,
    this.password,
    this.photoUrl,
    required this.type,
    this.eventId,
    this.eventName,
    this.permissions = const [],
    this.stages = const [],
    this.categories = const [],
    this.cell,
    this.volunteerNo,
  });

  factory UserManagementModel.fromJson(Map<String, dynamic> json) {
    return UserManagementModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      name: json['name']?.toString() ?? json['username']?.toString() ?? '',
      password: json['password']?.toString(),
      photoUrl:
          json['photoUrl']?.toString() ??
          json['photo_url']?.toString() ??
          json['photo']?.toString(),
      type:
          json['type']?.toString() ??
          json['role']?.toString() ??
          json['userType']?.toString() ??
          '',
      eventId: json['eventId'] is int
          ? json['eventId']
          : int.tryParse(json['eventId']?.toString() ?? ''),
      eventName:
          json['eventName']?.toString() ?? json['event_name']?.toString(),
      permissions: json['permissions'] is List
          ? (json['permissions'] as List).map((e) => e.toString()).toList()
          : [],
      stages: json['stages'] is List
          ? (json['stages'] as List).map((e) => e.toString()).toList()
          : [],
      categories: json['categories'] is List
          ? (json['categories'] as List).map((e) => e.toString()).toList()
          : [],
      cell:
          json['cell']?.toString() ??
          json['phone']?.toString() ??
          json['phoneNo']?.toString(),
      volunteerNo:
          json['volunteerNo']?.toString() ?? json['volunteer_no']?.toString(),
    );
  }

  Map<String, dynamic> toJson({bool includePassword = false}) {
    final json = <String, dynamic>{
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      if (eventId != null) 'eventId': eventId,
      if (eventName != null) 'eventName': eventName,
      if (permissions.isNotEmpty) 'permissions': permissions,
      if (stages.isNotEmpty) 'stages': stages,
      if (categories.isNotEmpty) 'categories': categories,
      if (cell != null && cell!.isNotEmpty) 'cell': cell,
      if (volunteerNo != null) 'volunteerNo': volunteerNo,
    };

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
    String? type,
    int? eventId,
    String? eventName,
    List<String>? permissions,
    List<String>? stages,
    List<String>? categories,
    String? cell,
    String? volunteerNo,
  }) {
    return UserManagementModel(
      id: id ?? this.id,
      name: name ?? this.name,
      password: password ?? this.password,
      photoUrl: photoUrl ?? this.photoUrl,
      type: type ?? this.type,
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      permissions: permissions ?? this.permissions,
      stages: stages ?? this.stages,
      categories: categories ?? this.categories,
      cell: cell ?? this.cell,
      volunteerNo: volunteerNo ?? this.volunteerNo,
    );
  }
}
