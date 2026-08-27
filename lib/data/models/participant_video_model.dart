class ParticipantVideoModel {
  final DateTime? entryDate;
  final String? submissionType;
  final int? countValue;
  final String? videoUrl;
  final String? driveWebUrl;
  final String? drivePath;
  final String? originalFileName;
  final String? resolution;

  const ParticipantVideoModel({
    this.entryDate,
    this.submissionType,
    this.countValue,
    this.videoUrl,
    this.driveWebUrl,
    this.drivePath,
    this.originalFileName,
    this.resolution,
  });

  bool get isCount =>
      (submissionType ?? '').toUpperCase() == 'COUNT' || countValue != null;

  bool get hasUrl => (videoUrl ?? '').trim().isNotEmpty;

  bool get hasFile =>
      (driveWebUrl ?? '').trim().isNotEmpty ||
      (drivePath ?? '').trim().isNotEmpty;

  bool get hasSubmission => isCount || hasUrl || hasFile;

  factory ParticipantVideoModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ParticipantVideoModel();
    }
    return ParticipantVideoModel(
      entryDate: _parseDate(json['entryDate']),
      submissionType: json['submissionType']?.toString(),
      countValue: json['countValue'] is int
          ? json['countValue'] as int
          : int.tryParse(json['countValue']?.toString() ?? ''),
      videoUrl: json['videoUrl']?.toString(),
      driveWebUrl: json['driveWebUrl']?.toString(),
      drivePath: json['drivePath']?.toString(),
      originalFileName: json['originalFileName']?.toString(),
      resolution: json['resolution']?.toString(),
    );
  }
}

class ParticipantVideoSession {
  final String? token;
  final int? registrationId;
  final String? registrationNo;
  final String? participantName;
  final String? competitionName;
  final String? categoryName;
  final String? sex;
  final bool driveUploadEnabled;

  /// Why file upload is unavailable, straight from the server.
  final String? driveUploadDisabledReason;
  final DateTime? today;
  final DateTime? startedOn;
  final String? lockedMode;
  /// COUNT or VIDEO from category configuration; empty when the participant may choose.
  final String? configuredType;
  final int? competitionId;
  final int? categoryId;
  final int? stageId;
  final int? groupId;
  final bool optForECertificate;
  final bool certificateAvailable;
  final int? durationDays;
  final DateTime? certificateAvailableOn;
  final List<ParticipantVideoModel> entries;
  final ParticipantVideoModel? video;

  const ParticipantVideoSession({
    this.token,
    this.registrationId,
    this.registrationNo,
    this.participantName,
    this.competitionName,
    this.categoryName,
    this.sex,
    this.driveUploadEnabled = false,
    this.driveUploadDisabledReason,
    this.today,
    this.startedOn,
    this.lockedMode,
    this.configuredType,
    this.competitionId,
    this.categoryId,
    this.stageId,
    this.groupId,
    this.optForECertificate = false,
    this.certificateAvailable = false,
    this.durationDays,
    this.certificateAvailableOn,
    this.entries = const [],
    this.video,
  });

  bool get hasStarted => startedOn != null;

  bool get hasConfiguredType {
    final type = configuredType?.trim().toUpperCase();
    return type == 'COUNT' || type == 'VIDEO';
  }

  bool get isCountType {
    final type = (configuredType ?? lockedMode)?.trim().toUpperCase();
    return type == 'COUNT';
  }

  bool get hasSavedUrl => video?.hasUrl == true;

  ParticipantVideoModel? entryFor(DateTime date) {
    final key = _dateKey(date);
    for (final entry in entries) {
      final entryDate = entry.entryDate;
      if (entryDate != null && _dateKey(entryDate) == key) {
        return entry;
      }
    }
    return null;
  }

  factory ParticipantVideoSession.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'];
    final entries = <ParticipantVideoModel>[];
    if (rawEntries is List) {
      for (final item in rawEntries) {
        if (item is Map) {
          entries.add(
            ParticipantVideoModel.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return ParticipantVideoSession(
      token: json['token']?.toString(),
      registrationId: json['registrationId'] is int
          ? json['registrationId'] as int
          : int.tryParse(json['registrationId']?.toString() ?? ''),
      registrationNo: json['registrationNo']?.toString(),
      participantName: json['participantName']?.toString(),
      competitionName: json['competitionName']?.toString(),
      categoryName: json['categoryName']?.toString(),
      sex: json['sex']?.toString(),
      driveUploadEnabled: json['driveUploadEnabled'] == true,
      driveUploadDisabledReason: json['driveUploadDisabledReason']?.toString(),
      today: _parseDate(json['today']),
      startedOn: _parseDate(json['startedOn']),
      lockedMode: json['lockedMode']?.toString(),
      configuredType: json['configuredType']?.toString(),
      competitionId: json['competitionId'] is int
          ? json['competitionId'] as int
          : int.tryParse(json['competitionId']?.toString() ?? ''),
      categoryId: json['categoryId'] is int
          ? json['categoryId'] as int
          : int.tryParse(json['categoryId']?.toString() ?? ''),
      stageId: json['stageId'] is int
          ? json['stageId'] as int
          : int.tryParse(json['stageId']?.toString() ?? ''),
      groupId: json['groupId'] is int
          ? json['groupId'] as int
          : int.tryParse(json['groupId']?.toString() ?? ''),
      optForECertificate: json['optForECertificate'] == true,
      certificateAvailable: json['certificateAvailable'] == true,
      durationDays: json['durationDays'] is int
          ? json['durationDays'] as int
          : int.tryParse(json['durationDays']?.toString() ?? ''),
      certificateAvailableOn: _parseDate(json['certificateAvailableOn']),
      entries: entries,
      video: json['video'] is Map
          ? ParticipantVideoModel.fromJson(
              Map<String, dynamic>.from(json['video'] as Map),
            )
          : null,
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return DateTime(value.year, value.month, value.day);
  if (value is String && value.trim().isNotEmpty) {
    final parsed = DateTime.tryParse(value.trim());
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
  if (value is List && value.length >= 3) {
    final year = int.tryParse(value[0].toString());
    final month = int.tryParse(value[1].toString());
    final day = int.tryParse(value[2].toString());
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }
  return null;
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
