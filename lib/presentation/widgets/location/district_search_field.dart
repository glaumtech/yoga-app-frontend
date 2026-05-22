import 'package:flutter/material.dart';

import '../../../data/models/district_model.dart';

/// Searchable district field using [RawAutocomplete].
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
    this.onDistrictSelected,
  });

  final TextEditingController textEditingController;
  final FocusNode focusNode;
  final List<DistrictModel> districts;
  final InputDecoration Function({Widget? suffixIcon}) decorationBuilder;
  final bool isMobile;
  final String hintText;
  final int maxOptions;
  final double optionsMaxHeight;
  final FormFieldValidator<String>? validator;
  final ValueChanged<DistrictModel>? onDistrictSelected;

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<DistrictModel>(
      focusNode: focusNode,
      textEditingController: textEditingController,
      displayStringForOption: (DistrictModel d) => d.districtName,
      optionsBuilder: (TextEditingValue value) {
        final q = value.text.trim().toLowerCase();
        Iterable<DistrictModel> opts = districts;
        if (q.isNotEmpty) {
          opts = opts.where((d) => d.districtName.toLowerCase().contains(q));
        }
        return opts.take(maxOptions);
      },
      onSelected: (DistrictModel d) {
        onDistrictSelected?.call(d);
      },
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
        AutocompleteOnSelected<DistrictModel> onSelected,
        Iterable<DistrictModel> options,
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
                        d.districtName,
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
