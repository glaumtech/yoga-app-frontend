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
    this.yogaTeacherName,
    this.yogaTeacherCell,
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
  final String? yogaTeacherName;
  final String? yogaTeacherCell;
  final String? label;

  static const ReportsParticipantsListPreset all = ReportsParticipantsListPreset(
    label: 'Total Participants',
  );

  factory ReportsParticipantsListPreset.boys() =>
      const ReportsParticipantsListPreset(
        genders: ['MALE'],
        label: 'No of Boys',
      );

  factory ReportsParticipantsListPreset.girls() =>
      const ReportsParticipantsListPreset(
        genders: ['FEMALE'],
        label: 'No of Girls',
      );

  factory ReportsParticipantsListPreset.categoryType(String type) =>
      ReportsParticipantsListPreset(
        categoryTypes: [type.toUpperCase()],
        label: _formatDisplayLabel(type.toUpperCase()),
      );

  factory ReportsParticipantsListPreset.onlineRegistration() =>
      const ReportsParticipantsListPreset(
        spotRegistration: false,
        label: 'Online Registration',
      );

  factory ReportsParticipantsListPreset.spotRegistration() =>
      const ReportsParticipantsListPreset(
        spotRegistration: true,
        label: 'Spot Registration',
      );

  factory ReportsParticipantsListPreset.institution(
    int institutionId, {
    String? institutionName,
    String? yogaTeacherName,
    String? yogaTeacherCell,
  }) {
    final teacherName = yogaTeacherName?.trim() ?? '';
    final teacherCell = yogaTeacherCell?.trim() ?? '';
    final instLabel = institutionName?.trim().isNotEmpty == true
        ? institutionName!.trim()
        : 'Institution';
    return ReportsParticipantsListPreset(
      institutionId: institutionId,
      yogaTeacherName: teacherName.isEmpty ? null : teacherName,
      yogaTeacherCell: teacherCell.isEmpty ? null : teacherCell,
      label: teacherName.isEmpty
          ? instLabel
          : '$instLabel · $teacherName',
    );
  }

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

  factory ReportsParticipantsListPreset.yogaCentersOnly() =>
      const ReportsParticipantsListPreset(
        institutionKind: 'YOGA_CENTER',
        label: 'Yoga Centers',
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

  factory ReportsParticipantsListPreset.yogaTeacher({
    required String yogaTeacherName,
    String? yogaTeacherCell,
  }) {
    final name = yogaTeacherName.trim();
    final cell = yogaTeacherCell?.trim() ?? '';
    return ReportsParticipantsListPreset(
      yogaTeacherName: name,
      yogaTeacherCell: cell.isEmpty ? null : cell,
      label: name.isNotEmpty ? name : 'Yoga Master Students',
    );
  }

  String get displayTitle {
    if (label != null && label!.trim().isNotEmpty) {
      return _formatDisplayLabel(label!.trim());
    }
    if (genders != null && genders!.length == 1) {
      if (genders!.first.toUpperCase() == 'MALE') return 'Boys';
      if (genders!.first.toUpperCase() == 'FEMALE') return 'Girls';
    }
    if (categoryTypes != null && categoryTypes!.length == 1) {
      return _formatDisplayLabel(categoryTypes!.first);
    }
    if (spotRegistration == true) return 'Spot registration';
    if (spotRegistration == false) return 'Online registration';
    return 'All participants';
  }

  static String _formatDisplayLabel(String raw) {
    switch (raw.toUpperCase()) {
      case 'COMMON':
        return 'Common Category';
      case 'SPECIAL':
        return 'Special Category';
      case 'CHAMPIONS':
        return 'Champions Category';
      default:
        return raw;
    }
  }
}
