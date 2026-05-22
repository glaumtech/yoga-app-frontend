import 'dart:convert';

/// Optional wrapper for persisted designer state.
///
/// The certificate template body can be plain HTML, or (for backward
/// compatibility) JSON that includes a `designer` object.
class CertificateDesignerEnvelope {
  final Map<String, dynamic> designer;

  const CertificateDesignerEnvelope({required this.designer});

  static CertificateDesignerEnvelope? tryDecode(String? raw) {
    if (raw == null) return null;
    final text = raw.trim();
    if (text.isEmpty) return null;

    dynamic decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      return null;
    }

    if (decoded is! Map) return null;
    final map = Map<String, dynamic>.from(decoded);

    final nested = map['designer'];
    if (nested is Map) {
      return CertificateDesignerEnvelope(
        designer: Map<String, dynamic>.from(nested),
      );
    }

    // Accept direct designer payloads too.
    if (map.containsKey('layers') || map.containsKey('paper')) {
      return CertificateDesignerEnvelope(designer: map);
    }

    return null;
  }
}
