import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'bulk_registration_template.dart';

const bulkTemplateDropdownRows = 500;

/// Excel template. Sex, category, and group are dropdowns filled from the
/// selected competition, using the same labels as the registration form.
Uint8List buildBulkRegistrationTemplateXlsx({
  required BulkRegistrationTemplateSelection selection,
  required List<String> sexes,
  required List<String> categories,
  required List<String> groups,
}) {
  final sexList = _uniqueLabels(sexes);
  final categoryList = _uniqueLabels(categories);
  final groupList = _uniqueLabels(groups);

  final participants = _participantsSheet(
    selection: selection,
    sexCount: sexList.length,
    categoryCount: categoryList.length,
    groupCount: groupList.length,
  );
  final lists = _listsSheet(
    sexes: sexList,
    categories: categoryList,
    groups: groupList,
  );

  final archive = Archive();
  void add(String path, String xml) {
    final data = utf8.encode(xml);
    archive.addFile(ArchiveFile(path, data.length, data));
  }

  add('[Content_Types].xml', _contentTypes);
  add('_rels/.rels', _rootRels);
  add('xl/workbook.xml', _workbook);
  add('xl/_rels/workbook.xml.rels', _workbookRels);
  add('xl/styles.xml', _styles);
  add('xl/worksheets/sheet1.xml', participants);
  add('xl/worksheets/sheet2.xml', lists);

  return Uint8List.fromList(ZipEncoder().encode(archive));
}

/// First worksheet of an Excel file, as text rows. Dates stored as Excel
/// serial numbers are returned as that number so the template parser can
/// convert them.
List<List<String>> readBulkRegistrationXlsxRows(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final workbook = _zipText(archive, 'xl/workbook.xml');
  if (workbook == null) {
    throw const FormatException('Workbook is missing');
  }

  final sheetTarget =
      _participantSheetTarget(workbook, archive) ??
      'xl/worksheets/sheet1.xml';
  final sheetXml = _zipText(archive, sheetTarget);
  if (sheetXml == null) {
    throw const FormatException('Worksheet is missing');
  }

  final shared = _sharedStrings(_zipText(archive, 'xl/sharedStrings.xml'));
  return _sheetRows(sheetXml, shared);
}

String _participantsSheet({
  required BulkRegistrationTemplateSelection selection,
  required int sexCount,
  required int categoryCount,
  required int groupCount,
}) {
  final rows = StringBuffer();
  rows.write(_textRow(1, ['Competition Id', selection.competitionId]));
  rows.write(_textRow(2, ['Competition', selection.competitionName]));
  rows.write(
    _textRow(4, const [
      'Name',
      'Phone',
      'Date of Birth',
      'Sex',
      'Category',
      'Group',
    ]),
  );

  final validations = <String>[];
  // Column letters on the Lists sheet follow the order these are added,
  // and only columns that have values are written.
  var listColumn = 0;
  String? listLetter(int count) {
    if (count <= 0) return null;
    final letter = _columnLetter(listColumn);
    listColumn++;
    return letter;
  }

  final sexLetter = listLetter(sexCount);
  final categoryLetter = listLetter(categoryCount);
  final groupLetter = listLetter(groupCount);

  void addValidation(String column, String? listLetter, int count) {
    if (listLetter == null || count <= 0) return;
    validations.add(
      '<dataValidation type="list" allowBlank="1" showErrorMessage="1" '
      'errorTitle="Invalid value" error="Choose a value from this competition." '
      'sqref="${column}5:$column$bulkTemplateDropdownRows">'
      '<formula1>Lists!\$$listLetter\$1:\$$listLetter\$$count</formula1>'
      '</dataValidation>',
    );
  }

  addValidation('D', sexLetter, sexCount);
  addValidation('E', categoryLetter, categoryCount);
  addValidation('F', groupLetter, groupCount);

  final validationXml = validations.isEmpty
      ? ''
      : '<dataValidations count="${validations.length}">'
            '${validations.join()}'
            '</dataValidations>';

  return '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <cols>
    <col min="1" max="1" width="24" customWidth="1"/>
    <col min="2" max="2" width="16" customWidth="1"/>
    <col min="3" max="3" width="16" customWidth="1"/>
    <col min="4" max="4" width="14" customWidth="1"/>
    <col min="5" max="6" width="24" customWidth="1"/>
  </cols>
  <sheetData>${rows.toString()}</sheetData>
  $validationXml
</worksheet>
''';
}

String _listsSheet({
  required List<String> sexes,
  required List<String> categories,
  required List<String> groups,
}) {
  final columns = <List<String>>[
    if (sexes.isNotEmpty) sexes,
    if (categories.isNotEmpty) categories,
    if (groups.isNotEmpty) groups,
  ];
  final maxRows = columns.fold<int>(0, (max, column) {
    return column.length > max ? column.length : max;
  });
  final rows = StringBuffer();
  for (var r = 0; r < maxRows; r++) {
    final cells = StringBuffer();
    for (var c = 0; c < columns.length; c++) {
      if (r >= columns[c].length) continue;
      final ref = '${_columnLetter(c)}${r + 1}';
      cells.write(
        '<c r="$ref" t="inlineStr"><is><t>${_xml(columns[c][r])}</t></is></c>',
      );
    }
    rows.write('<row r="${r + 1}">$cells</row>');
  }

  return '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheetData>${rows.toString()}</sheetData>
</worksheet>
''';
}

