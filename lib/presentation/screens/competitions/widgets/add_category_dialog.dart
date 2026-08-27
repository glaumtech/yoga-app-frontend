import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';

/// Existing category entries used for name+mode duplicate checks.
class ExistingCategoryEntry {
  const ExistingCategoryEntry({
    required this.name,
    required this.mode,
  });

  final String name;
  final String mode;
}

/// Three-step modal: format → mode → category name.
class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({
    super.key,
    this.existingCategories = const [],
  });

  /// Categories already on this competition (duplicate = same name + same mode).
  final List<ExistingCategoryEntry> existingCategories;

  /// Returns `{format, mode, name}` or null if cancelled.
  static Future<Map<String, String>?> show(
    BuildContext context, {
    List<ExistingCategoryEntry> existingCategories = const [],
    @Deprecated('Use existingCategories') List<String> existingCategoryNames = const [],
  }) {
    final entries = existingCategories.isNotEmpty
        ? existingCategories
        : existingCategoryNames
            .where((n) => n.trim().isNotEmpty)
            .map((n) => ExistingCategoryEntry(name: n, mode: 'OFFLINE'))
            .toList();
    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddCategoryDialog(
        existingCategories: entries,
      ),
    );
  }

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  /// 0 = format, 1 = mode, 2 = name
  int _step = 0;
  String? _format; // ASANAS | CHALLENGE
  String? _mode; // ONLINE | OFFLINE
  final _nameController = TextEditingController();
  String? _nameError;

  String _normalizeMode(String? mode) =>
      (mode ?? 'OFFLINE').trim().toUpperCase() == 'ONLINE' ? 'ONLINE' : 'OFFLINE';

  bool _isDuplicate(String name, String mode) {
    final normalizedName = name.trim().toUpperCase();
    final normalizedMode = _normalizeMode(mode);
    return widget.existingCategories.any(
      (e) =>
          e.name.trim().toUpperCase() == normalizedName &&
          _normalizeMode(e.mode) == normalizedMode,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _selectFormat(String format) {
    setState(() {
      _format = format;
      _step = 1;
      _nameError = null;
    });
  }

  void _selectMode(String mode) {
    setState(() {
      _mode = mode;
      _step = 2;
      _nameError = null;
    });
  }

  void _goBack() {
    setState(() {
      if (_step == 2) {
        _step = 1;
        _nameError = null;
        _nameController.clear();
      } else if (_step == 1) {
        _step = 0;
        _mode = null;
      }
    });
  }

  void _confirm() {
    final name = _nameController.text.trim().toUpperCase();
    final mode = _normalizeMode(_mode);
    if (name.isEmpty) {
      setState(() => _nameError = 'Category name is required');
      return;
    }
    if (_isDuplicate(name, mode)) {
      final modeLabel = mode == 'ONLINE' ? 'Online' : 'Offline';
      setState(
        () => _nameError =
            'Category "$name" already exists for $modeLabel mode',
      );
      return;
    }
    Navigator.of(context).pop(<String, String>{
      'format': _format ?? 'ASANAS',
      'mode': mode,
      'name': name,
    });
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: switch (_step) {
            0 => _buildFormatStep(primary),
            1 => _buildModeStep(primary),
            _ => _buildNameStep(primary),
          },
        ),
      ),
    );
  }

  Widget _buildFormatStep(Color primary) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Add Category',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Step 1 of 3 — Choose competition format',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 20),
        _OptionCard(
          title: 'Asanas',
          subtitle: 'Stage-based yoga asana competition',
          icon: Icons.self_improvement,
          accent: primary,
          onTap: () => _selectFormat('ASANAS'),
        ),
        const SizedBox(height: 12),
        _OptionCard(
          title: 'Challenge',
          subtitle: 'Single-pose endurance or speed challenge',
          icon: Icons.bolt,
          accent: const Color(0xFF0369A1),
          // badge: 'Coming soon',
          onTap: () => _selectFormat('CHALLENGE'),
        ),
        const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            onPressed: _cancel,
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }

  Widget _buildModeStep(Color primary) {
    final isChallenge = _format == 'CHALLENGE';
    final formatLabel = isChallenge ? 'Challenge' : 'Asanas';
    final formatColor =
        isChallenge ? const Color(0xFF0369A1) : primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select mode',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
            children: [
              const TextSpan(text: 'Step 2 of 3 — Format: '),
              TextSpan(
                text: formatLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: formatColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _OptionCard(
          title: 'Online',
          subtitle: 'Digital registration and online participation flow',
          icon: Icons.cloud_outlined,
          accent: primary,
          onTap: () => _selectMode('ONLINE'),
        ),
        const SizedBox(height: 12),
        _OptionCard(
          title: 'Offline',
          subtitle: 'On-site / spot registration and venue-based flow',
          icon: Icons.storefront_outlined,
          accent: const Color(0xFF0F766E),
          onTap: () => _selectMode('OFFLINE'),
        ),
        const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _goBack,
              icon: const Icon(Icons.chevron_left, size: 18),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: BorderSide(color: primary.withValues(alpha: 0.4)),
                backgroundColor: primary.withValues(alpha: 0.06),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: _cancel,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNameStep(Color primary) {
    final isChallenge = _format == 'CHALLENGE';
    final formatLabel = isChallenge ? 'Challenge' : 'Asanas';
    final formatColor =
        isChallenge ? const Color(0xFF0369A1) : primary;
    final modeLabel = _mode == 'ONLINE' ? 'Online' : 'Offline';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Name your category',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
            children: [
              const TextSpan(text: 'Step 3 of 3 — Format: '),
              TextSpan(
                text: formatLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: formatColor,
                ),
              ),
              const TextSpan(text: ' · Mode: '),
              TextSpan(
                text: modeLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Category Name',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            UpperCaseTextFormatter(),
          ],
          decoration: InputDecoration(
            hintText: 'e.g. ARTISTIC, PAIR YOGA',
            errorText: _nameError,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
          onSubmitted: (_) => _confirm(),
        ),
        const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _goBack,
              icon: const Icon(Icons.chevron_left, size: 18),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: BorderSide(color: primary.withValues(alpha: 0.4)),
                backgroundColor: primary.withValues(alpha: 0.06),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: _cancel,
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FilledButton.icon(
                onPressed: _confirm,
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'Create',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 2),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Forces uppercase input as the user types.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
