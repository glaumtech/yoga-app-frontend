import 'dart:convert';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../data/models/certificate_designer_envelope.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../controllers/certificate_template_controller.dart';
import '../../../widgets/pinned_scroll_views.dart';

const PinnedScrollBarStyle _kCertificateScrollbarStyle = PinnedScrollBarStyle.dark;

enum _LayerKind { text, image }

class _DynamicFieldSpec {
  const _DynamicFieldSpec({
    required this.key,
    required this.label,
    required this.kind,
  });

  final String key;
  final String label;
  final _LayerKind kind;
}

const List<_DynamicFieldSpec> _kDefaultDynamicFields = [
  _DynamicFieldSpec(
    key: 'participantName',
    label: 'Participant name',
    kind: _LayerKind.text,
  ),
  _DynamicFieldSpec(key: 'dob', label: 'DOB', kind: _LayerKind.text),
  _DynamicFieldSpec(key: 'age', label: 'Age', kind: _LayerKind.text),
  _DynamicFieldSpec(
    key: 'startDate',
    label: 'Start date',
    kind: _LayerKind.text,
  ),
  _DynamicFieldSpec(key: 'endDate', label: 'End date', kind: _LayerKind.text),
  _DynamicFieldSpec(
    key: 'currentDate',
    label: 'Current date',
    kind: _LayerKind.text,
  ),
  _DynamicFieldSpec(
    key: 'participantPhoto',
    label: 'Participant photo',
    kind: _LayerKind.image,
  ),
  _DynamicFieldSpec(
    key: 'winnerCategory',
    label: 'Winner category',
    kind: _LayerKind.text,
  ),
  _DynamicFieldSpec(
    key: 'institutionName',
    label: 'Institution name',
    kind: _LayerKind.text,
  ),
  _DynamicFieldSpec(
    key: 'competitionName',
    label: 'Competition name',
    kind: _LayerKind.text,
  ),
  _DynamicFieldSpec(
    key: 'competitionAddrss',
    label: 'Competition address',
    kind: _LayerKind.text,
  ),
];

class _TemplateLayer {
  _TemplateLayer({
    required this.id,
    required this.kind,
    required this.name,
    required this.offset,
    this.text,
    this.imageBytes,
    this.fontSize = 28,
    this.placeholderKey,
  });

  final String id;
  final _LayerKind kind;
  String name;
  Offset offset;
  String? text;
  Uint8List? imageBytes;
  String? placeholderKey;
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
  double imageWidth = 100;
  double imageHeight = 72;
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
  final TextEditingController _imageWidthController = TextEditingController();
  final TextEditingController _imageHeightController = TextEditingController();
  final FocusNode _inlineEditFocusNode = FocusNode();
  final TextEditingController _customWidthMmController = TextEditingController(
    text: '1123',
  );
  final TextEditingController _customHeightMmController = TextEditingController(
    text: '794',
  );
  final ScrollController _sidebarScrollController = ScrollController();
  final ScrollController _layersScrollController = ScrollController();
  final ScrollController _defaultFieldsScrollController = ScrollController();
  final ScrollController _textToolbarScrollController = ScrollController();
  final ScrollController _textSlidersScrollController = ScrollController();

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
  bool _defaultFieldsMenuOpen = false;

  bool get _isMultiMoveMode => _multiMoveMode ?? false;

  Set<String> get _selectedLayerIds => _multiSelectedLayerIds ??= <String>{};

