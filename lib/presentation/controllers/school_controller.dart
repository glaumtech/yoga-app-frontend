import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/school_model.dart';
import '../../data/models/state_model.dart';
import '../../data/models/city_model.dart';
import '../../data/models/api_response.dart';
import '../../data/models/institution_type_model.dart';
import '../../data/models/institution_category_model.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/repositories/school_repository.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/storage_service.dart';
import '../../../core/navigation/root_scaffold_messenger_key.dart';

// Conditional import for web
import 'dart:html' as html show AnchorElement, Blob, Url;

class SchoolController extends GetxController {
  static const String locationGroupRequiredMessage =
      'Please fill at least one of District, City/Town/Village, or Pincode';

  final LocationRepository _locationRepository = LocationRepository();
  final SchoolRepository _schoolRepository = SchoolRepository();

  // Form controllers
  final formKey = GlobalKey<FormState>();
  final institutionNameController = TextEditingController();
  final institutionShortNameController = TextEditingController();
  final addressController = TextEditingController();
  final pincodeController = TextEditingController();
  final emailController = TextEditingController();
  final websiteController = TextEditingController();
  final landLineController = TextEditingController();
  final mobileController = TextEditingController();
  final contributorNameController = TextEditingController();
  final contributorMobileController = TextEditingController();
  final searchController = TextEditingController();

  /// Create form (school create screen): state/city autocomplete controllers.
  final TextEditingController createFormStateTextController =
      TextEditingController();
  final FocusNode createFormStateFocusNode = FocusNode();
  final TextEditingController createFormDistrictTextController =
      TextEditingController();
  final FocusNode createFormDistrictFocusNode = FocusNode();
  final TextEditingController createFormCityTextController =
      TextEditingController();
  final FocusNode createFormCityFocusNode = FocusNode();

  /// List filters (school list screen): separate from create form to avoid clashes.
  final TextEditingController listFilterStateTextController =
      TextEditingController();
  final FocusNode listFilterStateFocusNode = FocusNode();
  final TextEditingController listFilterCityTextController =
      TextEditingController();
  final FocusNode listFilterCityFocusNode = FocusNode();

  // Observable state
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<SchoolModel> schools = <SchoolModel>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isListView = false.obs; // Toggle between create and list view
  final RxBool isEditMode = false.obs; // Edit mode flag
  final RxnString editingSchoolId = RxnString(); // ID of school being edited
  final RxMap<String, dynamic> pagination =
      <String, dynamic>{}.obs; // Pagination info

  // Pagination state
  final RxInt currentPage = 1.obs;
  final RxInt itemsPerPage = 20.obs;
  final RxInt totalItems = 0.obs;
  final RxInt totalPages = 0.obs;

  // Sorting state
  final RxString sortBy =
      'createdAt'.obs; // createdAt, institutionName, stateName, cityName
  final RxString sortOrder = 'desc'.obs; // asc, desc

  // Form fields
  final RxString selectedDistrict = ''.obs;
  final RxString selectedCity =
      ''.obs; // Selected city name (create-new / fallback)
  /// Village/city row id from API list; sent as `cityId` on save/update when set.
  final RxInt createFormSelectedCityId = 0.obs;

  /// Bumped when create-form district draft text changes (GetX does not track [TextEditingController]).
  final RxInt createFormDistrictDraftRevision = 0.obs;
  final RxString selectedState = ''.obs;
  final RxInt selectedStateId = 0.obs; // Store state ID
  final RxString selectedPincode = ''.obs;
  final RxString selectedInstitutionType = ''.obs;

  // Sub-category fields (using category ID and display name)
  final RxInt selectedInstitutionCategoryId = 0.obs;
  final RxString selectedInstitutionCategory = ''.obs;
  final RxSet<int> selectedInstitutionCategoryIds = <int>{}.obs;
  final RxString customCategory = ''.obs;

  // Report generation fields
  final RxString reportDistrict = ''.obs;
  final RxString reportState = ''.obs;
  final RxInt reportInstitutionTypeId = 0.obs;

  // API-loaded data
  final RxList<StateModel> states = <StateModel>[].obs;
  final RxList<CityModel> cities = <CityModel>[].obs;

  /// District names for the current list/create state selection (GET /city/districts/state/{id}).
  final RxList<String> stateDistrictList = <String>[].obs;
  final RxList<CityModel> createFormVillages = <CityModel>[].obs;
  final RxBool isLoadingStates = false.obs;
  final RxBool isLoadingCities = false.obs;
  final RxBool isLoadingStateDistricts = false.obs;
  final RxBool isLoadingCreateFormVillages = false.obs;

  // Institution types and categories from API
  final RxList<InstitutionTypeModel> institutionTypes =
      <InstitutionTypeModel>[].obs;
  final RxList<InstitutionCategoryModel> institutionCategories =
      <InstitutionCategoryModel>[].obs;
  final RxBool isLoadingInstitutionTypes = false.obs;
  final RxBool isLoadingInstitutionCategories = false.obs;

  // Selected institution type ID
  final RxInt selectedInstitutionTypeId = 0.obs;

  // Load institution types from API
  Future<void> loadInstitutionTypes() async {
    try {
      isLoadingInstitutionTypes.value = true;
      final response = await _schoolRepository.getAllInstitutionTypes();
      if (response.success && response.data != null) {
        institutionTypes.value = response.data!;
        // Keep API response order (backend already sorts by displayOrder).
      } else {
        errorMessage.value =
            response.message ?? 'Failed to load institution types';
      }
    } catch (e) {
      errorMessage.value = 'Error loading institution types: ${e.toString()}';
      print('Error loading institution types: $e');
    } finally {
      isLoadingInstitutionTypes.value = false;
    }
  }

  // Load institution categories by type ID
  Future<void> loadInstitutionCategoriesByTypeId(int typeId) async {
    try {
      isLoadingInstitutionCategories.value = true;
      institutionCategories.clear();
      selectedInstitutionCategoryId.value = 0;
      selectedInstitutionCategory.value = '';
      selectedInstitutionCategoryIds.clear();

      final response = await _schoolRepository.getInstitutionCategoriesByType(
        typeId,
      );
      if (response.success && response.data != null) {
        institutionCategories.value = response.data!;
        // Keep API response order (backend already sorts by displayOrder).
      } else {
        errorMessage.value =
            response.message ?? 'Failed to load institution categories';
        institutionCategories.clear();
      }
    } catch (e) {
      errorMessage.value =
          'Error loading institution categories: ${e.toString()}';
      print('Error loading institution categories: $e');
      institutionCategories.clear();
    } finally {
      isLoadingInstitutionCategories.value = false;
    }
  }

