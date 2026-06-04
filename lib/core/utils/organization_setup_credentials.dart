import 'dart:math';

/// Generates org-admin username/password patterns for organization setup.
class OrganizationSetupCredentials {
  OrganizationSetupCredentials._();

  static final Random _random = Random.secure();

  static String slugifyOrganizationName(String orgName) {
    var slug = orgName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    slug = slug.replaceAll(RegExp(r'^_+|_+$'), '');
    return slug.isEmpty ? 'org' : slug;
  }

  static String orgAdminUsername(String orgName) =>
      '${slugifyOrganizationName(orgName)}_orgadmin';

  static String orgAdminDisplayName(String orgName) {
    final name = orgName.trim();
    return name.isEmpty ? 'Organization Admin' : '$name Admin';
  }

  static String generatePassword({int length = 12}) {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789@#';
    return List.generate(
      length,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
  }
}
