import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A reusable toggle button group widget
///
/// Displays a group of toggle buttons with consistent styling.
/// Supports responsive design and optional icons.
/// Automatically determines screen size using MediaQuery.
class ToggleButtonGroup extends StatelessWidget {
  /// List of button options, each with a label and optional icon
  final List<ToggleButtonOption> options;

  /// Index of the currently selected button
  final int selectedIndex;

  /// Callback when a button is tapped
  final ValueChanged<int> onTap;

  /// Optional custom primary color (defaults to AppTheme.primaryColor)
  final Color? primaryColor;

  const ToggleButtonGroup({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onTap,
    this.primaryColor,
  }) : assert(
         selectedIndex >= 0 && selectedIndex < options.length,
         'selectedIndex must be within the range of options',
       );

  @override
  Widget build(BuildContext context) {
    final color = primaryColor ?? AppTheme.primaryColor;

    // Determine screen size internally
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...options
              .asMap()
              .entries
              .map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isFirst = index == 0;
                final isLast = index == options.length - 1;
                final isSelected = index == selectedIndex;

                return [
                  if (index > 0)
                    Container(width: 1, height: 32, color: Colors.grey[200]),
                  _ToggleButton(
                    label: option.label,
                    icon: option.icon,
                    isSelected: isSelected,
                    onTap: () => onTap(index),
                    isMobile: isMobile,
                    isTablet: isTablet,
                    isFirst: isFirst,
                    isLast: isLast,
                    primaryColor: color,
                  ),
                ];
              })
              .expand((widgets) => widgets),
        ],
      ),
    );
  }
}

/// Represents a single toggle button option
class ToggleButtonOption {
  /// The label text for the button
  final String label;

  /// Optional icon to display before the label
  final IconData? icon;

  const ToggleButtonOption({required this.label, this.icon});
}

/// Internal widget for individual toggle button
class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isMobile;
  final bool isTablet;
  final bool isFirst;
  final bool isLast;
  final Color primaryColor;

  const _ToggleButton({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isMobile,
    required this.isTablet,
    required this.isFirst,
    required this.isLast,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.only(
          topLeft: isFirst ? const Radius.circular(8) : Radius.zero,
          bottomLeft: isFirst ? const Radius.circular(8) : Radius.zero,
          topRight: isLast ? const Radius.circular(8) : Radius.zero,
          bottomRight: isLast ? const Radius.circular(8) : Radius.zero,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 24,
            vertical: isMobile ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.only(
              topLeft: isFirst ? const Radius.circular(8) : Radius.zero,
              bottomLeft: isFirst ? const Radius.circular(8) : Radius.zero,
              topRight: isLast ? const Radius.circular(8) : Radius.zero,
              bottomRight: isLast ? const Radius.circular(8) : Radius.zero,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: isMobile ? 16 : 18,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
                SizedBox(width: isMobile ? 4 : 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: isMobile ? 14 : 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
