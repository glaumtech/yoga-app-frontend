class UploadResponse {
  final int statusCode;
  final String body;

  const UploadResponse({required this.statusCode, required this.body});
}

class UploadException implements Exception {
  final String message;

  const UploadException(this.message);

  @override
  String toString() => message;
}
