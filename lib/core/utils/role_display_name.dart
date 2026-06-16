/// Friendly labels for backend role type names shown in the UI.
String displayRoleName(String? typeName) {
  final key = typeName?.trim().toUpperCase() ?? '';
  switch (key) {
    case 'BRANCH_ADMIN':
    case 'BRANCH ADMIN':
      return 'Super Admin';
    case 'ORG_ADMIN':
    case 'ORG ADMIN':
      return 'Organization Admin';
    case 'SUB_ADMIN':
    case 'SUB ADMIN':
      return 'Sub Admin';
    case 'JURY':
      return 'Jury';
    case 'SPOT_REG_ADMIN':
    case 'SPOT REG ADMIN':
      return 'Spot Registration Admin';
    case 'VOLUNTEER':
    case 'VOLUNTEERS':
      return 'Volunteer';
    default:
      final raw = typeName?.trim() ?? '';
      if (raw.isEmpty) return '';
      return raw.replaceAll('_', ' ');
  }
}