  // Map institution type ID to API format (using typeName from model)
  String _mapInstitutionTypeToApi(int typeId, {int? categoryId}) {
    final type = institutionTypes.firstWhereOrNull((t) => t.id == typeId);
    if (type == null) return '';

    String baseType = type.typeName;

    // Append category ID if provided
    if (categoryId != null && categoryId > 0) {
      return '$baseType|$categoryId';
    }

    return baseType;
  }

  bool get hasAnyLocationDetailFilled {
    final district = _committedOrDraftDistrict();
    final city = _committedOrDraftCityName();
    final pincode = pincodeController.text.trim();
    return district.isNotEmpty || city.isNotEmpty || pincode.isNotEmpty;
  }

  String _committedOrDraftDistrict() {
    final committed = selectedDistrict.value.trim();
    if (committed.isNotEmpty) return committed;
    return createFormDistrictTextController.text.trim();
  }

  String _committedOrDraftCityName() {
    final committed = selectedCity.value.trim();
    if (committed.isNotEmpty) return committed;
    return _parseCityNameFromDisplay(createFormCityTextController.text.trim());
  }

  String _parseCityNameFromDisplay(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.contains(',')) {
      return trimmed.split(',').first.trim();
    }
    return trimmed;
  }

  String? validateLocationGroupRequirement() {
    if (selectedStateId.value <= 0) {
      return 'Please select state first';
    }
    if (!hasAnyLocationDetailFilled) {
      return locationGroupRequiredMessage;
    }
    return null;
  }

  String? validatePincodeField(String? value) {
    final groupError = validateLocationGroupRequirement();
    if (groupError != null) return groupError;

    final pin = (value ?? '').trim();
    if (pin.isEmpty) return null;
    if (pin.length != 6) return 'Pincode must be 6 digits';
    if (!RegExp(r'^[0-9]+$').hasMatch(pin)) {
      return 'Pincode must contain only numbers';
    }
    return null;
  }

  List<CityModel> _citiesForSelectedState() {
    final stateId = selectedStateId.value;
    if (stateId <= 0) return [];
    final byId = <int, CityModel>{};
    for (final c in createFormVillages) {
      if (c.stateId == stateId) byId[c.id] = c;
    }
    for (final c in cities) {
      if (c.stateId == stateId) byId[c.id] = c;
    }
    return byId.values.toList();
  }

  Future<void> _ensureLocationCitiesLoaded() async {
    if (selectedStateId.value <= 0) return;

    final district = _committedOrDraftDistrict();
    if (district.isNotEmpty && createFormVillages.isEmpty) {
      if (selectedDistrict.value.trim() != district) {
        selectedDistrict.value = district;
      }
      await loadCreateFormVillagesByDistrict();
    }

    if (cities.isEmpty) {
      await loadCitiesByStateId(selectedStateId.value);
    }
  }

  int? _findExistingCityId({
    required String cityName,
    String? district,
    String? pincode,
  }) {
    final nameNorm = cityName.trim().toLowerCase();
    if (nameNorm.isEmpty || selectedStateId.value <= 0) return null;

    final districtNorm = (district ?? _committedOrDraftDistrict()).trim().toLowerCase();
    final pinNorm = (pincode ?? pincodeController.text.trim()).trim();

    var matches = _citiesForSelectedState().where((c) {
      if (c.cityName.trim().toLowerCase() != nameNorm) return false;
      if (districtNorm.isNotEmpty &&
          c.district.trim().toLowerCase() != districtNorm) {
        return false;
      }
      if (pinNorm.isNotEmpty && c.pincode.trim() != pinNorm) return false;
      return true;
    }).toList();

    if (matches.isEmpty) {
      matches = _citiesForSelectedState()
          .where((c) => c.cityName.trim().toLowerCase() == nameNorm)
          .toList();
    }

    if (matches.isEmpty) return null;
    if (matches.length == 1) return matches.first.id;

    if (pinNorm.isNotEmpty) {
      final pinMatches =
          matches.where((c) => c.pincode.trim() == pinNorm).toList();
      if (pinMatches.length == 1) return pinMatches.first.id;
    }

    return matches.first.id;
  }

  // Get city ID from selected city name (ambiguous if several villages share same cityName)
  int? _getCityIdFromName(String cityName) {
    return _findExistingCityId(cityName: cityName);
  }

  /// Same display as village field in [SchoolCreateScreen] after selection.
  String _createFormVillageDisplay(CityModel c) {
    final v = (c.village ?? c.description ?? '').trim();
    if (v.isEmpty) return c.cityName.trim();
    return '${c.cityName}, $v';
  }

  int? getCityIdForSelectedStateAndDistrict(String cityName) {
    return _getCityIdFromName(cityName);
  }

  Future<int?> _createCityRecord({
    required String cityName,
    required String district,
    required String pincode,
  }) async {
    await _ensureLocationCitiesLoaded();

    final existingId = _findExistingCityId(
      cityName: cityName,
      district: district,
      pincode: pincode,
    );
    if (existingId != null) {
      return existingId;
    }

    final response = await _locationRepository.createCity(
      cityName: cityName,
      district: district,
      pincode: pincode,
      stateId: selectedStateId.value,
      description: null,
    );

    if (!response.success || response.data == null) {
      final message = response.message ?? '';
      if (message.toLowerCase().contains('already exists')) {
        await _ensureLocationCitiesLoaded();
        final reusedId = _findExistingCityId(
          cityName: cityName,
          district: district,
          pincode: pincode,
        );
        if (reusedId != null) return reusedId;
      }
      errorMessage.value = message.isNotEmpty ? message : 'Failed to add city';
      return null;
    }

    final createdCity = response.data!;
    final cityIdx = cities.indexWhere((c) => c.id == createdCity.id);
    if (cityIdx >= 0) {
      cities[cityIdx] = createdCity;
    } else {
      cities.add(createdCity);
    }
    cities.refresh();
    final villageIdx = createFormVillages.indexWhere(
      (c) => c.id == createdCity.id,
    );
    if (villageIdx >= 0) {
      createFormVillages[villageIdx] = createdCity;
    } else {
      createFormVillages.add(createdCity);
    }
    createFormVillages.refresh();

    createFormSelectedCityId.value = createdCity.id;
    if (createdCity.district.trim().isNotEmpty) {
      selectedDistrict.value = createdCity.district;
      createFormDistrictTextController.text = createdCity.district;
    }
    selectedCity.value = createdCity.cityName;
    final createdV = (createdCity.village ?? createdCity.description ?? '')
        .trim();
    createFormCityTextController.text = createdV.isEmpty
        ? createdCity.cityName
        : '${createdCity.cityName}, $createdV';
    if (createdCity.pincode.trim().isNotEmpty) {
      pincodeController.text = createdCity.pincode;
    }

    return createdCity.id;
  }

  Future<int?> resolveOrCreateCityIdForCreateForm() async {
    if (selectedStateId.value <= 0) {
      return null;
    }

    await _ensureLocationCitiesLoaded();

    final explicitId = createFormSelectedCityId.value;
    if (explicitId > 0) {
      final row =
          createFormVillages.firstWhereOrNull((c) => c.id == explicitId) ??
          cities.firstWhereOrNull((c) => c.id == explicitId);
      if (row != null && row.stateId == selectedStateId.value) {
        final dNorm = _committedOrDraftDistrict().toLowerCase();
        final rowD = row.district.trim().toLowerCase();
        if (dNorm.isEmpty || rowD == dNorm) {
          return explicitId;
        }
      }
    }

    final district = _committedOrDraftDistrict();
    final pincode = pincodeController.text.trim();
    final cityName = _committedOrDraftCityName();

    if (!hasAnyLocationDetailFilled) {
      errorMessage.value = locationGroupRequiredMessage;
      return null;
    }

    if (cityName.isEmpty && pincode.isNotEmpty) {
      final matches = _citiesForSelectedState()
          .where((c) => c.pincode.trim() == pincode)
          .toList();
      if (matches.length == 1) return matches.first.id;
      if (matches.length > 1) {
        errorMessage.value =
            'Multiple cities match this pincode. Please select City/Town/Village.';
        return null;
      }
    }

    if (cityName.isEmpty && district.isNotEmpty) {
      final existingDistrictCityId = _findExistingCityId(
        cityName: district,
        district: district,
        pincode: pincode,
      );
      if (existingDistrictCityId != null) return existingDistrictCityId;

      final districtMatches = _citiesForSelectedState()
          .where(
            (c) => c.district.trim().toLowerCase() == district.toLowerCase(),
          )
          .toList();
      if (districtMatches.length == 1) return districtMatches.first.id;
      if (districtMatches.length > 1) {
        if (pincode.isNotEmpty) {
          final pinMatches = districtMatches
              .where((c) => c.pincode.trim() == pincode)
              .toList();
          if (pinMatches.length == 1) return pinMatches.first.id;
        }
        final namedMatches = districtMatches
            .where(
              (c) => c.cityName.trim().toLowerCase() == district.toLowerCase(),
            )
            .toList();
        if (namedMatches.length == 1) return namedMatches.first.id;
        if (namedMatches.isNotEmpty) return namedMatches.first.id;
      }
      return _createCityRecord(
        cityName: district,
        district: district,
        pincode: pincode,
      );
    }

    if (cityName.isEmpty && pincode.isNotEmpty) {
      return _createCityRecord(
        cityName: pincode,
        district: district,
        pincode: pincode,
      );
    }

    if (cityName.isEmpty) {
      errorMessage.value = locationGroupRequiredMessage;
      return null;
    }

    final existingCityId = _getCityIdFromName(cityName);
    if (existingCityId != null) {
      return existingCityId;
    }

    return _createCityRecord(
      cityName: cityName,
      district: district,
      pincode: pincode,
    );
  }

  // Get districts for autocomplete: prefer API list, else derive from loaded cities.
  List<String> getDistrictsForState(String stateName) {
    if (selectedStateId.value == 0) return [];
    if (stateDistrictList.isNotEmpty) {
      return List<String>.from(stateDistrictList);
    }
    final stateCities = cities
        .where((city) => city.stateId == selectedStateId.value)
        .toList();
    final districts = stateCities
        .map((city) => city.district.trim())
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList();
    districts.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return districts;
  }

  // Get cities for selected district
  List<CityModel> getCitiesForDistrict(String district) {
    if (selectedStateId.value == 0 || district.isEmpty) return [];

    return cities
        .where(
          (city) =>
              city.stateId == selectedStateId.value &&
              city.district == district,
        )
        .toList()
      ..sort((a, b) => a.cityName.compareTo(b.cityName));
  }

  // Get pincodes for selected district
  List<String> getPincodesForDistrict(String district) {
    if (selectedStateId.value == 0) return [];

    final districtCities = cities
        .where(
          (city) =>
              city.stateId == selectedStateId.value &&
              city.district == district,
        )
        .toList();
    final pincodes = districtCities
        .map((city) => city.pincode)
        .toSet()
        .toList();
    pincodes.sort();
    return pincodes;
  }

  @override
  void onInit() {
    super.onInit();
    loadSchools();
    loadStates();
    loadInstitutionTypes();
  }

  // Load states from API
  Future<void> loadStates() async {
    try {
      isLoadingStates.value = true;
      final response = await _locationRepository.getAllStates();
      if (response.success && response.data != null) {
        states.value = response.data!;
        // Sort by state name
        states.sort((a, b) => a.stateName.compareTo(b.stateName));
      } else {
        errorMessage.value = response.message ?? 'Failed to load states';
      }
    } catch (e) {
      errorMessage.value = 'Error loading states: ${e.toString()}';
      print('Error loading states: $e');
    } finally {
      isLoadingStates.value = false;
    }
  }

  /// Create form: state autocomplete selection (id 0 = clear).
  Future<void> setCreateFormState(int stateId) async {
    selectedDistrict.value = '';
    selectedCity.value = '';
    createFormSelectedCityId.value = 0;
    pincodeController.clear();
    createFormDistrictTextController.clear();
    createFormCityTextController.clear();
    createFormVillages.clear();

    if (stateId <= 0) {
      selectedState.value = '';
      selectedStateId.value = 0;
      cities.clear();
      stateDistrictList.clear();
      createFormStateTextController.clear();
      return;
    }

    final st = states.firstWhereOrNull((s) => s.id == stateId);
    if (st != null) {
      selectedState.value = st.stateName;
      selectedStateId.value = st.id;
      createFormStateTextController.text = st.stateName;
    }

    cities.clear();
    await loadDistrictsByStateId(stateId);
  }

  void setCreateFormDistrict(String district) {
    final d = district.trim();
    createFormSelectedCityId.value = 0;
    selectedDistrict.value = d;
    createFormDistrictTextController.text = d;
    selectedCity.value = '';
    createFormCityTextController.clear();
    pincodeController.clear();
    createFormVillages.clear();
    if (selectedStateId.value > 0 && d.isNotEmpty) {
      loadCreateFormVillagesByDistrict();
    }
  }

  void setCreateFormCityName(String cityName) {
    createFormCityTextController.text = cityName;
    final c = cityName.trim();
    createFormSelectedCityId.value = 0;

    if (c.isEmpty) {
      selectedCity.value = '';
      return;
    }

    final lower = c.toLowerCase();
    final districtNorm = selectedDistrict.value.trim().toLowerCase();

    for (final row in createFormVillages) {
      if (_createFormVillageDisplay(row).toLowerCase() == lower) {
        createFormSelectedCityId.value = row.id;
        selectedDistrict.value = row.district;
        createFormDistrictTextController.text = row.district;
        selectedCity.value = row.cityName;
        pincodeController.text = row.pincode;
        return;
      }
    }

    final ambiguousMatches = createFormVillages.where((row) {
      if (row.stateId != selectedStateId.value) return false;
      if (districtNorm.isNotEmpty &&
          row.district.trim().toLowerCase() != districtNorm) {
        return false;
      }
      return row.cityName.trim().toLowerCase() == lower;
    }).toList();
    if (ambiguousMatches.length == 1) {
      final row = ambiguousMatches.first;
      createFormSelectedCityId.value = row.id;
      selectedDistrict.value = row.district;
      createFormDistrictTextController.text = row.district;
      pincodeController.text = row.pincode;
      selectedCity.value = row.cityName;
      return;
    }

    final cityId = _getCityIdFromName(c);
    if (cityId != null) {
      createFormSelectedCityId.value = cityId;
      final city = (createFormVillages.isNotEmpty ? createFormVillages : cities)
          .firstWhereOrNull((x) => x.id == cityId);
      if (city != null) {
        selectedDistrict.value = city.district;
        createFormDistrictTextController.text = city.district;
        pincodeController.text = city.pincode;
        selectedCity.value = city.cityName;
        return;
      }
    }

    selectedCity.value = c;
  }

  /// Create form: city autocomplete selection (id 0 = clear).
  void setCreateFormCity(int cityId) {
    if (cityId <= 0) {
      createFormSelectedCityId.value = 0;
      selectedCity.value = '';
      createFormCityTextController.clear();
      pincodeController.clear();
      return;
    }
    final c = (createFormVillages.isNotEmpty ? createFormVillages : cities)
        .firstWhereOrNull((x) => x.id == cityId);
    if (c != null) {
      createFormSelectedCityId.value = c.id;
      selectedDistrict.value = c.district;
      createFormDistrictTextController.text = c.district;
      selectedCity.value = c.cityName;
      final v = (c.village ?? c.description ?? '').trim();
      createFormCityTextController.text = v.isEmpty
          ? c.cityName
          : '${c.cityName}, $v';
      pincodeController.text = c.pincode;
    } else {
      createFormSelectedCityId.value = 0;
    }
  }

  Future<void> loadCreateFormVillagesByDistrict() async {
    final district = _committedOrDraftDistrict();
    if (selectedStateId.value <= 0 || district.isEmpty) {
      createFormVillages.clear();
      return;
    }
    if (selectedDistrict.value.trim() != district) {
      selectedDistrict.value = district;
    }
    try {
      isLoadingCreateFormVillages.value = true;
      final response = await _locationRepository.getVillagesByStateAndDistrict(
        stateId: selectedStateId.value,
        district: district,
      );
      if (response.success && response.data != null) {
        createFormVillages.value = response.data!;
      } else {
        createFormVillages.clear();
      }
    } catch (e) {
      createFormVillages.clear();
      print('Error in loadCreateFormVillagesByDistrict: $e');
    } finally {
      isLoadingCreateFormVillages.value = false;
    }
  }

  /// List filter: state (id 0 = clear); reloads schools.
  Future<void> setListFilterState(int stateId) async {
    reportDistrict.value = '';
    listFilterCityTextController.clear();

    if (stateId <= 0) {
      reportState.value = '';
      selectedStateId.value = 0;
      cities.clear();
      stateDistrictList.clear();
      listFilterStateTextController.clear();
      await loadSchools(resetPage: true);
      return;
    }

    final st = states.firstWhereOrNull((s) => s.id == stateId);
    if (st != null) {
      reportState.value = st.stateName;
      selectedStateId.value = st.id;
      listFilterStateTextController.text = st.stateName;
    }

    cities.clear();
    await loadDistrictsByStateId(stateId);
    await loadSchools(resetPage: true);
  }

  /// List filter: city/district label uses city name for API (id 0 = clear).
  void setListFilterCity(int cityId) {
    if (cityId <= 0) {
      reportDistrict.value = '';
      listFilterCityTextController.clear();
      loadSchools(resetPage: true);
      return;
    }
    final c = cities.firstWhereOrNull((x) => x.id == cityId);
    if (c != null) {
      reportDistrict.value = c.cityName;
      listFilterCityTextController.text = c.cityName;
    }
    loadSchools(resetPage: true);
  }

  /// List filter: district text (empty = clear).
  void setListFilterDistrict(String district) {
    final d = district.trim();
    reportDistrict.value = d;
    listFilterCityTextController.text = d;
    loadSchools(resetPage: true);
  }

  // Load cities by state ID
  Future<void> loadCitiesByStateId(int stateId) async {
    try {
      isLoadingCities.value = true;
      cities.clear(); // Clear previous cities
      final response = await _locationRepository.getCitiesByStateId(stateId);
      if (response.success && response.data != null) {
        cities.value = response.data!;
      } else {
        errorMessage.value = response.message ?? 'Failed to load cities';
        cities.clear();
      }
    } catch (e) {
      errorMessage.value = 'Error loading cities: ${e.toString()}';
      print('Error loading cities: $e');
      cities.clear();
    } finally {
      isLoadingCities.value = false;
    }
  }

  Future<void> loadDistrictsByStateId(int stateId) async {
    if (stateId <= 0) {
      stateDistrictList.clear();
      return;
    }
    isLoadingStateDistricts.value = true;
    try {
      final response = await _locationRepository.getDistrictsByStateId(stateId);
      if (response.success && response.data != null) {
        stateDistrictList.value = response.data!;
      } else {
        stateDistrictList.clear();
      }
    } catch (e) {
      print('Error loading districts: $e');
      stateDistrictList.clear();
    } finally {
      isLoadingStateDistricts.value = false;
    }
  }

  @override
  void onClose() {
    institutionNameController.dispose();
    institutionShortNameController.dispose();
    addressController.dispose();
    pincodeController.dispose();
    emailController.dispose();
    websiteController.dispose();
    landLineController.dispose();
    mobileController.dispose();
    contributorNameController.dispose();
    contributorMobileController.dispose();
    searchController.dispose();
    createFormStateTextController.dispose();
    createFormStateFocusNode.dispose();
    createFormDistrictTextController.dispose();
    createFormDistrictFocusNode.dispose();
    createFormCityTextController.dispose();
    createFormCityFocusNode.dispose();
    listFilterStateTextController.dispose();
    listFilterStateFocusNode.dispose();
    listFilterCityTextController.dispose();
    listFilterCityFocusNode.dispose();
    super.onClose();
  }

  // Load schools with filters
  Future<void> loadSchools({
    String? search,
    int? stateId,
    int? cityId,
    int? institutionTypeId,
    int? page,
    int? limit,
    String? sortByParam,
    String? orderParam,
    bool resetPage = false,
    bool useReportFilters = true,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Reset to page 1 if requested
      if (resetPage) {
        currentPage.value = 1;
      }

      // Use provided parameters or current controller values
      final searchTerm = search ?? searchQuery.value;
      final pageNum =
          page ??
          (currentPage.value > 0
              ? currentPage.value - 1
              : 0); // API uses 0-based
      final limitNum = limit ?? itemsPerPage.value;
      final sortByValue = sortByParam ?? sortBy.value;
      final orderValue = orderParam ?? sortOrder.value;

      // Use report filters if enabled
      int? finalStateId = stateId;
      int? finalCityId = cityId;
      int? finalInstitutionTypeId = institutionTypeId;
      String? finalDistrict;

      if (useReportFilters) {
        // Use report state filter if set
        if (reportState.value.isNotEmpty && finalStateId == null) {
          final selectedState = states.firstWhereOrNull(
            (s) => s.stateName == reportState.value,
          );
          if (selectedState != null) {
            finalStateId = selectedState.id;
          }
        }

        // Use district filter directly (no city-id fallback required)
        if (reportDistrict.value.isNotEmpty) {
          finalDistrict = reportDistrict.value;
        }

        // Use report institution type filter if set
        if (reportInstitutionTypeId.value > 0 &&
            finalInstitutionTypeId == null) {
          finalInstitutionTypeId = reportInstitutionTypeId.value;
        }
      }

      final response = await _schoolRepository.getInstitutionsList(
        search: searchTerm.isNotEmpty ? searchTerm : null,
        stateId: finalStateId,
        cityId: finalCityId,
        district: finalDistrict,
        institutionTypeId: finalInstitutionTypeId,
        page: pageNum,
        limit: limitNum,
        sortBy: sortByValue,
        order: orderValue,
      );

      if (response.success && response.data != null) {
        schools.value = response.data!.institutions;

        // Update pagination info
        if (response.data!.pagination != null) {
          pagination.value = response.data!.pagination!;
          final paginationData = response.data!.pagination!;
          currentPage.value =
              (paginationData['page'] as int? ?? 0) + 1; // Convert to 1-based
          totalItems.value = paginationData['total'] as int? ?? 0;
          totalPages.value = paginationData['totalPages'] as int? ?? 0;
          itemsPerPage.value = paginationData['limit'] as int? ?? 20;
        } else {
          // Fallback: estimate pagination if not provided
          if (schools.isNotEmpty) {
            if (schools.length < itemsPerPage.value) {
              totalPages.value = currentPage.value;
            } else {
              totalPages.value = currentPage.value + 1;
            }
            totalItems.value = schools.length;
          } else {
            totalPages.value = 0;
            totalItems.value = 0;
          }
        }

        // If no results and not on first page, go back to page 1
        if (schools.isEmpty && currentPage.value > 1) {
          currentPage.value = 1;
          return loadSchools();
        }
      } else {
        errorMessage.value = response.message ?? 'Failed to load schools';
        schools.value = [];
        totalPages.value = 0;
        totalItems.value = 0;
      }
    } catch (e) {
      errorMessage.value = 'Error loading schools: ${e.toString()}';
      print('Error in loadSchools: $e');
      schools.value = [];
      totalPages.value = 0;
      totalItems.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  // Pagination methods
  void nextPage() {
    if (currentPage.value < totalPages.value) {
      currentPage.value++;
      loadSchools();
    }
  }

  void previousPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
      loadSchools();
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages.value) {
      currentPage.value = page;
      loadSchools();
    }
  }

  // Sorting methods
  void setSorting(String newSortBy, String newOrder) {
    sortBy.value = newSortBy;
    sortOrder.value = newOrder;
    loadSchools(resetPage: true);
  }

  // Toggle view mode
  void toggleViewMode(bool isList) {
    isListView.value = isList;
    if (isList) {
      // Exit edit mode when switching to list
      resetForm();
      // Keep list mode active (resetForm sets isEditMode/isListView)
      isListView.value = true;
    } else {
      // When switching back to create, always start fresh
      resetForm();
    }
  }

  // Submit school form
  Future<void> submitSchool() async {
    if (!formKey.currentState!.validate()) {
      // Important: The institution dialog closes based on `errorMessage`.
      // If validation fails and we don't set an error, the dialog thinks it's
      // a success and auto-closes.
      errorMessage.value = 'Please fill all required fields';
      return;
    }

    if (selectedInstitutionTypeId.value == 0) {
      errorMessage.value = 'Please select institution type';
      return;
    }

    // If categories exist for this type, validate category selection
    if (institutionCategories.isNotEmpty) {
      final selectedType = institutionTypes.firstWhereOrNull(
        (t) => t.id == selectedInstitutionTypeId.value,
      );
      final isYogaCenter =
          (selectedType?.typeName.toUpperCase() == 'YOGA_CENTER');

      if (isYogaCenter) {
        if (selectedInstitutionCategoryIds.isEmpty) {
          errorMessage.value = 'Please select at least one category';
          return;
        }
      } else {
        if (selectedInstitutionCategoryId.value == 0 &&
            selectedInstitutionCategory.value.isEmpty) {
          errorMessage.value = 'Please select or add a category';
          return;
        }
      }
    }

    if (selectedStateId.value == 0) {
      errorMessage.value = 'Please select state';
      return;
    }

    if (!hasAnyLocationDetailFilled) {
      errorMessage.value = locationGroupRequiredMessage;
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final cityId = await resolveOrCreateCityIdForCreateForm();
      if (cityId == null) {
        errorMessage.value = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Invalid city';
        return;
      }

      final institutionName = institutionNameController.text.trim();
      final institutionShortName = institutionShortNameController.text.trim();
      final address = addressController.text.trim();
      final pincode = pincodeController.text.trim();
      final emailId = emailController.text.trim();
      final website = websiteController.text.trim();
      final landLine = landLineController.text.trim();
      final mobile = mobileController.text.trim();
      final contributorName = contributorNameController.text.trim();
      final contributorMobileNo = contributorMobileController.text.trim();

      final categoryIds = selectedInstitutionCategoryIds.isNotEmpty
          ? selectedInstitutionCategoryIds.toList()
          : null;

      print('Submitting institution:');
      print('  Name: $institutionName');
      print('  Short Name: $institutionShortName');
      print('  Address: $address');
      print('  Email ID: $emailId');
      print('  Website: $website');
      print('  Land line: $landLine');
      print('  Mobile: $mobile');
      print('  Contributor Name: $contributorName');
      print('  Contributor Mobile No: $contributorMobileNo');
      print('  State ID: ${selectedStateId.value}');
      print('  City ID: $cityId');
      print('  Pincode: $pincode');
      print('  Institution Type ID: ${selectedInstitutionTypeId.value}');
      print('  Institution Category IDs: ${categoryIds ?? 'null'}');

      ApiResponse<SchoolModel> response;

      if (isEditMode.value &&
          editingSchoolId.value != null &&
          editingSchoolId.value!.isNotEmpty) {
        // Update existing institution
        response = await _schoolRepository.updateInstitution(
          id: editingSchoolId.value ?? '',
          institutionName: institutionName,
          institutionShortName: institutionShortName.isNotEmpty
              ? institutionShortName
              : null,
          address: address,
          emailId: emailId.isNotEmpty ? emailId : null,
          stateId: selectedStateId.value,
          cityId: cityId,
          institutionTypeId: selectedInstitutionTypeId.value,
          institutionCategoryIds: categoryIds,
          pincode: pincode,
          website: website,
          landLine: landLine,
          mobile: mobile,
          contributorName: contributorName,
          contributorMobileNo: contributorMobileNo,
        );
      } else {
        // Create new institution
        response = await _schoolRepository.createInstitution(
          institutionName: institutionName,
          institutionShortName: institutionShortName.isNotEmpty
              ? institutionShortName
              : null,
          address: address,
          emailId: emailId.isNotEmpty ? emailId : null,
          stateId: selectedStateId.value,
          cityId: cityId,
          institutionTypeId: selectedInstitutionTypeId.value,
          institutionCategoryIds: categoryIds,
          pincode: pincode,
          website: website.isNotEmpty ? website : null,
          landLine: landLine.isNotEmpty ? landLine : null,
          mobile: mobile.isNotEmpty ? mobile : null,
          contributorName: contributorName.isNotEmpty ? contributorName : null,
          contributorMobileNo: contributorMobileNo.isNotEmpty
              ? contributorMobileNo
              : null,
        );
      }

      if (response.success && response.data != null) {
        final wasEditMode = isEditMode.value;

        // Reset form and exit edit mode
        resetForm();
        isEditMode.value = false;
        editingSchoolId.value = null;

        Get.snackbar(
          'Success',
          wasEditMode
              ? 'School/College updated successfully'
              : 'School/College added successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Reload schools list
        await loadSchools();

        // After update, navigate back to list screen for better UX.
        if (wasEditMode) {
          toggleViewMode(true);
        }
      } else {
        errorMessage.value =
            response.message ??
            (isEditMode.value
                ? 'Failed to update institution'
                : 'Failed to create institution');
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      errorMessage.value = 'Error submitting school: ${e.toString()}';
      print('Error in submitSchool: $e');
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Load school for editing
  Future<void> loadSchoolForEdit(String id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Ensure states are loaded first
      if (states.isEmpty) {
        await loadStates();
      }

      // Ensure institution types are loaded first
      if (institutionTypes.isEmpty) {
        await loadInstitutionTypes();
      }

      final response = await _schoolRepository.getInstitutionById(id);

      if (response.success && response.data != null) {
        final school = response.data!;

        print('Loading school for edit: ${school.institutionName}');
        print('State ID: ${school.stateId}, State Name: ${school.stateName}');
        print('City ID: ${school.cityId}, City Name: ${school.cityName}');
        print(
          'Institution Type Display Name: ${school.institutionTypeDisplayName}',
        );
        print('Institution Type: ${school.institutionType}');

        // Set edit mode first
        isEditMode.value = true;
        editingSchoolId.value = id;

        // Switch to create view (not list view) first
        isListView.value = false;

        // Wait for view to switch
        await Future.delayed(const Duration(milliseconds: 200));

        // Populate form fields - always populate these
        institutionNameController.text = school.institutionName;
        institutionShortNameController.text = school.institutionShortName ?? '';
        addressController.text = school.address;
        pincodeController.text = school.pincode;
        emailController.text = school.email ?? '';
        websiteController.text = school.website ?? '';
        landLineController.text = school.landLine ?? '';
        mobileController.text = school.mobile ?? '';
        contributorNameController.text = school.contributorName ?? '';
        contributorMobileController.text = school.contributorMobileNo ?? '';

        // Find and set institution type ID - prefer displayName from API if available
        InstitutionTypeModel? type;
        if (school.institutionTypeDisplayName != null &&
            school.institutionTypeDisplayName!.isNotEmpty) {
          // Use displayName from API response
          type = institutionTypes.firstWhereOrNull(
            (t) => t.displayName == school.institutionTypeDisplayName,
          );
          print(
            'Matching by displayName: ${school.institutionTypeDisplayName}',
          );
        }

        // Fallback: Map API institution type to UI format
        if (type == null) {
          final uiType = _mapInstitutionTypeFromApi(school.institutionType);
          selectedInstitutionType.value = uiType;
          type = institutionTypes.firstWhereOrNull(
            (t) =>
                t.displayName == uiType ||
                t.typeName == school.institutionType.split('|')[0],
          );
          print('Matching by mapped type: $uiType');
        }

        if (type != null) {
          selectedInstitutionTypeId.value = type.id;
          selectedInstitutionType.value = type.displayName;
          print('Institution type set: ${type.displayName} (ID: ${type.id})');
          // Load categories for this type
          await loadInstitutionCategoriesByTypeId(type.id);

          // Wait for categories to load
          await Future.delayed(const Duration(milliseconds: 300));

          // Pre-populate categories from IDs (backend now returns institutionCategoryIds)
          if (school.institutionCategoryIds.isNotEmpty) {
            selectedInstitutionCategoryIds
              ..clear()
              ..addAll(school.institutionCategoryIds);

            final names = institutionCategories
                .where((c) => selectedInstitutionCategoryIds.contains(c.id))
                .map((c) => c.displayName)
                .toList();
            selectedInstitutionCategory.value = names.join(', ');

            // For single-select UI types, pick the first category ID
            selectedInstitutionCategoryId.value =
                selectedInstitutionCategoryIds.isNotEmpty
                ? selectedInstitutionCategoryIds.first
                : 0;
          }
        } else {
          print(
            'Warning: Institution type not found. Available types: ${institutionTypes.map((t) => t.displayName).toList()}',
          );
        }

        print(
          'Basic fields populated - Name: ${school.institutionName}, Address: ${school.address}',
        );

        // Load location: district list by state only (no full /city/state/{id} on state change).
        // Villages for the form load via /city/villages/... after district is known.
        CityModel? resolvedCityForDisplay;
        if (school.stateId != null && school.stateId! > 0) {
          print('State ID found: ${school.stateId}');
          selectedStateId.value = school.stateId!;

          // Find and set state name from states list
          if (school.stateName != null) {
            selectedState.value = school.stateName!;
          } else {
            final state = states.firstWhereOrNull(
              (s) => s.id == school.stateId,
            );
            if (state != null) {
              selectedState.value = state.stateName;
            }
          }

          cities.clear();
          await loadDistrictsByStateId(school.stateId!);

          var districtStr = (school.district ?? '').trim();

          if (districtStr.isEmpty &&
              school.cityId != null &&
              school.stateId != null) {
            await loadCitiesByStateId(school.stateId!);
            final inferred =
                cities.firstWhereOrNull((c) => c.id == school.cityId) ??
                cities.firstWhereOrNull((c) => c.cityName == school.cityName);
            districtStr = (inferred?.district ?? '').trim();
            cities.clear();
          }

          if (districtStr.isNotEmpty) {
            selectedDistrict.value = districtStr;
            createFormDistrictTextController.text = districtStr;
            await loadCreateFormVillagesByDistrict();
          }

          if (school.cityId != null && school.cityName != null) {
            CityModel? matchingCity =
                createFormVillages.firstWhereOrNull(
                  (c) => c.id == school.cityId,
                ) ??
                createFormVillages.firstWhereOrNull(
                  (c) => c.cityName == school.cityName,
                );

            if (matchingCity != null) {
              var d = matchingCity.district.trim();
              if (d.isEmpty &&
                  school.district != null &&
                  school.district!.trim().isNotEmpty) {
                d = school.district!.trim();
              }
              final previousDistrict = selectedDistrict.value.trim();
              if (d.isNotEmpty) {
                selectedDistrict.value = d;
                createFormDistrictTextController.text = d;
              }
              selectedCity.value = matchingCity.cityName;
              if (d.isNotEmpty && d != previousDistrict) {
                await loadCreateFormVillagesByDistrict();
              }
              resolvedCityForDisplay = matchingCity;
              print(
                'City set to: ${selectedCity.value} (ID: ${matchingCity.id})',
              );
            } else {
              await loadCitiesByStateId(school.stateId!);
              final fromAll =
                  cities.firstWhereOrNull((c) => c.id == school.cityId) ??
                  cities.firstWhereOrNull((c) => c.cityName == school.cityName);
              cities.clear();
              if (fromAll != null) {
                var d = fromAll.district.trim();
                if (d.isEmpty &&
                    school.district != null &&
                    school.district!.trim().isNotEmpty) {
                  d = school.district!.trim();
                }
                selectedDistrict.value = d;
                selectedCity.value = fromAll.cityName;
                createFormDistrictTextController.text = d;
                await loadCreateFormVillagesByDistrict();
                resolvedCityForDisplay =
                    createFormVillages.firstWhereOrNull(
                      (c) => c.id == fromAll.id,
                    ) ??
                    fromAll;
                print('City set after full city lookup: ${selectedCity.value}');
              } else {
                print(
                  'City not found. Expected: ${school.cityName} (ID: ${school.cityId})',
                );
              }
            }
          }

          if (selectedDistrict.value.trim().isEmpty &&
              school.district != null &&
              school.district!.trim().isNotEmpty) {
            selectedDistrict.value = school.district!.trim();
            createFormDistrictTextController.text = school.district!.trim();
            await loadCreateFormVillagesByDistrict();
          }
        } else {
          print('Warning: State ID is null or 0. Cannot load state/city data.');
          print(
            'School data - stateId: ${school.stateId}, cityId: ${school.cityId}',
          );
          print(
            'School data - stateName: ${school.stateName}, cityName: ${school.cityName}',
          );
        }

        createFormStateTextController.text = selectedState.value;
        createFormDistrictTextController.text = selectedDistrict.value;
        final cmForVillageDisplay =
            resolvedCityForDisplay ??
            createFormVillages.firstWhereOrNull((c) => c.id == school.cityId) ??
            createFormVillages.firstWhereOrNull(
              (c) => c.cityName == school.cityName,
            );
        if (cmForVillageDisplay != null) {
          final v =
              (cmForVillageDisplay.village ??
                      cmForVillageDisplay.description ??
                      '')
                  .trim();
          createFormCityTextController.text = v.isEmpty
              ? cmForVillageDisplay.cityName
              : '${cmForVillageDisplay.cityName}, $v';
        } else {
          createFormCityTextController.text = selectedCity.value;
        }

        if (school.cityId != null && school.cityId! > 0) {
          createFormSelectedCityId.value = school.cityId!;
        } else {
          createFormSelectedCityId.value = cmForVillageDisplay?.id ?? 0;
        }

        print(
          'Form populated - State: ${selectedState.value}, City: ${selectedCity.value}',
        );
        print(
          'Form fields - Name: ${institutionNameController.text}, Address: ${addressController.text}, Pincode: ${pincodeController.text}',
        );
      } else {
        errorMessage.value = response.message ?? 'Failed to load institution';
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      errorMessage.value = 'Error loading institution: ${e.toString()}';
      print('Error in loadSchoolForEdit: $e');
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Delete school
  Future<void> deleteSchool(String id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _schoolRepository.deleteInstitution(id);

      if (response.success) {
        rootScaffoldMessengerKey.currentState
          ?..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: const Text('School/College deleted successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              margin: const EdgeInsets.all(12),
            ),
          );

        // Reload schools list
        await loadSchools();
      } else {
        errorMessage.value = response.message ?? 'Failed to delete institution';
        rootScaffoldMessengerKey.currentState
          ?..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(errorMessage.value),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              margin: const EdgeInsets.all(12),
            ),
          );
      }
    } catch (e) {
      errorMessage.value = 'Error deleting institution: ${e.toString()}';
      print('Error in deleteSchool: $e');
      rootScaffoldMessengerKey.currentState
        ?..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(errorMessage.value),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(12),
          ),
        );
    } finally {
      isLoading.value = false;
    }
  }

  // Map API institution type from API format to UI format
  String _mapInstitutionTypeFromApi(String apiType) {
    // Handle sub-categories (format: BASE_TYPE|SUBCATEGORY)
    final parts = apiType.split('|');
    final baseType = parts[0].toUpperCase();

    String uiType;
    switch (baseType) {
      case 'PRIVATE_SCHOOL':
        uiType = 'Private School';
        // Extract category ID if present
        if (parts.length > 1) {
          final categoryId = int.tryParse(parts[1]);
          if (categoryId != null) {
            selectedInstitutionCategoryId.value = categoryId;
            // Load categories to get display name
            final type = institutionTypes.firstWhereOrNull(
              (t) => t.typeName == 'PRIVATE_SCHOOL',
            );
            if (type != null) {
              loadInstitutionCategoriesByTypeId(type.id).then((_) {
                final category = institutionCategories.firstWhereOrNull(
                  (c) => c.id == categoryId,
                );
                if (category != null) {
                  selectedInstitutionCategory.value = category.displayName;
                }
              });
            }
          }
        }
        break;
      case 'GOVT_AIDED_SCHOOL':
      case 'GOVT_SCHOOL':
        uiType = 'Govt / Govt Aided School';
        // Extract category ID if present
        if (parts.length > 1) {
          final categoryId = int.tryParse(parts[1]);
          if (categoryId != null) {
            selectedInstitutionCategoryId.value = categoryId;
            // Load categories to get display name
            final type = institutionTypes.firstWhereOrNull(
              (t) =>
                  t.typeName == 'GOVT_AIDED_SCHOOL' ||
                  t.typeName == 'GOVT_SCHOOL',
            );
            if (type != null) {
              loadInstitutionCategoriesByTypeId(type.id).then((_) {
                final category = institutionCategories.firstWhereOrNull(
                  (c) => c.id == categoryId,
                );
                if (category != null) {
                  selectedInstitutionCategory.value = category.displayName;
                }
              });
            }
          }
        }
        break;
      case 'PRIVATE_COLLEGE':
        uiType = 'Private College';
        break;
      case 'GOVT_AIDED_COLLEGE':
      case 'GOVT_COLLEGE':
        uiType = 'Govt / Govt Aided College';
        break;
      case 'YOGA_CENTER':
        uiType = 'Yoga Center';
        break;
      default:
        // If already in UI format, return as is
        if (institutionTypes.contains(apiType)) {
          return apiType;
        }
        return apiType;
    }

    return uiType;
  }

  // Reset form
  void resetForm() {
    formKey.currentState?.reset();
    selectedDistrict.value = '';
    selectedCity.value = '';
    createFormSelectedCityId.value = 0;
    selectedState.value = '';
    selectedStateId.value = 0;
    selectedPincode.value = '';
    selectedInstitutionType.value = '';
    selectedInstitutionTypeId.value = 0;
    selectedInstitutionCategory.value = '';
    selectedInstitutionCategoryId.value = 0;
    selectedInstitutionCategoryIds.clear();
    customCategory.value = '';
    institutionCategories.clear();
    institutionNameController.clear();
    institutionShortNameController.clear();
    addressController.clear();
    pincodeController.clear();
    emailController.clear();
    websiteController.clear();
    landLineController.clear();
    mobileController.clear();
    contributorNameController.clear();
    contributorMobileController.clear();
    cities.clear();
    createFormVillages.clear();
    createFormStateTextController.clear();
    createFormDistrictTextController.clear();
    createFormDistrictDraftRevision.value = 0;
    createFormCityTextController.clear();
    errorMessage.value = '';
    isEditMode.value = false;
    editingSchoolId.value = null;
  }

  // Get filtered schools based on search query
  List<SchoolModel> getFilteredSchools() {
    if (searchQuery.value.isEmpty) {
      return schools;
    }
    final query = searchQuery.value.toLowerCase();
    return schools.where((school) {
      return school.institutionName.toLowerCase().contains(query) ||
          school.address.toLowerCase().contains(query) ||
          (school.district?.toLowerCase().contains(query) ?? false) ||
          (school.cityName?.toLowerCase().contains(query) ?? false) ||
          (school.village?.toLowerCase().contains(query) ?? false) ||
          (school.state?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  // Create and add institution category via API
  Future<bool> createInstitutionCategory(String categoryName) async {
    if (categoryName.trim().isEmpty || selectedInstitutionTypeId.value == 0) {
      return false;
    }

    try {
      isLoadingInstitutionCategories.value = true;
      errorMessage.value = '';

      // Use categoryName as displayName if not provided separately
      final displayName = categoryName.trim();
      final categoryNameFormatted = categoryName
          .trim()
          .toUpperCase()
          .replaceAll(' ', '_');

      final response = await _schoolRepository.createInstitutionCategory(
        categoryName: categoryNameFormatted,
        displayName: displayName,
        institutionTypeId: selectedInstitutionTypeId.value,
      );

      if (response.success && response.data != null) {
        // Reload categories to include the new one
        await loadInstitutionCategoriesByTypeId(
          selectedInstitutionTypeId.value,
        );

        // Select the newly created category
        selectedInstitutionCategoryId.value = response.data!.id;
        selectedInstitutionCategory.value = response.data!.displayName;

        Get.snackbar(
          'Success',
          'Category "$displayName" created successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to create category';
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error creating category: ${e.toString()}';
      print('Error in createInstitutionCategory: $e');
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoadingInstitutionCategories.value = false;
    }
  }

  // Generate report and print
  Future<void> generateReport(String reportType) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      Get.snackbar(
        'Generating',
        'Preparing report...',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );

      // Get filter values
      int? stateIdForPrint;
      int? cityIdForPrint;

      if (reportState.value.isNotEmpty) {
        final state = states.firstWhereOrNull(
          (s) => s.stateName == reportState.value,
        );
        stateIdForPrint = state?.id;
      }

      if (reportDistrict.value.isNotEmpty && stateIdForPrint != null) {
        final city = cities.firstWhereOrNull(
          (c) =>
              c.cityName == reportDistrict.value &&
              c.stateId == stateIdForPrint,
        );
        cityIdForPrint = city?.id;
      }

      // Prepare request body
      final requestBody = <String, dynamic>{};
      if (searchQuery.value.isNotEmpty) {
        requestBody['search'] = searchQuery.value;
      }
      if (stateIdForPrint != null) {
        requestBody['stateId'] = stateIdForPrint;
      }
      if (cityIdForPrint != null) {
        requestBody['cityId'] = cityIdForPrint;
      }
      if (reportInstitutionTypeId.value > 0) {
        requestBody['institutionTypeId'] = reportInstitutionTypeId.value;
      }
      requestBody['sortBy'] = sortBy.value;
      requestBody['order'] = sortOrder.value;

      // Download PDF from backend
      await _downloadInstitutionsPdf(requestBody);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error generating report: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Download institutions PDF report
  Future<void> _downloadInstitutionsPdf(
    Map<String, dynamic> requestBody,
  ) async {
    try {
      final url = '${BaseUrl.baseUrl}${EndPoints.institutionPrint}';
      final uri = Uri.parse(url);

      // Include auth token if available
      final token = StorageService.getString(AppConstants.tokenKey);
      final headers = <String, String>{
        'Accept': 'application/pdf',
        'Content-Type': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Use proper JSON encoding
      final jsonBody = jsonEncode(requestBody);
      final response = await http.post(uri, headers: headers, body: jsonBody);

      if (response.statusCode == 200) {
        if (kIsWeb) {
          // Web: Create blob and trigger download/print
          final blob = html.Blob([response.bodyBytes]);
          final blobUrl = html.Url.createObjectUrlFromBlob(blob);
          html.AnchorElement(href: blobUrl)
            ..setAttribute('download', 'institutions_report.pdf')
            ..click();
          html.Url.revokeObjectUrl(blobUrl);

          Get.snackbar(
            'Success',
            'Report download started',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          // Mobile: Open PDF
          final dataUri = Uri.dataFromBytes(
            response.bodyBytes,
            mimeType: 'application/pdf',
          );
          if (await canLaunchUrl(dataUri)) {
            await launchUrl(dataUri, mode: LaunchMode.externalApplication);
            Get.snackbar(
              'Success',
              'Report opened',
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
          } else {
            Get.snackbar(
              'Error',
              'Could not open report',
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        }
      } else {
        Get.snackbar(
          'Error',
          'Failed to generate report (status ${response.statusCode})',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to download report: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
