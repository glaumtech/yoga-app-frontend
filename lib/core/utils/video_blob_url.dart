import 'dart:typed_data';

import 'video_blob_url_stub.dart'
    if (dart.library.html) 'video_blob_url_web.dart' as impl;

String? createVideoBlobUrl(Uint8List bytes) => impl.createVideoBlobUrl(bytes);

void revokeVideoBlobUrl(String url) => impl.revokeVideoBlobUrl(url);
