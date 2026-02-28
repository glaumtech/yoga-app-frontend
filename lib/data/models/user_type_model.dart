class UserTypeModel {
  final int id;
  final String typeName;
  final String description;
  final List<PermissionModel> permissions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserTypeModel({
    required this.id,
    required this.typeName,
    required this.description,
    required this.permissions,
    this.createdAt,
    this.updatedAt,
  });

  factory UserTypeModel.fromJson(Map<String, dynamic> json) {
    final permissionsList = json['permissions'] as List<dynamic>? ?? [];
    final permissions = permissionsList
        .map((p) => PermissionModel.fromJson(p as Map<String, dynamic>))
        .toList();

    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return UserTypeModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      typeName: json['typeName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      permissions: permissions,
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'typeName': typeName,
      'description': description,
      'permissions': permissions.map((p) => p.toJson()).toList(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}

class PermissionModel {
  final int id;
  final String permissionName;
  final String description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PermissionModel({
    required this.id,
    required this.permissionName,
    required this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return PermissionModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      permissionName: json['permissionName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'permissionName': permissionName,
      'description': description,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}
