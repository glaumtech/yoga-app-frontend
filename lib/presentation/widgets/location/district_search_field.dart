import 'package:flutter/material.dart';

/// Searchable district field using [RawAutocomplete].
///
/// Pass [textEditingController] and [focusNode] from a long-lived owner (e.g. GetX controller)
/// and dispose them there. The selected value is read from [textEditingController] when searching.
class DistrictSearchField extends StatelessWidget {
  const DistrictSearchField({
    super.key,
    required this.textEditingController,
    required this.focusNode,
    required this.districts,
    required this.decorationBuilder,
    required this.isMobile,
    this.hintText = 'Search district (optional)',
    this.maxOptions = 100,
    this.optionsMaxHeight = 200,
    this.validator,
  });

  final TextEditingController textEditingController;
  final FocusNode focusNode;
  final List<String> districts;
  final InputDecoration Function({Widget? suffixIcon}) decorationBuilder;
  final bool isMobile;
  final String hintText;
  final int maxOptions;
  final double optionsMaxHeight;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      focusNode: focusNode,
      textEditingController: textEditingController,
      displayStringForOption: (String d) => d,
      optionsBuilder: (TextEditingValue value) {
        final q = value.text.trim().toLowerCase();
        Iterable<String> opts = districts;
        if (q.isNotEmpty) {
          opts = opts.where((d) => d.toLowerCase().contains(q));
        }
        return opts.take(maxOptions);
      },
      onSelected: (_) {},
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController fieldController,
        FocusNode fieldFocusNode,
        VoidCallback onFieldSubmitted,
      ) {
        return TextFormField(
          controller: fieldController,
          focusNode: fieldFocusNode,
          style: TextStyle(fontSize: isMobile ? 14 : 15),
          decoration: decorationBuilder(suffixIcon: const Icon(Icons.search))
              .copyWith(hintText: hintText),
          validator: validator,
          onFieldSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (
        BuildContext context,
        AutocompleteOnSelected<String> onSelected,
        Iterable<String> options,
      ) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: optionsMaxHeight),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final d = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(d),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 15,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
