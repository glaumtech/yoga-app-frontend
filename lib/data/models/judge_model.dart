class JudgeModel {
  final String? id;
  final String name;
  final String address;
  final String designation;
  final String username;
  final String? email;
  final String? password;
  final String? confirmPassword;
  final String role;

  JudgeModel({
    this.id,
    required this.name,
    required this.address,
    required this.designation,
    required this.username,
    this.email,
    this.password,
    this.confirmPassword,
    this.role = 'judge',
  });

  factory JudgeModel.fromJson(Map<String, dynamic> json) {
    return JudgeModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      username:
          json['username']?.toString() ?? json['userName']?.toString() ?? '',
      email: json['email']?.toString(),
      password: json['password']?.toString(),
      confirmPassword:
          json['confirmPassword']?.toString() ??
          json['confirm_password']?.toString(),
      role: json['role']?.toString() ?? 'judge',
    );
  }

  Map<String, dynamic> toJson({bool includePassword = false}) {
    final json = {
      if (id != null) 'id': id,
      'name': name,
      'address': address,
      'designation': designation,
      'username': username,
      if (email != null && email!.isNotEmpty) 'email': email,
      'role': role,
    };

    if (includePassword) {
      if (password != null && password!.isNotEmpty) {
        json['password'] = password;
      }
      if (confirmPassword != null && confirmPassword!.isNotEmpty) {
        json['confirmPassword'] = confirmPassword;
      }
    }

    return json;
  }

  JudgeModel copyWith({
    String? id,
    String? name,
    String? address,
    String? designation,
    String? username,
    String? email,
    String? password,
    String? confirmPassword,
    String? role,
  }) {
    return JudgeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      designation: designation ?? this.designation,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      role: role ?? this.role,
    );
  }
}
