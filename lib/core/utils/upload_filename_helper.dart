import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Ensures multipart uploads use filenames the backend accepts (extension-based).
class UploadFilenameHelper {
  UploadFilenameHelper._();

  static const List<String> photoExtensions = ['jpg', 'jpeg', 'png'];
  static const List<String> certificateExtensions = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
  ];

  static const int maxImageBytes = 10 * 1024 * 1024;
  static const int maxPdfBytes = 25 * 1024 * 1024;

  static String extensionFromBytes(Uint8List bytes) {
    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return 'jpg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46) {
      return 'pdf';
    }
    return '';
  }

  static String? extensionFromFileName(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final base = name.split('/').last.split('\\').last.trim();
    final dot = base.lastIndexOf('.');
    if (dot <= 0 || dot == base.length - 1) return null;
    return base.substring(dot + 1).toLowerCase();
  }

  static String resolveFilename({
    required String? originalName,
    required Uint8List bytes,
    required List<String> allowedExtensions,
    required String defaultStem,
  }) {
    var ext = extensionFromFileName(originalName);
    if (ext == null || !allowedExtensions.contains(ext)) {
      final detected = extensionFromBytes(bytes);
      if (detected.isNotEmpty && allowedExtensions.contains(detected)) {
        ext = detected;
      }
    }

    if (ext == null || !allowedExtensions.contains(ext)) {
      throw FormatException(
        allowedExtensions.contains('pdf')
            ? 'File must be PDF, JPG, JPEG, or PNG.'
            : 'Photo must be JPG, JPEG, or PNG.',
      );
    }

    final stem = _stemFromFileName(originalName) ?? defaultStem;
    return '$stem.$ext';
  }

  static String resolveParticipantPhotoFilename(
    String? originalName,
    Uint8List bytes,
  ) {
    return resolveFilename(
      originalName: originalName,
      bytes: bytes,
      allowedExtensions: photoExtensions,
      defaultStem: 'photo',
    );
  }

  static String resolveBonafideFilename(String? originalName, Uint8List bytes) {
    final nameExt = extensionFromFileName(originalName);
    final bytesExt = extensionFromBytes(bytes);
    final isPdf = nameExt == 'pdf' || bytesExt == 'pdf';
    if (isPdf) {
      return resolveFilename(
        originalName: originalName,
        bytes: bytes,
        allowedExtensions: const ['pdf'],
        defaultStem: 'certificate',
      );
    }
    return resolveFilename(
      originalName: originalName,
      bytes: bytes,
      allowedExtensions: photoExtensions,
      defaultStem: 'certificate',
    );
  }

  static String? validateImageSize(Uint8List bytes, {required bool isPdf}) {
    final maxSize = isPdf ? maxPdfBytes : maxImageBytes;
    if (bytes.length > maxSize) {
      return isPdf
          ? 'PDF certificate size exceeds 25 MB limit'
          : 'Image file size exceeds 10 MB limit';
    }
    return null;
  }

  static Future<({Uint8List bytes, String filename})> readParticipantPhoto({
    XFile? xFile,
    File? file,
  }) async {
    final bytes = await _readBytes(xFile: xFile, file: file);
    final filename = resolveParticipantPhotoFilename(
      xFile?.name ?? file?.path,
      bytes,
    );
    final sizeError = validateImageSize(bytes, isPdf: false);
    if (sizeError != null) throw FormatException(sizeError);
    return (bytes: bytes, filename: filename);
  }

  static Future<({Uint8List bytes, String filename})> readBonafideCertificate({
    XFile? xFile,
    File? file,
  }) async {
    final bytes = await _readBytes(xFile: xFile, file: file);
    final filename = resolveBonafideFilename(
      xFile?.name ?? file?.path,
      bytes,
    );
    final isPdf = extensionFromFileName(filename) == 'pdf';
    final sizeError = validateImageSize(bytes, isPdf: isPdf);
    if (sizeError != null) throw FormatException(sizeError);
    return (bytes: bytes, filename: filename);
  }

  static Future<({Uint8List bytes, String filename})> readPaymentProof({
    required XFile xFile,
  }) async {
    final bytes = await xFile.readAsBytes();
    final filename = resolveParticipantPhotoFilename(xFile.name, bytes);
    final sizeError = validateImageSize(bytes, isPdf: false);
    if (sizeError != null) throw FormatException(sizeError);
    return (bytes: bytes, filename: filename);
  }

  static Future<Uint8List> _readBytes({XFile? xFile, File? file}) async {
    if (xFile != null) return xFile.readAsBytes();
    if (file != null) return file.readAsBytes();
    throw const FormatException('No file selected');
  }

  static String? _stemFromFileName(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final base = name.split('/').last.split('\\').last.trim();
    final dot = base.lastIndexOf('.');
    final stem = dot > 0 ? base.substring(0, dot).trim() : base.trim();
    return stem.isEmpty ? null : stem;
  }
}
