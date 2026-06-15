import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'upload_filename_helper.dart';

/// Result of validating and optionally compressing a profile/participant photo.
class ProcessedPhoto {
  const ProcessedPhoto({
    required this.bytes,
    required this.fileName,
    required this.xFile,
    this.file,
  });

  final Uint8List bytes;
  final String fileName;
  final XFile xFile;
  final File? file;
}

class PhotoUploadProcessor {
  PhotoUploadProcessor._();

  /// Participant/user photos: compress above this down to [targetBytes].
  static const int compressThresholdBytes = 1 * 1024 * 1024;

  /// Target size after participant/user photo compression.
  static const int targetBytes = 1 * 1024 * 1024;

  /// Brochure and bonafide image uploads: compress above this down to [documentImageTargetBytes].
  static const int documentImageCompressThresholdBytes = 2 * 1024 * 1024;

  /// Target size after brochure/bonafide image compression.
  static const int documentImageTargetBytes = 2 * 1024 * 1024;

  static Future<ProcessedPhoto?> processXFile(
    XFile file, {
    int? compressThresholdBytes,
    int? targetBytes,
  }) async {
    final bytes = await file.readAsBytes();
    return processBytes(
      bytes,
      originalFileName: file.name,
      compressThresholdBytes: compressThresholdBytes,
      targetBytes: targetBytes,
    );
  }

  static Future<ProcessedPhoto?> processBytes(
    Uint8List bytes, {
    String? originalFileName,
    int? compressThresholdBytes,
    int? targetBytes,
  }) async {
    if (bytes.isEmpty) return null;

    final threshold = compressThresholdBytes ?? PhotoUploadProcessor.compressThresholdBytes;
    final target = targetBytes ?? PhotoUploadProcessor.targetBytes;

    final wasCompressed = bytes.length > threshold;
    final outputBytes = wasCompressed
        ? await _compressToTarget(
            bytes,
            targetBytes: target,
            failureMessage:
                'Could not compress image below ${_formatMb(target)}. Try a smaller image.',
          )
        : bytes;

    final fileName = _outputFileName(
      originalFileName,
      outputBytes,
      wasCompressed: wasCompressed,
    );
    final xFile = XFile.fromData(
      outputBytes,
      name: fileName,
      mimeType: wasCompressed ? 'image/jpeg' : _mimeTypeForFileName(fileName),
    );

    File? file;
    if (!kIsWeb) {
      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/upload_${DateTime.now().millisecondsSinceEpoch}_$fileName';
      file = File(path);
      await file.writeAsBytes(outputBytes);
    }

    return ProcessedPhoto(
      bytes: outputBytes,
      fileName: fileName,
      xFile: xFile,
      file: file,
    );
  }

  static String _outputFileName(
    String? originalName,
    Uint8List bytes, {
    required bool wasCompressed,
  }) {
    if (wasCompressed) {
      final stem = UploadFilenameHelper.resolveFilename(
        originalName: originalName,
        bytes: bytes,
        allowedExtensions: UploadFilenameHelper.photoExtensions,
        defaultStem: 'photo',
      );
      final dot = stem.lastIndexOf('.');
      final nameStem = dot > 0 ? stem.substring(0, dot) : 'photo';
      return '$nameStem.jpg';
    }
    return UploadFilenameHelper.resolveParticipantPhotoFilename(
      originalName,
      bytes,
    );
  }

  static String _formatMb(int bytes) {
    final mb = bytes / (1024 * 1024);
    return mb == mb.roundToDouble() ? '${mb.toInt()} MB' : '${mb.toStringAsFixed(1)} MB';
  }

  static String _mimeTypeForFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    return 'image/jpeg';
  }

  static Future<Uint8List> _compressToTarget(
    Uint8List input, {
    required int targetBytes,
    required String failureMessage,
  }) async {
    final decoded = img.decodeImage(input);
    if (decoded == null) {
      throw const PhotoUploadException('Unable to read image file');
    }

    final qualities = [85, 75, 65, 55, 45, 35, 25, 15];
    final scalePercents = [100, 90, 80, 70, 60, 50, 40, 30];

    for (final scalePercent in scalePercents) {
      final image = scalePercent == 100
          ? decoded
          : img.copyResize(
              decoded,
              width: (decoded.width * scalePercent / 100).round(),
              height: (decoded.height * scalePercent / 100).round(),
            );

      for (final quality in qualities) {
        final encoded = Uint8List.fromList(
          img.encodeJpg(image, quality: quality),
        );
        if (encoded.length <= targetBytes) {
          return encoded;
        }
      }
    }

    final fallback = img.copyResize(decoded, width: 320);
    final encoded = Uint8List.fromList(img.encodeJpg(fallback, quality: 10));
    if (encoded.length <= targetBytes) {
      return encoded;
    }

    throw PhotoUploadException(failureMessage);
  }
}

class PhotoUploadException implements Exception {
  const PhotoUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}
