import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../controllers/certificate_template_controller.dart';
import '../../../widgets/form_title.dart';

/// Built-in merge tokens for the template designer (insert into body).
const List<({String token, String label})> _kBuiltInMergeFields = [
  (token: '{{participantName}}', label: 'Participant name'),
  (token: '{{schoolName}}', label: 'School / institution'),
  (token: '{{event}}', label: 'Event name'),
  (token: '{{date}}', label: 'Date'),
  (token: '{{category}}', label: 'Category'),
  (token: '{{stageName}}', label: 'Stage'),
  (token: '{{headline}}', label: 'Headline'),
  (token: '{{subjectPronoun}}', label: 'Subject pronoun'),
  (token: '{{possessivePronoun}}', label: 'Possessive pronoun'),
];

/// Settings: certificate template designer (layout similar to admin “create template” UIs).
class CertificateTemplateTab extends StatefulWidget {
  const CertificateTemplateTab({super.key});

  @override
  State<CertificateTemplateTab> createState() => _CertificateTemplateTabState();
}

class _CertificateTemplateTabState extends State<CertificateTemplateTab> {
  final TextEditingController _fieldSearchController = TextEditingController();

  /// Custom tokens from “Create template fields” (token -> display label).
  final Map<String, String> _customMergeFields = {};

  @override
  void initState() {
    super.initState();
    Get.put(CertificateTemplateController(), permanent: false);
  }

  @override
  void dispose() {
    _fieldSearchController.dispose();
    super.dispose();
  }

  void _bump() => setState(() {});

  CertificateTemplateController get _c => Get.find<CertificateTemplateController>();

  void _insertToken(String token) {
    final t = _c.templateBody;
    final text = t.text;
    final sel = t.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final newText = text.replaceRange(start, end, token);
    final newOff = start + token.length;
    t.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOff),
    );
    setState(() {});
  }

  void _wrapSelection(String left, String right) {
    final t = _c.templateBody;
    final s = t.selection;
    if (!s.isValid) return;
    final selected = s.textInside(t.text);
    final inner = selected.isEmpty ? '' : selected;
    final replaced = left + inner + right;
    final newText = t.text.replaceRange(s.start, s.end, replaced);
    final newOff = s.start + replaced.length;
    t.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOff),
    );
    setState(() {});
  }

  Future<void> _showCreateFieldDialog() async {
    final keyCtrl = TextEditingController();
    final labelCtrl = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Create template field'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: keyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Field key',
                  hintText: 'e.g. district_name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Display label (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      final raw = keyCtrl.text.trim();
      if (raw.isEmpty) return;
      final slug = raw.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      if (slug.isEmpty) return;
      final token = '{{$slug}}';
      final label = labelCtrl.text.trim().isEmpty ? slug : labelCtrl.text.trim();
      setState(() => _customMergeFields[token] = label);
    } finally {
      keyCtrl.dispose();
      labelCtrl.dispose();
    }
  }

  Future<void> _onSave() async {
    if (_c.templateName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template name is required')),
      );
      return;
    }
    await _c.save();
  }

  Future<void> _onCancel() async {
    await _c.load();
    if (mounted) setState(() {});
  }

  int _wordCount(String s) {
    final t = s.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
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

      final viewH = MediaQuery.sizeOf(context).height;
      final editorH = math.max(260.0, math.min(520.0, viewH * 0.38));

      return LayoutBuilder(
        builder: (context, constraints) {
          final h = math.max(260.0, math.min(560.0, constraints.maxHeight * 0.45));
          final workH = constraints.maxHeight.isFinite ? h : editorH;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 16,
              vertical: isMobile ? 8 : 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormTitle(
                  text: 'Certificate template',
                  isMobile: isMobile,
                  isTablet: false,
                ),
                const SizedBox(height: 8),
                _TopHeaderRow(c: c, isMobile: isMobile, primary: primary),
                const SizedBox(height: 12),
                SizedBox(
                  height: workH,
                  child: isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: math.min(220, workH * 0.42),
                              child: _TemplateFieldsSidebar(
                                c: c,
                                fieldSearchController: _fieldSearchController,
                                customMergeFields: _customMergeFields,
                                onCreateField: _showCreateFieldDialog,
                                onInsertToken: _insertToken,
                                onSearchChanged: _bump,
                                primary: primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: _RichEditorPanel(
                                c: c,
                                onBodyChanged: _bump,
                                onBold: () => _wrapSelection('**', '**'),
                                onItalic: () => _wrapSelection('_', '_'),
                                onUnderline: () => _wrapSelection('<u>', '</u>'),
                                wordCount: _wordCount(c.templateBody.text),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: 280,
                              child: _TemplateFieldsSidebar(
                                c: c,
                                fieldSearchController: _fieldSearchController,
                                customMergeFields: _customMergeFields,
                                onCreateField: _showCreateFieldDialog,
                                onInsertToken: _insertToken,
                                onSearchChanged: _bump,
                                primary: primary,
                              ),
                            ),
                            const VerticalDivider(width: 1),
                            Expanded(
                              child: _RichEditorPanel(
                                c: c,
                                onBodyChanged: _bump,
                                onBold: () => _wrapSelection('**', '**'),
                                onItalic: () => _wrapSelection('_', '_'),
                                onUnderline: () => _wrapSelection('<u>', '</u>'),
                                wordCount: _wordCount(c.templateBody.text),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                _BottomActions(
                  c: c,
                  onSave: _onSave,
                  onCancel: _onCancel,
                  primary: primary,
                ),
                const SizedBox(height: 8),
                _StructuredFieldsExpansion(
                  c: c,
                  isMobile: isMobile,
                  onFieldChanged: _bump,
                ),
              ],
            ),
          );
        },
      );
    });
  }
}

