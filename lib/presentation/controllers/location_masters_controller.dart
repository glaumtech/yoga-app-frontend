import 'dart:convert';
import 'dart:html' as html show AnchorElement, Blob, Url;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/navigation/root_scaffold_messenger_key.dart';
import '../../data/models/city_model.dart';
import '../../data/models/district_model.dart';
import '../../data/models/location_import_result.dart';
import '../../data/models/state_model.dart';
import '../../data/repositories/location_repository.dart';

class LocationMastersController extends GetxController {
  final LocationRepository _repo = LocationRepository();

  final RxBool isLoadingStates = false.obs;
  final RxBool isLoadingDistricts = false.obs;
  final RxBool isLoadingCities = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isImporting = false.obs;
  final RxBool showCityImport = false.obs;

  final RxList<StateModel> states = <StateModel>[].obs;
  final RxList<DistrictModel> districts = <DistrictModel>[].obs;
  final RxList<CityModel> cities = <CityModel>[].obs;

  final RxnInt filterDistrictStateId = RxnInt();
  final RxnInt filterCityStateId = RxnInt();
  final RxnInt filterCityDistrictId = RxnInt();

  final TextEditingController stateNameController = TextEditingController();
  final TextEditingController stateCodeController = TextEditingController();
  final TextEditingController stateDescriptionController =
      TextEditingController();

  final TextEditingController districtNameController = TextEditingController();
  final TextEditingController districtDescriptionController =
      TextEditingController();
  final RxnInt districtFormStateId = RxnInt();

  final TextEditingController cityNameController = TextEditingController();
  final TextEditingController cityPincodeController = TextEditingController();
  final TextEditingController cityDescriptionController =
      TextEditingController();
  final RxnInt cityFormStateId = RxnInt();
  final RxnInt cityFormDistrictId = RxnInt();

  final RxnInt editingStateId = RxnInt();
  final RxnInt editingDistrictId = RxnInt();
  final RxnInt editingCityId = RxnInt();

