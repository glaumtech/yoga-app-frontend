/// How the Champions category is determined for a competition.
enum ChampionshipStyle {
  separateCategory(
    'SEPARATE_CATEGORY',
    'Separate Champions category',
    'Participants register directly in the Champions category (select Champions below).',
  ),
  fromFirstPlaceWinners(
    'FROM_FIRST_PLACE_WINNERS',
    'From 1st place winners',
    'Champions are filled from 1st-place winners in Common/Special categories for boys and girls. '
        'Do not select Champions as a competition category.',
  );

  const ChampionshipStyle(this.apiValue, this.label, this.description);

  final String apiValue;
  final String label;
  final String description;

  String get confirmationMessage {
    switch (this) {
      case ChampionshipStyle.separateCategory:
        return 'Champions will be a separate registration category on this competition. '
            'You can select the Champions category and set its fee.';
      case ChampionshipStyle.fromFirstPlaceWinners:
        return 'Champions will be determined from 1st-place winners (boys and girls) '
            'in the other categories. The Champions category must not be selected for this competition.';
    }
  }

  static ChampionshipStyle? fromApiValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final v = value.trim().toUpperCase();
    for (final style in ChampionshipStyle.values) {
      if (style.apiValue == v) return style;
    }
    return null;
  }
}
