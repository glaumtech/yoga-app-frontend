import 'package:flutter/material.dart';

import '../../../data/models/state_model.dart';

/// Searchable state field using [RawAutocomplete]. Clears selection when text is emptied.
///
/// Pass [textEditingController] and [focusNode] from a long-lived owner (e.g. GetX controller)
/// and dispose them there.
class StateSearchField extends StatelessWidget {
  const StateSearchField({
    super.key,
    required this.textEditingController,
    required this.focusNode,
    required this.states,
    required this.decorationBuilder,
    required this.isMobile,
    required this.onStateId,
    this.hintText = 'Search state (optional)',
    this.maxOptions = 100,
    this.optionsMaxHeight = 200,
    this.validator,
  });

  final TextEditingController textEditingController;
  final FocusNode focusNode;
  final List<StateModel> states;
  final InputDecoration Function({Widget? suffixIcon}) decorationBuilder;
  final bool isMobile;
  final Future<void> Function(int stateId) onStateId;
  final String hintText;
  final int maxOptions;
  final double optionsMaxHeight;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<StateModel>(
      focusNode: focusNode,
      textEditingController: textEditingController,
      displayStringForOption: (StateModel s) => s.stateName,
      optionsBuilder: (TextEditingValue value) {
        final q = value.text.trim().toLowerCase();
        Iterable<StateModel> opts = states;
        if (q.isNotEmpty) {
          opts = opts.where(
            (s) => s.stateName.toLowerCase().contains(q),
          );
        }
        return opts.take(maxOptions);
      },
      onSelected: (StateModel s) async {
        await onStateId(s.id);
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController fieldController,
        FocusNode fieldFocusNode,
        VoidCallback onFieldSubmitted,
      ) {
        return TextFormField(
          autovalidateMode: validator != null
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          controller: fieldController,
          focusNode: fieldFocusNode,
          style: TextStyle(fontSize: isMobile ? 14 : 15),
          decoration: decorationBuilder(suffixIcon: const Icon(Icons.search))
              .copyWith(hintText: hintText),
          validator: validator,
          onChanged: (v) {
            if (v.trim().isEmpty) {
              onStateId(0);
            }
          },
          onFieldSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (
        BuildContext context,
        AutocompleteOnSelected<StateModel> onSelected,
        Iterable<StateModel> options,
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
                  final s = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(s),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(
                        s.stateName,
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
