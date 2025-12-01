class SingleParticipantScoreResponseModel {
  final int eventId;
  final ParticipantScoreModel participant;

  SingleParticipantScoreResponseModel({
    required this.eventId,
    required this.participant,
  });

  factory SingleParticipantScoreResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final scoreOfParticipant =
        json['scoreOfParticipant'] as Map<String, dynamic>?;

    if (scoreOfParticipant == null) {
      throw Exception('scoreOfParticipant is null in API response');
    }

    final eventId = scoreOfParticipant['eventId'] is int
        ? scoreOfParticipant['eventId']
        : (scoreOfParticipant['eventId'] is String
              ? int.tryParse(scoreOfParticipant['eventId']) ?? 0
              : 0);

    final participant = ParticipantScoreModel.fromJson(scoreOfParticipant);

    return SingleParticipantScoreResponseModel(
      eventId: eventId,
      participant: participant,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'scoreOfParticipant': {'eventId': eventId, ...participant.toJson()},
    };
  }
}

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
        .map((p) {
          try {
            if (p is Map<String, dynamic>) {
              return ParticipantScoreModel.fromJson(p);
            }
            return null;
          } catch (e) {
            print('Error parsing participant: $e');
            return null;
          }
        })
        .whereType<ParticipantScoreModel>()
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
  final String participantName;
  final String? groupName;
  final String? schoolName;
  final int age;
  final String gender;
  final String? participantCode;
  final List<CategoryScoreModel> categories;
  final String? address;
  final String? dateOfBirth;
  final String? yogaMasterName;
  final int? yogaMasterContact;

  ParticipantScoreModel({
    required this.participantId,
    required this.participantName,
    this.groupName,
    this.schoolName,
    required this.age,
    required this.gender,
    this.participantCode,
    required this.categories,
    this.address,
    this.dateOfBirth,
    this.yogaMasterName,
    this.yogaMasterContact,
  });

  factory ParticipantScoreModel.fromJson(Map<String, dynamic> json) {
    // Safely parse categories - handle null case
    List<CategoryScoreModel> categories = [];
    try {
      final categoriesValue = json['categories'];
      if (categoriesValue != null) {
        if (categoriesValue is List) {
          final categoriesList = categoriesValue;
          categories = categoriesList
              .map((c) {
                try {
                  if (c is Map<String, dynamic>) {
                    return CategoryScoreModel.fromJson(c);
                  }
                  return null;
                } catch (e) {
                  print('Error parsing category: $e');
                  return null;
                }
              })
              .whereType<CategoryScoreModel>()
              .toList();
        }
      }
    } catch (e) {
      print('Error parsing categories list: $e');
      categories = []; // Ensure it's always a list, never null
    }

    return ParticipantScoreModel(
      participantId: json['participantId'] is int
          ? json['participantId']
          : (json['participantId'] is String
                ? int.tryParse(json['participantId']) ?? 0
                : 0),
      participantName: json['participantName']?.toString() ?? '',
      groupName: json['groupName']?.toString(),
      schoolName: json['schoolName']?.toString(),
      age: json['age'] is int
          ? json['age']
          : (json['age'] is String ? int.tryParse(json['age']) ?? 0 : 0),
      gender: json['gender']?.toString() ?? '',
      participantCode: json['participantCode']?.toString(),
      categories: categories, // Always a list, never null
      address: json['address']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      yogaMasterName: json['yogaMasterName']?.toString(),
      yogaMasterContact: json['yogaMasterContact'] is int
          ? json['yogaMasterContact']
          : (json['yogaMasterContact'] is String
                ? int.tryParse(json['yogaMasterContact'])
                : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participantId': participantId,
      'participantName': participantName,
      if (groupName != null) 'groupName': groupName,
      if (schoolName != null) 'schoolName': schoolName,
      'age': age,
      'gender': gender,
      if (participantCode != null) 'participantCode': participantCode,
      'categories': categories.map((c) => c.toJson()).toList(),
      if (address != null) 'address': address,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (yogaMasterName != null) 'yogaMasterName': yogaMasterName,
      if (yogaMasterContact != null) 'yogaMasterContact': yogaMasterContact,
    };
  }
}