class _TopHeaderRow extends StatelessWidget {
  final CertificateTemplateController c;
  final bool isMobile;
  final Color primary;

  const _TopHeaderRow({
    required this.c,
    required this.isMobile,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final nameField = TextField(
      controller: c.templateName,
      decoration: InputDecoration(
        labelText: 'Template name *',
        hintText: 'Name',
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
    );

    final typeField = Obx(() {
      final v = c.certificateType.value;
      final items = <DropdownMenuItem<String>>[
        ...kCertificateTypes.map(
          (e) => DropdownMenuItem(value: e.value, child: Text(e.label)),
        ),
      ];
      return InputDecorator(
        decoration: InputDecoration(
          labelText: 'Certificate type *',
          border: const OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primary, width: 1.5),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            borderRadius: BorderRadius.circular(8),
            hint: const Text('Select certificate type'),
            value: kCertificateTypes.any((e) => e.value == v) ? v : 'prize_winner',
            items: items,
            onChanged: (x) {
              if (x != null) c.certificateType.value = x;
            },
          ),
        ),
      );
    });

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          nameField,
          const SizedBox(height: 12),
          typeField,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 1, child: nameField),
        const SizedBox(width: 16),
        Expanded(flex: 1, child: typeField),
      ],
    );
  }
}

class _TemplateFieldsSidebar extends StatelessWidget {
  final CertificateTemplateController c;
  final TextEditingController fieldSearchController;
  final Map<String, String> customMergeFields;
  final Future<void> Function() onCreateField;
  final void Function(String token) onInsertToken;
  final VoidCallback onSearchChanged;
  final Color primary;

