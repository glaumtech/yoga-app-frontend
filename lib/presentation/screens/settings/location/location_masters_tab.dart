import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/location_import_result.dart';
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
                          tooltip: s.hasDistricts
                              ? '${s.stateName} is mapped to a district and cannot be deleted'
                              : 'Delete',
                          icon: Icon(
                            Icons.delete,
                            color: s.hasDistricts ? Colors.grey : Colors.red,
                          ),
                          onPressed: s.hasDistricts
                              ? null
                              : () async {
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

    final formCard = _locationFormCard(
      isMobile: isMobile,
      addTitle: () =>
          c.editingStateId.value == null ? 'Add State' : 'Edit State',
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                          tooltip: d.hasCities
                              ? '${d.districtName} is mapped to a city and cannot be deleted'
                              : 'Delete',
                          icon: Icon(
                            Icons.delete,
                            color: d.hasCities ? Colors.grey : Colors.red,
                          ),
                          onPressed: d.hasCities
                              ? null
                              : () async {
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

    final formCard = _locationFormCard(
      isMobile: isMobile,
      addTitle: () => c.editingDistrictId.value == null
          ? 'Add District'
          : 'Edit District',
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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

    final formCard = _locationFormCard(
      isMobile: isMobile,
      importMode: c.showCityImport,
      importTitle: 'Import City / Pincode',
      addTitle: () => c.editingCityId.value == null
          ? 'Add City / Pincode'
          : 'Edit City / Pincode',
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
    );

    return _splitLayout(
      isMobile: isMobile,
      listCard: listCard,
      formCard: formCard,
    );
  }
}

Widget _locationFormCard({
  required bool isMobile,
  RxBool? importMode,
  String importTitle = '',
  required String Function() addTitle,
  required Widget form,
}) {
  final mode = importMode;
  final header = Obx(() {
    final importing = mode?.value ?? false;
    final title = importing ? importTitle : addTitle();
    if (mode == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      );
    }
    return _formModeHeader(
      title: title,
      importSelected: importing,
      onAdd: () => mode.value = false,
      onImport: () => mode.value = true,
    );
  });

  final body = mode == null
      ? form
      : Obx(() => mode.value ? const _LocationImportPanel() : form);

  if (isMobile) {
    return _panelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          body,
        ],
      ),
    );
  }

  return _panelCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Expanded(
          child: PinnedVerticalScrollView(child: body),
        ),
      ],
    ),
  );
}

Widget _formModeHeader({
  required String title,
  required bool importSelected,
  required VoidCallback onAdd,
  required VoidCallback onImport,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        _modeActionButton(
          label: 'Add',
          icon: Icons.add,
          selected: !importSelected,
          onPressed: onAdd,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _modeActionButton(
          label: 'Import',
          icon: Icons.upload_file,
          selected: importSelected,
          onPressed: onImport,
        ),
      ],
    ),
  );
}

Widget _modeActionButton({
  required String label,
  required IconData icon,
  required bool selected,
  required VoidCallback onPressed,
}) {
  return TextButton.icon(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      backgroundColor: selected ? AppTheme.primaryColor : Colors.white,
      foregroundColor: selected ? Colors.white : AppTheme.primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppTheme.primaryColor),
      ),
    ),
    icon: Icon(icon, size: 18),
    label: Text(label),
  );
}

class _LocationImportPanel extends StatefulWidget {
  const _LocationImportPanel();

  @override
  State<_LocationImportPanel> createState() => _LocationImportPanelState();
}

class _LocationImportPanelState extends State<_LocationImportPanel> {
  Uint8List? _bytes;
  String? _filename;
  String? _pickError;
  LocationImportResult? _result;

  Future<void> _pickFile() async {
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        allowMultiple: false,
        withData: true,
      );
      if (!mounted || picked == null || picked.files.isEmpty) return;
      final file = picked.files.first;
      final bytes = file.bytes ?? await file.xFile.readAsBytes();
      if (!mounted) return;
      final name = file.name.trim().isEmpty ? 'locations.csv' : file.name.trim();
      if (!name.toLowerCase().endsWith('.csv')) {
        setState(() {
          _pickError = 'Choose a .csv file';
          _bytes = null;
          _filename = null;
          _result = null;
        });
        return;
      }
      if (bytes.isEmpty) {
        setState(() {
          _pickError = 'The selected file is empty';
          _bytes = null;
          _filename = null;
          _result = null;
        });
        return;
      }
      setState(() {
        _bytes = bytes;
        _filename = name;
        _pickError = null;
        _result = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _pickError = 'Could not read the selected file');
    }
  }

  Future<void> _upload() async {
    final bytes = _bytes;
    final filename = _filename;
    if (bytes == null || filename == null) {
      setState(() => _pickError = 'Choose a CSV file first');
      return;
    }
    final controller = Get.find<LocationMastersController>();
    final result = await controller.importLocationCsv(
      bytes: bytes,
      filename: filename,
    );
    if (!mounted) return;
    setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LocationMastersController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // const Text(
        //   'Download the template, fill one row for each city, then upload the CSV. '
        //   'Columns are state name, state code, district, city, pincode, and description.',
        // ),
        // const SizedBox(height: 10),
        // const Text(
        //   'If the state already exists, that state is used. If the district already exists in that state, that district is used. If the same city and pincode already exist in that district, the row is skipped.',
        // ),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: _pickFile,
          child: Row(
            children: [
              const Icon(Icons.attach_file, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _filename ?? 'Choose CSV file',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (_pickError != null) ...[
          const SizedBox(height: 8),
          Text(
            _pickError!,
            style: TextStyle(color: Colors.red.shade700),
          ),
        ],
        if (_result != null) ...[
          const SizedBox(height: 14),
          _ImportSummary(result: _result!),
        ],
        const SizedBox(height: 14),
        Obx(() {
          final importing = controller.isImporting.value;
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: importing
                    ? null
                    : controller.downloadLocationImportTemplate,
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Template'),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: importing || _bytes == null ? null : _upload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                icon: importing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload_file, size: 18),
                label: const Text('Import'),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _ImportSummary extends StatelessWidget {
  const _ImportSummary({required this.result});

  final LocationImportResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${result.totalRows} rows processed',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'States: ${result.statesCreated} created, ${result.statesReused} reused',
          ),
          Text(
            'Districts: ${result.districtsCreated} created, ${result.districtsReused} reused',
          ),
          Text(
            'Cities: ${result.citiesCreated} created, ${result.citiesReused} already existed, ${result.citiesUpdated} updated',
          ),
          if (result.failedRows > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${result.failedRows} row${result.failedRows == 1 ? '' : 's'} failed',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            ...result.errors.map(
              (error) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Row ${error.row}: ${error.message}',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
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
