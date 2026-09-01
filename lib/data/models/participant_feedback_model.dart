class ParticipantFeedbackModel {
  final int? id;
  final int? registrationId;
  final int? competitionId;
  final String? registrationNo;
  final String? participantName;
  final String reviewText;
  final bool isPublic;
  final bool hasImage;
  final String? imageUrl;

  const ParticipantFeedbackModel({
    this.id,
    this.registrationId,
    this.competitionId,
    this.registrationNo,
    this.participantName,
    this.reviewText = '',
    this.isPublic = false,
    this.hasImage = false,
    this.imageUrl,
  });

  factory ParticipantFeedbackModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ParticipantFeedbackModel();
    }

    int? parseInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '');
    }

    bool parseBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v.toString().toLowerCase();
      return s == 'true' || s == '1' || s == 'yes';
    }

    return ParticipantFeedbackModel(
      id: parseInt(json['id']),
      registrationId: parseInt(json['registrationId']),
      competitionId: parseInt(json['competitionId']),
      registrationNo: json['registrationNo']?.toString(),
      participantName: json['participantName']?.toString(),
      reviewText: json['reviewText']?.toString() ?? '',
      isPublic: parseBool(json['isPublic']) || parseBool(json['publiclyVisible']),
      hasImage: parseBool(json['hasImage']),
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  String? absoluteImageUrl(String baseUrl) {
    final relative = imageUrl?.trim();
    if (relative == null || relative.isEmpty) return null;
    if (relative.startsWith('http://') || relative.startsWith('https://')) {
      return relative;
    }
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final path = relative.startsWith('/') ? relative : '/$relative';
    return '$base$path';
  }
}
