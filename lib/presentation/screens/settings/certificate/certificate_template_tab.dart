import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../data/models/certificate_designer_envelope.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../controllers/certificate_template_controller.dart';

enum _LayerKind { text, image }

class _TemplateLayer {
  _TemplateLayer({
    required this.id,
    required this.kind,
    required this.name,
    required this.offset,
    this.text,
    this.imageBytes,
    this.fontSize = 28,
  });

  final String id;
  final _LayerKind kind;
  String name;
  Offset offset;
  String? text;
  Uint8List? imageBytes;
  double fontSize;
  Color textColor = const Color(0xFF1F2A44);
  FontWeight fontWeight = FontWeight.w700;
  bool isItalic = false;
  bool isUnderlined = false;
  bool hasDashedBottomBorder = false;
  TextAlign textAlign = TextAlign.left;
  double lineHeight = 1.2;
  double letterSpacing = 0;
  String fontFamily = 'Inter';
  double textBoxWidth = 360;
}

/// Settings: certificate template designer (layout similar to admin “create template” UIs).
class CertificateTemplateTab extends StatefulWidget {
  const CertificateTemplateTab({super.key});

  @override
  State<CertificateTemplateTab> createState() => _CertificateTemplateTabState();
}

class _CertificateTemplateTabState extends State<CertificateTemplateTab> {
  static const List<String> _paperOptions = <String>[
    'A4 (794x1123 px)',
    'A3 (1123x1587 px)',
    'A5 (559x794 px)',
    'Letter (816x1056 px)',
    'Square (200x200 px)',
    'Custom',
  ];

  final TextEditingController _canvasNameController = TextEditingController();
  final TextEditingController _layerTextController = TextEditingController();
  final FocusNode _inlineEditFocusNode = FocusNode();
  final TextEditingController _customWidthMmController = TextEditingController(
    text: '1123',
  );
  final TextEditingController _customHeightMmController = TextEditingController(
    text: '794',
  );

  String _selectedPaper = 'Custom';
  String _selectedTemplateGender = 'Male';
  bool _portrait = false;
  double _customWidthMm = 1123;
  double _customHeightMm = 794;
  String? _backgroundImageUrl;
  Uint8List? _backgroundImageBytes;

  bool _designerHydrated = false;
  late final Worker _loadingWorker;
  String? _inlineEditingLayerId;
  bool? _multiMoveMode = false;
  Set<String>? _multiSelectedLayerIds;

  bool get _isMultiMoveMode => _multiMoveMode ?? false;

  Set<String> get _selectedLayerIds => _multiSelectedLayerIds ??= <String>{};

  int _selectedLayerIndex = 2;
  int _idSeq = 12;
  final List<_TemplateLayer> _layers = <_TemplateLayer>[
    _TemplateLayer(
        id: 'layer_1',
        kind: _LayerKind.text,
        name: '{{competitionName}}',
        text: '{{competitionName}}',
        offset: const Offset(290, 12),
        fontSize: 48,
      )
      ..fontWeight = FontWeight.w800
      ..textAlign = TextAlign.center
      ..textColor = const Color(0xFF111827)
      ..textBoxWidth = 560,
    _TemplateLayer(
        id: 'layer_2',
        kind: _LayerKind.text,
        name: 'Organized by details',
        text:
            'Organized by\nTamilNadu Professionally Qualified Registered Yoga Teachers Welfare Association,\nCo-organized by\n{{branchName}},{{branchCity}}',
        offset: const Offset(260, 86),
        fontSize: 18,
      )
      ..fontWeight = FontWeight.w700
      ..lineHeight = 1.4
      ..textAlign = TextAlign.center
      ..textColor = const Color(0xFF111827)
      ..textBoxWidth = 620,
    _TemplateLayer(
        id: 'layer_3',
        kind: _LayerKind.text,
        name: '{{winnerCategory}} Prize',
        text: '{{winnerCategory}} Prize',
        offset: const Offset(350, 238),
        fontSize: 45,
      )
      ..fontWeight = FontWeight.w800
      ..textAlign = TextAlign.center
      ..textColor = const Color(0xFF111827)
      ..textBoxWidth = 420,
    _TemplateLayer(
        id: 'layer_4',
        kind: _LayerKind.text,
        name: 'Body line 1',
        text:
            'This certificate is proudly presented to Selvan/Selvi {{participantName}} of',
        offset: const Offset(84, 368),
        fontSize: 18,
      )
      ..textColor = const Color(0xFF111827)
      ..textBoxWidth = 930,
    _TemplateLayer(
        id: 'layer_5',
        kind: _LayerKind.text,
        name: '{{participantName}}',
        text: '{{participantName}}',
        offset: const Offset(574, 364),
        fontSize: 35,
      )
      ..fontWeight = FontWeight.w800
      ..hasDashedBottomBorder = true
      ..textColor = const Color(0xFF111827)
      ..textBoxWidth = 246,
    _TemplateLayer(
        id: 'layer_6',
        kind: _LayerKind.text,
        name: '{{institutionName}}',
        text: '{{institutionName}}',
        offset: const Offset(390, 407),
        fontSize: 34,
      )
      ..fontWeight = FontWeight.w800
      ..hasDashedBottomBorder = true
      ..textColor = const Color(0xFF111827)
      ..textBoxWidth = 420,
    _TemplateLayer(
        id: 'layer_7',
        kind: _LayerKind.text,
        name: 'Body line 2',
        text:
            'his/her participation in the {{competitionName}} held on {{date}} at {{competitionAddrss}}. He/She is appreciated for {{winnerCategory}} Category. He/She is appreciated for his/her Excellence in the Competition.',
        offset: const Offset(76, 456),
        fontSize: 18,
      )
      ..textColor = const Color(0xFF111827)
      ..textBoxWidth = 960,
    _TemplateLayer(
        id: 'layer_8',
        kind: _LayerKind.text,
        name: 'Sign 1',
        text: 'Signature 1\nPresident',
        offset: const Offset(95, 675),
        fontSize: 34,
      )
      ..textAlign = TextAlign.center
      ..textColor = const Color(0xFF111827)
      ..textBoxWidth = 200,
    _TemplateLayer(
        id: 'layer_9',
        kind: _LayerKind.text,
        name: 'Sign 2',
        text: 'Signature 2\nSecretary',
        offset: const Offset(328, 675),
        fontSize: 34,
      )
      ..textAlign = TextAlign.center
      ..textColor = const Color(0xFF111827)
      ..textBoxWidth = 200,
    _TemplateLayer(
        id: 'layer_10',
        kind: _LayerKind.text,
        name: 'Sign 3',
        text: 'Signature 3\nCoordinator',
        offset: const Offset(560, 675),
        fontSize: 34,
      )
      ..textAlign = TextAlign.center
      ..textColor = const Color(0xFF111827)
      ..textBoxWidth = 220,
    _TemplateLayer(
        id: 'layer_11',
        kind: _LayerKind.text,
        name: 'Sign 4',
        text: 'Signature 4\nChief Guest',
        offset: const Offset(818, 675),
        fontSize: 34,
      )
      ..textAlign = TextAlign.center
      ..textColor = const Color(0xFF111827)
      ..textBoxWidth = 200,
  ];

  @override
  void initState() {
    super.initState();
    Get.put(CertificateTemplateController(), permanent: false);
    final c = _c;
    _loadingWorker = ever<bool>(c.isLoading, (loading) {
      if (!loading && mounted) {
        _hydrateFromController(c);
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || c.isLoading.value) return;
      _hydrateFromController(c);
      setState(() {});
    });
    _syncLayerTextEditor();
  }

  @override
  void dispose() {
    _loadingWorker.dispose();
    _canvasNameController.dispose();
    _layerTextController.dispose();
    _inlineEditFocusNode.dispose();
    _customWidthMmController.dispose();
    _customHeightMmController.dispose();
    super.dispose();
  }

