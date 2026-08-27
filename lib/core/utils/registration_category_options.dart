import '../../data/models/category_config_model.dart';
import '../../data/models/competition_model.dart';

/// A registerable category plus its Online/Offline delivery mode.
class RegistrationCategoryOption {
  static const separator = '||';

  final String categoryName;
  final String mode;

  const RegistrationCategoryOption({
    required this.categoryName,
    required this.mode,
  });

  bool get isOnline => mode == 'ONLINE';
  String get modeLabel => isOnline ? 'Online' : 'Offline';
  String get displayLabel => '$categoryName ($modeLabel)';
  String get valueKey => '$categoryName$separator$mode';

  static String normalizeMode(String? raw) {
    if (raw != null && raw.trim().toUpperCase() == 'ONLINE') {
      return 'ONLINE';
    }
    return 'OFFLINE';
  }

  static RegistrationCategoryOption? tryParse(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parts = value.split(separator);
    if (parts.length >= 2) {
      return RegistrationCategoryOption(
        categoryName: parts.first.trim(),
        mode: normalizeMode(parts.sublist(1).join(separator)),
      );
    }
    return RegistrationCategoryOption(
      categoryName: value.trim(),
      mode: 'OFFLINE',
    );
  }
}

List<RegistrationCategoryOption> buildRegistrationCategoryOptions({
  List<CompetitionCategoryConfigModel>? configs,
  List<CategoryModeSummary>? categoryModes,
  List<String>? categoryNames,
  String? competitionMode,
}) {
  if (configs != null && configs.isNotEmpty) {
    return configs
        .where((c) => c.categoryName.trim().isNotEmpty)
        .map(
          (c) => RegistrationCategoryOption(
            categoryName: c.categoryName.trim(),
            mode: RegistrationCategoryOption.normalizeMode(c.mode),
          ),
        )
        .toList();
  }

  if (categoryModes != null && categoryModes.isNotEmpty) {
    return categoryModes
        .where((c) => c.categoryName.trim().isNotEmpty)
        .map(
          (c) => RegistrationCategoryOption(
            categoryName: c.categoryName.trim(),
            mode: RegistrationCategoryOption.normalizeMode(c.mode),
          ),
        )
        .toList();
  }

  final names = categoryNames ?? const <String>[];
  final mode = RegistrationCategoryOption.normalizeMode(competitionMode);
  return names
      .where((n) => n.trim().isNotEmpty)
      .map(
        (n) => RegistrationCategoryOption(
          categoryName: n.trim(),
          mode: mode,
        ),
      )
      .toList();
}

CompetitionCategoryConfigModel? findCategoryConfig({
  required List<CompetitionCategoryConfigModel> configs,
  required String categoryName,
  String? mode,
}) {
  final name = categoryName.trim().toLowerCase();
  if (name.isEmpty) return null;

  final hasMode = mode != null && mode.trim().isNotEmpty;
  final normalizedMode =
      hasMode ? RegistrationCategoryOption.normalizeMode(mode) : null;

  if (normalizedMode != null) {
    for (final c in configs) {
      if (c.categoryName.trim().toLowerCase() == name &&
          RegistrationCategoryOption.normalizeMode(c.mode) == normalizedMode) {
        return c;
      }
    }
  }

  for (final c in configs) {
    if (c.categoryName.trim().toLowerCase() == name) {
      return c;
    }
  }
  return null;
}
