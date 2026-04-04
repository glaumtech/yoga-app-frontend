import 'package:flutter/material.dart';

import '../../../data/models/city_model.dart';

/// Searchable city field using [RawAutocomplete].
///
/// Pass [textEditingController] and [focusNode] from a long-lived owner (e.g. GetX controller)
/// and dispose them there.
class CitySearchField extends StatelessWidget {
  const CitySearchField({
    super.key,
    required this.textEditingController,
    required this.focusNode,
    required this.cities,
    required this.decorationBuilder,
    required this.isMobile,
    required this.onCityId,
    this.hintText = 'Search city (optional)',
    this.maxOptions = 100,
    this.optionsMaxHeight = 200,
    this.validator,
  });

  final TextEditingController textEditingController;
  final FocusNode focusNode;
  final List<CityModel> cities;
  final InputDecoration Function({Widget? suffixIcon}) decorationBuilder;
  final bool isMobile;
  final void Function(int cityId) onCityId;
  final String hintText;
  final int maxOptions;
  final double optionsMaxHeight;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<CityModel>(
      focusNode: focusNode,
      textEditingController: textEditingController,
      displayStringForOption: (CityModel c) => c.cityName,
      optionsBuilder: (TextEditingValue value) {
        final q = value.text.trim().toLowerCase();
        Iterable<CityModel> opts = cities;
        if (q.isNotEmpty) {
          opts = opts.where(
            (c) => c.cityName.toLowerCase().contains(q),
          );
        }
        return opts.take(maxOptions);
      },
      onSelected: (CityModel c) {
        onCityId(c.id);
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
          onChanged: (v) {
            if (v.trim().isEmpty) {
              onCityId(0);
            }
          },
          onFieldSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (
        BuildContext context,
        AutocompleteOnSelected<CityModel> onSelected,
        Iterable<CityModel> options,
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
                  final c = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(c),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(
                        c.cityName,
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