  CertificateTemplateController get _c =>
      Get.find<CertificateTemplateController>();

  static int _fontWeightToInt(FontWeight w) => w.value;

  static FontWeight _fontWeightFromInt(int v) {
    switch (v) {
      case 100:
        return FontWeight.w100;
      case 200:
        return FontWeight.w200;
      case 300:
        return FontWeight.w300;
      case 400:
        return FontWeight.w400;
      case 500:
        return FontWeight.w500;
      case 600:
        return FontWeight.w600;
      case 700:
        return FontWeight.w700;
      case 800:
        return FontWeight.w800;
      case 900:
        return FontWeight.w900;
      default:
        return FontWeight.w700;
    }
  }

  static String _textAlignToString(TextAlign a) {
    switch (a) {
      case TextAlign.left:
        return 'left';
      case TextAlign.right:
        return 'right';
      case TextAlign.center:
        return 'center';
      case TextAlign.justify:
        return 'justify';
      case TextAlign.start:
        return 'start';
      case TextAlign.end:
        return 'end';
    }
  }

  static TextAlign _textAlignFromString(String? s) {
    switch (s) {
      case 'right':
        return TextAlign.right;
      case 'center':
        return TextAlign.center;
      case 'justify':
        return TextAlign.justify;
      case 'start':
        return TextAlign.start;
      case 'end':
        return TextAlign.end;
      default:
        return TextAlign.left;
    }
  }

  void _hydrateFromController(
    CertificateTemplateController c, {
    bool force = false,
  }) {
    if (c.isLoading.value) return;
    if (_designerHydrated && !force) return;
    _designerHydrated = true;

    final name = c.templateName.text.trim();
    if (name.isEmpty) {
      c.templateName.text = 'Winner Certificate for Female';
    }
    _canvasNameController.text = c.templateName.text;

    final body = c.templateBody.text;
    final envelope = CertificateDesignerEnvelope.tryDecode(body);
    if (envelope != null) {
      _applyDesignerJson(envelope.designer);
      _syncBackgroundFromBackend(c);
    } else {
      final restoredFromHtml = _applyTemplateHtml(body);
      if (!restoredFromHtml) {
        _syncBackgroundFromBackend(c);
        final hasBackground =
            (_backgroundImageBytes != null &&
                _backgroundImageBytes!.isNotEmpty) ||
            (_backgroundImageUrl != null &&
                _backgroundImageUrl!.trim().isNotEmpty);
        if (!hasBackground) {
          _syncBackgroundFromTemplateBody(body);
        }
      }
      _syncTemplateGenderFromPronouns(c);
    }
    _syncLayerTextEditor();
  }

  void _ensureSelectedTemplateBody(CertificateTemplateController c, {int? id}) {
    final selectedId = id ?? c.selectedTemplateId.value;
    if (selectedId == null) return;
    String templateBody = '';
    for (final t in c.templates) {
      if (t.id == selectedId) {
        templateBody = t.templateBody.trim();
        break;
      }
    }
    if (templateBody.isEmpty) return;
    c.templateBody.text = templateBody;
  }

