import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'upload_response.dart';

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
}) async {
  final multipart = http.MultipartRequest('POST', url);
  multipart.headers.addAll(headers);
  extraFields?.forEach((key, value) {
    multipart.fields[key] = value;
  });
  multipart.files.add(
    http.MultipartFile.fromBytes(field, bytes, filename: filename),
  );

  final bodyStream = multipart.finalize();
  final totalBytes = multipart.contentLength;
  final request = http.StreamedRequest('POST', url);
  request.headers.addAll(multipart.headers);
  request.contentLength = totalBytes;

  final client = http.Client();
  try {
    final responseFuture = client.send(request);
    var sentBytes = 0;
    final progressStream = bodyStream.transform(
      StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (chunk, sink) {
          sentBytes += chunk.length;
          if (totalBytes > 0) {
            onProgress((sentBytes / totalBytes).clamp(0.0, 1.0));
          }
          sink.add(chunk);
        },
      ),
    );
    await request.sink.addStream(progressStream);
    await request.sink.close();

    final streamed = await responseFuture.timeout(timeout);
    final response = await http.Response.fromStream(streamed);
    return UploadResponse(
      statusCode: response.statusCode,
      body: response.body,
    );
  } finally {
    client.close();
  }
}
