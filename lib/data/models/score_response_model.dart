class ScoreResponseModel {
  final int eventId;
  final List<ParticipantScoreModel> participants;

  ScoreResponseModel({required this.eventId, required this.participants});

  factory ScoreResponseModel.fromJson(Map<String, dynamic> json) {
    final scoreOfParticipants =
        json['scoreOfParticipants'] as Map<String, dynamic>?;

    if (scoreOfParticipants == null) {
      return ScoreResponseModel(
        eventId: json['eventId'] is int
            ? json['eventId']
            : (json['eventId'] is String
                  ? int.tryParse(json['eventId']) ?? 0
                  : 0),
        participants: [],
      );
    }

    final eventId = scoreOfParticipants['eventId'] is int
        ? scoreOfParticipants['eventId']
        : (scoreOfParticipants['eventId'] is String
              ? int.tryParse(scoreOfParticipants['eventId']) ?? 0
              : 0);

    final participantsList =
        scoreOfParticipants['participants'] as List<dynamic>? ?? [];
    final participants = participantsList
        .map((p) => ParticipantScoreModel.fromJson(p as Map<String, dynamic>))
        .toList();

    return ScoreResponseModel(eventId: eventId, participants: participants);
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'scoreOfParticipants': {
        'eventId': eventId,
        'participants': participants.map((p) => p.toJson()).toList(),
      },
    };
  }
}

class ParticipantScoreModel {
  final int participantId;
  final String category;
  final List<AsanaScoreModel> asanas;

  ParticipantScoreModel({
    required this.participantId,
    required this.category,
    required this.asanas,
  });

  factory ParticipantScoreModel.fromJson(Map<String, dynamic> json) {
    final asanasList = json['asanas'] as List<dynamic>? ?? [];
    final asanas = asanasList
        .map((a) => AsanaScoreModel.fromJson(a as Map<String, dynamic>))
        .toList();

    return ParticipantScoreModel(
      participantId: json['participantId'] is int
          ? json['participantId']
          : (json['participantId'] is String
                ? int.tryParse(json['participantId']) ?? 0
                : 0),
      category: json['category']?.toString() ?? '',
      asanas: asanas,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participantId': participantId,
      'category': category,
      'asanas': asanas.map((a) => a.toJson()).toList(),
    };
  }
}

class AsanaScoreModel {
  final String asanaName;
  final List<JuryMarkModel> juryMarks;

  AsanaScoreModel({required this.asanaName, required this.juryMarks});

  factory AsanaScoreModel.fromJson(Map<String, dynamic> json) {
    final juryMarksList = json['juryMarks'] as List<dynamic>? ?? [];
    final juryMarks = juryMarksList
        .map((j) => JuryMarkModel.fromJson(j as Map<String, dynamic>))
        .toList();

    return AsanaScoreModel(
      asanaName: json['asanaName']?.toString() ?? '',
      juryMarks: juryMarks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'asanaName': asanaName,
      'juryMarks': juryMarks.map((j) => j.toJson()).toList(),
    };
  }
}

class JuryMarkModel {
  final String mark;
  final int juryId;

  JuryMarkModel({required this.mark, required this.juryId});

  factory JuryMarkModel.fromJson(Map<String, dynamic> json) {
    return JuryMarkModel(
      mark: json['mark']?.toString() ?? '0',
      juryId: json['juryId'] is int
          ? json['juryId']
          : (json['juryId'] is String ? int.tryParse(json['juryId']) ?? 0 : 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {'mark': mark, 'juryId': juryId};
  }
}
