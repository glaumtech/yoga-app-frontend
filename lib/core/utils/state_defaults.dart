import '../../data/models/state_model.dart';

/// Default location pre-selection used across organization forms.
class StateDefaults {
  StateDefaults._();

  static const String defaultCountry = 'India';
  static const String tamilNaduName = 'Tamil Nadu';
  static const String tamilNaduCode = 'TN';

  static StateModel? findTamilNadu(Iterable<StateModel> states) {
    for (final s in states) {
      final name = s.stateName.trim().toLowerCase();
      final code = s.stateCode.trim().toUpperCase();
      if (name == 'tamil nadu' ||
          name == 'tamilnadu' ||
          code == tamilNaduCode) {
        return s;
      }
    }
    return null;
  }
}
