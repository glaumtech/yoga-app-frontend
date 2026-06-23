class CompetitionScoringResetResult {
  final int participantScoresDeleted;
  final int asanaScoresDeleted;
  final int competitionsProcessed;

  const CompetitionScoringResetResult({
    required this.participantScoresDeleted,
    required this.asanaScoresDeleted,
    required this.competitionsProcessed,
  });

  factory CompetitionScoringResetResult.fromJson(Map<String, dynamic> json) {
    return CompetitionScoringResetResult(
      participantScoresDeleted:
          (json['deletedParticipantScoreCount'] as num?)?.toInt() ?? 0,
      asanaScoresDeleted:
          (json['deletedAsanaScoreCount'] as num?)?.toInt() ?? 0,
      competitionsProcessed:
          (json['competitionsProcessed'] as num?)?.toInt() ?? 0,
    );
  }

  bool get hasDeletedData =>
      participantScoresDeleted > 0 || asanaScoresDeleted > 0;
}