class CategoryScoreModel {
  final String category;
  final double grandTotal;
  final List<AsanaScoreModel> asanas;

  CategoryScoreModel({
    required this.category,
    required this.grandTotal,
    required this.asanas,
  });

  factory CategoryScoreModel.fromJson(Map<String, dynamic> json) {
    // Safely parse asanas - handle null case
    List<AsanaScoreModel> asanas = [];
    try {
      final asanasValue = json['asanas'];
      if (asanasValue != null) {
        if (asanasValue is List) {
          final asanasList = asanasValue;
          asanas = asanasList
              .map((a) {
                try {
                  if (a is Map<String, dynamic>) {
                    return AsanaScoreModel.fromJson(a);
                  }
                  return null;
                } catch (e) {
                  print('Error parsing asana: $e');
                  return null;
                }
              })
              .whereType<AsanaScoreModel>()
              .toList();
        }
      }
    } catch (e) {
      print('Error parsing asanas list: $e');
      asanas = []; // Ensure it's always a list, never null
    }

    return CategoryScoreModel(
      category: json['category']?.toString() ?? '',
      grandTotal: json['grandTotal'] is double
          ? json['grandTotal']
          : (json['grandTotal'] is int
                ? json['grandTotal'].toDouble()
                : (json['grandTotal'] is String
                      ? double.tryParse(json['grandTotal']) ?? 0.0
                      : 0.0)),
      asanas: asanas,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'grandTotal': grandTotal,
      'asanas': asanas.map((a) => a.toJson()).toList(),
    };
  }
}

class AsanaScoreModel {
  final String asanaName;
  final double subtotal;
  final List<JuryMarkModel> juryMarks;

  AsanaScoreModel({
    required this.asanaName,
    required this.subtotal,
    required this.juryMarks,
  });

  factory AsanaScoreModel.fromJson(Map<String, dynamic> json) {
    // Safely parse juryMarks - handle null case
    List<JuryMarkModel> juryMarks = [];
    try {
      final juryMarksValue = json['juryMarks'];
      if (juryMarksValue != null) {
        if (juryMarksValue is List) {
          final juryMarksList = juryMarksValue;
          juryMarks = juryMarksList
              .map((j) {
                try {
                  if (j is Map<String, dynamic>) {
                    return JuryMarkModel.fromJson(j);
                  }
                  return null;
                } catch (e) {
                  print('Error parsing jury mark: $e');
                  return null;
                }
              })
              .whereType<JuryMarkModel>()
              .toList();
        }
      }
    } catch (e) {
      print('Error parsing juryMarks list: $e');
      juryMarks = []; // Ensure it's always a list, never null
    }

    return AsanaScoreModel(
      asanaName: json['asanaName']?.toString() ?? '',
      subtotal: json['subtotal'] is double
          ? json['subtotal']
          : (json['subtotal'] is int
                ? json['subtotal'].toDouble()
                : (json['subtotal'] is String
                      ? double.tryParse(json['subtotal']) ?? 0.0
                      : 0.0)),
      juryMarks: juryMarks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'asanaName': asanaName,
      'subtotal': subtotal,
      'juryMarks': juryMarks.map((j) => j.toJson()).toList(),
    };
  }
}

class JuryMarkModel {
  final double score;
  final int juryId;
  final String? juryName;

  JuryMarkModel({required this.score, required this.juryId, this.juryName});

  factory JuryMarkModel.fromJson(Map<String, dynamic> json) {
    return JuryMarkModel(
      score: json['score'] is double
          ? json['score']
          : (json['score'] is int
                ? json['score'].toDouble()
                : (json['score'] is String
                      ? double.tryParse(json['score']) ?? 0.0
                      : 0.0)),
      juryId: json['juryId'] is int
          ? json['juryId']
          : (json['juryId'] is String ? int.tryParse(json['juryId']) ?? 0 : 0),
      juryName: json['juryName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'juryId': juryId,
      if (juryName != null) 'juryName': juryName,
    };
  }
}
