import 'dart:html' as html;
import 'dart:typed_data';

String? createVideoBlobUrl(Uint8List bytes) {
  final blob = html.Blob([bytes], 'video/mp4');
  return html.Url.createObjectUrlFromBlob(blob);
}

void revokeVideoBlobUrl(String url) {
  html.Url.revokeObjectUrl(url);
}
