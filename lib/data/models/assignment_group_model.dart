import 'participant_model.dart';

class AssignmentGroupModel {
  final int? assignedId;
  final String? teamId;
  final String teamName;
  final String category;
  final List<ParticipantModel> participants;
  final List<Map<String, dynamic>> juries;

  AssignmentGroupModel({
    this.assignedId,
    this.teamId,
    required this.teamName,
    required this.category,
    required this.participants,
    required this.juries,
  });

  factory AssignmentGroupModel.fromJson(Map<String, dynamic> json) {
    // Parse participants
    List<ParticipantModel> participantsList = [];
    if (json['participants'] != null && json['participants'] is List) {
      final participantsData = json['participants'] as List;
      for (final participantJson in participantsData) {
        try {
          // Map API response fields to ParticipantModel fields
          final participantData = participantJson is Map<String, dynamic>
              ? Map<String, dynamic>.from(participantJson)
              : participantJson as Map<String, dynamic>;

          // Map 'name' to 'participantName' if present
          if (participantData.containsKey('name') &&
              !participantData.containsKey('participantName')) {
            participantData['participantName'] = participantData['name'];
          }

          // Map 'group' to 'standard' if present
          if (participantData.containsKey('group') &&
              !participantData.containsKey('standard')) {
            participantData['standard'] = participantData['group'];
          }

          // Ensure required fields have defaults if missing
          participantData['dateOfBirth'] ??= DateTime.now().toIso8601String();
          participantData['age'] ??= 0;
          participantData['gender'] ??= '';
          participantData['category'] ??= '';
          participantData['standard'] ??= '';
          participantData['schoolName'] ??= '';
          participantData['address'] ??= '';
          participantData['yogaMasterName'] ??= '';
          participantData['yogaMasterContact'] ??= '';

          final participant = ParticipantModel.fromJson(participantData);
          participantsList.add(participant);
        } catch (e) {
          print('Error parsing participant: $e');
          print('Participant JSON: $participantJson');
        }
      }
    }

    // Parse juries
    List<Map<String, dynamic>> juriesList = [];
    if (json['juries'] != null && json['juries'] is List) {
      juriesList = (json['juries'] as List)
          .map(
            (e) => e is Map<String, dynamic>
                ? Map<String, dynamic>.from(e)
                : <String, dynamic>{},
          )
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return AssignmentGroupModel(
      assignedId: json['assignedId'] is int
          ? json['assignedId']
          : (json['assignedId'] is String
                ? int.tryParse(json['assignedId'])
                : null),
      teamId: json['teamId']?.toString(),
      teamName: json['teamName']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      participants: participantsList,
      juries: juriesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (assignedId != null) 'assignedId': assignedId,
      if (teamId != null) 'teamId': teamId,
      'teamName': teamName,
      'category': category,
      'participants': participants.map((p) => p.toJson()).toList(),
      'juries': juries,
    };
  }
}