  int _selectedLayerIndex = 0;
  int _idSeq = 1;
  final List<_TemplateLayer> _layers = <_TemplateLayer>[];

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
    _imageWidthController.dispose();
    _imageHeightController.dispose();
    _inlineEditFocusNode.dispose();
    _customWidthMmController.dispose();
    _customHeightMmController.dispose();
    _sidebarScrollController.dispose();
    _layersScrollController.dispose();
    _defaultFieldsScrollController.dispose();
    _textToolbarScrollController.dispose();
    _textSlidersScrollController.dispose();
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
      final hasBackground =
          (_backgroundImageBytes != null && _backgroundImageBytes!.isNotEmpty) ||
          (_backgroundImageUrl != null && _backgroundImageUrl!.trim().isNotEmpty);
      if (!hasBackground) {
        _syncBackgroundFromBackend(c);
        final hasBackendBackground =
            (_backgroundImageBytes != null &&
                _backgroundImageBytes!.isNotEmpty) ||
            (_backgroundImageUrl != null &&
                _backgroundImageUrl!.trim().isNotEmpty);
        if (!hasBackendBackground) {
          _syncBackgroundFromTemplateBody(body);
        }
      }
    } else {
      final restoredFromHtml = _applyTemplateHtml(body);
      if (!restoredFromHtml) {
        _clearDesignerCanvas();
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

  void _clearDesignerCanvas() {
    _layers.clear();
    _selectedLayerIndex = 0;
    _idSeq = 1;
    _inlineEditingLayerId = null;
    _multiMoveMode = false;
    _selectedLayerIds.clear();
    _backgroundImageBytes = null;
    _backgroundImageUrl = null;
    _layerTextController.clear();
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
    final positionedImg = RegExp(
      r"""<img[^>]*style=["'][^"']*position\s*:\s*absolute[^"']*["'][^>]*>""",
      caseSensitive: false,
    );
    if (!positionedTextDiv.hasMatch(text) && !positionedImg.hasMatch(text)) {
      return false;
    }

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
      if (RegExp(
        r'alt=["'']Background["'']',
        caseSensitive: false,
      ).hasMatch(m.group(0) ?? '')) {
        continue;
      }
      final left = _styleDouble(style, 'left') ?? 0;
      final top = _styleDouble(style, 'top') ?? 0;
      final width = (_styleDouble(style, 'width') ?? 100).clamp(40.0, 1400.0);
      final height = (_styleDouble(style, 'height') ?? 72).clamp(24.0, 1200.0);
      Uint8List? bytes;
      final data = _tryParseDataImageUrl(src);
      if (data != null) {
        bytes = data.$2;
      }
      final placeholderKey = _placeholderKeyFromToken(src);
      parsed.add(
        _TemplateLayer(
          id: 'layer_${_idSeq++}',
          kind: _LayerKind.image,
          name: placeholderKey == null ? 'Image' : '{{$placeholderKey}}',
          offset: Offset(left, top),
          imageBytes: bytes,
          placeholderKey: placeholderKey,
        )
          ..imageWidth = width
          ..imageHeight = height,
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
            placeholderKey: _placeholderKeyFromToken(layerText),
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
    final paper = (d['selectedPaper'] ?? d['paper'])?.toString();
    if (paper != null && paper.isNotEmpty) {
      _selectedPaper = _normalizedPaper(paper);
    }
    _portrait = d['portrait'] == true;
    final cw =
        ((d['customWidthMm'] as num?) ?? (d['customWidthPx'] as num?))
            ?.toDouble();
    final ch =
        ((d['customHeightMm'] as num?) ?? (d['customHeightPx'] as num?))
            ?.toDouble();
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
    String? b64 = d['backgroundImageBase64']?.toString();
    if ((b64 == null || b64.isEmpty) && bg is Map) {
      b64 = bg['base64']?.toString();
    }
    if (b64 != null && b64.isNotEmpty) {
      try {
        _backgroundImageBytes = base64Decode(b64);
        _backgroundImageUrl = null;
      } catch (_) {
        _backgroundImageBytes = null;
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
    } else {
      _layers.clear();
      _selectedLayerIndex = 0;
      _idSeq = 1;
      _inlineEditingLayerId = null;
      _selectedLayerIds.clear();
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
        placeholderKey: m['placeholderKey']?.toString(),
      )
        ..imageWidth = (m['imageWidth'] as num?)?.toDouble() ?? 100
        ..imageHeight = (m['imageHeight'] as num?)?.toDouble() ?? 72;
    }

    final layer =
        _TemplateLayer(
            id: id,
            kind: _LayerKind.text,
            name: name,
            text: m['text']?.toString(),
            offset: Offset(dx, dy),
            fontSize: (m['fontSize'] as num?)?.toDouble() ?? 28,
            placeholderKey:
                m['placeholderKey']?.toString() ??
                _placeholderKeyFromToken(m['text']?.toString()),
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

  String? _placeholderKeyFromToken(String? value) {
    if (value == null) return null;
    final m = RegExp(r'^\{\{\s*([A-Za-z][A-Za-z0-9]*)\s*\}\}$').firstMatch(
      value.trim(),
    );
    return m?.group(1);
  }

  String _dynamicFieldToken(_DynamicFieldSpec field) => '{{${field.key}}}';

  bool _layerUsesField(_TemplateLayer layer, _DynamicFieldSpec field) {
    if (layer.placeholderKey == field.key) return true;
    if (layer.text == _dynamicFieldToken(field)) return true;
    if (layer.name == _dynamicFieldToken(field)) return true;
    return false;
  }

  String _colorToCss(Color c) {
    final argb = c.toARGB32();
    final aInt = (argb >> 24) & 0xFF;
    final rInt = (argb >> 16) & 0xFF;
    final gInt = (argb >> 8) & 0xFF;
    final bInt = argb & 0xFF;
    final r = rInt.toRadixString(16).padLeft(2, '0');
    final g = gInt.toRadixString(16).padLeft(2, '0');
    final b = bInt.toRadixString(16).padLeft(2, '0');
    final a = aInt / 255.0;
    if (a >= 0.999) {
      return '#$r$g$b';
    }
    return 'rgba($rInt, $gInt, $bInt, ${a.toStringAsFixed(3)})';
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

  String _cssMm(double px) => '${(px * 25.4 / 96.0).toStringAsFixed(4)}mm';

  Size? _bitmapSize(Uint8List bytes) {
    if (bytes.length >= 24 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      final w =
          (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
      final h =
          (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
      if (w > 0 && h > 0) return Size(w.toDouble(), h.toDouble());
    }
    if (bytes.length > 10 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      var i = 2;
      while (i + 8 < bytes.length) {
        if (bytes[i] != 0xFF) {
          i++;
          continue;
        }
        final marker = bytes[i + 1];
        if (marker == 0xD9 || marker == 0xDA) break;
        if (i + 3 >= bytes.length) break;
        final len = (bytes[i + 2] << 8) | bytes[i + 3];
        if (marker >= 0xC0 && marker <= 0xC3) {
          final h = (bytes[i + 5] << 8) | bytes[i + 6];
          final w = (bytes[i + 7] << 8) | bytes[i + 8];
          if (w > 0 && h > 0) return Size(w.toDouble(), h.toDouble());
          break;
        }
        i += 2 + len;
      }
    }
    return null;
  }

  String _coverFittedImageHtml({
    required String src,
    required String alt,
    required double boxLeft,
    required double boxTop,
    required double boxWidth,
    required double boxHeight,
    Uint8List? bytes,
  }) {
    var imgLeft = boxLeft;
    var imgTop = boxTop;
    var imgWidth = boxWidth;
    var imgHeight = boxHeight;
    if (bytes != null && bytes.isNotEmpty) {
      final natural = _bitmapSize(bytes);
      if (natural != null && natural.width > 0 && natural.height > 0) {
        final scale = math.max(
          boxWidth / natural.width,
          boxHeight / natural.height,
        );
        imgWidth = natural.width * scale;
        imgHeight = natural.height * scale;
        imgLeft = boxLeft + (boxWidth - imgWidth) / 2;
        imgTop = boxTop + (boxHeight - imgHeight) / 2;
      }
    }
    return '''
<div style="position:absolute;left:${_cssMm(boxLeft)};top:${_cssMm(boxTop)};width:${_cssMm(boxWidth)};height:${_cssMm(boxHeight)};overflow:hidden;margin:0;padding:0;">
<img src="$src" alt="${_htmlEscape(alt)}" width="${boxWidth.round()}" height="${boxHeight.round()}" style="position:absolute;left:${_cssMm(imgLeft - boxLeft)};top:${_cssMm(imgTop - boxTop)};width:${_cssMm(imgWidth)};height:${_cssMm(imgHeight)};display:block;margin:0;padding:0;border:0;"/>
</div>''';
  }

  String _buildTemplateHtml() {
    final paper = _paperDimensionsPx();
    final shortSide = paper.width < paper.height ? paper.width : paper.height;
    final longSide = paper.width > paper.height ? paper.width : paper.height;
    final widthPx = _portrait ? shortSide : longSide;
    final heightPx = _portrait ? longSide : shortSide;
    final bgUrl = _backgroundImageDataUrl();
    final pageW = _cssMm(widthPx);
    final pageH = _cssMm(heightPx);

    final layerHtml = _layers
        .map((layer) {
          final left = layer.offset.dx;
          final top = layer.offset.dy;
          if (layer.kind == _LayerKind.image) {
            final iw = layer.imageWidth.clamp(40.0, 1400.0);
            final ih = layer.imageHeight.clamp(24.0, 1200.0);
            final photoKey = layer.placeholderKey;
            if (photoKey != null && photoKey.isNotEmpty) {
              return '''
<div style="position:absolute;left:${_cssMm(left)};top:${_cssMm(top)};width:${_cssMm(iw)};height:${_cssMm(ih)};overflow:hidden;margin:0;padding:0;">
<img src="{{$photoKey}}" alt="${_htmlEscape(layer.name)}" width="${iw.round()}" height="${ih.round()}" style="position:absolute;left:0;top:0;width:${_cssMm(iw)};height:${_cssMm(ih)};display:block;margin:0;padding:0;border:0;object-fit:cover;"/>
</div>''';
            }
            if (layer.imageBytes == null || layer.imageBytes!.isEmpty) {
              return '';
            }
            final imgData =
                'data:image/png;base64,${base64Encode(layer.imageBytes!)}';
            return _coverFittedImageHtml(
              src: imgData,
              alt: layer.name,
              boxLeft: left,
              boxTop: top,
              boxWidth: iw,
              boxHeight: ih,
              bytes: layer.imageBytes,
            );
          }
          final text = (layer.text ?? '').replaceAll('\n', '<br/>');
          final fw = _fontWeightToInt(layer.fontWeight);
          final fs = layer.fontSize;
          final lhPx = math.max(fs * layer.lineHeight, fs);
          final ls = layer.letterSpacing;
          final ta = _textAlignToString(layer.textAlign);
          final color = _colorToCss(layer.textColor);
          final ff = _htmlEscape(layer.fontFamily);
          final tw = layer.textBoxWidth;
          final italic = layer.isItalic ? 'italic' : 'normal';
          final decoration = layer.isUnderlined ? 'underline' : 'none';
          final borderBottom = layer.hasDashedBottomBorder
              ? 'border-bottom:0.2mm dashed $color;'
              : '';
          return '''
<div style="position:absolute;left:${_cssMm(left)};top:${_cssMm(top)};width:${_cssMm(tw)};margin:0;padding:0;border:0;box-sizing:border-box;white-space:nowrap;overflow:visible;font-size:${_cssMm(fs)};font-weight:${fw};font-style:$italic;text-decoration:$decoration;text-align:$ta;line-height:${_cssMm(lhPx)};letter-spacing:${_cssMm(ls)};color:$color;font-family:'$ff',sans-serif;$borderBottom">$text</div>''';
        })
        .join('\n');

    final backgroundCss = 'background:#ffffff;overflow:hidden;';
    String backgroundLayerHtml = '';
    if (bgUrl != null) {
      backgroundLayerHtml = _coverFittedImageHtml(
        src: _htmlEscape(bgUrl),
        alt: 'Background',
        boxLeft: 0,
        boxTop: 0,
        boxWidth: widthPx,
        boxHeight: heightPx,
        bytes: _backgroundImageBytes,
      );
    }

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8"/>
  <style id="cursor-pdf-page-size">
    @page { size: $pageW $pageH; margin: 0; }
    html, body { margin: 0; padding: 0; width: $pageW; height: $pageH; overflow: hidden; }
  </style>
</head>
<body style="margin:0;padding:0;">
  <div style="position:relative;width:$pageW;height:$pageH;$backgroundCss">
    $backgroundLayerHtml
    $layerHtml
  </div>
</body>
</html>
''';
  }

  Map<String, dynamic> _buildDesignerSnapshot() {
    final designer = <String, dynamic>{
      'selectedPaper': _selectedPaper,
      'portrait': _portrait,
      'customWidthMm': _customWidthMm,
      'customHeightMm': _customHeightMm,
      'layers': _layers.map((layer) {
        final map = <String, dynamic>{
          'id': layer.id,
          'kind': layer.kind == _LayerKind.image ? 'image' : 'text',
          'name': layer.name,
          'offset': {
            'dx': layer.offset.dx,
            'dy': layer.offset.dy,
          },
        };
        if (layer.placeholderKey != null && layer.placeholderKey!.isNotEmpty) {
          map['placeholderKey'] = layer.placeholderKey;
        }
        if (layer.kind == _LayerKind.image) {
          map['imageBase64'] = layer.imageBytes == null
              ? null
              : base64Encode(layer.imageBytes!);
          map['imageWidth'] = layer.imageWidth;
          map['imageHeight'] = layer.imageHeight;
        } else {
          map['text'] = layer.text;
          map['fontSize'] = layer.fontSize;
          map['fontWeight'] = _fontWeightToInt(layer.fontWeight);
          map['isItalic'] = layer.isItalic;
          map['isUnderlined'] = layer.isUnderlined;
          map['hasDashedBottomBorder'] = layer.hasDashedBottomBorder;
          map['textAlign'] = _textAlignToString(layer.textAlign);
          map['lineHeight'] = layer.lineHeight;
          map['letterSpacing'] = layer.letterSpacing;
          map['fontFamily'] = layer.fontFamily;
          map['textColor'] = layer.textColor.toARGB32();
          map['textBoxWidth'] = layer.textBoxWidth;
        }
        return map;
      }).toList(),
    };

    if (_backgroundImageBytes != null && _backgroundImageBytes!.isNotEmpty) {
      designer['backgroundImageBase64'] = base64Encode(_backgroundImageBytes!);
    } else if (_backgroundImageUrl != null &&
        _backgroundImageUrl!.trim().isNotEmpty) {
      designer['backgroundImageUrl'] = _backgroundImageUrl!.trim();
    }
    return designer;
  }

  void _persistDesignerToBackendModel(CertificateTemplateController c) {
    c.templateName.text = _canvasNameController.text.trim();
    final html = _buildTemplateHtml();
    final wrapped = <String, dynamic>{
      'templateBody': html,
      'designer': _buildDesignerSnapshot(),
    };
    c.templateBody.text = jsonEncode(wrapped);

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

  /// Full oriented canvas size in design pixels.
  Size _paperOrientedCanvasSize() {
    final base = _paperDimensionsPx();
    final shortSide = base.width < base.height ? base.width : base.height;
    final longSide = base.width > base.height ? base.width : base.height;
    final rawWidth = _portrait ? shortSide : longSide;
    final rawHeight = _portrait ? longSide : shortSide;
    return Size(rawWidth, rawHeight);
  }

  Widget _buildCertificateCanvas({
    required Size canvasSize,
    required ImageProvider<Object>? backgroundImageProvider,
  }) {
    return Container(
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
        clipBehavior: Clip.none,
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
    );
  }

  /// Scales the canvas to the full preview width; scrolls vertically when needed.
  Widget _buildScaledCertificatePreview({
    required Size canvasSize,
    required ImageProvider<Object>? backgroundImageProvider,
    required double viewW,
    required double viewH,
  }) {
    if (viewW <= 0 || viewH <= 0 || canvasSize.width <= 0) {
      return const SizedBox.shrink();
    }

    final scaledHeight = canvasSize.height * (viewW / canvasSize.width);
    final preview = SizedBox(
      width: viewW,
      height: scaledHeight,
      child: FittedBox(
        fit: BoxFit.fitWidth,
        alignment: Alignment.topCenter,
        child: _buildCertificateCanvas(
          canvasSize: canvasSize,
          backgroundImageProvider: backgroundImageProvider,
        ),
      ),
    );

    if (scaledHeight <= viewH) {
      return Align(alignment: Alignment.topCenter, child: preview);
    }

    return SingleChildScrollView(
      primary: false,
      child: preview,
    );
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

  void _addDynamicField(_DynamicFieldSpec field) {
    final existingIndex = _layers.indexWhere(
      (layer) => _layerUsesField(layer, field),
    );
    if (existingIndex >= 0) {
      setState(() {
        _selectedLayerIndex = existingIndex;
        _syncLayerTextEditor();
      });
      return;
    }

    setState(() {
      final id = 'layer_${_idSeq++}';
      final token = _dynamicFieldToken(field);
      if (field.kind == _LayerKind.image) {
        _layers.add(
          _TemplateLayer(
            id: id,
            kind: _LayerKind.image,
            name: token,
            offset: Offset(
              80 + (_layers.length * 12),
              90 + (_layers.length * 10),
            ),
            placeholderKey: field.key,
          )
            ..imageWidth = 120
            ..imageHeight = 150,
        );
      } else {
        _layers.add(
          _TemplateLayer(
            id: id,
            kind: _LayerKind.text,
            name: token,
            text: token,
            offset: Offset(
              80 + (_layers.length * 14),
              90 + (_layers.length * 12),
            ),
            fontSize: 24,
            placeholderKey: field.key,
          )
            ..fontWeight = FontWeight.w700
            ..textColor = const Color(0xFF111827)
            ..textBoxWidth = 280,
        );
      }
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
    if (layer == null) {
      _inlineEditingLayerId = null;
      _imageWidthController.clear();
      _imageHeightController.clear();
      return;
    }
    if (layer.kind == _LayerKind.image) {
      _inlineEditingLayerId = null;
      _imageWidthController.text = layer.imageWidth.round().toString();
      _imageHeightController.text = layer.imageHeight.round().toString();
      return;
    }
    _imageWidthController.clear();
    _imageHeightController.clear();
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

  bool get _allLayersSelected =>
      _layers.isNotEmpty &&
      _layers.every((layer) => _selectedLayerIds.contains(layer.id));

  bool get _someLayersSelected =>
      _layers.any((layer) => _selectedLayerIds.contains(layer.id));

  void _toggleSelectAllLayers() {
    setState(() {
      if (_allLayersSelected) {
        _selectedLayerIds.clear();
      } else {
        _selectedLayerIds
          ..clear()
          ..addAll(_layers.map((layer) => layer.id));
      }
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
            placeholderKey: source.placeholderKey,
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
          ..textBoxWidth = source.textBoxWidth
          ..imageWidth = source.imageWidth
          ..imageHeight = source.imageHeight;

    setState(() {
      _layers.add(duplicate);
      _selectedLayerIndex = _layers.length - 1;
      _syncLayerTextEditor();
    });
  }

  Widget _photoPlaceholderBox(
    _TemplateLayer layer,
    double width,
    double height,
  ) {
    final label = layer.placeholderKey == 'participantPhoto'
        ? 'Participant photo'
        : (layer.name.trim().isEmpty ? 'Photo' : layer.name);
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFE8EEF6),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: (height * 0.28).clamp(18, 42),
            color: const Color(0xFF64748B),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _adjustSelectedImageSize({
    double widthDelta = 0,
    double heightDelta = 0,
  }) {
    final layer = _selectedLayerOrNull;
    if (layer == null || layer.kind != _LayerKind.image) return;
    setState(() {
      layer.imageWidth = (layer.imageWidth + widthDelta).clamp(40, 1000);
      layer.imageHeight = (layer.imageHeight + heightDelta).clamp(24, 700);
      _syncLayerTextEditor();
    });
  }

  void _applyImageSizeFromFields(_TemplateLayer layer) {
    final width = double.tryParse(_imageWidthController.text.trim());
    final height = double.tryParse(_imageHeightController.text.trim());
    setState(() {
      if (width != null) {
        layer.imageWidth = width.clamp(40, 1000);
      }
      if (height != null) {
        layer.imageHeight = height.clamp(24, 700);
      }
      _syncLayerTextEditor();
    });
  }

  Widget _buildDefaultFieldsDropdown() {
    const itemHeight = 40.0;
    const visibleCount = 5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: const Color(0xFF182845),
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: () => setState(
              () => _defaultFieldsMenuOpen = !_defaultFieldsMenuOpen,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select a field',
                      style: TextStyle(
                        color: Colors.blueGrey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Icon(
                    _defaultFieldsMenuOpen
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Colors.white70,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_defaultFieldsMenuOpen) ...[
          const SizedBox(height: 4),
          Container(
            height: itemHeight * visibleCount,
            decoration: BoxDecoration(
              color: const Color(0xFF182845),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0xFF2E4568)),
            ),
            child: PinnedVerticalScrollViewport(
              controller: _defaultFieldsScrollController,
              alwaysShowScrollbar: true,
              style: _kCertificateScrollbarStyle,
              child: ListView.builder(
                controller: _defaultFieldsScrollController,
                primary: false,
                itemExtent: itemHeight,
                itemCount: _kDefaultDynamicFields.length,
                itemBuilder: (context, index) {
                  final field = _kDefaultDynamicFields[index];
                  final onCanvas = _layers.any(
                    (layer) => _layerUsesField(layer, field),
                  );
                  return InkWell(
                    onTap: () {
                      _addDynamicField(field);
                      setState(() => _defaultFieldsMenuOpen = false);
                    },
                    child: Container(
                      color: onCanvas
                          ? const Color(0xFF1D4ED8)
                          : Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        onCanvas ? '${field.label} (added)' : field.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _layerDisplayName(_TemplateLayer layer) {
    if (layer.placeholderKey != null) {
      for (final field in _kDefaultDynamicFields) {
        if (field.key == layer.placeholderKey) return field.label;
      }
    }
    return layer.name;
  }

  Widget _buildImageSizePanel(_TemplateLayer layer) {
    final isPhoto = layer.placeholderKey == 'participantPhoto';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF13233F),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2E4568)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
        children: [
          Text(
            isPhoto ? 'PHOTO SIZE' : 'IMAGE SIZE',
            style: const TextStyle(
              color: Color(0xFF9AB0D0),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'W',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 72,
            child: TextField(
              controller: _imageWidthController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: _panelFieldDecoration().copyWith(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              onSubmitted: (_) => _applyImageSizeFromFields(layer),
              onEditingComplete: () => _applyImageSizeFromFields(layer),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'H',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 72,
            child: TextField(
              controller: _imageHeightController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: _panelFieldDecoration().copyWith(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              onSubmitted: (_) => _applyImageSizeFromFields(layer),
              onEditingComplete: () => _applyImageSizeFromFields(layer),
            ),
          ),
          const SizedBox(width: 8),
          _styleIconButton(
            icon: Icons.remove,
            selected: false,
            onTap: () => _adjustSelectedImageSize(widthDelta: -10, heightDelta: -8),
          ),
          const SizedBox(width: 4),
          _styleIconButton(
            icon: Icons.add,
            selected: false,
            onTap: () => _adjustSelectedImageSize(widthDelta: 10, heightDelta: 8),
          ),
          const SizedBox(width: 8),
          Text(
            '${layer.imageWidth.round()} × ${layer.imageHeight.round()} px',
            style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 11),
          ),
        ],
        ),
      ),
    );
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
          _horizontalHoverScrollPanel(
            controller: _textToolbarScrollController,
            child: IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
          ),
          const SizedBox(height: 10),
          _horizontalHoverScrollPanel(
            controller: _textSlidersScrollController,
            child: IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
          ),
        ],
      ),
    );
  }

  Widget _horizontalHoverScrollPanel({
    required ScrollController controller,
    required Widget child,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return PinnedScrollHoverRegion(
          builder: (context, isHovered) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.stylus,
                      PointerDeviceKind.trackpad,
                    },
                  ),
                  child: SingleChildScrollView(
                    controller: controller,
                    scrollDirection: Axis.horizontal,
                    primary: false,
                    physics: const ClampingScrollPhysics(),
                    child: child,
                  ),
                ),
                PinnedHorizontalScrollBar(
                  controller: controller,
                  viewportWidth: constraints.maxWidth,
                  visible: isHovered,
                  style: _kCertificateScrollbarStyle,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLayerItem(_TemplateLayer layer, Size canvasSize, bool selected) {
    final boxWidth = layer.kind == _LayerKind.image
        ? layer.imageWidth
        : layer.textBoxWidth;
    final boxHeight = layer.kind == _LayerKind.image ? layer.imageHeight : 40.0;
    final maxLeft = (canvasSize.width - boxWidth).clamp(0.0, canvasSize.width);
    final maxTop = (canvasSize.height - boxHeight).clamp(0.0, canvasSize.height);
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
              final itemWidth = current.kind == _LayerKind.image
                  ? current.imageWidth
                  : current.textBoxWidth;
              final itemHeight = current.kind == _LayerKind.image
                  ? current.imageHeight
                  : 40.0;
              current.offset = Offset(
                (current.offset.dx + d.delta.dx).clamp(
                  0.0,
                  (canvasSize.width - itemWidth).clamp(0.0, canvasSize.width),
                ),
                (current.offset.dy + d.delta.dy).clamp(
                  0.0,
                  (canvasSize.height - itemHeight).clamp(0.0, canvasSize.height),
                ),
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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            layer.kind == _LayerKind.text
                ? _buildTextLayerContent(layer, selected)
                : _buildImageLayerContent(layer),
            if (selected)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.primaryColor,
                        width: 1.6,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            if (selected && layer.kind == _LayerKind.image)
              Positioned(
                right: 0,
                top: 0,
                child: _buildImageLayerToolbar(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextLayerContent(_TemplateLayer layer, bool selected) {
    final textStyle = TextStyle(
      fontSize: layer.fontSize,
      fontWeight: layer.fontWeight,
      fontStyle: layer.isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: layer.isUnderlined
          ? TextDecoration.underline
          : TextDecoration.none,
      color: layer.textColor,
      fontFamily: layer.fontFamily,
      height: layer.lineHeight,
      leadingDistribution: TextLeadingDistribution.even,
      letterSpacing: layer.letterSpacing,
    );
    return SizedBox(
      width: layer.textBoxWidth,
      child: selected && _inlineEditingLayerId == layer.id
          ? TextField(
              controller: _layerTextController,
              focusNode: _inlineEditFocusNode,
              autofocus: true,
              maxLines: 1,
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
                isCollapsed: true,
              ),
              style: textStyle,
            )
          : Stack(
              fit: StackFit.passthrough,
              children: [
                Text.rich(
                  TextSpan(
                    children: _buildInlineStyledSpans(
                      _resolveTemplateText(layer.text ?? ''),
                      textStyle,
                    ),
                  ),
                  textAlign: layer.textAlign,
                  softWrap: false,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
                if (layer.hasDashedBottomBorder)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final count = (constraints.maxWidth / 8).floor();
                        return Row(
                          children: List.generate(count, (i) {
                            return Container(
                              width: 4,
                              height: 1,
                              margin: const EdgeInsets.only(right: 4),
                              color: layer.textColor,
                            );
                          }),
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildImageLayerContent(_TemplateLayer layer) {
    final imageWidth = layer.imageWidth.clamp(40.0, 1000.0);
    final imageHeight = layer.imageHeight.clamp(24.0, 700.0);
    return SizedBox(
      width: imageWidth,
      height: imageHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: (layer.imageBytes == null || layer.imageBytes!.isEmpty)
            ? _photoPlaceholderBox(layer, imageWidth, imageHeight)
            : Image.memory(
                layer.imageBytes!,
                width: imageWidth,
                height: imageHeight,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) =>
                    _photoPlaceholderBox(layer, imageWidth, imageHeight),
              ),
      ),
    );
  }

  Widget _buildImageLayerToolbar() {
    return Material(
      color: const Color(0xCC0E1D34),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF1F3353)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _styleIconButton(
              icon: Icons.width_normal,
              selected: false,
              onTap: () => _adjustSelectedImageSize(widthDelta: -10),
            ),
            const SizedBox(width: 4),
            _styleIconButton(
              icon: Icons.height,
              selected: false,
              onTap: () => _adjustSelectedImageSize(heightDelta: -8),
            ),
            const SizedBox(width: 4),
            _styleIconButton(
              icon: Icons.add,
              selected: false,
              onTap: () => _adjustSelectedImageSize(
                widthDelta: 10,
                heightDelta: 8,
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: _deleteSelectedLayer,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 34,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B1A1A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: Color(0xFFF87171),
                ),
              ),
            ),
          ],
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

      final canvasSize = _paperOrientedCanvasSize();
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
              width: isMobile ? 200 : 250,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              color: const Color(0xFF0E1D34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: PinnedVerticalScrollViewport(
                      controller: _sidebarScrollController,
                      style: _kCertificateScrollbarStyle,
                      child: SingleChildScrollView(
                        controller: _sidebarScrollController,
                        primary: false,
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
                            _clearDesignerCanvas();
                            _designerHydrated = true;
                            _canvasNameController.text = c.templateName.text;
                            _persistDesignerToBackendModel(c);
                            _syncLayerTextEditor();
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
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'DEFAULT FIELDS',
                    style: TextStyle(
                      color: Colors.blueGrey.shade300,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDefaultFieldsDropdown(),
                  const SizedBox(height: 12),
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
                        color: const Color(0xFF1A2D4D),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF2E4568)),
                      ),
                      child: _layers.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                'Click a default field to add it to the template.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.blueGrey.shade300,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                if (_isMultiMoveMode)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      4,
                                      4,
                                      0,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Select all',
                                            style: TextStyle(
                                              color: Colors.blueGrey.shade100,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Checkbox(
                                          tristate: true,
                                          value: _allLayersSelected
                                              ? true
                                              : (_someLayersSelected
                                                    ? null
                                                    : false),
                                          onChanged: (_) =>
                                              _toggleSelectAllLayers(),
                                          side: BorderSide(
                                            color: Colors.blueGrey.shade200,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Expanded(
                                  child: PinnedVerticalScrollViewport(
                                    controller: _layersScrollController,
                                    alwaysShowScrollbar: true,
                                    style: _kCertificateScrollbarStyle,
                                    child: ListView.builder(
                                      controller: _layersScrollController,
                                      primary: false,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      itemCount: _layers.length,
                                      itemBuilder: (_, i) {
                                        final layer = _layers[i];
                                        final selected =
                                            i == _selectedLayerIndex;
                                        return ListTile(
                                          dense: true,
                                          selected: selected,
                                          selectedTileColor: const Color(
                                            0xFF213455,
                                          ),
                                          leading: Icon(
                                            layer.kind == _LayerKind.image
                                                ? (layer.placeholderKey ==
                                                          'participantPhoto'
                                                      ? Icons.person_outline
                                                      : Icons.image_outlined)
                                                : Icons.text_fields,
                                            color: selected
                                                ? Colors.white
                                                : Colors.blueGrey.shade200,
                                            size: 18,
                                          ),
                                          title: Text(
                                            _layerDisplayName(layer),
                                            style: TextStyle(
                                              color: selected
                                                  ? Colors.white
                                                  : Colors.blueGrey.shade100,
                                              fontSize: 12,
                                            ),
                                          ),
                                          trailing: _isMultiMoveMode
                                              ? Checkbox(
                                                  value: _selectedLayerIds
                                                      .contains(layer.id),
                                                  onChanged: (_) =>
                                                      _toggleMultiLayerSelection(
                                                        layer,
                                                      ),
                                                )
                                              : null,
                                          onTap: () {
                                            if (_isMultiMoveMode) {
                                              _toggleMultiLayerSelection(
                                                layer,
                                              );
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (selectedLayer?.kind == _LayerKind.text) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: _buildTextStylePanel(selectedLayer!),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    if (selectedLayer?.kind == _LayerKind.image) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                        child: _buildImageSizePanel(selectedLayer!),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, previewConstraints) {
                          return _buildScaledCertificatePreview(
                            canvasSize: canvasSize,
                            backgroundImageProvider: backgroundImageProvider,
                            viewW: previewConstraints.maxWidth,
                            viewH: previewConstraints.maxHeight,
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                      child: _BottomActions(
                        c: c,
                        onSave: _onSave,
                        onCancel: _onCancel,
                        primary: primary,
                      ),
                    ),
                  ],
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
