class CompetitionOptionModel {
  final int id;
  final String name;
  final double amount;
  final double spotAmount;

  /// Category allotment options only: `ONLINE` / `OFFLINE` (null = not mode specific).
  /// The same category can be configured once per mode (e.g. COMMON Offline and
  /// COMMON Online/Video), so [id] alone is not unique in that list — use [key].
  final String? mode;

  /// Category allotment options only: `COUNT` / `VIDEO` for online categories.
  final String? submissionType;

  CompetitionOptionModel({
    required this.id,
    required this.name,
    this.amount = 0,
    this.spotAmount = 0,
    this.mode,
    this.submissionType,
  });

  factory CompetitionOptionModel.fromJson(Map<String, dynamic> json) {
    final amount = _parseAmount(json['amount']);
    final spot = _parseAmount(json['spotAmount'] ?? json['spot_amount']);
    return CompetitionOptionModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ??
            json['stageName']?.toString() ??
            json['categoryName']?.toString() ??
            json['groupName']?.toString() ??
            '',
      amount: amount,
      spotAmount: spot > 0 ? spot : amount,
      mode: normalizeMode(json['mode']),
      submissionType: _blankToNull(json['submissionType']),
    );
  }

  /// Unique key for a (category, mode) option, e.g. `12|ONLINE`; `12` when no mode.
  String get key => categoryKey(id, mode);

  bool get isOnline => mode == 'ONLINE';

  bool get isVideo =>
      isOnline && (submissionType ?? '').trim().toUpperCase() == 'VIDEO';

  /// Human readable mode, e.g. `Offline`, `Online · Video`.
  String? get modeLabel => describeMode(mode, submissionType);

  static String categoryKey(int id, String? mode) {
    final m = normalizeMode(mode);
    return m == null ? '$id' : '$id|$m';
  }

  static String? normalizeMode(dynamic value) {
    final m = value?.toString().trim().toUpperCase() ?? '';
    return m == 'ONLINE' || m == 'OFFLINE' ? m : null;
  }

  static String? describeMode(String? mode, String? submissionType) {
    final m = normalizeMode(mode);
    if (m == null) return null;
    if (m == 'OFFLINE') return 'Offline';
    final sub = (submissionType ?? '').trim().toUpperCase();
    if (sub == 'VIDEO') return 'Online · Video';
    if (sub == 'COUNT') return 'Online · Count';
    return 'Online';
  }

  static String? _blankToNull(dynamic value) {
    final s = value?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'spotAmount': spotAmount,
      if (mode != null) 'mode': mode,
      if (submissionType != null) 'submissionType': submissionType,
    };
  }

  static double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