  const _TemplateFieldsSidebar({
    required this.c,
    required this.fieldSearchController,
    required this.customMergeFields,
    required this.onCreateField,
    required this.onInsertToken,
    required this.onSearchChanged,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final q = fieldSearchController.text.trim().toLowerCase();

    final builtIn = _kBuiltInMergeFields.where((e) {
      if (q.isEmpty) return true;
      return e.label.toLowerCase().contains(q) ||
          e.token.toLowerCase().contains(q);
    }).toList();

    final customEntries = customMergeFields.entries.where((e) {
      if (q.isEmpty) return true;
      return e.key.toLowerCase().contains(q) ||
          e.value.toLowerCase().contains(q);
    }).toList();

    final hasAny = builtIn.isNotEmpty || customEntries.isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextButton.icon(
              onPressed: () => onCreateField(),
              icon: Icon(Icons.add, size: 18, color: primary),
              label: Text('Create template fields', style: TextStyle(color: primary)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Template Fields',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: fieldSearchController,
              onChanged: (_) => onSearchChanged(),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: !hasAny
                ? Center(
                    child: Text(
                      q.isNotEmpty ? 'No matching fields' : 'Data not available',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    children: [
                      ...builtIn.map(
                        (e) => ListTile(
                          dense: true,
                          title: Text(e.label, style: const TextStyle(fontSize: 13)),
                          subtitle: Text(
                            e.token,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                              fontFamily: 'monospace',
                            ),
                          ),
                          onTap: () => onInsertToken(e.token),
                        ),
                      ),
                      ...customEntries.map(
                        (e) => ListTile(
                          dense: true,
                          title: Text(e.value, style: const TextStyle(fontSize: 13)),
                          subtitle: Text(
                            e.key,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                              fontFamily: 'monospace',
                            ),
                          ),
                          onTap: () => onInsertToken(e.key),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _RichEditorPanel extends StatelessWidget {
  final CertificateTemplateController c;
  final VoidCallback onBodyChanged;
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onUnderline;
  final int wordCount;

  const _RichEditorPanel({
    required this.c,
    required this.onBodyChanged,
    required this.onBold,
    required this.onItalic,
    required this.onUnderline,
    required this.wordCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EditorMenuBar(),
          _EditorToolbar(
            onBold: onBold,
            onItalic: onItalic,
            onUnderline: onUnderline,
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: c.templateBody,
                onChanged: (_) => onBodyChanged(),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontSize: 14, height: 1.45),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter description here...',
                  isCollapsed: true,
                ),
              ),
            ),
          ),
          _EditorStatusBar(wordCount: wordCount),
        ],
      ),
    );
  }
}

class _EditorMenuBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const menus = ['File', 'Edit', 'View', 'Insert', 'Format', 'Tools', 'Table'];
    return Material(
      color: const Color(0xFFF5F5F5),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final m in menus) _PopupMenuTitle(title: m),
          ],
        ),
      ),
    );
  }
}

class _PopupMenuTitle extends StatelessWidget {
  final String title;

  const _PopupMenuTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 36),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(title, style: const TextStyle(fontSize: 13)),
      ),
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          enabled: false,
          child: Text('Use the toolbar and canvas for editing', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}

class _EditorToolbar extends StatelessWidget {
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onUnderline;

  const _EditorToolbar({
    required this.onBold,
    required this.onItalic,
    required this.onUnderline,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFAFAFA),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Bold',
                onPressed: onBold,
                icon: const Text('B', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              IconButton(
                tooltip: 'Italic',
                onPressed: onItalic,
                icon: const Text('I', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 16)),
              ),
              IconButton(
                tooltip: 'Underline (HTML)',
                onPressed: onUnderline,
                icon: const Icon(Icons.format_underlined, size: 20),
              ),
              const _VBar(),
              IconButton(
                tooltip: 'Align left',
                onPressed: () {},
                icon: const Icon(Icons.format_align_left, size: 20),
              ),
              IconButton(
                tooltip: 'Align center',
                onPressed: () {},
                icon: const Icon(Icons.format_align_center, size: 20),
              ),
              IconButton(
                tooltip: 'Align right',
                onPressed: () {},
                icon: const Icon(Icons.format_align_right, size: 20),
              ),
              const _VBar(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DropdownButton<String>(
                  value: '12',
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: '10', child: Text('10pt')),
                    DropdownMenuItem(value: '12', child: Text('12pt')),
                    DropdownMenuItem(value: '14', child: Text('14pt')),
                    DropdownMenuItem(value: '18', child: Text('18pt')),
                  ],
                  onChanged: (_) {},
                ),
              ),
              const _VBar(),
              IconButton(
                tooltip: 'Bullet list',
                onPressed: () {},
                icon: const Icon(Icons.format_list_bulleted, size: 20),
              ),
              IconButton(
                tooltip: 'Numbered list',
                onPressed: () {},
                icon: const Icon(Icons.format_list_numbered, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VBar extends StatelessWidget {
  const _VBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 1,
      height: 24,
      color: Colors.grey[400],
    );
  }
}

