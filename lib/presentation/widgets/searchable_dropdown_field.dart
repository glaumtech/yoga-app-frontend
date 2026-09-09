import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class SearchableDropdownItem {
  final String value;
  final String label;

  const SearchableDropdownItem({required this.value, required this.label});
}

/// Dropdown that shows a search box and only [visibleItemCount] rows before scrolling.
class SearchableDropdownField extends StatefulWidget {
  const SearchableDropdownField({
    super.key,
    required this.items,
    required this.onChanged,
    this.selectedValue,
    this.hintText = 'Select',
    this.searchHint = 'Search competition...',
    this.emptyListMessage = 'No competitions found',
    this.emptyOptionLabel,
    this.emptyOptionValue = '',
    this.visibleItemCount = 5,
    this.enabled = true,
    this.labelText,
    this.fillColor,
    this.contentPadding,
    this.isDense = true,
    this.validator,
    this.autovalidateMode,
    this.suffixIcon,
  });

  final List<SearchableDropdownItem> items;
  final String? selectedValue;
  final ValueChanged<String> onChanged;
  final String hintText;
  final String searchHint;
  final String emptyListMessage;
  final String? emptyOptionLabel;
  final String emptyOptionValue;
  final int visibleItemCount;
  final bool enabled;
  final String? labelText;
  final Color? fillColor;
  final EdgeInsetsGeometry? contentPadding;
  final bool isDense;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;
  final Widget? suffixIcon;

  @override
  State<SearchableDropdownField> createState() =>
      _SearchableDropdownFieldState();
}

class _SearchableDropdownFieldState extends State<SearchableDropdownField> {
  static const double _itemHeight = 44;

  final OverlayPortalController _overlay = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  String _query = '';
  bool _isOpen = false;
  void Function(String) _emitChange = (_) {};

  @override
  void initState() {
    super.initState();
    _emitChange = widget.onChanged;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<SearchableDropdownItem> get _allItems {
    if (widget.emptyOptionLabel == null) return widget.items;
    return [
      SearchableDropdownItem(
        value: widget.emptyOptionValue,
        label: widget.emptyOptionLabel!,
      ),
      ...widget.items,
    ];
  }

  String? get _selectedLabel {
    final selected = widget.selectedValue ?? '';
    if (selected.isEmpty) {
      return widget.emptyOptionLabel;
    }
    for (final item in widget.items) {
      if (item.value == selected) return item.label;
    }
    return widget.emptyOptionLabel;
  }

  List<SearchableDropdownItem> get _filteredItems {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _allItems;
    return _allItems
        .where((item) => item.label.toLowerCase().contains(query))
        .toList();
  }

  void _open() {
    if (!widget.enabled || _isOpen) return;
    _searchController.clear();
    _query = '';
    _overlay.show();
    setState(() => _isOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _close() {
    if (!_isOpen) return;
    _searchFocusNode.unfocus();
    _overlay.hide();
    if (!mounted) return;
    setState(() {
      _isOpen = false;
      _query = '';
      _searchController.clear();
    });
  }

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _select(SearchableDropdownItem item) {
    _emitChange(item.value);
    _close();
  }

  @override
  Widget build(BuildContext context) {
    _emitChange = widget.onChanged;
    if (widget.validator == null) {
      return _buildPortal(errorText: null);
    }
    return FormField<String>(
      initialValue: widget.selectedValue,
      validator: widget.validator,
      autovalidateMode:
          widget.autovalidateMode ?? AutovalidateMode.onUserInteraction,
      builder: (state) {
        _emitChange = (value) {
          state.didChange(value.isEmpty ? null : value);
          widget.onChanged(value);
        };
        return _buildPortal(errorText: state.errorText);
      },
    );
  }

  Widget _buildPortal({required String? errorText}) {
    final selectedLabel = _selectedLabel;
    final isOpen = _isOpen;
    final hasValue = (widget.selectedValue ?? '').isNotEmpty ||
        widget.emptyOptionLabel != null;

    return OverlayPortal(
      controller: _overlay,
      overlayChildBuilder: _buildOverlay,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled ? _toggle : null,
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              isEmpty: !hasValue || selectedLabel == null,
              decoration: InputDecoration(
                labelText: widget.labelText,
                errorText: errorText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isOpen
                        ? AppTheme.primaryColor
                        : (Colors.grey[400] ?? Colors.grey),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.primaryColor),
                ),
                filled: true,
                fillColor: widget.fillColor ?? Colors.grey[50],
                contentPadding:
                    widget.contentPadding ??
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                isDense: widget.isDense,
                suffixIcon:
                    widget.suffixIcon ??
                    Icon(
                      isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: AppTheme.primaryColor,
                    ),
              ),
              child: Text(
                selectedLabel ?? widget.hintText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: selectedLabel == null
                      ? Colors.grey[600]
                      : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final box = this.context.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 280;
    final filtered = _filteredItems;
    final visibleCount = widget.visibleItemCount < 1
        ? 1
        : widget.visibleItemCount;
    final listHeight =
        (filtered.isEmpty ? 1 : filtered.length.clamp(1, visibleCount)) *
        _itemHeight;
    final selected = widget.selectedValue ?? widget.emptyOptionValue;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _close,
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 4),
          child: Material(
            elevation: 8,
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: width,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: widget.searchHint,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: listHeight,
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                widget.emptyListMessage,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                        : Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: filtered.length > visibleCount,
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.zero,
                              itemExtent: _itemHeight,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                final isSelected = item.value == selected;
                                return InkWell(
                                  onTap: () => _select(item),
                                  child: Container(
                                    color: isSelected
                                        ? AppTheme.primaryColor.withValues(
                                            alpha: 0.12,
                                          )
                                        : null,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      item.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppTheme.primaryColor
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
