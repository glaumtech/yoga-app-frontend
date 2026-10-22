class LocationImportRowError {
  final int row;
  final String message;

  const LocationImportRowError({required this.row, required this.message});
}

class LocationImportResult {
  final int totalRows;
  final int statesCreated;
  final int statesReused;
  final int districtsCreated;
  final int districtsReused;
  final int citiesCreated;
  final int citiesReused;
  final int citiesUpdated;
  final int failedRows;
  final int? focusStateId;
  final List<LocationImportRowError> errors;

  const LocationImportResult({
    required this.totalRows,
    required this.statesCreated,
    required this.statesReused,
    required this.districtsCreated,
    required this.districtsReused,
    required this.citiesCreated,
    required this.citiesReused,
    required this.citiesUpdated,
    required this.failedRows,
    required this.focusStateId,
    required this.errors,
  });

  factory LocationImportResult.fromJson(Map<String, dynamic> json) {
    final rawErrors = json['errors'];
    final errors = <LocationImportRowError>[];
    if (rawErrors is List) {
      for (final item in rawErrors) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          errors.add(
            LocationImportRowError(
              row: _asInt(map['row']),
              message: (map['message'] ?? '').toString(),
            ),
          );
        }
      }
    }

    final focus = json['focusStateId'];
    return LocationImportResult(
      totalRows: _asInt(json['totalRows']),
      statesCreated: _asInt(json['statesCreated']),
      statesReused: _asInt(json['statesReused']),
      districtsCreated: _asInt(json['districtsCreated']),
      districtsReused: _asInt(json['districtsReused']),
      citiesCreated: _asInt(json['citiesCreated']),
      citiesReused: _asInt(json['citiesReused']),
      citiesUpdated: _asInt(json['citiesUpdated']),
      failedRows: _asInt(json['failedRows']),
      focusStateId: focus == null ? null : _asInt(focus),
      errors: errors,
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}
