import '../../controllers/competition_controller.dart';
import '../../../core/utils/registration_category_options.dart';
import '../../../data/models/competition_model.dart';

/// Same label the bulk-registration Group dropdown shows.
String bulkGroupStageLabel(String groupName, String stageName) =>
    '$groupName (GROUP $stageName)';

/// Group and stage pairs a bulk-registration row can use for one category.
List<({String groupName, String stageName})> groupStageEntriesForBulk(
  CompetitionModel? competition,
  CompetitionController competitionController, {
  String? categoryName,
  String? categoryMode,
}) {
  if (competition == null) return const [];

  final selectedCategory = categoryName?.trim() ?? '';
  if (selectedCategory.isNotEmpty &&
      competition.categoryConfigs != null &&
      competition.categoryConfigs!.isNotEmpty) {
    final cfg = findCategoryConfig(
      configs: competition.categoryConfigs!,
      categoryName: selectedCategory,
      mode: categoryMode,
    );
    if (cfg != null) {
      final fromAllotment = <({String groupName, String stageName})>[];
      if (cfg.stageAllotment.isNotEmpty) {
        final stages = cfg.stageAllotment.keys.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        for (final stageName in stages) {
          final groups = _groupsInCreatedOrderForBulk(
            cfg.stageAllotment[stageName] ?? const [],
            selectedGroups: cfg.selectedGroups,
          );
          for (final groupName in groups) {
            fromAllotment.add((groupName: groupName, stageName: stageName));
          }
        }
        if (fromAllotment.isNotEmpty) return fromAllotment;
      }
      if (cfg.selectedGroups.isNotEmpty) {
        final stageByGroup = <String, String>{};
        final labels = competition.stageGroupLabels;
        if (labels != null) {
          for (final e in labels.entries) {
            for (final g in e.value) {
              stageByGroup[g.trim().toLowerCase()] = e.key;
            }
          }
        }
        final groups = _groupsInCreatedOrderForBulk(cfg.selectedGroups);
        for (final groupName in groups) {
          final stageName =
              stageByGroup[groupName.trim().toLowerCase()] ?? 'Stage';
          fromAllotment.add((groupName: groupName, stageName: stageName));
        }
        if (fromAllotment.isNotEmpty) return fromAllotment;
      }
    }
  }

  final entries = <({String groupName, String stageName})>[];

  if (competition.stageGroups != null && competition.stageGroups!.isNotEmpty) {
    final sortedStageIds =
        competition.stageGroups!.keys
            .map((id) => int.tryParse(id))
            .whereType<int>()
            .toList()
          ..sort((a, b) {
            final stageA =
                competitionController.getStageNameById(a)?.toLowerCase() ?? '';
            final stageB =
                competitionController.getStageNameById(b)?.toLowerCase() ?? '';
            return stageA.compareTo(stageB);
          });

    for (final stageId in sortedStageIds) {
      final stageName = competitionController.getStageNameById(stageId);
      if (stageName == null) continue;

      final groupIds = List<int>.from(
        competition.stageGroups![stageId.toString()] ?? const [],
      );

      for (final groupId in groupIds) {
        final groupName = competitionController.getGroupNameById(groupId);
        if (groupName != null) {
          entries.add((groupName: groupName, stageName: stageName));
        }
      }
    }
  }

  if (entries.isEmpty && competition.stageGroupLabels != null) {
    final sortedStages = competition.stageGroupLabels!.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    for (final stageName in sortedStages) {
      final groups = _groupsInCreatedOrderForBulk(
        competition.stageGroupLabels![stageName] ?? const [],
      );
      for (final groupName in groups) {
        entries.add((groupName: groupName, stageName: stageName));
      }
    }
  }

  return entries;
}

/// Registration group list in Challenge Config / created order, not A–Z.
List<String> _groupsInCreatedOrderForBulk(
  Iterable<String> groups, {
  List<String> selectedGroups = const [],
}) {
  final seen = <String>{};
  final result = <String>[];

  void add(String raw) {
    final name = raw.trim();
    if (name.isEmpty) return;
    if (seen.add(name.toLowerCase())) {
      result.add(name);
    }
  }

  if (selectedGroups.isNotEmpty) {
    final wanted = {
      for (final g in groups)
        if (g.trim().isNotEmpty) g.trim().toLowerCase(),
    };
    for (final g in selectedGroups) {
      if (wanted.contains(g.trim().toLowerCase())) add(g);
    }
  }
  for (final g in groups) {
    add(g);
  }
  return result;
}

/// Sex choices for a competition, narrowed to the selected category when it
/// has its own gender list.
List<String> bulkSexOptions(
  CompetitionModel? competition, {
  String? categoryName,
  String? categoryMode,
  String? includeValue,
}) {
  const fallback = ['Male', 'Female'];
  final configs = competition?.categoryConfigs;
  var options = fallback;
  if (configs != null && configs.isNotEmpty) {
    final selectedCategory = categoryName?.trim() ?? '';
    if (selectedCategory.isNotEmpty) {
      final config = findCategoryConfig(
        configs: configs,
        categoryName: selectedCategory,
        mode: categoryMode,
      );
      if (config != null && config.selectedGenders.isNotEmpty) {
        final seen = <String>{};
        final genders = <String>[];
        for (final gender in config.selectedGenders) {
          final label = gender.trim();
          if (label.isEmpty) continue;
          if (seen.add(label.toLowerCase())) genders.add(label);
        }
        if (genders.isNotEmpty) options = genders;
      }
    }
    if (identical(options, fallback)) {
      final seen = <String>{};
      final genders = <String>[];
      for (final config in configs) {
        for (final gender in config.selectedGenders) {
          final label = gender.trim();
          if (label.isEmpty) continue;
          if (seen.add(label.toLowerCase())) genders.add(label);
        }
      }
      if (genders.isNotEmpty) options = genders;
    }
  }

  final extra = includeValue?.trim() ?? '';
  if (extra.isNotEmpty &&
      !options.any((option) => option.toLowerCase() == extra.toLowerCase())) {
    options = [...options, extra];
  }
  return options;
}
