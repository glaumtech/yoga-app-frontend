/// One online submission of a participant, as shown on the jury scoring screen.
class JuryParticipantVideo {
  final String? entryDate;
  final String? submissionType;
  final int? countValue;
  final String? resolution;
  final String? fileName;

  /// Streams inline (HTTP Range) — for the in-app preview player.
  final String? previewUrl;

  /// Same file served as an attachment — for the browser's download manager.
  final String? downloadUrl;

  /// Link the participant submitted instead of uploading a file.
  final String? externalUrl;

  const JuryParticipantVideo({
    this.entryDate,
    this.submissionType,
    this.countValue,
    this.resolution,
    this.fileName,
    this.previewUrl,
    this.downloadUrl,
    this.externalUrl,
  });

  bool get hasFile => previewUrl != null;

  /// [fileUrlBase] is `<baseUrl>/participant-video/file`.
  factory JuryParticipantVideo.fromJson(
    Map<String, dynamic> json, {
    required String fileUrlBase,
  }) {
    String? clean(dynamic v) {
      final s = v?.toString().trim() ?? '';
      return s.isEmpty ? null : s;
    }

    final token = clean(json['fileToken']);
    final tokenQuery = token == null
        ? null
        : '?token=${Uri.encodeQueryComponent(token)}';
    return JuryParticipantVideo(
      entryDate: clean(json['entryDate']),
      submissionType: clean(json['submissionType']),
      countValue: json['countValue'] is int
          ? json['countValue'] as int
          : int.tryParse(json['countValue']?.toString() ?? ''),
      resolution: clean(json['resolution']),
      fileName: clean(json['fileName']),
      previewUrl: tokenQuery == null ? null : '$fileUrlBase$tokenQuery',
      downloadUrl: tokenQuery == null
          ? null
          : '$fileUrlBase$tokenQuery&download=true',
      externalUrl: clean(json['videoUrl']) ?? clean(json['driveWebUrl']),
    );
  }
}
