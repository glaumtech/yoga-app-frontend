import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

/// Competition chosen before the bulk-registration template is downloaded.
/// Sex, category, and group are columns on each participant row.
/// Category is "COMMON (Offline)". Group is "I (GROUP A)". Older files that
/// still split category mode and stage into their own columns are accepted.
class BulkRegistrationTemplateSelection {
  final String competitionId;
  final String competitionName;

  const BulkRegistrationTemplateSelection({
    required this.competitionId,
    required this.competitionName,
  });
}

class ParsedBulkParticipant {
  final String name;
  final String phone;
  final DateTime? dateOfBirth;
  final String sex;
  final String categoryName;
  final String categoryMode;
  final String groupName;
  final String stageName;

  const ParsedBulkParticipant({
    required this.name,
    required this.phone,
    required this.dateOfBirth,
    this.sex = '',
    this.categoryName = '',
    this.categoryMode = '',
    this.groupName = '',
    this.stageName = '',
  });
}

class ParsedBulkRegistrationTemplate {
  final String? error;
  final BulkRegistrationTemplateSelection? selection;
  final List<ParsedBulkParticipant> participants;
  final int invalidPhones;
  final int invalidDates;

  const ParsedBulkRegistrationTemplate({
    this.error,
    this.selection,
    this.participants = const [],
    this.invalidPhones = 0,
    this.invalidDates = 0,
  });
}

const bulkRegistrationExampleName = 'Example Participant';

ParsedBulkRegistrationTemplate parseBulkRegistrationTemplate(Uint8List bytes) {
  final text = utf8
      .decode(bytes, allowMalformed: true)
      .replaceFirst('\uFEFF', '')
      .trim();
  if (text.isEmpty) {
    return const ParsedBulkRegistrationTemplate(
      error: 'The selected file is empty',
    );
  }

  final firstLine = text
      .split(RegExp(r'\r?\n'))
      .firstWhere((line) => line.trim().isNotEmpty, orElse: () => '');
  final delimiter = firstLine.contains(';') && !firstLine.contains(',')
      ? ';'
      : ',';
  final table = CsvToListConverter(
    fieldDelimiter: delimiter,
    shouldParseNumbers: false,
    eol: '\n',
  ).convert(text.replaceAll('\r\n', '\n').replaceAll('\r', '\n'));

  return parseBulkRegistrationRows(
    table.map((row) => row.map((cell) => cell?.toString() ?? '').toList()).toList(),
  );
}

