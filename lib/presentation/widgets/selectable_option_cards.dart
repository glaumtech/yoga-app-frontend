import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A single option in [SelectableOptionCards].
class SelectableOptionItem {
  const SelectableOptionItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
  });

  final String value;
  final String label;
  final String? subtitle;
  final IconData? icon;
}

/// Reusable row/grid of tappable cards (subscription mode, payment method, etc.).
class SelectableOptionCards extends StatelessWidget {
  const SelectableOptionCards({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    this.enabled = true,
    this.minCardWidth = 140,
  });

  final List<SelectableOptionItem> options;
  final String? selectedValue;
  final ValueChanged<String> onSelected;
  final bool enabled;
  final double minCardWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRow = constraints.maxWidth >= 520 && options.length <= 4;
        if (useRow) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: options.map((opt) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: opt == options.last ? 0 : 10,
                  ),
                  child: _OptionCard(
                    option: opt,
                    selected: selectedValue == opt.value,
                    enabled: enabled,
                    onTap: () => onSelected(opt.value),
                  ),
                ),
              );
            }).toList(),
          );
        }
        return Column(
          children: options.map((opt) {
            return Padding(
              padding: EdgeInsets.only(bottom: opt == options.last ? 0 : 10),
              child: _OptionCard(
                option: opt,
                selected: selectedValue == opt.value,
                enabled: enabled,
                onTap: () => onSelected(opt.value),
                expand: true,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.expand = false,
  });

  final SelectableOptionItem option;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor;
    final borderColor = selected ? primary : Colors.grey.shade300;
    final bgColor = selected
        ? primary.withValues(alpha: 0.08)
        : Colors.grey.shade50;

    final card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
            color: enabled ? bgColor : Colors.grey.shade100,
          ),
          child: Row(
            children: [
              if (option.icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selected
                        ? primary.withValues(alpha: 0.15)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    option.icon,
                    size: 22,
                    color: selected ? primary : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: selected ? primary : Colors.grey.shade900,
                      ),
                    ),
                    if (option.subtitle != null &&
                        option.subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        option.subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 22,
                color: selected ? primary : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );

    if (expand) {
      return SizedBox(width: double.infinity, child: card);
    }
    return card;
  }
}