  bool _applyTemplateHtml(String body) {
    final text = body.trim();
    if (text.isEmpty) return false;

    final positionedTextDiv = RegExp(
      r"""<div[^>]*style=["'][^"']*position\s*:\s*absolute[^"']*["'][^>]*>[\s\S]*?<\/div>""",
      caseSensitive: false,
    );
    if (!positionedTextDiv.hasMatch(text)) return false;

    final rootMatch = RegExp(
      r"""<div[^>]*style=["']([^"']*position\s*:\s*relative[^"']*)["'][^>]*>""",
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(text);
    if (rootMatch != null) {
      final style = rootMatch.group(1) ?? '';
      final width = _styleDouble(style, 'width');
      final height = _styleDouble(style, 'height');
      if (width != null && height != null && width > 0 && height > 0) {
        _selectedPaper = 'Custom';
        _customWidthMm = width;
        _customHeightMm = height;
        _customWidthMmController.text = _fmtNum(width);
        _customHeightMmController.text = _fmtNum(height);
      }
      _syncBackgroundFromRootStyle(style);
    }

    final List<_TemplateLayer> parsed = <_TemplateLayer>[];

    final imageRe = RegExp(
      r"""<img[^>]*src=["']([^"']+)["'][^>]*style=["']([^"']*)["'][^>]*>""",
      caseSensitive: false,
      dotAll: true,
    );
    for (final m in imageRe.allMatches(text)) {
      final src = m.group(1)?.trim() ?? '';
      final style = m.group(2) ?? '';
      final left = _styleDouble(style, 'left') ?? 0;
      final top = _styleDouble(style, 'top') ?? 0;
      Uint8List? bytes;
      final data = _tryParseDataImageUrl(src);
      if (data != null) {
        bytes = data.$2;
      }
      parsed.add(
        _TemplateLayer(
          id: 'layer_${_idSeq++}',
          kind: _LayerKind.image,
          name: 'Image',
          offset: Offset(left, top),
          imageBytes: bytes,
        ),
      );
    }

    final textRe = RegExp(
      r"""<div[^>]*style=["']([^"']*position\s*:\s*absolute[^"']*)["'][^>]*>([\s\S]*?)<\/div>""",
      caseSensitive: false,
      dotAll: true,
    );
    for (final m in textRe.allMatches(text)) {
      final style = m.group(1) ?? '';
      final raw = m.group(2) ?? '';
      final left = _styleDouble(style, 'left') ?? 0;
      final top = _styleDouble(style, 'top') ?? 0;
      final width = _styleDouble(style, 'width') ?? 360;
      final fontSize = _styleDouble(style, 'font-size') ?? 28;
      final fontWeight = _styleInt(style, 'font-weight') ?? 700;
      final lineHeight = _styleDouble(style, 'line-height') ?? 1.2;
      final letterSpacing = _styleDouble(style, 'letter-spacing') ?? 0;
      final fontFamily =
          _styleString(
            style,
            'font-family',
          )?.split(',').first.replaceAll("'", '').replaceAll('"', '').trim() ??
          'Inter';
      final textAlign = _textAlignFromString(
        _styleString(style, 'text-align') ?? 'left',
      );
      final colorCss = _styleString(style, 'color');
      final color = _colorFromCss(colorCss) ?? const Color(0xFF1F2A44);
      final hasBoldTag = RegExp(
        r'<\s*b\s*>',
        caseSensitive: false,
      ).hasMatch(raw);
      final hasItalicTag = RegExp(
        r'<\s*em\s*>',
        caseSensitive: false,
      ).hasMatch(raw);
      final hasUnderlineTag = RegExp(
        r'<\s*u\s*>',
        caseSensitive: false,
      ).hasMatch(raw);

      final isItalic =
          (_styleString(style, 'font-style') ?? 'normal')
              .toLowerCase()
              .contains('italic') ||
          hasItalicTag;
      final isUnderlined =
          (_styleString(style, 'text-decoration') ?? 'none')
              .toLowerCase()
              .contains('underline') ||
          hasUnderlineTag;
      final hasDashedBottomBorder = (RegExp(
        r'border-bottom\s*:\s*[^;]*dashed',
        caseSensitive: false,
      ).hasMatch(style));

      final layerText = _htmlUnescape(
        raw
            .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
            .replaceAll(RegExp(r'</?b>', caseSensitive: false), '')
            .replaceAll(RegExp(r'</?em>', caseSensitive: false), '')
            .replaceAll(RegExp(r'</?u>', caseSensitive: false), '')
            .replaceAll(RegExp(r'<[^>]+>'), '')
            .trim(),
      );
      final layerName = _htmlUnescape(
        raw
            .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
            .replaceAll(RegExp(r'<[^>]+>'), '')
            .trim(),
      );

      parsed.add(
        _TemplateLayer(
            id: 'layer_${_idSeq++}',
            kind: _LayerKind.text,
            name: layerName.isEmpty ? 'Text layer' : layerName,
            offset: Offset(left, top),
            text: layerText,
            fontSize: fontSize,
          )
          ..fontWeight = _fontWeightFromInt(hasBoldTag ? 700 : fontWeight)
          ..isItalic = isItalic
          ..isUnderlined = isUnderlined
          ..hasDashedBottomBorder = hasDashedBottomBorder
          ..textAlign = textAlign
          ..lineHeight = lineHeight
          ..letterSpacing = letterSpacing
          ..fontFamily = fontFamily
          ..textBoxWidth = width
          ..textColor = color,
      );
    }

    if (parsed.isEmpty) return false;
    _layers
      ..clear()
      ..addAll(parsed);
    _recalcIdSeq();
    _selectedLayerIndex = 0;
    return true;
  }

  String _htmlUnescape(String value) {
    return value
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&');
  }

  String? _styleString(String style, String key) {
    final m = RegExp(
      '$key\\s*:\\s*([^;]+)',
      caseSensitive: false,
    ).firstMatch(style);
    return m?.group(1)?.trim();
  }

  double? _styleDouble(String style, String key) {
    final raw = _styleString(style, key);
    if (raw == null || raw.isEmpty) return null;
    final normalized = raw.replaceAll('px', '').trim();
    return double.tryParse(normalized);
  }

  int? _styleInt(String style, String key) {
    final raw = _styleString(style, key);
    if (raw == null || raw.isEmpty) return null;
    return int.tryParse(raw.trim());
  }

  Color? _colorFromCss(String? css) {
    if (css == null) return null;
    final v = css.trim().toLowerCase();
    if (v.isEmpty) return null;
    if (v.startsWith('#')) {
      final hex = v.substring(1);
      if (hex.length == 6) {
        final n = int.tryParse(hex, radix: 16);
        if (n == null) return null;
        return Color(0xFF000000 | n);
      }
    }
    final rgba = RegExp(
      r'rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)(?:\s*,\s*([0-9.]+))?\s*\)',
      caseSensitive: false,
    ).firstMatch(v);
    if (rgba != null) {
      final r = int.tryParse(rgba.group(1) ?? '0') ?? 0;
      final g = int.tryParse(rgba.group(2) ?? '0') ?? 0;
      final b = int.tryParse(rgba.group(3) ?? '0') ?? 0;
      final a = double.tryParse(rgba.group(4) ?? '1') ?? 1;
      return Color.fromRGBO(r, g, b, a.clamp(0, 1));
    }
    return null;
  }

  void _syncBackgroundFromRootStyle(String rootStyle) {
    final match = RegExp(
      r'background-image\s*:\s*url\((.*?)\)',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(rootStyle);

    if (match == null) {
      _backgroundImageUrl = null;
      _backgroundImageBytes = null;
      return;
    }

    var raw = (match.group(1) ?? '').trim();
    if (raw.isEmpty) {
      _backgroundImageUrl = null;
      _backgroundImageBytes = null;
      return;
    }

    if ((raw.startsWith('"') && raw.endsWith('"')) ||
        (raw.startsWith("'") && raw.endsWith("'"))) {
      raw = raw.substring(1, raw.length - 1).trim();
    }

    raw = raw
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&');

    final parsedData = _tryParseDataImageUrl(raw);
    if (parsedData != null) {
      _backgroundImageBytes = parsedData.$2;
      _backgroundImageUrl = null;
      return;
    }

    _backgroundImageUrl = raw;
    _backgroundImageBytes = null;
  }

  void _syncBackgroundFromBackend(CertificateTemplateController c) {
    final url = c.backgroundImageUrl.text.trim();
    if (url.isEmpty) {
      _backgroundImageUrl = null;
      _backgroundImageBytes = null;
      return;
    }
    final data = _tryParseDataImageUrl(url);
    if (data != null) {
      _backgroundImageBytes = data.$2;
      _backgroundImageUrl = null;
      return;
    }
    _backgroundImageUrl = url;
    _backgroundImageBytes = null;
  }

  void _syncBackgroundFromTemplateBody(String body) {
    final text = body.trim();
    if (text.isEmpty) return;

    final match = RegExp(
      r'background-image\s*:\s*url\((.*?)\)',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(text);
    if (match == null) return;

    var raw = (match.group(1) ?? '').trim();
    if (raw.isEmpty) return;
    if ((raw.startsWith('"') && raw.endsWith('"')) ||
        (raw.startsWith("'") && raw.endsWith("'"))) {
      raw = raw.substring(1, raw.length - 1).trim();
    }
    raw = raw
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&');
    if (raw.isEmpty) return;

    final parsedData = _tryParseDataImageUrl(raw);
    if (parsedData != null) {
      _backgroundImageBytes = parsedData.$2;
      _backgroundImageUrl = null;
      return;
    }

    _backgroundImageUrl = raw;
    _backgroundImageBytes = null;
  }

  (String mime, Uint8List bytes)? _tryParseDataImageUrl(String url) {
    final prefix = RegExp(r'^data:([^;]+);base64,(.+)$');
    final m = prefix.firstMatch(url.trim());
    if (m == null) return null;
    final mime = m.group(1) ?? 'image/png';
    final b64 = m.group(2);
    if (b64 == null) return null;
    try {
      return (mime, base64Decode(b64));
    } catch (_) {
      return null;
    }
  }

  void _syncTemplateGenderFromPronouns(CertificateTemplateController c) {
    final d = c.subjectPronounDefault.text.trim().toLowerCase();
    _selectedTemplateGender = (d == 'she' || d == 'her') ? 'Female' : 'Male';
  }

  void _applyDesignerJson(Map<String, dynamic> d) {
    final paper = d['paper']?.toString();
    if (paper != null && paper.isNotEmpty) {
      _selectedPaper = _normalizedPaper(paper);
    }
    _portrait = d['portrait'] == true;
    final cw = (d['customWidthPx'] as num?)?.toDouble();
    final ch = (d['customHeightPx'] as num?)?.toDouble();
    if (cw != null && cw > 0) {
      _customWidthMm = cw;
      _customWidthMmController.text = _fmtNum(cw);
    }
    if (ch != null && ch > 0) {
      _customHeightMm = ch;
      _customHeightMmController.text = _fmtNum(ch);
    }
    final gender = d['templateGender']?.toString();
    if (gender == 'Female' || gender == 'Male') {
      _selectedTemplateGender = gender!;
    }

    final bg = d['background'];
    if (bg is Map) {
      final b64 = bg['base64']?.toString();
      if (b64 != null && b64.isNotEmpty) {
        try {
          _backgroundImageBytes = base64Decode(b64);
          _backgroundImageUrl = null;
        } catch (_) {
          _backgroundImageBytes = null;
        }
      }
    } else {
      _backgroundImageBytes = null;
      _backgroundImageUrl = d['backgroundImageUrl']?.toString();
      if (_backgroundImageUrl != null && _backgroundImageUrl!.isEmpty) {
        _backgroundImageUrl = null;
      }
    }

    final layersJson = d['layers'];
    if (layersJson is List && layersJson.isNotEmpty) {
      _layers
        ..clear()
        ..addAll(
          layersJson.whereType<Map>().map(
            (e) => _layerFromJson(Map<String, dynamic>.from(e)),
          ),
        );
      _recalcIdSeq();
      if (_selectedLayerIndex >= _layers.length) {
        _selectedLayerIndex = _layers.isEmpty ? 0 : _layers.length - 1;
      }
    }
  }

  String _fmtNum(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toString();
  }

  void _recalcIdSeq() {
    var maxId = 0;
    for (final layer in _layers) {
      final m = RegExp(r'^layer_(\d+)$').firstMatch(layer.id);
      if (m != null) {
        final n = int.tryParse(m.group(1) ?? '');
        if (n != null && n > maxId) maxId = n;
      }
    }
    _idSeq = maxId + 1;
  }

  _TemplateLayer _layerFromJson(Map<String, dynamic> m) {
    final id = m['id']?.toString() ?? 'layer_unknown';
    final kind = m['kind']?.toString() == 'image'
        ? _LayerKind.image
        : _LayerKind.text;
    final name = m['name']?.toString() ?? '';
    final off = m['offset'];
    double dx = 0;
    double dy = 0;
    if (off is Map) {
      dx = (off['dx'] as num?)?.toDouble() ?? 0;
      dy = (off['dy'] as num?)?.toDouble() ?? 0;
    }
    if (kind == _LayerKind.image) {
      Uint8List? bytes;
      final b64 = m['imageBase64']?.toString();
      if (b64 != null && b64.isNotEmpty) {
        try {
          bytes = base64Decode(b64);
        } catch (_) {}
      }
      return _TemplateLayer(
        id: id,
        kind: _LayerKind.image,
        name: name,
        imageBytes: bytes,
        offset: Offset(dx, dy),
      );
    }

    final layer =
        _TemplateLayer(
            id: id,
            kind: _LayerKind.text,
            name: name,
            text: m['text']?.toString(),
            offset: Offset(dx, dy),
            fontSize: (m['fontSize'] as num?)?.toDouble() ?? 28,
          )
          ..fontWeight = _fontWeightFromInt(
            (m['fontWeight'] as num?)?.toInt() ?? 700,
          )
          ..isItalic = m['isItalic'] == true
          ..isUnderlined = m['isUnderlined'] == true
          ..hasDashedBottomBorder = m['hasDashedBottomBorder'] == true
          ..textAlign = _textAlignFromString(m['textAlign']?.toString())
          ..lineHeight = (m['lineHeight'] as num?)?.toDouble() ?? 1.2
          ..letterSpacing = (m['letterSpacing'] as num?)?.toDouble() ?? 0
          ..fontFamily = m['fontFamily']?.toString() ?? 'Inter'
          ..textBoxWidth = (m['textBoxWidth'] as num?)?.toDouble() ?? 360;

    final tc = (m['textColor'] as num?)?.toInt();
    if (tc != null) {
      layer.textColor = Color(tc);
    }
    return layer;
  }

  String _htmlEscape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  String _colorToCss(Color c) {
    final r = c.r.round().toRadixString(16).padLeft(2, '0');
    final g = c.g.round().toRadixString(16).padLeft(2, '0');
    final b = c.b.round().toRadixString(16).padLeft(2, '0');
    final a = c.a;
    if (a >= 0.999) {
      return '#$r$g$b';
    }
    return 'rgba(${c.r.round()}, ${c.g.round()}, ${c.b.round()}, ${a.toStringAsFixed(3)})';
  }

  String? _backgroundImageDataUrl() {
    if (_backgroundImageBytes != null && _backgroundImageBytes!.isNotEmpty) {
      return 'data:image/png;base64,${base64Encode(_backgroundImageBytes!)}';
    }
    if (_backgroundImageUrl != null && _backgroundImageUrl!.trim().isNotEmpty) {
      return _backgroundImageUrl!.trim();
    }
    return null;
  }

  String _buildTemplateHtml() {
    final paper = _paperDimensionsPx();
    final shortSide = paper.width < paper.height ? paper.width : paper.height;
    final longSide = paper.width > paper.height ? paper.width : paper.height;
    final widthPx = _portrait ? shortSide : longSide;
    final heightPx = _portrait ? longSide : shortSide;
    final bgUrl = _backgroundImageDataUrl();

    final layerHtml = _layers
        .map((layer) {
          final left = layer.offset.dx.toStringAsFixed(2);
          final top = layer.offset.dy.toStringAsFixed(2);
          if (layer.kind == _LayerKind.image) {
            if (layer.imageBytes == null || layer.imageBytes!.isEmpty)
              return '';
            final imgData =
                'data:image/png;base64,${base64Encode(layer.imageBytes!)}';
            return '''
<img src="$imgData" alt="${_htmlEscape(layer.name)}" style="position:absolute;left:${left}px;top:${top}px;width:100px;height:72px;object-fit:cover;" />''';
          }
          final text = _resolveTemplateText(
            layer.text ?? '',
          ).replaceAll('\n', '<br/>');
          final fw = _fontWeightToInt(layer.fontWeight);
          final fs = layer.fontSize.toStringAsFixed(2);
          final lh = layer.lineHeight.toStringAsFixed(2);
          final ls = layer.letterSpacing.toStringAsFixed(2);
          final ta = _textAlignToString(layer.textAlign);
          final color = _colorToCss(layer.textColor);
          final ff = _htmlEscape(layer.fontFamily);
          final tw = layer.textBoxWidth.toStringAsFixed(2);
          final italic = layer.isItalic ? 'italic' : 'normal';
          final decoration = layer.isUnderlined ? 'underline' : 'none';
          final borderBottom = layer.hasDashedBottomBorder
              ? 'border-bottom:1px dashed $color;'
              : '';
          return '''
<div style="position:absolute;left:${left}px;top:${top}px;width:${tw}px;font-size:${fs}px;font-weight:${fw};font-style:$italic;text-decoration:$decoration;text-align:$ta;line-height:$lh;letter-spacing:${ls}px;color:$color;font-family:'$ff',sans-serif;$borderBottom">$text</div>''';
        })
        .join('\n');

    final backgroundCss = bgUrl == null
        ? 'background:#ffffff;'
        : 'background-image:url(${_htmlEscape(bgUrl)});background-size:cover;background-position:center;background-repeat:no-repeat;';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>${_htmlEscape(_canvasNameController.text.trim())}</title>
</head>
<body style="margin:0;padding:0;">
  <div style="position:relative;width:${widthPx.toStringAsFixed(2)}px;height:${heightPx.toStringAsFixed(2)}px;$backgroundCss">
    $layerHtml
  </div>
</body>
</html>
''';
  }

  void _persistDesignerToBackendModel(CertificateTemplateController c) {
    c.templateName.text = _canvasNameController.text.trim();
    c.templateBody.text = _buildTemplateHtml();

    if (_backgroundImageBytes != null && _backgroundImageBytes!.isNotEmpty) {
      c.backgroundPreset.value = 'CUSTOM_IMAGE';
      c.backgroundImageUrl.text =
          'data:image/png;base64,${base64Encode(_backgroundImageBytes!)}';
    } else if (_backgroundImageUrl != null &&
        _backgroundImageUrl!.trim().isNotEmpty) {
      c.backgroundPreset.value = 'CUSTOM_IMAGE';
      c.backgroundImageUrl.text = _backgroundImageUrl!.trim();
    }

    if (_selectedTemplateGender == 'Female') {
      c.subjectPronounDefault.text = 'She';
      c.possessivePronounDefault.text = 'Her';
    } else {
      c.subjectPronounDefault.text = 'He';
      c.possessivePronounDefault.text = 'His';
    }
  }

  Future<void> _onSave() async {
    if (_canvasNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template name is required')),
      );
      return;
    }
    _persistDesignerToBackendModel(_c);
    await _c.save();
    if (mounted) {
      _designerHydrated = false;
      _hydrateFromController(_c, force: true);
      setState(() {});
    }
  }

  Future<void> _onCancel() async {
    _designerHydrated = false;
    await _c.load();
    if (mounted) {
      _hydrateFromController(_c, force: true);
      _canvasNameController.text = _c.templateName.text;
      setState(() {});
    }
  }

  String _normalizedPaper(String value) {
    switch (value) {
      case 'A4 (210x297 mm)':
      case 'A4 (210x297 px)':
        return 'A4 (794x1123 px)';
      case 'A3 (297x420 mm)':
      case 'A3 (297x420 px)':
        return 'A3 (1123x1587 px)';
      case 'A5 (148x210 mm)':
      case 'A5 (148x210 px)':
        return 'A5 (559x794 px)';
      case 'Letter (215.9x279.4 mm)':
      case 'Letter (215.9x279.4 px)':
        return 'Letter (816x1056 px)';
      case 'Square (200x200 mm)':
        return 'Square (200x200 px)';
      default:
        return _paperOptions.contains(value) ? value : 'A4 (794x1123 px)';
    }
  }

  Size _paperDimensionsPx() {
    switch (_normalizedPaper(_selectedPaper)) {
      case 'A3 (1123x1587 px)':
        return const Size(1123, 1587);
      case 'A5 (559x794 px)':
        return const Size(559, 794);
      case 'Letter (816x1056 px)':
        return const Size(816, 1056);
      case 'Square (200x200 px)':
        return const Size(200, 200);
      case 'Custom':
        if (_customWidthMm <= 0 || _customHeightMm <= 0) {
          return const Size(794, 1123);
        }
        return Size(_customWidthMm, _customHeightMm);
      default:
        return const Size(794, 1123);
    }
  }

  Size _paperCanvasSize({required bool mobile, required double screenWidth}) {
    final base = _paperDimensionsPx();
    final shortSide = base.width < base.height ? base.width : base.height;
    final longSide = base.width > base.height ? base.width : base.height;
    final rawWidth = _portrait ? shortSide : longSide;
    final rawHeight = _portrait ? longSide : shortSide;

    final sidebarWidth = mobile ? 220.0 : 300.0;
    final availableWidth = (screenWidth - sidebarWidth - 56).clamp(
      220.0,
      1400.0,
    );
    final scale = rawWidth > availableWidth ? (availableWidth / rawWidth) : 1.0;
    return Size(rawWidth * scale, rawHeight * scale);
  }

  String _resolveTemplateText(String value) {
    final subjectPronoun = _selectedTemplateGender == 'Female' ? 'She' : 'He';
    final possessivePronoun = _selectedTemplateGender == 'Female'
        ? 'Her'
        : 'His';
    final dateOnly = DateTime.now()
        .toLocal()
        .toIso8601String()
        .split('T')
        .first;
    return value
        .replaceAll('{{date}}', dateOnly)
        .replaceAll('{{subjectPronoun}}', subjectPronoun)
        .replaceAll('{{possessivePronoun}}', possessivePronoun);
  }

  Future<void> _pickBackgroundImage() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (!mounted || picked == null || picked.files.isEmpty) return;

    final file = picked.files.first;
    if (file.bytes == null || file.bytes!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load selected image')),
      );
      return;
    }

    setState(() {
      _backgroundImageBytes = file.bytes;
      _backgroundImageUrl = null;
    });
  }

  void _addTextLayer() {
    setState(() {
      final id = 'layer_${_idSeq++}';
      _layers.add(
        _TemplateLayer(
          id: id,
          kind: _LayerKind.text,
          name: '{{dynamic_field}}',
          text: '{{dynamic_field}}',
          offset: Offset(
            80 + (_layers.length * 14),
            90 + (_layers.length * 12),
          ),
          fontSize: 32,
        ),
      );
      _selectedLayerIndex = _layers.length - 1;
      _syncLayerTextEditor();
    });
  }

  Future<void> _addImageLayer() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (!mounted || picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    if (file.bytes == null || file.bytes!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load selected image')),
      );
      return;
    }

    setState(() {
      final id = 'layer_${_idSeq++}';
      _layers.add(
        _TemplateLayer(
          id: id,
          kind: _LayerKind.image,
          name: 'Image ${_layers.length + 1}',
          imageBytes: file.bytes,
          offset: Offset(
            100 + (_layers.length * 16),
            130 + (_layers.length * 10),
          ),
        ),
      );
      _selectedLayerIndex = _layers.length - 1;
      _syncLayerTextEditor();
    });
  }

  _TemplateLayer? get _selectedLayerOrNull {
    if (_layers.isEmpty) return null;
    if (_selectedLayerIndex < 0 || _selectedLayerIndex >= _layers.length) {
      return null;
    }
    return _layers[_selectedLayerIndex];
  }

  void _syncLayerTextEditor() {
    final layer = _selectedLayerOrNull;
    if (layer == null || layer.kind != _LayerKind.text) {
      _inlineEditingLayerId = null;
      return;
    }
    _layerTextController.text = layer.text ?? '';
    _layerTextController.selection = TextSelection.collapsed(
      offset: _layerTextController.text.length,
    );
  }

  void _toggleMultiLayerSelection(_TemplateLayer layer) {
    setState(() {
      if (_selectedLayerIds.contains(layer.id)) {
        _selectedLayerIds.remove(layer.id);
      } else {
        _selectedLayerIds.add(layer.id);
      }
      _selectedLayerIndex = _layers.indexOf(layer);
      _syncLayerTextEditor();
    });
  }

  void _startInlineEdit(_TemplateLayer layer) {
    if (layer.kind != _LayerKind.text) return;
    _layerTextController.text = layer.text ?? '';
    _layerTextController.selection = TextSelection.collapsed(
      offset: _layerTextController.text.length,
    );
    _inlineEditingLayerId = layer.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _inlineEditFocusNode.requestFocus();
    });
  }

  void _stopInlineEdit() {
    _inlineEditingLayerId = null;
    _inlineEditFocusNode.unfocus();
  }

  void _applyTagToSelectedText(
    _TemplateLayer layer, {
    required String openTag,
    required String closeTag,
  }) {
    final text = _layerTextController.text;
    final selection = _layerTextController.selection;
    if (selection.start < 0 ||
        selection.end < 0 ||
        selection.start == selection.end) {
      return;
    }
    final start = selection.start < selection.end
        ? selection.start
        : selection.end;
    final end = selection.start < selection.end
        ? selection.end
        : selection.start;
    final selected = text.substring(start, end);
    final updated =
        text.substring(0, start) +
        openTag +
        selected +
        closeTag +
        text.substring(end);
    setState(() {
      _layerTextController.text = updated;
      _layerTextController.selection = TextSelection.collapsed(
        offset: start + openTag.length + selected.length + closeTag.length,
      );
      layer.text = updated;
      layer.name = updated.isEmpty ? 'Text layer' : updated;
    });
  }

  List<TextSpan> _buildInlineStyledSpans(String input, TextStyle baseStyle) {
    final spans = <TextSpan>[];
    final stack = <TextStyle>[baseStyle];
    final token = RegExp(
      r'(<\/?(?:strong|b|em|i|u)\s*>|<br\s*\/?>)',
      caseSensitive: false,
    );

    int cursor = 0;
    for (final match in token.allMatches(input)) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(
            text: input.substring(cursor, match.start),
            style: stack.last,
          ),
        );
      }
      final tag = (match.group(0) ?? '').toLowerCase();
      if (tag.startsWith('<br')) {
        spans.add(TextSpan(text: '\n', style: stack.last));
      } else if (tag == '<b>' || tag == '<strong>') {
        stack.add(
          stack.last.merge(const TextStyle(fontWeight: FontWeight.w900)),
        );
      } else if (tag == '<i>' || tag == '<em>') {
        stack.add(
          stack.last.merge(const TextStyle(fontStyle: FontStyle.italic)),
        );
      } else if (tag == '<u>') {
        stack.add(
          stack.last.merge(
            const TextStyle(decoration: TextDecoration.underline),
          ),
        );
      } else if (tag == '</b>' ||
          tag == '</strong>' ||
          tag == '</i>' ||
          tag == '</em>' ||
          tag == '</u>') {
        if (stack.length > 1) {
          stack.removeLast();
        }
      }
      cursor = match.end;
    }
    if (cursor < input.length) {
      spans.add(TextSpan(text: input.substring(cursor), style: stack.last));
    }
    return spans;
  }

  void _deleteSelectedLayer() {
    if (_layers.isEmpty) return;
    setState(() {
      _layers.removeAt(_selectedLayerIndex);
      if (_layers.isEmpty) {
        _selectedLayerIndex = 0;
      } else if (_selectedLayerIndex >= _layers.length) {
        _selectedLayerIndex = _layers.length - 1;
      }
      _syncLayerTextEditor();
    });
  }

  void _duplicateSelectedLayer() {
    final source = _selectedLayerOrNull;
    if (source == null) return;

    final id = 'layer_${_idSeq++}';
    final duplicate =
        _TemplateLayer(
            id: id,
            kind: source.kind,
            name: '${source.name} copy',
            offset: Offset(source.offset.dx + 16, source.offset.dy + 16),
            text: source.text,
            imageBytes: source.imageBytes == null
                ? null
                : Uint8List.fromList(source.imageBytes!),
            fontSize: source.fontSize,
          )
          ..textColor = source.textColor
          ..fontWeight = source.fontWeight
          ..isItalic = source.isItalic
          ..isUnderlined = source.isUnderlined
          ..hasDashedBottomBorder = source.hasDashedBottomBorder
          ..textAlign = source.textAlign
          ..lineHeight = source.lineHeight
          ..letterSpacing = source.letterSpacing
          ..fontFamily = source.fontFamily
          ..textBoxWidth = source.textBoxWidth;

    setState(() {
      _layers.add(duplicate);
      _selectedLayerIndex = _layers.length - 1;
      _syncLayerTextEditor();
    });
  }

  Widget _styleIconButton({
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3E5BFF) : const Color(0xFF1B2B46),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }

  Widget _buildTextStylePanel(_TemplateLayer layer) {
    final textThemeStyle = TextStyle(
      fontWeight: layer.fontWeight,
      fontStyle: layer.isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: layer.isUnderlined
          ? TextDecoration.underline
          : TextDecoration.none,
      fontFamily: layer.fontFamily,
      color: Colors.white,
      fontSize: 13,
    );
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2942),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF263D62)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CONTENT & FONT',
                        style: TextStyle(
                          color: Color(0xFF9AB0D0),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _layerTextController,
                                  onChanged: (v) {
                                    setState(() {
                                      layer.text = v;
                                      layer.name = v.isEmpty ? 'Text layer' : v;
                                    });
                                  },
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                  decoration: _panelFieldDecoration(),
                                ),
                              ),
                              const SizedBox(width: 6),
                              _styleIconButton(
                                icon: Icons.format_bold,
                                selected: false,
                                onTap: () => _applyTagToSelectedText(
                                  layer,
                                  openTag: '<b>',
                                  closeTag: '</b>',
                                ),
                              ),
                              const SizedBox(width: 4),
                              _styleIconButton(
                                icon: Icons.format_italic,
                                selected: false,
                                onTap: () => _applyTagToSelectedText(
                                  layer,
                                  openTag: '<em>',
                                  closeTag: '</em>',
                                ),
                              ),
                              const SizedBox(width: 4),
                              _styleIconButton(
                                icon: Icons.format_underlined,
                                selected: false,
                                onTap: () => _applyTagToSelectedText(
                                  layer,
                                  openTag: '<u>',
                                  closeTag: '</u>',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            child: DropdownButtonFormField<String>(
                              initialValue: layer.fontFamily,
                              isExpanded: true,
                              iconSize: 16,
                              dropdownColor: const Color(0xFF1A2942),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              decoration: _panelFieldDecoration().copyWith(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Inter',
                                  child: Text('Inter'),
                                ),
                                DropdownMenuItem(
                                  value: 'Roboto',
                                  child: Text('Roboto'),
                                ),
                                DropdownMenuItem(
                                  value: 'Serif',
                                  child: Text('Serif'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => layer.fontFamily = v);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(width: 1, height: 52, color: const Color(0xFF2A3E61)),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ALIGNMENT & STYLES',
                      style: TextStyle(
                        color: Color(0xFF9AB0D0),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _styleIconButton(
                          icon: Icons.format_align_left,
                          selected: layer.textAlign == TextAlign.left,
                          onTap: () =>
                              setState(() => layer.textAlign = TextAlign.left),
                        ),
                        const SizedBox(width: 6),
                        _styleIconButton(
                          icon: Icons.format_align_center,
                          selected: layer.textAlign == TextAlign.center,
                          onTap: () => setState(
                            () => layer.textAlign = TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _styleIconButton(
                          icon: Icons.format_align_right,
                          selected: layer.textAlign == TextAlign.right,
                          onTap: () =>
                              setState(() => layer.textAlign = TextAlign.right),
                        ),
                        const SizedBox(width: 10),
                        _styleIconButton(
                          icon: Icons.format_bold,
                          selected: layer.fontWeight == FontWeight.w700,
                          onTap: () => setState(() {
                            layer.fontWeight =
                                layer.fontWeight == FontWeight.w700
                                ? FontWeight.w500
                                : FontWeight.w700;
                          }),
                        ),
                        const SizedBox(width: 6),
                        _styleIconButton(
                          icon: Icons.format_italic,
                          selected: layer.isItalic,
                          onTap: () =>
                              setState(() => layer.isItalic = !layer.isItalic),
                        ),
                        const SizedBox(width: 6),
                        _styleIconButton(
                          icon: Icons.format_underlined,
                          selected: layer.isUnderlined,
                          onTap: () => setState(
                            () => layer.isUnderlined = !layer.isUnderlined,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _styleIconButton(
                          icon: Icons.border_bottom,
                          selected: layer.hasDashedBottomBorder,
                          onTap: () => setState(
                            () => layer.hasDashedBottomBorder =
                                !layer.hasDashedBottomBorder,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Container(width: 1, height: 52, color: const Color(0xFF2A3E61)),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VISUALS',
                      style: TextStyle(
                        color: Color(0xFF9AB0D0),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        InkWell(
                          onTap: () async {
                            final picked = await showDialog<Color>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Pick text color'),
                                content: Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children:
                                      const [
                                        Color(0xFF1F2A44),
                                        Color(0xFFFFFFFF),
                                        Color(0xFF0EA5E9),
                                        Color(0xFFEF4444),
                                        Color(0xFF16A34A),
                                        Color(0xFFF59E0B),
                                      ].map((c) {
                                        return _ColorDot(color: c);
                                      }).toList(),
                                ),
                              ),
                            );
                            if (picked != null) {
                              setState(() => layer.textColor = picked);
                            }
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: layer.textColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF4D658A),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 88,
                          child: InputDecorator(
                            decoration: _panelFieldDecoration(),
                            child: Text(
                              'SIZE ${layer.fontSize.toInt()}',
                              style: textThemeStyle.copyWith(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _styleIconButton(
                          icon: Icons.remove,
                          selected: false,
                          onTap: () => setState(() {
                            layer.fontSize = (layer.fontSize - 1).clamp(
                              10,
                              120,
                            );
                          }),
                        ),
                        const SizedBox(width: 4),
                        _styleIconButton(
                          icon: Icons.add,
                          selected: false,
                          onTap: () => setState(() {
                            layer.fontSize = (layer.fontSize + 1).clamp(
                              10,
                              120,
                            );
                          }),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          tooltip: 'Duplicate layer',
                          onPressed: _duplicateSelectedLayer,
                          icon: const Icon(
                            Icons.copy_outlined,
                            color: Color(0xFF93C5FD),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete layer',
                          onPressed: _deleteSelectedLayer,
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFF87171),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(
                  width: 84,
                  child: Text(
                    'LINE HEIGHT',
                    style: TextStyle(
                      color: Color(0xFF9AB0D0),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: Slider(
                    min: 0.9,
                    max: 2.0,
                    value: layer.lineHeight,
                    onChanged: (v) => setState(() => layer.lineHeight = v),
                  ),
                ),
                SizedBox(
                  width: 34,
                  child: Text(
                    layer.lineHeight.toStringAsFixed(1),
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 18),
                const SizedBox(
                  width: 52,
                  child: Text(
                    'SPACING',
                    style: TextStyle(
                      color: Color(0xFF9AB0D0),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: Slider(
                    min: 0,
                    max: 20,
                    value: layer.letterSpacing,
                    onChanged: (v) => setState(() => layer.letterSpacing = v),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${layer.letterSpacing.toStringAsFixed(0)}px',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 18),
                const SizedBox(
                  width: 72,
                  child: Text(
                    'TEXT WIDTH',
                    style: TextStyle(
                      color: Color(0xFF9AB0D0),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: Slider(
                    min: 80,
                    max: 1400,
                    value: layer.textBoxWidth.clamp(80.0, 1400.0),
                    onChanged: (v) => setState(() => layer.textBoxWidth = v),
                  ),
                ),
                SizedBox(
                  width: 46,
                  child: Text(
                    '${layer.textBoxWidth.toStringAsFixed(0)}px',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerItem(_TemplateLayer layer, Size canvasSize, bool selected) {
    final stroke = selected ? AppTheme.primaryColor : Colors.transparent;
    final maxLeft = canvasSize.width > 60 ? canvasSize.width - 60 : 0.0;
    final maxTop = canvasSize.height > 40 ? canvasSize.height - 40 : 0.0;
    final dragMaxLeft = canvasSize.width > 50 ? canvasSize.width - 50 : 0.0;
    final dragMaxTop = canvasSize.height > 28 ? canvasSize.height - 28 : 0.0;
    return Positioned(
      left: layer.offset.dx.clamp(0.0, maxLeft),
      top: layer.offset.dy.clamp(0.0, maxTop),
      child: GestureDetector(
        onPanUpdate: (d) {
          setState(() {
            if (_inlineEditingLayerId == layer.id) {
              _stopInlineEdit();
            }
            final moveIds = <String>{
              if (_isMultiMoveMode &&
                  _selectedLayerIds.contains(layer.id) &&
                  _selectedLayerIds.isNotEmpty)
                ..._selectedLayerIds
              else
                layer.id,
            };
            for (final id in moveIds) {
              final idx = _layers.indexWhere((l) => l.id == id);
              if (idx < 0) continue;
              final current = _layers[idx];
              current.offset = Offset(
                (current.offset.dx + d.delta.dx).clamp(0.0, dragMaxLeft),
                (current.offset.dy + d.delta.dy).clamp(0.0, dragMaxTop),
              );
            }
          });
        },
        onTap: () {
          if (_isMultiMoveMode) {
            _toggleMultiLayerSelection(layer);
            return;
          }
          setState(() {
            _selectedLayerIndex = _layers.indexOf(layer);
            _syncLayerTextEditor();
          });
        },
        onDoubleTap: layer.kind == _LayerKind.text
            ? () => setState(() {
                _selectedLayerIndex = _layers.indexOf(layer);
                _startInlineEdit(layer);
              })
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: stroke, width: 1.6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: layer.kind == _LayerKind.text
              ? SizedBox(
                  width: layer.textBoxWidth,
                  child: selected && _inlineEditingLayerId == layer.id
                      ? TextField(
                          controller: _layerTextController,
                          focusNode: _inlineEditFocusNode,
                          autofocus: true,
                          maxLines: null,
                          textAlign: layer.textAlign,
                          onChanged: (v) {
                            setState(() {
                              layer.text = v;
                              layer.name = v.isEmpty ? 'Text layer' : v;
                            });
                          },
                          onSubmitted: (_) => setState(_stopInlineEdit),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(
                            fontSize: layer.fontSize,
                            fontWeight: layer.fontWeight,
                            fontStyle: layer.isItalic
                                ? FontStyle.italic
                                : FontStyle.normal,
                            decoration: layer.isUnderlined
                                ? TextDecoration.underline
                                : TextDecoration.none,
                            color: layer.textColor,
                            fontFamily: layer.fontFamily,
                            height: layer.lineHeight,
                            letterSpacing: layer.letterSpacing,
                          ),
                        )
                      : Stack(
                          fit: StackFit.passthrough,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: _buildInlineStyledSpans(
                                  _resolveTemplateText(layer.text ?? ''),
                                  TextStyle(
                                    fontSize: layer.fontSize,
                                    fontWeight: layer.fontWeight,
                                    fontStyle: layer.isItalic
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                    decoration: layer.isUnderlined
                                        ? TextDecoration.underline
                                        : TextDecoration.none,
                                    color: layer.textColor,
                                    fontFamily: layer.fontFamily,
                                    height: layer.lineHeight,
                                    letterSpacing: layer.letterSpacing,
                                  ),
                                ),
                              ),
                              textAlign: layer.textAlign,
                            ),
                            if (layer.hasDashedBottomBorder)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final count = (constraints.maxWidth / 8)
                                        .floor();
                                    return Row(
                                      children: List.generate(count, (i) {
                                        return Container(
                                          width: 4,
                                          height: 1,
                                          margin: const EdgeInsets.only(
                                            right: 4,
                                          ),
                                          color: layer.textColor,
                                        );
                                      }),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.memory(
                    layer.imageBytes ?? Uint8List(0),
                    width: 100,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 100,
                      height: 72,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined, size: 20),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 760;
    final primary = AppTheme.primaryColor;

    return Obx(() {
      if (c.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final canvasSize = _paperCanvasSize(
        mobile: isMobile,
        screenWidth: screenWidth,
      );
      final selectedLayer = _selectedLayerOrNull;
      final ImageProvider<Object>? backgroundImageProvider =
          _backgroundImageBytes != null
          ? MemoryImage(_backgroundImageBytes!)
          : (_backgroundImageUrl == null || _backgroundImageUrl!.isEmpty)
          ? null
          : NetworkImage(_backgroundImageUrl!);

      return Container(
        color: const Color(0xFF091528),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: isMobile ? 220 : 300,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              color: const Color(0xFF0E1D34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'TEMPLATE NAME',
                    style: TextStyle(
                      color: Colors.blueGrey.shade300,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _canvasNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _darkFieldDecoration().copyWith(
                      hintText: 'Enter template name',
                      hintStyle: TextStyle(
                        color: Colors.blueGrey.shade400,
                        fontSize: 12,
                      ),
                    ),
                    onChanged: (v) => _c.templateName.text = v,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            c.createNewTemplateDraft();
                            _designerHydrated = false;
                            _hydrateFromController(c, force: true);
                            setState(() {});
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text(
                            'New',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.blueGrey.shade600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: c.selectedTemplateId.value == null
                              ? null
                              : () async {
                                  await c.deleteSelectedTemplate();
                                  _designerHydrated = false;
                                  _hydrateFromController(c, force: true);
                                  if (mounted) setState(() {});
                                },
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text(
                            'Delete',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.blueGrey.shade600),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: c.selectedTemplateId.value == null
                        ? null
                        : () {
                            _persistDesignerToBackendModel(c);
                            c.createDuplicateTemplateDraft(
                              sourceName: _canvasNameController.text,
                            );
                            _canvasNameController.text = c.templateName.text;
                            if (mounted) setState(() {});
                          },
                    icon: const Icon(Icons.copy_outlined, size: 16),
                    label: const Text(
                      'Duplicate',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.blueGrey.shade600),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'SELECT TEMPLATE',
                    style: TextStyle(
                      color: Colors.blueGrey.shade300,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: c.selectedTemplateId.value,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF182845),
                    decoration: _darkFieldDecoration(),
                    style: const TextStyle(color: Colors.white),
                    selectedItemBuilder: (context) {
                      final rows = c.templates
                          .where((t) => t.id != null)
                          .toList();
                      return rows
                          .map(
                            (t) => Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                t.isDefault
                                    ? '${t.templateName} (default)'
                                    : t.templateName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList();
                    },
                    items: c.templates
                        .where((t) => t.id != null)
                        .map(
                          (t) => DropdownMenuItem<int>(
                            value: t.id!,
                            child: Text(
                              t.isDefault
                                  ? '${t.templateName} (default)'
                                  : t.templateName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) async {
                      if (v == null) return;
                      await c.selectTemplateById(v);
                      _ensureSelectedTemplateBody(c, id: v);
                      _designerHydrated = false;
                      _hydrateFromController(c, force: true);
                      if (mounted) setState(() {});
                    },
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: c.selectedTemplateId.value == null
                        ? null
                        : () async {
                            await c.setSelectedAsDefault();
                            _designerHydrated = false;
                            _hydrateFromController(c, force: true);
                            if (mounted) setState(() {});
                          },
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text(
                      'Set as default',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.blueGrey.shade600),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'CANVAS SETUP',
                    style: TextStyle(
                      color: Colors.blueGrey.shade300,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _normalizedPaper(_selectedPaper),
                    dropdownColor: const Color(0xFF182845),
                    decoration: _darkFieldDecoration(),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(
                        value: 'A4 (794x1123 px)',
                        child: Text('A4 (794x1123 px)'),
                      ),
                      DropdownMenuItem(
                        value: 'A3 (1123x1587 px)',
                        child: Text('A3 (1123x1587 px)'),
                      ),
                      DropdownMenuItem(
                        value: 'A5 (559x794 px)',
                        child: Text('A5 (559x794 px)'),
                      ),
                      DropdownMenuItem(
                        value: 'Letter (816x1056 px)',
                        child: Text('Letter (816x1056 px)'),
                      ),
                      DropdownMenuItem(
                        value: 'Square (200x200 px)',
                        child: Text('Square (200x200 px)'),
                      ),
                      DropdownMenuItem(value: 'Custom', child: Text('Custom')),
                    ],
                    onChanged: (v) => setState(
                      () => _selectedPaper = _normalizedPaper(
                        v ?? _selectedPaper,
                      ),
                    ),
                  ),
                  if (_normalizedPaper(_selectedPaper) == 'Custom') ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customWidthMmController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}$'),
                              ),
                            ],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            decoration: _darkFieldDecoration().copyWith(
                              labelText: 'WIDTH (PX)',
                              labelStyle: TextStyle(
                                color: Colors.blueGrey.shade300,
                                fontSize: 11,
                              ),
                            ),
                            onChanged: (value) {
                              final parsed = double.tryParse(value);
                              if (parsed == null || parsed <= 0) return;
                              setState(() => _customWidthMm = parsed);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _customHeightMmController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}$'),
                              ),
                            ],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            decoration: _darkFieldDecoration().copyWith(
                              labelText: 'HEIGHT (PX)',
                              labelStyle: TextStyle(
                                color: Colors.blueGrey.shade300,
                                fontSize: 11,
                              ),
                            ),
                            onChanged: (value) {
                              final parsed = double.tryParse(value);
                              if (parsed == null || parsed <= 0) return;
                              setState(() => _customHeightMm = parsed);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF182845),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () => setState(() => _portrait = true),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              backgroundColor: _portrait
                                  ? const Color(0xFF2E7AF4)
                                  : Colors.transparent,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              'Portrait',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => setState(() => _portrait = false),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              backgroundColor: !_portrait
                                  ? const Color(0xFF2E7AF4)
                                  : Colors.transparent,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              'Landscape',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'ADD ELEMENTS',
                    style: TextStyle(
                      color: Colors.blueGrey.shade300,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addTextLayer,
                          icon: const Icon(Icons.text_fields, size: 18),
                          label: const Text('Text'),
                          style: _darkButtonStyle(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addImageLayer,
                          icon: const Icon(Icons.image_outlined, size: 18),
                          label: const Text('Image'),
                          style: _darkButtonStyle(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'BACKGROUND IMAGE',
                    style: TextStyle(
                      color: Colors.blueGrey.shade300,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickBackgroundImage,
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: const Text('Upload Background'),
                    style: _darkButtonStyle(),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'LAYERS',
                    style: TextStyle(
                      color: Colors.blueGrey.shade300,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Switch(
                        value: _isMultiMoveMode,
                        onChanged: (v) => setState(() {
                          _multiMoveMode = v;
                          if (!v) {
                            _selectedLayerIds.clear();
                          }
                        }),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Multi move',
                        style: TextStyle(
                          color: Colors.blueGrey.shade100,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_isMultiMoveMode) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(${_selectedLayerIds.length} selected)',
                          style: TextStyle(
                            color: Colors.blueGrey.shade300,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF14233D),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListView.builder(
                        itemCount: _layers.length,
                        itemBuilder: (_, i) {
                          final layer = _layers[i];
                          final selected = i == _selectedLayerIndex;
                          return ListTile(
                            dense: true,
                            selected: selected,
                            selectedTileColor: const Color(0xFF213455),
                            leading: Icon(
                              layer.kind == _LayerKind.text
                                  ? Icons.text_fields
                                  : Icons.image_outlined,
                              color: selected
                                  ? Colors.white
                                  : Colors.blueGrey.shade200,
                              size: 18,
                            ),
                            title: Text(
                              layer.name,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : Colors.blueGrey.shade100,
                                fontSize: 12,
                              ),
                            ),
                            trailing: _isMultiMoveMode
                                ? Checkbox(
                                    value: _selectedLayerIds.contains(layer.id),
                                    onChanged: (_) =>
                                        _toggleMultiLayerSelection(layer),
                                  )
                                : null,
                            onTap: () {
                              if (_isMultiMoveMode) {
                                _toggleMultiLayerSelection(layer);
                                return;
                              }
                              setState(() {
                                _selectedLayerIndex = i;
                                _syncLayerTextEditor();
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF071326), Color(0xFF0A1730)],
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (selectedLayer?.kind == _LayerKind.text) ...[
                        Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: _buildTextStylePanel(selectedLayer!),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: canvasSize.width,
                          height: canvasSize.height,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFFCFD8DC),
                              width: 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 24,
                                color: Color(0x33000000),
                                offset: Offset(0, 12),
                              ),
                            ],
                            image: backgroundImageProvider == null
                                ? null
                                : DecorationImage(
                                    image: backgroundImageProvider,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          child: Stack(
                            children: [
                              for (var i = 0; i < _layers.length; i++)
                                _buildLayerItem(
                                  _layers[i],
                                  canvasSize,
                                  i == _selectedLayerIndex ||
                                      _selectedLayerIds.contains(_layers[i].id),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _BottomActions(
                        c: c,
                        onSave: _onSave,
                        onCancel: _onCancel,
                        primary: primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  InputDecoration _panelFieldDecoration() {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: const Color(0xFF16253E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }

  InputDecoration _darkFieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF182845),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  ButtonStyle _darkButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: BorderSide(color: Colors.blueGrey.shade500),
      backgroundColor: const Color(0xFF182845),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(color),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black12),
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final CertificateTemplateController c;
  final Future<void> Function() onSave;
  final Future<void> Function() onCancel;
  final Color primary;

  const _BottomActions({
    required this.c,
    required this.onSave,
    required this.onCancel,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: c.isSaving.value ? null : () => onCancel(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: c.isSaving.value ? null : () => onSave(),
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            ),
            child: c.isSaving.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