String _textRow(int rowNumber, List<String> values) {
  final cells = StringBuffer();
  for (var i = 0; i < values.length; i++) {
    if (values[i].isEmpty) continue;
    final ref = '${_columnLetter(i)}$rowNumber';
    cells.write(
      '<c r="$ref" t="inlineStr"><is><t>${_xml(values[i])}</t></is></c>',
    );
  }
  return '<row r="$rowNumber">$cells</row>';
}

String _columnLetter(int index) {
  var n = index;
  final letters = StringBuffer();
  do {
    letters.writeCharCode(65 + (n % 26));
    n = (n ~/ 26) - 1;
  } while (n >= 0);
  return letters.toString().split('').reversed.join();
}

List<String> _uniqueLabels(List<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    final label = value.trim();
    if (label.isEmpty) continue;
    if (seen.add(label.toLowerCase())) result.add(label);
  }
  return result;
}

String _xml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

const _contentTypes = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
</Types>
''';

const _rootRels = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>
''';

const _workbook = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="Participants" sheetId="1" r:id="rId1"/>
    <sheet name="Lists" sheetId="2" r:id="rId2" state="hidden"/>
  </sheets>
</workbook>
''';

const _workbookRels = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>
''';

const _styles = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="1"><font><sz val="11"/><name val="Calibri"/></font></fonts>
  <fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills>
  <borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
  <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
  <cellXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/></cellXfs>
