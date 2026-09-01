import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'upload_response.dart';

/// Uses XMLHttpRequest directly because package:http buffers the whole body in
/// the browser, which makes upload progress jump straight to 100%.
Future<UploadResponse> uploadFileWithProgress({
  required Uri url,
  required Map<String, String> headers,
  required String field,
  required Uint8List bytes,
  required String filename,
  required String contentType,
  required void Function(double progress) onProgress,
  required Duration timeout,
  Map<String, String>? extraFields,
}) {
  final request = html.HttpRequest();
  final completer = Completer<UploadResponse>();

  request.open('POST', url.toString());
  headers.forEach((key, value) {
    if (key.toLowerCase() == 'content-type') {
      return; // the browser sets the multipart boundary itself
    }
    request.setRequestHeader(key, value);
  });

  request.upload.onProgress.listen((event) {
    final total = event.total ?? 0;
    final loaded = event.loaded ?? 0;
    if (total > 0) {
      onProgress((loaded / total).clamp(0.0, 1.0));
    }
  });

  void completeWith(UploadResponse response) {
    if (!completer.isCompleted) {
      completer.complete(response);
    }
  }

  void failWith(String message) {
    if (!completer.isCompleted) {
      completer.completeError(UploadException(message));
    }
  }

  request.onLoad.listen((_) {
    completeWith(
      UploadResponse(
        statusCode: request.status ?? 0,
        body: request.responseText ?? '',
      ),
    );
  });
  request.onError.listen((_) {
    failWith(
      'Could not reach the server while uploading. Check your connection and '
      'that the backend allows uploads from this site.',
    );
  });
  request.onAbort.listen((_) => failWith('Upload was cancelled.'));

  final form = html.FormData();
  extraFields?.forEach((key, value) {
    form.append(key, value);
  });
  form.appendBlob(field, html.Blob(<Object>[bytes], contentType), filename);
  request.send(form);

  return completer.future.timeout(
    timeout,
    onTimeout: () {
      request.abort();
      throw TimeoutException('Upload timed out', timeout);
    },
  );
}
