import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/school_model.dart';

/// Placeholder id used internally when the API returns no institutions (shows "add new" UI).
const String kInstitutionAutocompleteNoResultsId = '__NO_RESULTS__';

/// Institution name search field with async API search, loading state, and optional "add new" action.
///
/// Wire [formTextController] to your form model (e.g. participant school name). [onSearch] should
/// populate [suggestions] and toggle [isLoading].
class InstitutionNameAutocompleteField extends StatelessWidget {
  const InstitutionNameAutocompleteField({
    super.key,
    required this.autocompleteKey,
    required this.formTextController,
    required this.onSearch,
    required this.suggestions,
    required this.isLoading,
    required this.onInstitutionSelected,
    required this.isViewMode,
    this.validator,
    this.onAddNewInstitution,
    this.onClear,
    this.onValueChanged,
    this.minQueryLength = 3,
    this.hintText = 'Search or type institution name',
    this.optionsMaxHeight = 200,
  });

  /// Unique key segment so the field resets when the form resets (e.g. edit vs new).
  final String autocompleteKey;
  final TextEditingController formTextController;
  final Future<void> Function(String query) onSearch;
  final RxList<SchoolModel> suggestions;
  final RxBool isLoading;
  final void Function(SchoolModel institution) onInstitutionSelected;
  final RxBool isViewMode;
  final String? Function(String? value)? validator;
  final void Function(BuildContext context, String searchText)?
      onAddNewInstitution;
  final VoidCallback? onClear;
  final VoidCallback? onValueChanged;
  final int minQueryLength;
  final String hintText;
  final double optionsMaxHeight;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<SchoolModel>(
      key: ValueKey(autocompleteKey),
      displayStringForOption: (SchoolModel option) => option.institutionName,
        optionsBuilder: (TextEditingValue textEditingValue) async {
          if (textEditingValue.text.isEmpty ||
              textEditingValue.text.length < minQueryLength) {
            return const Iterable<SchoolModel>.empty();
          }
          final searchText = textEditingValue.text.trim();
          await onSearch(searchText);
          final list = suggestions;
          if (list.isEmpty &&
              !isLoading.value &&
              searchText.length >= minQueryLength) {
            return [
              SchoolModel(
                id: kInstitutionAutocompleteNoResultsId,
                institutionName: kInstitutionAutocompleteNoResultsId,
                address: '',
                pincode: '',
                institutionType: kInstitutionAutocompleteNoResultsId,
                stateId: 0,
                cityId: 0,
              ),
            ];
          }
          return list;
        },
        onSelected: (inst) {
          // Keep the outer form controller in sync so the selected value
          // remains visible even if the Autocomplete rebuilds.
          if (formTextController.text != inst.institutionName) {
            formTextController.value = TextEditingValue(
              text: inst.institutionName,
              selection: TextSelection.collapsed(
                offset: inst.institutionName.length,
              ),
            );
          }
          onInstitutionSelected(inst);
          onValueChanged?.call();
        },
        fieldViewBuilder: (
          BuildContext context,
          TextEditingController textEditingController,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted,
        ) {
          return Obx(() {
            if (textEditingController.text != formTextController.text) {
              textEditingController.value = formTextController.value;
            }
            final hasText = textEditingController.text.trim().isNotEmpty;
            return TextFormField(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              controller: textEditingController,
              readOnly: isViewMode.value,
              focusNode: focusNode,
              onFieldSubmitted: (String value) => onFieldSubmitted(),
              onChanged: isViewMode.value
                  ? null
                  : (value) {
                      if (formTextController.text != value) {
                        formTextController.text = value;
                      }
                      onValueChanged?.call();
                    },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: isLoading.value
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (hasText
                        ? IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              textEditingController.clear();
                              formTextController.clear();
                              suggestions.clear();
                              FocusScope.of(context).unfocus();
                              onClear?.call();
                              onValueChanged?.call();
                            },
                          )
                        : const Icon(Icons.search)),
                hintText: hintText,
                filled: true,
                fillColor: isViewMode.value ? Colors.grey[200] : Colors.white,
              ),
              validator: validator,
            );
          });
        },
        optionsViewBuilder: (
          BuildContext context,
          AutocompleteOnSelected<SchoolModel> onSelected,
          Iterable<SchoolModel> options,
        ) {
          return Obx(() {
            final searchText = formTextController.text.trim();
            final hasSearchText = searchText.length >= minQueryLength;
            final loading = isLoading.value;
            final sug = suggestions;
            final optionsList = options.toList();
            final hasPlaceholder = optionsList.isNotEmpty &&
                optionsList.first.id == kInstitutionAutocompleteNoResultsId;
            final hasNoResults = hasSearchText &&
                !loading &&
                sug.isEmpty &&
                hasPlaceholder;

            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: optionsMaxHeight),
                  child: hasNoResults
                      ? Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.school_outlined,
                                  size: 32,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No institution found',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'for "$searchText"',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (onAddNewInstitution != null) ...[
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      FocusScope.of(context).unfocus();
                                      onAddNewInstitution!(context, searchText);
                                    },
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Add New Institution'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.green[700],
                                      side: BorderSide(
                                        color: Colors.green[700]!,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : loading
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final list = options.toList();
                                final SchoolModel option = list[index];
                                if (option.id ==
                                    kInstitutionAutocompleteNoResultsId) {
                                  return const SizedBox.shrink();
                                }
                                return InkWell(
                                  onTap: () => onSelected(option),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          option.institutionName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (option.address.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            option.address,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        if (option.cityName != null ||
                                            option.stateName != null ||
                                            option.pincode.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '${option.cityName ?? ''}${option.cityName != null && option.stateName != null ? ', ' : ''}${option.stateName ?? ''}${(option.cityName != null || option.stateName != null) && option.pincode.isNotEmpty ? ' - ' : ''}${option.pincode.isNotEmpty ? option.pincode : ''}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ),
            );
          });
        },
    );
  }
}
