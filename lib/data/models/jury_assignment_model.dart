class JuryAssignmentModel {
  final int juryId;
  final List<StageAssignment> stages;
  final List<CategoryAssignment> categories;
  final int competitionId;
  final String competitionName;
  final int minimumMarks;
  final int maximumMarks;

  JuryAssignmentModel({
    required this.juryId,
    required this.stages,
    required this.categories,
    required this.competitionId,
    required this.competitionName,
    required this.minimumMarks,
    required this.maximumMarks,
  });

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
      maximumMarks: json['maximumMarks'] as int? ?? 100,
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

  CategoryAssignment({required this.id, required this.categoryName});

  factory CategoryAssignment.fromJson(Map<String, dynamic> json) {
    return CategoryAssignment(
      id: json['id'] as int? ?? 0,
      categoryName: json['categoryName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'categoryName': categoryName};
  }
}