</styleSheet>
''';

String? _participantSheetTarget(String workbook, Archive archive) {
  final sheets = RegExp(
    r'<sheet\b([^>]*)/?>',
    caseSensitive: false,
  ).allMatches(workbook);
  String? fallback;
  for (final sheet in sheets) {
    final attrs = sheet.group(1) ?? '';
    final name = _attr(attrs, 'name')?.toLowerCase() ?? '';
    final state = _attr(attrs, 'state')?.toLowerCase() ?? '';
    final relId = _attr(attrs, 'id');
    if (relId == null || state == 'hidden') continue;
    final target = _relationshipTarget(archive, relId);
    if (target == null) continue;
    fallback ??= target;
    if (name == 'participants') return target;
  }
  return fallback;
}

String? _relationshipTarget(Archive archive, String relId) {
  final rels = _zipText(archive, 'xl/_rels/workbook.xml.rels');
  if (rels == null) return null;
  final matches = RegExp(
    r'<Relationship\b([^>]*)/?>',
    caseSensitive: false,
  ).allMatches(rels);
  for (final match in matches) {
    final attrs = match.group(1) ?? '';
    if (_attr(attrs, 'Id') != relId) continue;
    final target = _attr(attrs, 'Target');
    if (target == null || target.isEmpty) return null;
    final path = target.startsWith('/') ? target.substring(1) : 'xl/$target';
    return path.replaceAll('\\', '/');
  }
  return null;
}

List<String> _sharedStrings(String? xml) {
  if (xml == null || xml.isEmpty) return const [];
  final items = <String>[];
  final matches = RegExp(
    r'<si\b[^>]*>(.*?)</si>',
    caseSensitive: false,
    dotAll: true,
  ).allMatches(xml);
  for (final match in matches) {
    final body = match.group(1) ?? '';
    final texts = RegExp(
      r'<t\b[^>]*>(.*?)</t>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(body);
    final buffer = StringBuffer();
    for (final text in texts) {
      buffer.write(_xmlUnescape(text.group(1) ?? ''));
    }
    items.add(buffer.toString());
  }
  return items;
}

List<List<String>> _sheetRows(String xml, List<String> sharedStrings) {
  final rows = <int, Map<int, String>>{};
  var maxColumn = 0;
  final rowMatches = RegExp(
    r'<row\b([^>]*)>(.*?)</row>',
    caseSensitive: false,
    dotAll: true,
  ).allMatches(xml);
  for (final rowMatch in rowMatches) {
    final rowAttrs = rowMatch.group(1) ?? '';
    final rowXml = rowMatch.group(2) ?? '';
    var rowNumber = int.tryParse(_attr(rowAttrs, 'r') ?? '') ?? 0;
    if (rowNumber <= 0) rowNumber = rows.length + 1;
    final cells = <int, String>{};
    final cellMatches = RegExp(
      r'<c\b([^>]*)(?:/>|>(.*?)</c>)',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(rowXml);
    for (final cellMatch in cellMatches) {
      final attrs = cellMatch.group(1) ?? '';
      final inner = cellMatch.group(2) ?? '';
      final ref = _attr(attrs, 'r') ?? '';
      final column = _columnIndexFromRef(ref);
      if (column < 0) continue;
      if (column > maxColumn) maxColumn = column;
      cells[column] = _cellText(attrs, inner, sharedStrings);
    }
    rows[rowNumber] = cells;
  }

  if (rows.isEmpty) return const [];
  final lastRow = rows.keys.reduce((a, b) => a > b ? a : b);
  return [
    for (var r = 1; r <= lastRow; r++)
      [
        for (var c = 0; c <= maxColumn; c++) (rows[r]?[c] ?? '').trim(),
      ],
  ];
}

String _cellText(String attrs, String inner, List<String> sharedStrings) {
  final type = (_attr(attrs, 't') ?? '').toLowerCase();
  if (type == 'inlinestr') {
    final texts = RegExp(
      r'<t\b[^>]*>(.*?)</t>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(inner);
    final buffer = StringBuffer();
    for (final text in texts) {
      buffer.write(_xmlUnescape(text.group(1) ?? ''));
    }
    return buffer.toString();
  }

  final valueMatch = RegExp(
    r'<v\b[^>]*>(.*?)</v>',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(inner);
  final raw = _xmlUnescape(valueMatch?.group(1)?.trim() ?? '');
  if (type == 's') {
    final index = int.tryParse(raw);
    if (index != null && index >= 0 && index < sharedStrings.length) {
      return sharedStrings[index];
    }
    return '';
  }
  if (type == 'b') return raw == '1' ? 'TRUE' : 'FALSE';
  if (raw.isEmpty) return '';
  return _plainNumber(raw);
}

String _plainNumber(String raw) {
  final number = double.tryParse(raw);
  if (number == null) return raw;
  if (number == number.roundToDouble() && number.abs() < 1000000000000000) {
    return number.round().toString();
  }
  return raw;
}

int _columnIndexFromRef(String ref) {
  final letters = RegExp(r'^[A-Za-z]+').firstMatch(ref)?.group(0);
  if (letters == null || letters.isEmpty) return -1;
  var index = 0;
  for (final code in letters.toUpperCase().codeUnits) {
    index = (index * 26) + (code - 64);
  }
  return index - 1;
}

String? _attr(String attrs, String name) {
  final match = RegExp(
    '(?:^|\\s)(?:[\\w-]+:)?$name="([^"]*)"',
    caseSensitive: false,
  ).firstMatch(attrs);
  return match == null ? null : _xmlUnescape(match.group(1) ?? '');
}

String? _zipText(Archive archive, String path) {
  final wanted = path.replaceAll('\\', '/').toLowerCase();
  for (final file in archive.files) {
    if (!file.isFile) continue;
    final name = file.name.replaceAll('\\', '/').toLowerCase();
    if (name == wanted || name.endsWith('/$wanted')) {
      return utf8.decode(file.content, allowMalformed: true);
    }
  }
  return null;
}

String _xmlUnescape(String value) {
  return value
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');
}
