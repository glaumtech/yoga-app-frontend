class UserModel {
  final int id;
  final String email;
  final String username;
  final String roleName;
  final int roleId;
  final String? phoneNo;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.roleName,
    required this.roleId,
    this.phoneNo,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle phone_no/phoneNo which can be int or String
    String? phoneNo;
    final phoneValue = json['phone_no'] ?? json['phoneNo'];
    if (phoneValue != null) {
      if (phoneValue is int) {
        phoneNo = phoneValue.toString();
      } else if (phoneValue is String) {
        phoneNo = phoneValue;
      } else {
        phoneNo = phoneValue.toString();
      }
    }

    return UserModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      roleName: json['role_name'] ?? '',
      roleId: json['role_id'] is int
          ? json['role_id']
          : int.tryParse(json['role_id']?.toString() ?? '0') ?? 0,
      phoneNo: phoneNo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'role_name': roleName,
      'role_id': roleId,
      if (phoneNo != null) 'phone_no': phoneNo,
    };
  }

  UserModel copyWith({
    int? id,
    String? email,
    String? username,
    String? roleName,
    int? roleId,
    String? phoneNo,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      roleName: roleName ?? this.roleName,
      roleId: roleId ?? this.roleId,
      phoneNo: phoneNo ?? this.phoneNo,
    );
  }

  // Helper getters for backward compatibility
  String get name => username;
  String get role {
    try {
      return roleName;
    } catch (e) {
      // Fallback if roleName is not accessible
      return '';
    }
  }

  String? get phone => phoneNo;
}