  final TextEditingController stateSearchController = TextEditingController();
  final TextEditingController districtSearchController =
      TextEditingController();
  final TextEditingController citySearchController = TextEditingController();
  final RxString stateSearchQuery = ''.obs;
  final RxString districtSearchQuery = ''.obs;
  final RxString citySearchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    stateSearchController.addListener(() {
      stateSearchQuery.value = stateSearchController.text.trim().toLowerCase();
    });
    districtSearchController.addListener(() {
      districtSearchQuery.value =
          districtSearchController.text.trim().toLowerCase();
    });
    citySearchController.addListener(() {
      citySearchQuery.value = citySearchController.text.trim().toLowerCase();
    });
    loadStates();
  }

  @override
  void onClose() {
    stateNameController.dispose();
    stateCodeController.dispose();
    stateDescriptionController.dispose();
    districtNameController.dispose();
    districtDescriptionController.dispose();
    cityNameController.dispose();
    cityPincodeController.dispose();
    cityDescriptionController.dispose();
    stateSearchController.dispose();
    districtSearchController.dispose();
    citySearchController.dispose();
    super.onClose();
  }

  void _toastError(String message) {
    final m = message.trim();
    if (m.isEmpty) return;
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(m),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(12),
        ),
      );
  }

  void _toastSuccess(String message) {
    final m = message.trim();
    if (m.isEmpty) return;
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(m),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(12),
        ),
      );
  }

  List<StateModel> get filteredStates {
    final q = stateSearchQuery.value;
    final list = [...states]
      ..sort(
        (a, b) => a.stateName.toLowerCase().compareTo(b.stateName.toLowerCase()),
      );
    if (q.isEmpty) return list;
    return list
        .where(
          (s) =>
              s.stateName.toLowerCase().contains(q) ||
              s.stateCode.toLowerCase().contains(q),
        )
        .toList();
  }

  List<DistrictModel> get filteredDistricts {
    final q = districtSearchQuery.value;
    final stateId = filterDistrictStateId.value;
    var list = [...districts];
    if (stateId != null && stateId > 0) {
      list = list.where((d) => d.stateId == stateId).toList();
    }
    list.sort(
      (a, b) =>
          a.districtName.toLowerCase().compareTo(b.districtName.toLowerCase()),
    );
    if (q.isEmpty) return list;
    return list
        .where(
          (d) =>
              d.districtName.toLowerCase().contains(q) ||
              (d.stateName ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  List<CityModel> get filteredCities {
    final q = citySearchQuery.value;
    final stateId = filterCityStateId.value;
    final districtId = filterCityDistrictId.value;
    var list = [...cities];
    if (stateId != null && stateId > 0) {
      list = list.where((c) => c.stateId == stateId).toList();
    }
    if (districtId != null && districtId > 0) {
      list = list.where((c) => c.districtId == districtId).toList();
    }
    list.sort(
      (a, b) => a.cityName.toLowerCase().compareTo(b.cityName.toLowerCase()),
    );
    if (q.isEmpty) return list;
    return list
        .where(
          (c) =>
              c.cityName.toLowerCase().contains(q) ||
              c.pincode.toLowerCase().contains(q) ||
              c.districtName.toLowerCase().contains(q) ||
              (c.village ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  List<DistrictModel> districtsForState(int? stateId) {
    if (stateId == null || stateId <= 0) return const [];
    final list = districts.where((d) => d.stateId == stateId).toList()
      ..sort(
        (a, b) => a.districtName.toLowerCase().compareTo(
              b.districtName.toLowerCase(),
            ),
      );
    return list;
  }

  String stateLabel(int stateId) {
    final match = states.firstWhereOrNull((s) => s.id == stateId);
    return match?.stateName ?? 'State #$stateId';
  }

  Future<void> loadStates() async {
    if (isLoadingStates.value) return;
    try {
      isLoadingStates.value = true;
      final res = await _repo.getAllStates();
      if (!res.success || res.data == null) {
        _toastError(res.message ?? 'Failed to load states');
        return;
      }
      states.assignAll(res.data!);
      filterDistrictStateId.value ??=
          states.isNotEmpty ? states.first.id : null;
      filterCityStateId.value ??= states.isNotEmpty ? states.first.id : null;
      districtFormStateId.value ??= states.isNotEmpty ? states.first.id : null;
      cityFormStateId.value ??= states.isNotEmpty ? states.first.id : null;

      await Future.wait([
        loadDistrictsForFilter(),
        loadCitiesForFilter(),
      ]);
    } catch (e) {
      _toastError(e.toString());
    } finally {
      isLoadingStates.value = false;
    }
  }

  Future<void> loadDistrictsForFilter() async {
    final stateId = filterDistrictStateId.value;
    if (stateId == null || stateId <= 0) {
      districts.clear();
      return;
    }
    if (isLoadingDistricts.value) return;
    try {
      isLoadingDistricts.value = true;
      final res = await _repo.getDistrictsByStateId(stateId);
      if (!res.success || res.data == null) {
        _toastError(res.message ?? 'Failed to load districts');
        return;
      }
      // Keep other states' districts that may already be loaded for city form.
      final others = districts.where((d) => d.stateId != stateId).toList();
      districts.assignAll([...others, ...res.data!]);
    } catch (e) {
      _toastError(e.toString());
    } finally {
      isLoadingDistricts.value = false;
    }
  }

  Future<void> loadCitiesForFilter() async {
    final stateId = filterCityStateId.value;
    if (stateId == null || stateId <= 0) {
      cities.clear();
      return;
    }
    if (isLoadingCities.value) return;
    try {
      isLoadingCities.value = true;
      // Ensure districts for city filter/form are available.
      final districtRes = await _repo.getDistrictsByStateId(stateId);
      if (districtRes.success && districtRes.data != null) {
        final others = districts.where((d) => d.stateId != stateId).toList();
        districts.assignAll([...others, ...districtRes.data!]);
        final available = districtsForState(stateId);
        // Keep "All districts" (null) unless current filter id is invalid.
        if (filterCityDistrictId.value != null &&
            !available.any((d) => d.id == filterCityDistrictId.value)) {
          filterCityDistrictId.value = null;
        }
        if (cityFormStateId.value == stateId) {
          if (cityFormDistrictId.value == null ||
              !available.any((d) => d.id == cityFormDistrictId.value)) {
            cityFormDistrictId.value =
                available.isNotEmpty ? available.first.id : null;
          }
        }
      }

      final cityRes = await _repo.getCitiesByStateId(stateId);
      if (!cityRes.success || cityRes.data == null) {
        _toastError(cityRes.message ?? 'Failed to load cities');
        return;
      }
      final others = cities.where((c) => c.stateId != stateId).toList();
      cities.assignAll([...others, ...cityRes.data!]);
    } catch (e) {
      _toastError(e.toString());
    } finally {
      isLoadingCities.value = false;
    }
  }

  void setDistrictFilterState(int? stateId) {
    if (stateId == null) return;
    filterDistrictStateId.value = stateId;
    districtFormStateId.value ??= stateId;
    loadDistrictsForFilter();
  }

  void setCityFilterState(int? stateId) {
    if (stateId == null) return;
    filterCityStateId.value = stateId;
    filterCityDistrictId.value = null;
    cityFormStateId.value ??= stateId;
    loadCitiesForFilter();
  }

  void setCityFilterDistrict(int? districtId) {
    filterCityDistrictId.value = districtId;
  }

  void setDistrictFormState(int? stateId) {
    districtFormStateId.value = stateId;
  }

  Future<void> setCityFormState(int? stateId) async {
    cityFormStateId.value = stateId;
    cityFormDistrictId.value = null;
    if (stateId == null || stateId <= 0) return;
    final res = await _repo.getDistrictsByStateId(stateId);
    if (res.success && res.data != null) {
      final others = districts.where((d) => d.stateId != stateId).toList();
      districts.assignAll([...others, ...res.data!]);
      final available = districtsForState(stateId);
      cityFormDistrictId.value =
          available.isNotEmpty ? available.first.id : null;
    }
  }

  void setCityFormDistrict(int? districtId) {
    cityFormDistrictId.value = districtId;
  }

  void startCreateState() {
    editingStateId.value = null;
    stateNameController.clear();
    stateCodeController.clear();
    stateDescriptionController.clear();
  }

  void startEditState(StateModel s) {
    editingStateId.value = s.id;
    stateNameController.text = s.stateName;
    stateCodeController.text = s.stateCode;
    stateDescriptionController.text = s.description ?? '';
  }

  Future<void> saveState() async {
    final name = stateNameController.text.trim();
    final code = stateCodeController.text.trim();
    if (name.isEmpty || code.isEmpty) {
      _toastError('State name and code are required');
      return;
    }
    if (isSaving.value) return;
    try {
      isSaving.value = true;
      final id = editingStateId.value;
      final res = id == null
          ? await _repo.createState(
              stateName: name,
              stateCode: code,
              description: stateDescriptionController.text.trim(),
            )
          : await _repo.updateState(
              id: id,
              stateName: name,
              stateCode: code,
              description: stateDescriptionController.text.trim(),
            );
      if (!res.success) {
        _toastError(res.message ?? 'Failed to save state');
        return;
      }
      _toastSuccess(id == null ? 'State created' : 'State updated');
      startCreateState();
      await loadStates();
    } catch (e) {
      _toastError(e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteState(int id) async {
    final res = await _repo.deleteState(id);
    if (!res.success) {
      _toastError(res.message ?? 'Failed to delete state');
      return;
    }
    _toastSuccess('State deleted');
    if (editingStateId.value == id) startCreateState();
    await loadStates();
  }

  void startCreateDistrict() {
    editingDistrictId.value = null;
    districtNameController.clear();
    districtDescriptionController.clear();
    districtFormStateId.value =
        filterDistrictStateId.value ??
        (states.isNotEmpty ? states.first.id : null);
  }

  void startEditDistrict(DistrictModel d) {
    editingDistrictId.value = d.id;
    districtNameController.text = d.districtName;
    districtDescriptionController.text = d.description ?? '';
    districtFormStateId.value = d.stateId;
  }

  Future<void> saveDistrict() async {
    final name = districtNameController.text.trim();
    final stateId = districtFormStateId.value;
    if (name.isEmpty) {
      _toastError('District name is required');
      return;
    }
    if (stateId == null || stateId <= 0) {
      _toastError('Please select a state');
      return;
    }
    if (isSaving.value) return;
    try {
      isSaving.value = true;
      final id = editingDistrictId.value;
      final res = id == null
          ? await _repo.createDistrict(
              districtName: name,
              stateId: stateId,
              description: districtDescriptionController.text.trim(),
            )
          : await _repo.updateDistrict(
              id: id,
              districtName: name,
              stateId: stateId,
              description: districtDescriptionController.text.trim(),
            );
      if (!res.success) {
        _toastError(res.message ?? 'Failed to save district');
        return;
      }
      _toastSuccess(id == null ? 'District created' : 'District updated');
      filterDistrictStateId.value = stateId;
      startCreateDistrict();
      await loadDistrictsForFilter();
      _setStateHasDistricts(stateId, true);
      if (filterCityStateId.value == stateId) {
        await loadCitiesForFilter();
      }
    } catch (e) {
      _toastError(e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteDistrict(int id) async {
    final existing = districts.firstWhereOrNull((d) => d.id == id);
    final res = await _repo.deleteDistrict(id);
    if (!res.success) {
      _toastError(res.message ?? 'Failed to delete district');
      return;
    }
    _toastSuccess('District deleted');
    if (editingDistrictId.value == id) startCreateDistrict();
    await loadDistrictsForFilter();
    await loadCitiesForFilter();
    if (existing != null) {
      _setStateHasDistricts(
        existing.stateId,
        districts.any((d) => d.stateId == existing.stateId),
      );
    }
  }

  void _setStateHasDistricts(int stateId, bool hasDistricts) {
    final index = states.indexWhere((s) => s.id == stateId);
    if (index < 0 || states[index].hasDistricts == hasDistricts) return;
    final current = states[index];
    states[index] = StateModel(
      id: current.id,
      stateName: current.stateName,
      stateCode: current.stateCode,
      description: current.description,
      hasDistricts: hasDistricts,
    );
  }

  void startCreateCity() {
    editingCityId.value = null;
    cityNameController.clear();
    cityPincodeController.clear();
    cityDescriptionController.clear();
    final stateId = filterCityStateId.value ??
        (states.isNotEmpty ? states.first.id : null);
    cityFormStateId.value = stateId;
    final available = districtsForState(stateId);
    cityFormDistrictId.value = filterCityDistrictId.value ??
        (available.isNotEmpty ? available.first.id : null);
  }

  void startEditCity(CityModel c) {
    showCityImport.value = false;
    editingCityId.value = c.id;
    cityNameController.text = c.cityName;
    cityPincodeController.text = c.pincode;
    cityDescriptionController.text = c.description ?? '';
    cityFormStateId.value = c.stateId;
    cityFormDistrictId.value = c.districtId > 0 ? c.districtId : null;
    setCityFormState(c.stateId).then((_) {
      cityFormDistrictId.value = c.districtId > 0 ? c.districtId : null;
    });
  }

  Future<void> saveCity() async {
    final name = cityNameController.text.trim();
    final stateId = cityFormStateId.value;
    final districtId = cityFormDistrictId.value;
    final pincode = cityPincodeController.text.trim();
    if (name.isEmpty) {
      _toastError('City / town / village name is required');
      return;
    }
    if (stateId == null || stateId <= 0) {
      _toastError('Please select a state');
      return;
    }
    if (districtId == null || districtId <= 0) {
      _toastError('Please select a district');
      return;
    }
    if (pincode.isNotEmpty && !RegExp(r'^\d{6}$').hasMatch(pincode)) {
      _toastError('Pincode must be 6 digits');
      return;
    }
    if (isSaving.value) return;
    final previous = editingCityId.value == null
        ? null
        : cities.firstWhereOrNull((city) => city.id == editingCityId.value);
    try {
      isSaving.value = true;
      final id = editingCityId.value;
      final res = id == null
          ? await _repo.createCity(
              cityName: name,
              districtId: districtId,
              pincode: pincode,
              stateId: stateId,
              description: cityDescriptionController.text.trim(),
            )
          : await _repo.updateCity(
              id: id,
              cityName: name,
              districtId: districtId,
              pincode: pincode,
              stateId: stateId,
              description: cityDescriptionController.text.trim(),
            );
      if (!res.success) {
        _toastError(res.message ?? 'Failed to save city');
        return;
      }
      _toastSuccess(id == null ? 'City created' : 'City updated');
      filterCityStateId.value = stateId;
      filterCityDistrictId.value = districtId;
      startCreateCity();
      await loadCitiesForFilter();
      _setDistrictHasCities(districtId, true);
      if (previous != null &&
          previous.districtId > 0 &&
          previous.districtId != districtId) {
        _setDistrictHasCities(
          previous.districtId,
          cities.any((city) => city.districtId == previous.districtId),
        );
      }
    } catch (e) {
      _toastError(e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteCity(int id) async {
    final existing = cities.firstWhereOrNull((city) => city.id == id);
    final res = await _repo.deleteCity(id);
    if (!res.success) {
      _toastError(res.message ?? 'Failed to delete city');
      return;
    }
    _toastSuccess('City deleted');
    if (editingCityId.value == id) startCreateCity();
    await loadCitiesForFilter();
    if (existing != null && existing.districtId > 0) {
      _setDistrictHasCities(
        existing.districtId,
        cities.any((city) => city.districtId == existing.districtId),
      );
    }
  }

  void _setDistrictHasCities(int districtId, bool hasCities) {
    final index = districts.indexWhere((d) => d.id == districtId);
    if (index < 0 || districts[index].hasCities == hasCities) return;
    final current = districts[index];
    districts[index] = DistrictModel(
      id: current.id,
      districtName: current.districtName,
      stateId: current.stateId,
      stateName: current.stateName,
      description: current.description,
      hasCities: hasCities,
    );
  }

  void downloadLocationImportTemplate() {
    final bytes = utf8.encode('\uFEFF$_locationImportTemplate');
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: blobUrl)
      ..setAttribute('download', 'location_import_template.csv')
      ..click();
    html.Url.revokeObjectUrl(blobUrl);
  }

  Future<LocationImportResult?> importLocationCsv({
    required Uint8List bytes,
    required String filename,
  }) async {
    if (isImporting.value) return null;
    if (bytes.isEmpty) {
      _toastError('The selected CSV file is empty');
      return null;
    }
    if (bytes.length > 5 * 1024 * 1024) {
      _toastError('CSV file must be 5 MB or smaller');
      return null;
    }
    try {
      isImporting.value = true;
      final res = await _repo.importLocations(bytes: bytes, filename: filename);
      if (!res.success || res.data == null) {
        _toastError(res.message ?? 'Failed to import locations');
        return null;
      }
      final result = res.data!;
      final focusStateId = result.focusStateId;
      if (focusStateId != null && focusStateId > 0) {
        filterDistrictStateId.value = focusStateId;
        filterCityStateId.value = focusStateId;
        filterCityDistrictId.value = null;
        districtFormStateId.value = focusStateId;
        cityFormStateId.value = focusStateId;
        cityFormDistrictId.value = null;
      }
      await loadStates();
      if (result.failedRows > 0 &&
          result.citiesCreated == 0 &&
          result.citiesUpdated == 0 &&
          result.citiesReused == 0) {
        _toastError(res.message ?? 'No rows were imported');
      } else {
        _toastSuccess(res.message ?? 'Locations imported');
      }
      return result;
    } catch (e) {
      _toastError(e.toString());
      return null;
    } finally {
      isImporting.value = false;
    }
  }
}

const String _locationImportTemplate = '''state_name,state_code,district_name,city_name,pincode,description
''';