class _EditorStatusBar extends StatelessWidget {
  final int wordCount;

  const _EditorStatusBar({required this.wordCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.grey[200],
      child: Row(
        children: [
          Text('p', style: TextStyle(fontSize: 12, color: Colors.grey[800])),
          const Spacer(),
          Text(
            '$wordCount words',
            style: TextStyle(fontSize: 12, color: Colors.grey[800]),
          ),
        ],
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _StructuredFieldsExpansion extends StatelessWidget {
  final CertificateTemplateController c;
  final bool isMobile;
  final VoidCallback onFieldChanged;

  const _StructuredFieldsExpansion({
    required this.c,
    required this.isMobile,
    required this.onFieldChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: false,
        title: const Text(
          'Structured fields (PDF API)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          'Branding lines, background, pronouns — used by server PDF generation',
          style: TextStyle(fontSize: 12),
        ),
        children: [
          SizedBox(
            height: isMobile ? 360 : 420,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BrandingSection(
                    c: c,
                    isMobile: isMobile,
                    onFieldChanged: onFieldChanged,
                  ),
                  const SizedBox(height: 8),
                  _AppearanceSection(
                    c: c,
                    isMobile: isMobile,
                    onFieldChanged: onFieldChanged,
                  ),
                  const SizedBox(height: 8),
                  _PronounsSection(
                    c: c,
                    isMobile: isMobile,
                    onFieldChanged: onFieldChanged,
                  ),
                  const SizedBox(height: 8),
                  _StageSection(
                    c: c,
                    isMobile: isMobile,
                    onFieldChanged: onFieldChanged,
                  ),
                  const SizedBox(height: 8),
                  _PreviewSection(c: c, isMobile: isMobile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandingSection extends StatelessWidget {
  final CertificateTemplateController c;
  final bool isMobile;
  final VoidCallback onFieldChanged;

  const _BrandingSection({
    required this.c,
    required this.isMobile,
    required this.onFieldChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        title: const Text(
          'Branding text',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _LabeledField(
            label: 'Subtitle / tagline',
            controller: c.subtitle,
            onTextChanged: onFieldChanged,
          ),
          _LabeledField(
            label: 'Organized by line',
            controller: c.organizedByLine,
            onTextChanged: onFieldChanged,
          ),
          _LabeledField(
            label: 'Organizer association (emphasized line)',
            controller: c.organizerAssociationLine,
            onTextChanged: onFieldChanged,
          ),
          _LabeledField(
            label: 'Coordinated intro (e.g. “Coordinated by”)',
            controller: c.coordinatedIntro,
            onTextChanged: onFieldChanged,
          ),
          _LabeledField(
            label: 'Coordinated name (studio / venue)',
            controller: c.coordinatedName,
            onTextChanged: onFieldChanged,
          ),
          _LabeledField(
            label: 'Signature label 1',
            controller: c.signatureLabel1,
            onTextChanged: onFieldChanged,
          ),
          _LabeledField(
            label: 'Signature label 2',
            controller: c.signatureLabel2,
            onTextChanged: onFieldChanged,
          ),
          _LabeledField(
            label: 'Signature label 3',
            controller: c.signatureLabel3,
            onTextChanged: onFieldChanged,
          ),
          _LabeledField(
            label: 'Signature label 4',
            controller: c.signatureLabel4,
            onTextChanged: onFieldChanged,
          ),
          _LabeledField(
            label: 'Footer text',
            controller: c.footerText,
            onTextChanged: onFieldChanged,
          ),
        ],
      ),
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  final CertificateTemplateController c;
  final bool isMobile;
  final VoidCallback onFieldChanged;

  const _AppearanceSection({
    required this.c,
    required this.isMobile,
    required this.onFieldChanged,
  });

  LinearGradient? _gradientForPreset(String preset) {
    switch (preset) {
      case 'GRADIENT_GOLD':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8E1), Color(0xFFFFD54F), Color(0xFFFFA000)],
        );
      case 'GRADIENT_BLUE':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE3F2FD), Color(0xFF64B5F6), Color(0xFF1565C0)],
        );
      case 'MINIMAL_WHITE':
        return const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF5F5F5)],
        );
      case 'DARK_FRAME':
        return const LinearGradient(
          colors: [Color(0xFF263238), Color(0xFF37474F)],
        );
      case 'CUSTOM_IMAGE':
        return LinearGradient(
          colors: [Colors.grey.shade300, Colors.grey.shade500],
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFFFFFDE7), Color(0xFFFFF3E0)],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: const Text(
          'Background & design',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: const Text(
          'Preset frames and optional image / accent (used when the server supports them)',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Obx(() {
            final preset = c.backgroundPreset.value;
            final known = kCertificateBackgroundPresets.any((e) => e.value == preset);
            final items = <DropdownMenuItem<String>>[
              if (!known)
                DropdownMenuItem(
                  value: preset,
                  child: Text('Server value: $preset'),
                ),
              ...kCertificateBackgroundPresets.map(
                (e) => DropdownMenuItem(
                  value: e.value,
                  child: Text(e.label),
                ),
              ),
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Background style',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(8),
                      value: preset,
                      items: items,
                      onChanged: (v) {
                        if (v != null) c.backgroundPreset.value = v;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Preview (approximate)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: isMobile ? 100 : 120,
                    width: double.infinity,
                    child: preset == 'CUSTOM_IMAGE' && c.backgroundImageUrl.text.trim().isNotEmpty
                        ? Image.network(
                            c.backgroundImageUrl.text.trim(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              decoration: BoxDecoration(
                                gradient: _gradientForPreset(preset),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Could not load image',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: _gradientForPreset(preset),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              c.subtitle.text.isNotEmpty ? c.subtitle.text : 'Certificate subtitle',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: preset == 'DARK_FRAME' ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 12),
          _LabeledField(
            label: 'Custom background image URL (HTTPS)',
            controller: c.backgroundImageUrl,
            hint: 'Used when “Custom image” is selected',
            onTextChanged: onFieldChanged,
          ),
          _LabeledField(
            label: 'Accent color (#RRGGBB)',
            controller: c.accentColorHex,
            hint: 'Optional border / highlight color',
            onTextChanged: onFieldChanged,
          ),
          _LabeledField(
            label: 'Logo image URL (optional)',
            controller: c.logoImageUrl,
            hint: 'Shown when supported by the PDF template',
            onTextChanged: onFieldChanged,
          ),
        ],
      ),
    );
  }
}

class _PronounsSection extends StatelessWidget {
  final CertificateTemplateController c;
  final bool isMobile;
  final VoidCallback onFieldChanged;

  const _PronounsSection({
    required this.c,
    required this.isMobile,
    required this.onFieldChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: const Text(
          'Gender wording',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: const Text('Used from participant sex; fallback when unknown'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Text('Subject (e.g. He / She / They)'),
          const SizedBox(height: 8),
          _LabeledField(
            label: 'Male',
            controller: c.subjectPronounMale,
            onTextChanged: onFieldChanged,
          ),
          _LabeledField(
            label: 'Female',
            controller: c.subjectPronounFemale,
            onTextChanged: onFieldChanged,
          ),
          _LabeledField(
            label: 'Other',
            controller: c.subjectPronounOther,
            onTextChanged: onFieldChanged,
          ),
          _LabeledField(
            label: 'Default (unknown / missing)',
            controller: c.subjectPronounDefault,
            onTextChanged: onFieldChanged,
          ),
          const Divider(height: 24),
          const Text('Possessive (e.g. his / her / their)'),
          const SizedBox(height: 8),
          _LabeledField(
            label: 'Male',
            controller: c.possessivePronounMale,
            onTextChanged: onFieldChanged,
          ),
          _LabeledField(
            label: 'Female',
            controller: c.possessivePronounFemale,
            onTextChanged: onFieldChanged,
          ),
          _LabeledField(
            label: 'Other',
            controller: c.possessivePronounOther,
            onTextChanged: onFieldChanged,
          ),
          _LabeledField(
            label: 'Default (unknown / missing)',
            controller: c.possessivePronounDefault,
            onTextChanged: onFieldChanged,
          ),
        ],
      ),
    );
  }
}

class _StageSection extends StatelessWidget {
  final CertificateTemplateController c;
  final bool isMobile;
  final VoidCallback onFieldChanged;

  const _StageSection({
    required this.c,
    required this.isMobile,
    required this.onFieldChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: const Text(
          'Stage line',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        children: [
          Obx(
            () => SwitchListTile(
              title: const Text('Include stage in “won in …” line'),
              subtitle: const Text(
                'When off, stage is omitted from the combined category line.',
              ),
              value: c.includeStageInWinLine.value,
              onChanged: (v) {
                c.includeStageInWinLine.value = v;
                onFieldChanged();
              },
            ),
          ),
          Obx(
            () => SwitchListTile(
              title: const Text('Show dedicated stage line'),
              subtitle: const Text(
                'Adds a separate line for stage name when enabled.',
              ),
              value: c.showDedicatedStageLine.value,
              onChanged: (v) {
                c.showDedicatedStageLine.value = v;
                onFieldChanged();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _LabeledField(
              label: 'Stage line prefix / pattern',
              controller: c.stageLinePrefix,
              hint: 'e.g. Stage:',
              onTextChanged: onFieldChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewSection extends StatelessWidget {
  final CertificateTemplateController c;
  final bool isMobile;

  const _PreviewSection({required this.c, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sample copy',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final sub = c.subtitle.text.trim().isEmpty
                    ? '~ International Yoga Festival ~'
                    : c.subtitle.text.trim();
                final org = c.organizedByLine.text.trim().isEmpty
                    ? 'Organized by …'
                    : c.organizedByLine.text.trim();
                final assoc = c.organizerAssociationLine.text.trim();
                final foot = c.footerText.text.trim().isEmpty
                    ? 'Generated by Yoga Wellness System'
                    : c.footerText.text.trim();
                final subj = c.subjectPronounMale.text.trim().isEmpty
                    ? 'He'
                    : c.subjectPronounMale.text.trim();
                final poss = c.possessivePronounMale.text.trim().isEmpty
                    ? 'his'
                    : c.possessivePronounMale.text.trim();
                final stageExtra = c.showDedicatedStageLine.value
                    ? '${c.stageLinePrefix.text.trim().isEmpty ? 'Stage:' : c.stageLinePrefix.text.trim()} Main Stage\n'
                    : '';

                return Text(
                  '$sub\n\n'
                  '$org\n'
                  '${assoc.isNotEmpty ? '$assoc\n' : ''}'
                  '\n'
                  '$subj has won in … (category line'
                  '${c.includeStageInWinLine.value ? ', stage included' : ', stage omitted'}).\n'
                  '$poss Excellence …\n'
                  '${stageExtra.isNotEmpty ? '\n$stageExtra' : ''}'
                  '\n$foot',
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final VoidCallback? onTextChanged;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.hint,
    this.onTextChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        maxLines: hint != null && (hint!.length > 40) ? 2 : 1,
        onChanged: (_) => onTextChanged?.call(),
      ),
    );
  }
}
