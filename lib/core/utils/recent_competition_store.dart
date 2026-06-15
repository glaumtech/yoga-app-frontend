import 'dart:convert';

import 'storage_service.dart';

class RecentCompetitionEntry {
  const RecentCompetitionEntry({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory RecentCompetitionEntry.fromJson(Map<String, dynamic> json) {
    return RecentCompetitionEntry(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class RecentCompetitionStore {
  RecentCompetitionStore._();

  static const int maxEntries = 5;

  static List<RecentCompetitionEntry> read(String storageKey) {
    try {
      final raw = StorageService.getString(storageKey);
      if (raw == null || raw.isEmpty) return const [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map>()
          .map((item) => RecentCompetitionEntry.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .where((entry) => entry.id.isNotEmpty && entry.name.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> add({
    required String storageKey,
    required String id,
    required String name,
  }) async {
    if (id.isEmpty || name.isEmpty) return;

    final existing = read(storageKey);
    final updated = [
      RecentCompetitionEntry(id: id, name: name),
      ...existing.where((entry) => entry.id != id),
    ].take(maxEntries).toList();

    await StorageService.setString(
      storageKey,
      jsonEncode(updated.map((entry) => entry.toJson()).toList()),
    );
  }
}
