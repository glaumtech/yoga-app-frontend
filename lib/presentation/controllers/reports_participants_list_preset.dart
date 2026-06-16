/// Filters applied when opening the registered participants report from the dashboard.
class ReportsParticipantsListPreset {
  const ReportsParticipantsListPreset({
    this.genders,
    this.categoryTypes,
    this.spotRegistration,
    this.institutionId,
    this.institutionKind,
    this.hasInstitution,
    this.registrationPrefix,
    this.age,
    this.label,
  });

  final List<String>? genders;
  final List<String>? categoryTypes;
  final bool? spotRegistration;
  final int? institutionId;

  /// `SCHOOL` or `COLLEGE` — filters by institution type on the report API.
  final String? institutionKind;

  /// When true, only registrations linked to an institution are included.
  final bool? hasInstitution;
  final String? registrationPrefix;
  final int? age;
  final String? label;

  static const ReportsParticipantsListPreset all =
      ReportsParticipantsListPreset();

  factory ReportsParticipantsListPreset.boys() =>
      const ReportsParticipantsListPreset(
        genders: ['MALE'],
        label: 'Boys',
      );

  factory ReportsParticipantsListPreset.girls() =>
      const ReportsParticipantsListPreset(
        genders: ['FEMALE'],
        label: 'Girls',
      );

  factory ReportsParticipantsListPreset.categoryType(String type) =>
      ReportsParticipantsListPreset(
        categoryTypes: [type.toUpperCase()],
        label: type,
      );

  factory ReportsParticipantsListPreset.onlineRegistration() =>
      const ReportsParticipantsListPreset(
        spotRegistration: false,
        label: 'Online registration',
      );

  factory ReportsParticipantsListPreset.spotRegistration() =>
      const ReportsParticipantsListPreset(
        spotRegistration: true,
        label: 'Spot registration',
      );

  factory ReportsParticipantsListPreset.institution(
    int institutionId, {
    String? institutionName,
  }) =>
      ReportsParticipantsListPreset(
        institutionId: institutionId,
        label: institutionName?.trim().isNotEmpty == true
            ? institutionName!.trim()
            : 'Institution',
      );

  factory ReportsParticipantsListPreset.allInstitutions() =>
      const ReportsParticipantsListPreset(
        hasInstitution: true,
        label: 'All institutions',
      );

  factory ReportsParticipantsListPreset.schoolsOnly() =>
      const ReportsParticipantsListPreset(
        institutionKind: 'SCHOOL',
        label: 'Schools only',
      );

  factory ReportsParticipantsListPreset.collegesOnly() =>
      const ReportsParticipantsListPreset(
        institutionKind: 'COLLEGE',
        label: 'Colleges only',
      );

  factory ReportsParticipantsListPreset.prefixAndAge({
    required String prefix,
    required int age,
  }) =>
      ReportsParticipantsListPreset(
        registrationPrefix: prefix.toUpperCase(),
        age: age,
        label: 'Age $age ($prefix)',
      );
}