ParsedBulkRegistrationTemplate parseBulkRegistrationRows(
  List<List<String>> table,
) {
  final meta = <String, String>{};
  var headerIndex = -1;
  for (var i = 0; i < table.length; i++) {
    final cells = _cells(table[i]);
    if (cells.isEmpty) continue;
    if (cells.first.toLowerCase() == 'name') {
      headerIndex = i;
      break;
    }
    if (cells.length >= 2) {
      meta[_metaKey(cells.first)] = cells[1];
    }
  }

  if (headerIndex < 0) {
    return const ParsedBulkRegistrationTemplate(
      error:
          'This file is not a bulk registration template. Download the test template and fill it.',
    );
  }

  final headers = _cells(table[headerIndex]).map(_metaKey).toList();
  final nameCol = _columnIndex(headers, const ['name']);
  final phoneCol = _columnIndex(headers, const ['phone']);
  final dobCol = _columnIndex(headers, const ['date of birth', 'dob']);
  final sexCol = _columnIndex(headers, const ['sex']);
  final categoryCol = _columnIndex(headers, const ['category']);
  final categoryModeCol = _columnIndex(headers, const ['category mode']);
  final groupCol = _columnIndex(headers, const ['group']);
  final stageCol = _columnIndex(headers, const ['stage']);

  final competitionId = meta['competition id'] ?? '';
  final competitionName = meta['competition'] ?? '';

  if (competitionId.isEmpty && competitionName.isEmpty) {
    return const ParsedBulkRegistrationTemplate(
      error: 'The template is missing the competition. Download it again.',
    );
  }

  final participants = <ParsedBulkParticipant>[];
  var invalidPhones = 0;
  var invalidDates = 0;
  for (var i = headerIndex + 1; i < table.length; i++) {
    final cells = _cells(table[i]);
    if (cells.every((cell) => cell.isEmpty)) continue;
    final name = _cellAt(cells, nameCol < 0 ? 0 : nameCol);
    if (name.isEmpty) continue;
    if (name.toLowerCase() == bulkRegistrationExampleName.toLowerCase()) {
      continue;
    }
    final phone = _normalizePhone(_cellAt(cells, phoneCol < 0 ? 1 : phoneCol));
    final rawDate = _cellAt(cells, dobCol < 0 ? 2 : dobCol);
    final dob = _parseTemplateDate(rawDate);
    if (phone.length != 10) invalidPhones++;
    if (rawDate.isNotEmpty && dob == null) invalidDates++;
    participants.add(
      ParsedBulkParticipant(
        name: name,
        phone: phone,
        dateOfBirth: dob,
        sex: _participantValue(cells, sexCol, meta['sex']),
        categoryName: _participantValue(cells, categoryCol, meta['category']),
        categoryMode: _participantValue(
          cells,
          categoryModeCol,
          meta['category mode'],
        ),
        groupName: _participantValue(cells, groupCol, meta['group']),
        stageName: _participantValue(cells, stageCol, meta['stage']),
      ),
    );
  }

  if (participants.isEmpty) {
    return const ParsedBulkRegistrationTemplate(
      error:
          'Add participant name, phone, and date of birth in the template, then import it.',
    );
  }

  return ParsedBulkRegistrationTemplate(
    selection: BulkRegistrationTemplateSelection(
      competitionId: competitionId,
      competitionName: competitionName,
    ),
    participants: participants,
    invalidPhones: invalidPhones,
    invalidDates: invalidDates,
  );
}

List<String> _cells(List<dynamic> row) {
  return row.map((cell) => cell?.toString().trim() ?? '').toList();
}

int _columnIndex(List<String> headers, List<String> names) {
  for (var i = 0; i < headers.length; i++) {
    if (names.contains(headers[i])) return i;
  }
  return -1;
}

String _cellAt(List<String> cells, int index) {
  if (index < 0 || index >= cells.length) return '';
  return cells[index];
}

/// Cell value when the column exists; otherwise the legacy header-line value.
String _participantValue(List<String> cells, int index, String? legacy) {
  if (index >= 0) return _cellAt(cells, index);
  return legacy?.trim() ?? '';
}

String _metaKey(String raw) => raw.trim().toLowerCase();

String _normalizePhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11 && digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  if (digits.length > 10 && digits.startsWith('91')) {
    digits = digits.substring(digits.length - 10);
  }
  return digits;
}

DateTime? _parseTemplateDate(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;

  if (!text.contains('/') && !text.contains('-') && !text.contains('.')) {
    final serial = int.tryParse(text);
    if (serial != null && serial >= 20000 && serial <= 80000) {
      final date = DateTime(1899, 12, 30).add(Duration(days: serial));
      return _validDate(date.year, date.month, date.day);
    }
  }

  final iso = DateTime.tryParse(text);
  if (iso != null && text.contains('-') && text.indexOf('-') == 4) {
    return DateTime(iso.year, iso.month, iso.day);
  }

  final numeric = RegExp(
    r'^(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{4})$',
  ).firstMatch(text);
  if (numeric != null) {
    return _validDate(
      int.parse(numeric.group(3)!),
      int.parse(numeric.group(2)!),
      int.parse(numeric.group(1)!),
    );
  }

  final named = RegExp(
    r'^(\d{1,2})[\/\-.\s]([A-Za-z]{3,9})[\/\-.\s](\d{4})$',
  ).firstMatch(text);
  if (named != null) {
    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };
    final month = months[named.group(2)!.substring(0, 3).toLowerCase()];
    if (month == null) return null;
    return _validDate(int.parse(named.group(3)!), month, int.parse(named.group(1)!));
  }

  return null;
}

DateTime? _validDate(int year, int month, int day) {
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;
  if (date.isAfter(DateTime.now())) return null;
  return date;
}
