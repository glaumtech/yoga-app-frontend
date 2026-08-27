class JuryAssignmentModel {
  final int juryId;
  final List<StageAssignment> stages;
  final List<CategoryAssignment> categories;
  final int competitionId;
  final String competitionName;
  final int minimumMarks;
  final int maximumMarks;
  final int skippedAsanaMarks;
  final bool male;
  final bool female;
  final String? championshipStyle;
  final bool hideStageGroupSelection;

  JuryAssignmentModel({
    required this.juryId,
    required this.stages,
    required this.categories,
    required this.competitionId,
    required this.competitionName,
    required this.minimumMarks,
    required this.maximumMarks,
    this.skippedAsanaMarks = 0,
    this.male = false,
    this.female = false,
    this.championshipStyle,
    this.hideStageGroupSelection = false,
  });

  bool get isWinnerBasedChampionship =>
      championshipStyle?.trim().toUpperCase() == 'FROM_FIRST_PLACE_WINNERS';

  bool get hasChampionsCategoryAssignment => categories.any(
        (c) => c.categoryName.trim().toUpperCase() == 'CHAMPIONS',
      );

  factory JuryAssignmentModel.fromJson(Map<String, dynamic> json) {
    final stagesList = json['stages'] as List<dynamic>? ?? [];
    final categoriesList = json['categories'] as List<dynamic>? ?? [];

    return JuryAssignmentModel(
      juryId: json['juryId'] as int? ?? 0,
      stages: stagesList
          .map(
            (stage) => StageAssignment.fromJson(stage as Map<String, dynamic>),
          )
          .toList(),
      categories: categoriesList
          .map(
            (category) =>
                CategoryAssignment.fromJson(category as Map<String, dynamic>),
          )
          .toList(),
      competitionId: json['competitionId'] as int? ?? 0,
      competitionName: json['competitionName'] as String? ?? '',
      minimumMarks: json['minimumMarks'] as int? ?? 0,
      // Use 0 when absent so callers can fall back to a default range (e.g. 3–10).
      maximumMarks: json['maximumMarks'] as int? ?? 0,
      skippedAsanaMarks: json['skippedAsanaMarks'] as int? ?? 0,
      male: json['male'] as bool? ?? false,
      female: json['female'] as bool? ?? false,
      championshipStyle: json['championshipStyle']?.toString(),
      hideStageGroupSelection: json['hideStageGroupSelection'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'juryId': juryId,
      'stages': stages.map((stage) => stage.toJson()).toList(),
      'categories': categories.map((category) => category.toJson()).toList(),
      'competitionId': competitionId,
      'competitionName': competitionName,
      'minimumMarks': minimumMarks,
      'maximumMarks': maximumMarks,
      'skippedAsanaMarks': skippedAsanaMarks,
      'male': male,
      'female': female,
      if (championshipStyle != null) 'championshipStyle': championshipStyle,
      'hideStageGroupSelection': hideStageGroupSelection,
    };
  }
}

class StageAssignment {
  final int id;
  final String stageName;
  final List<GroupAssignment> groups;

  StageAssignment({
    required this.id,
    required this.stageName,
    required this.groups,
  });

  factory StageAssignment.fromJson(Map<String, dynamic> json) {
    final groupsList = json['groups'] as List<dynamic>? ?? [];
    return StageAssignment(
      id: json['id'] as int? ?? 0,
      stageName: json['stageName'] as String? ?? '',
      groups: groupsList
          .map(
            (group) => GroupAssignment.fromJson(group as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stageName': stageName,
      'groups': groups.map((group) => group.toJson()).toList(),
    };
  }
}

class GroupAssignment {
  final int id;
  final String groupName;

  GroupAssignment({required this.id, required this.groupName});

  factory GroupAssignment.fromJson(Map<String, dynamic> json) {
    return GroupAssignment(
      id: json['id'] as int? ?? 0,
      groupName: json['groupName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'groupName': groupName};
  }
}

class CategoryAssignment {
  final int id;
  final String categoryName;
  /// Compulsory / from-chart asanas from category config.
  final int compulsoryAsanas;
  /// Own-choice asanas from category config.
  final int ownChoiceAsanas;
  /// Total asanas to score for this category (compulsory + own choice).
  final int numberOfAsanas;

  CategoryAssignment({
    required this.id,
    required this.categoryName,
    this.compulsoryAsanas = 4,
    this.ownChoiceAsanas = 2,
    int? numberOfAsanas,
  }) : numberOfAsanas =
            numberOfAsanas ??
            ((compulsoryAsanas + ownChoiceAsanas) > 0
                ? compulsoryAsanas + ownChoiceAsanas
                : 5);

  bool get isChampions =>
      categoryName.trim().toUpperCase() == 'CHAMPIONS';

  factory CategoryAssignment.fromJson(Map<String, dynamic> json) {
    final compulsory = json['compulsoryAsanas'] as int? ?? 4;
    final ownChoice = json['ownChoiceAsanas'] as int? ?? 2;
    final totalFromApi = json['numberOfAsanas'] as int?;
    final total = totalFromApi != null && totalFromApi > 0
        ? totalFromApi
        : (compulsory + ownChoice > 0 ? compulsory + ownChoice : 5);
    return CategoryAssignment(
      id: json['id'] as int? ?? 0,
      categoryName: json['categoryName'] as String? ?? '',
      compulsoryAsanas: compulsory,
      ownChoiceAsanas: ownChoice,
      numberOfAsanas: total,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryName': categoryName,
      'compulsoryAsanas': compulsoryAsanas,
      'ownChoiceAsanas': ownChoiceAsanas,
      'numberOfAsanas': numberOfAsanas,
    };
  }
}
