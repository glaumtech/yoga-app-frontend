class ParticipantAssignmentModel {
  final String? id;
  final String teamId;
  final String participantId;
  final String? participantName;
  final String? teamName;
  final DateTime? assignedAt;

  ParticipantAssignmentModel({
    this.id,
    required this.teamId,
    required this.participantId,
    this.participantName,
    this.teamName,
    this.assignedAt,
  });

  factory ParticipantAssignmentModel.fromJson(Map<String, dynamic> json) {
    return ParticipantAssignmentModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      teamId: json['teamId']?.toString() ?? json['team_id']?.toString() ?? '',
      participantId:
          json['participantId']?.toString() ??
          json['participant_id']?.toString() ??
          '',
      participantName:
          json['participantName']?.toString() ??
          json['participant_name']?.toString(),
      teamName: json['teamName']?.toString() ?? json['team_name']?.toString(),
      assignedAt: json['assignedAt'] != null
          ? (json['assignedAt'] is String
                ? DateTime.parse(json['assignedAt'])
                : json['assignedAt'] is int
                ? DateTime.fromMillisecondsSinceEpoch(json['assignedAt'])
                : null)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'teamId': teamId,
      'participantId': participantId,
      if (participantName != null) 'participantName': participantName,
      if (teamName != null) 'teamName': teamName,
      if (assignedAt != null) 'assignedAt': assignedAt!.toIso8601String(),
    };
  }
}

class AssignParticipantsRequest {
  final String teamId;
  final List<String> participantIds;

  AssignParticipantsRequest({
    required this.teamId,
    required this.participantIds,
  });

  Map<String, dynamic> toJson() {
    return {'teamId': teamId, 'participantIds': participantIds};
  }
}
