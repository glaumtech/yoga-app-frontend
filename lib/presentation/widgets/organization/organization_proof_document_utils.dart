import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

Uint8List organizationProofNormalizeBytes(Uint8List bytes) {
  final copy = Uint8List(bytes.length);
  for (var i = 0; i < bytes.length; i++) {
    copy[i] = bytes[i];
  }
  return copy;
}

Future<Uint8List> organizationProofReadPickedPdfBytes(PlatformFile picked) async {
  late final Uint8List raw;
  if (kIsWeb) {
    raw = await picked.xFile.readAsBytes();
  } else if (picked.bytes != null && picked.bytes!.isNotEmpty) {
    raw = picked.bytes!;
  } else {
    raw = await picked.xFile.readAsBytes();
  }
  return organizationProofNormalizeBytes(raw);
}

String? organizationProofFileNameFromPath(String? path) {
  if (path == null || path.trim().isEmpty) return null;
  final parts = path.replaceAll('\\', '/').split('/');
  return parts.isEmpty ? null : parts.last;
}
