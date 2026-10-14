import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../controllers/location_masters_controller.dart';
import '../../../widgets/form_title.dart';
import '../../../widgets/pinned_scroll_views.dart';

/// States CRUD panel for Institution Config.
class LocationStatesPanel extends StatelessWidget {
  const LocationStatesPanel({super.key, required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<LocationMastersController>();
    final listCard = _panelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormTitle(text: 'States', isMobile: isMobile, isTablet: false),
          const SizedBox(height: 10),
          TextField(
            controller: c.stateSearchController,
            decoration: const InputDecoration(
              labelText: 'Search states',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Obx(() {
              if (c.isLoadingStates.value && c.states.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final rows = c.filteredStates;
              if (rows.isEmpty) {
                return const Center(child: Text('No states found.'));
              }
              return ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final s = rows[index];
                  return ListTile(
                    dense: true,
                    title: Text(s.stateName),
                    subtitle: Text(s.stateCode),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit),
                          onPressed: () => c.startEditState(s),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final ok = await _confirmDelete(
                              context,
                              title: 'Delete state',
                              message: 'Delete "${s.stateName}"?',
                            );
                            if (ok) await c.deleteState(s.id);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );

    final formCard = _panelCard(
      child: PinnedVerticalScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(
              () => FormTitle(
                text: c.editingStateId.value == null
                    ? 'Add State'
                    : 'Edit State',
                isMobile: isMobile,
                isTablet: false,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: c.stateNameController,
              decoration: const InputDecoration(labelText: 'State name *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: c.stateCodeController,
              decoration: const InputDecoration(
                labelText: 'State code *',
                hintText: 'e.g. TN',
              ),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                LengthLimitingTextInputFormatter(10),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: c.stateDescriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
            const SizedBox(height: 14),
            _formActions(
              onClear: c.startCreateState,
              onSave: c.saveState,
              isEdit: () => c.editingStateId.value != null,
              isSaving: () => c.isSaving.value,
            ),
          ],
        ),
      ),
    );

    return _splitLayout(
      isMobile: isMobile,
      listCard: listCard,
      formCard: formCard,
    );
  }
}

/// Districts CRUD panel for Institution Config.
class LocationDistrictsPanel extends StatelessWidget {
  const LocationDistrictsPanel({super.key, required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<LocationMastersController>();
    final listCard = _panelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormTitle(text: 'Districts', isMobile: isMobile, isTablet: false),
          const SizedBox(height: 10),
          Obx(() {
            final stateIds = c.states.map((s) => s.id).toSet();
            final filterValue = _safeIntValue(
              c.filterDistrictStateId.value,
              stateIds,
            );
            return DropdownButtonFormField<int>(
              value: filterValue,
              isExpanded: true,
              items: c.states
                  .map(
                    (s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(
                        s.stateName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: c.setDistrictFilterState,
              decoration: const InputDecoration(
                labelText: 'Filter by state',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          TextField(
            controller: c.districtSearchController,
            decoration: const InputDecoration(
              labelText: 'Search districts',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Obx(() {
              if (c.isLoadingDistricts.value && c.filteredDistricts.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final rows = c.filteredDistricts;
              if (rows.isEmpty) {
                return const Center(child: Text('No districts found.'));
              }
              return ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final d = rows[index];
                  return ListTile(
                    dense: true,
                    title: Text(d.districtName),
                    subtitle: Text(
                      d.stateName?.isNotEmpty == true
                          ? d.stateName!
                          : c.stateLabel(d.stateId),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit),
                          onPressed: () => c.startEditDistrict(d),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final ok = await _confirmDelete(
                              context,
                              title: 'Delete district',
                              message: 'Delete "${d.districtName}"?',
                            );
                            if (ok) await c.deleteDistrict(d.id);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );

    final formCard = _panelCard(
      child: PinnedVerticalScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(
              () => FormTitle(
                text: c.editingDistrictId.value == null
                    ? 'Add District'
                    : 'Edit District',
                isMobile: isMobile,
                isTablet: false,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final stateIds = c.states.map((s) => s.id).toSet();
              final formValue = _safeIntValue(
                c.districtFormStateId.value,
                stateIds,
              );
              return DropdownButtonFormField<int>(
                value: formValue,
                isExpanded: true,
                items: c.states
                    .map(
                      (s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(
                          s.stateName,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: c.setDistrictFormState,
                decoration: const InputDecoration(labelText: 'State *'),
              );
            }),
            const SizedBox(height: 10),
            TextField(
              controller: c.districtNameController,
              decoration: const InputDecoration(labelText: 'District name *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: c.districtDescriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
            const SizedBox(height: 14),
            _formActions(
              onClear: c.startCreateDistrict,
              onSave: c.saveDistrict,
              isEdit: () => c.editingDistrictId.value != null,
              isSaving: () => c.isSaving.value,
            ),
          ],
        ),
      ),
    );

    return _splitLayout(
      isMobile: isMobile,
      listCard: listCard,
      formCard: formCard,
    );
  }
}

/// Cities / pincode CRUD panel for Institution Config.
class LocationCitiesPanel extends StatelessWidget {
  const LocationCitiesPanel({super.key, required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<LocationMastersController>();
    final listCard = _panelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormTitle(
            text: 'Cities / Towns / Villages',
            isMobile: isMobile,
            isTablet: false,
          ),
          const SizedBox(height: 10),
          Obx(() {
            final stateIds = c.states.map((s) => s.id).toSet();
            final filterValue = _safeIntValue(
              c.filterCityStateId.value,
              stateIds,
            );
            return DropdownButtonFormField<int>(
              value: filterValue,
              isExpanded: true,
              items: c.states
                  .map(
                    (s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(
                        s.stateName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: c.setCityFilterState,
              decoration: const InputDecoration(
                labelText: 'Filter by state',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          Obx(() {
            final districts = c.districtsForState(c.filterCityStateId.value);
            final districtIds = districts.map((d) => d.id).toSet();
            final filterDistrict = _safeNullableIntValue(
              c.filterCityDistrictId.value,
              districtIds,
            );
            return DropdownButtonFormField<int?>(
              value: filterDistrict,
              isExpanded: true,
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    'All districts',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                ...districts.map(
                  (d) => DropdownMenuItem<int?>(
                    value: d.id,
                    child: Text(
                      d.districtName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
              onChanged: c.setCityFilterDistrict,
              decoration: const InputDecoration(
                labelText: 'Filter by district',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          TextField(
            controller: c.citySearchController,
            decoration: const InputDecoration(
              labelText: 'Search city / pincode',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Obx(() {
              if (c.isLoadingCities.value && c.filteredCities.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final rows = c.filteredCities;
              if (rows.isEmpty) {
                return const Center(child: Text('No cities found.'));
              }
              return ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final city = rows[index];
                  final village = (city.village ?? city.description ?? '')
                      .trim();
                  return ListTile(
                    dense: true,
                    title: Text(city.cityName),
                    subtitle: Text(
                      [
                        if (city.districtName.isNotEmpty) city.districtName,
                        if (city.pincode.isNotEmpty) city.pincode,
                        if (village.isNotEmpty) village,
                      ].join(' • '),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit),
                          onPressed: () => c.startEditCity(city),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final ok = await _confirmDelete(
                              context,
                              title: 'Delete city',
                              message: 'Delete "${city.cityName}"?',
                            );
                            if (ok) await c.deleteCity(city.id);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );

    final formCard = _panelCard(
      child: PinnedVerticalScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(
              () => FormTitle(
                text: c.editingCityId.value == null
                    ? 'Add City / Pincode'
                    : 'Edit City / Pincode',
                isMobile: isMobile,
                isTablet: false,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final stateIds = c.states.map((s) => s.id).toSet();
              final formValue = _safeIntValue(
                c.cityFormStateId.value,
                stateIds,
              );
              return DropdownButtonFormField<int>(
                value: formValue,
                isExpanded: true,
                items: c.states
                    .map(
                      (s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(
                          s.stateName,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: c.setCityFormState,
                decoration: const InputDecoration(labelText: 'State *'),
              );
            }),
            const SizedBox(height: 10),
            Obx(() {
              final districts = c.districtsForState(c.cityFormStateId.value);
              final districtIds = districts.map((d) => d.id).toSet();
              final formDistrict = _safeIntValue(
                c.cityFormDistrictId.value,
                districtIds,
              );
              return DropdownButtonFormField<int>(
                value: formDistrict,
                isExpanded: true,
                items: districts
                    .map(
                      (d) => DropdownMenuItem(
                        value: d.id,
                        child: Text(
                          d.districtName,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: districts.isEmpty ? null : c.setCityFormDistrict,
                decoration: InputDecoration(
                  labelText: 'District *',
                  hintText: districts.isEmpty
                      ? 'Add a district for this state first'
                      : null,
                ),
              );
            }),
            const SizedBox(height: 10),
            TextField(
              controller: c.cityNameController,
              decoration: const InputDecoration(
                labelText: 'City / town / village *',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: c.cityPincodeController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(
                labelText: 'Pincode (optional)',
                hintText: '6 digits',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: c.cityDescriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
            const SizedBox(height: 14),
            _formActions(
              onClear: c.startCreateCity,
              onSave: c.saveCity,
              isEdit: () => c.editingCityId.value != null,
              isSaving: () => c.isSaving.value,
            ),
          ],
        ),
      ),
    );

    return _splitLayout(
      isMobile: isMobile,
      listCard: listCard,
      formCard: formCard,
    );
  }
}

int? _safeIntValue(int? value, Set<int> validIds) {
  if (value == null) return null;
  return validIds.contains(value) ? value : null;
}

int? _safeNullableIntValue(int? value, Set<int> validIds) {
  if (value == null) return null;
  return validIds.contains(value) ? value : null;
}

Widget _panelCard({required Widget child}) {
  return Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: child,
    ),
  );
}

Widget _splitLayout({
  required bool isMobile,
  required Widget listCard,
  required Widget formCard,
}) {
  return Padding(
    padding: EdgeInsets.all(isMobile ? 12 : 16),
    child: isMobile
        ? PinnedVerticalScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 420, child: listCard),
                const SizedBox(height: 12),
                formCard,
              ],
            ),
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 2, child: listCard),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: formCard),
            ],
          ),
  );
}

Widget _formActions({
  required VoidCallback onClear,
  required Future<void> Function() onSave,
  required bool Function() isEdit,
  required bool Function() isSaving,
}) {
  return Obx(() {
    final saving = isSaving();
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: saving ? null : onClear,
          child: const Text('Clear'),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: saving ? null : onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(isEdit() ? 'Update' : 'Save'),
        ),
      ],
    );
  });
}

Future<bool> _confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return ok == true;
}
