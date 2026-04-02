/// Permission entity from `/permission` API (distinct from user-type nested PermissionModel).
class AppPermissionRecord {
  final int? id;
  final String permissionName;
  final String? description;
  final String? permissionKey;
  final String? type;
  final String? menu;
  final String? subMenu;
  final String? tab;

  const AppPermissionRecord({
    this.id,
    required this.permissionName,
    this.description,
    this.permissionKey,
    this.type,
    this.menu,
    this.subMenu,
    this.tab,
  });

  factory AppPermissionRecord.fromJson(Map<String, dynamic> json) {
    final idVal = json['id'];
    final subMenuVal = json['subMenu'] ?? json['sub_menu'];
    return AppPermissionRecord(
      id: idVal is int
          ? idVal
          : (idVal != null ? int.tryParse(idVal.toString()) : null),
      permissionName: json['permissionName']?.toString() ?? '',
      description: json['description']?.toString(),
      permissionKey:
          json['permissionKey']?.toString() ?? json['permission_key']?.toString(),
      type: json['type']?.toString(),
      menu: json['menu']?.toString(),
      subMenu: subMenuVal?.toString(),
      tab: json['tab']?.toString(),
    );
  }
}
