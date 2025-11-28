class TeamModel {
  final String? id;
  final String teamName;
  final String eventId;
  final List<String> juryIds; // List of judge IDs
  final String category; // 'Common' or 'Special'
  final List<Map<String, dynamic>>?
  juryList; // Optional: juryList from API with id and name

  TeamModel({
    this.id,
    required this.teamName,
    required this.eventId,
    required this.juryIds,
    required this.category,
    this.juryList,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    // Handle juryIds - can be List<String> or List<int>
    // Also handle juryList array of objects with id and name
    List<String> juryIdsList = [];

    // Store juryList if available (array of objects with id and name)
    List<Map<String, dynamic>>? juryListData;
    if (json['juryList'] != null && json['juryList'] is List) {
      juryListData = (json['juryList'] as List)
          .map((e) {
            if (e is Map<String, dynamic>) {
              return e;
            }
            return <String, dynamic>{};
          })
          .where((e) => e.isNotEmpty)
          .toList();

      // Extract IDs from juryList
      juryIdsList = juryListData
          .map((e) => e['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    } else if (json['juryIds'] != null) {
      if (json['juryIds'] is List) {
        juryIdsList = (json['juryIds'] as List)
            .map((e) => e.toString())
            .toList();
      }
    } else if (json['jury_ids'] != null) {
      if (json['jury_ids'] is List) {
        juryIdsList = (json['jury_ids'] as List)
            .map((e) => e.toString())
            .toList();
      }
    }

    return TeamModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      teamName:
          json['name']?.toString() ??
          json['teamName']?.toString() ??
          json['team_name']?.toString() ??
          '',
      eventId:
          json['eventId']?.toString() ?? json['event_id']?.toString() ?? '',
      juryIds: juryIdsList,
      category: json['category']?.toString() ?? '',
      juryList: juryListData,
    );
  }

  Map<String, dynamic> toJson({bool includeCreatedAt = false}) {
    return {
      if (id != null) 'id': id,
      'teamName': teamName,
      'eventId': eventId,
      'juryIds': juryIds,
      'category': category,
    };
  }

  TeamModel copyWith({
    String? id,
    String? teamName,
    String? eventId,
    List<String>? juryIds,
    String? category,
    List<Map<String, dynamic>>? juryList,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamModel(
      id: id ?? this.id,
      teamName: teamName ?? this.teamName,
      eventId: eventId ?? this.eventId,
      juryIds: juryIds ?? this.juryIds,
      category: category ?? this.category,
      juryList: juryList ?? this.juryList,
    );
  }
}
