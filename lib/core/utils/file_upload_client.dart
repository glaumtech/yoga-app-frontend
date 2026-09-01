import 'dart:typed_data';

import 'file_upload_client_io.dart'
    if (dart.library.html) 'file_upload_client_web.dart'
    as impl;
import 'upload_response.dart';

export 'upload_response.dart';

/// Posts [bytes] as a single multipart field and reports real byte-level progress.
Future<UploadResponse> uploadFileWithProgress({
  required Uri url,
  required Map<String, String> headers,
  required String field,
  required Uint8List bytes,
  required String filename,
  required String contentType,
  required void Function(double progress) onProgress,
  Duration timeout = const Duration(minutes: 30),
  Map<String, String>? extraFields,
}) {
  return impl.uploadFileWithProgress(
    url: url,
    headers: headers,
    field: field,
    bytes: bytes,
    filename: filename,
    contentType: contentType,
    onProgress: onProgress,
    timeout: timeout,
    extraFields: extraFields,
  );
}
