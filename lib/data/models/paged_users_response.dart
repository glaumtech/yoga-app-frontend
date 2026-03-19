import 'user_management_model.dart';

class UsersPagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  UsersPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory UsersPagination.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return UsersPagination(
      page: toInt(json['page']),
      limit: toInt(json['limit']),
      total: toInt(json['total']),
      totalPages: toInt(json['totalPages']),
    );
  }
}

class PagedUsersResponse {
  final List<UserManagementModel> users;
  final UsersPagination? pagination;

  PagedUsersResponse({required this.users, this.pagination});

  factory PagedUsersResponse.fromJson(Map<String, dynamic> json) {
    final rawUsers = json['users'];
    final users = (rawUsers is List)
        ? rawUsers
            .map((e) => UserManagementModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList()
        : <UserManagementModel>[];

    final p = json['pagination'];
    final pagination = (p is Map)
        ? UsersPagination.fromJson(Map<String, dynamic>.from(p))
        : null;

    return PagedUsersResponse(users: users, pagination: pagination);
  }
}

