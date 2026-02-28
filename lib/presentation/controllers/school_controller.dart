import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/school_model.dart';
import '../../data/models/state_model.dart';
import '../../data/models/city_model.dart';
import '../../data/models/api_response.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/repositories/school_repository.dart';

class SchoolController extends GetxController {
  final LocationRepository _locationRepository = LocationRepository();
  final SchoolRepository _schoolRepository = SchoolRepository();

  // Form controllers
  final formKey = GlobalKey<FormState>();
  final institutionNameController = TextEditingController();
  final addressController = TextEditingController();
  final pincodeController = TextEditingController();

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
  final RxString selectedCity = ''.obs; // Selected city name
  final RxString selectedState = ''.obs;
  final RxInt selectedStateId = 0.obs; // Store state ID
  final RxString selectedPincode = ''.obs;
  final RxString selectedInstitutionType = ''.obs;

  // Report generation fields
  final RxString reportDistrict = ''.obs;
  final RxString reportState = ''.obs;

  // API-loaded data
  final RxList<StateModel> states = <StateModel>[].obs;
  final RxList<CityModel> cities = <CityModel>[].obs;
  final RxBool isLoadingStates = false.obs;
  final RxBool isLoadingCities = false.obs;

  static const List<String> institutionTypes = [
    'Private School',
    'Govt / Govt Aided School',
    'Private College',
    'Govt / Govt Aided College',
  ];

  // Map UI institution type to API format
  String _mapInstitutionTypeToApi(String uiType) {
    switch (uiType) {
      case 'Private School':
        return 'PRIVATE_SCHOOL';
      case 'Govt / Govt Aided School':
        return 'GOVT_AIDED_SCHOOL';
      case 'Private College':
        return 'PRIVATE_COLLEGE';
      case 'Govt / Govt Aided College':
        return 'GOVT_AIDED_COLLEGE';
      default:
        return uiType.toUpperCase().replaceAll(' ', '_').replaceAll('/', '_');
    }
  }

  // Get city ID from selected city name
  int? _getCityIdFromName(String cityName) {
    if (cityName.isEmpty || selectedStateId.value == 0) {
      return null;
    }
    final city = cities.firstWhereOrNull(
      (c) => c.cityName == cityName && c.stateId == selectedStateId.value,
    );
    return city?.id;
  }

  // Get districts (unique) from cities for selected state
  List<String> getDistrictsForState(String stateName) {
    if (selectedStateId.value == 0) return [];

    final stateCities = cities
        .where((city) => city.stateId == selectedStateId.value)
        .toList();
    final districts = stateCities.map((city) => city.district).toSet().toList();
    districts.sort();
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

  @override
  void onClose() {
    institutionNameController.dispose();
    addressController.dispose();
    pincodeController.dispose();
    super.onClose();
  }

  // Load schools with filters
  Future<void> loadSchools({
    String? search,
    int? stateId,
    int? cityId,
    String? institutionType,
    int? page,
    int? limit,
    String? sortByParam,
    String? orderParam,
    bool resetPage = false,
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

      // Map UI institution type to API format if needed
      String? apiInstitutionType;
      if (institutionType != null && institutionType.isNotEmpty) {
        apiInstitutionType = _mapInstitutionTypeToApi(institutionType);
      }

      final response = await _schoolRepository.getInstitutionsList(
        search: searchTerm.isNotEmpty ? searchTerm : null,
        stateId: stateId,
        cityId: cityId,
        institutionType: apiInstitutionType,
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
      isEditMode.value = false;
      editingSchoolId.value = null;
    }
  }

  // Submit school form
  Future<void> submitSchool() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (selectedInstitutionType.value.isEmpty) {
      errorMessage.value = 'Please select institution type';
      return;
    }

    if (selectedStateId.value == 0) {
      errorMessage.value = 'Please select state';
      return;
    }

    if (selectedCity.value.isEmpty) {
      errorMessage.value = 'Please select city';
      return;
    }

    final cityId = _getCityIdFromName(selectedCity.value);
    if (cityId == null) {
      errorMessage.value = 'Invalid city selection';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final institutionName = institutionNameController.text.trim();
      final address = addressController.text.trim();
      final pincode = pincodeController.text.trim();
      final apiInstitutionType = _mapInstitutionTypeToApi(
        selectedInstitutionType.value,
      );

      print('Submitting institution:');
      print('  Name: $institutionName');
      print('  Address: $address');
      print('  State ID: ${selectedStateId.value}');
      print('  City ID: $cityId');
      print('  Pincode: $pincode');
      print('  Institution Type: $apiInstitutionType');

      ApiResponse<SchoolModel> response;

      if (isEditMode.value &&
          editingSchoolId.value != null &&
          editingSchoolId.value!.isNotEmpty) {
        // Update existing institution
        response = await _schoolRepository.updateInstitution(
          id: editingSchoolId.value ?? '',
          institutionName: institutionName,
          address: address,
          stateId: selectedStateId.value,
          cityId: cityId,
          institutionType: apiInstitutionType,
          pincode: pincode,
        );
      } else {
        // Create new institution
        response = await _schoolRepository.createInstitution(
          institutionName: institutionName,
          address: address,
          stateId: selectedStateId.value,
          cityId: cityId,
          institutionType: apiInstitutionType,
          pincode: pincode,
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

      final response = await _schoolRepository.getInstitutionById(id);

      if (response.success && response.data != null) {
        final school = response.data!;

        print('Loading school for edit: ${school.institutionName}');
        print('State ID: ${school.stateId}, State Name: ${school.stateName}');
        print('City ID: ${school.cityId}, City Name: ${school.cityName}');

        // Set edit mode first
        isEditMode.value = true;
        editingSchoolId.value = id;

        // Switch to create view (not list view) first
        isListView.value = false;

        // Wait for view to switch
        await Future.delayed(const Duration(milliseconds: 200));

        // Populate form fields - always populate these
        institutionNameController.text = school.institutionName;
        addressController.text = school.address;
        pincodeController.text = school.pincode;

        // Map API institution type to UI format
        selectedInstitutionType.value = _mapInstitutionTypeFromApi(
          school.institutionType,
        );

        print(
          'Basic fields populated - Name: ${school.institutionName}, Address: ${school.address}',
        );

        // Load state and city if available
        if (school.stateId != null && school.stateId! > 0) {
          print('State ID found: ${school.stateId}');
          selectedStateId.value = school.stateId!;

          // Find and set state name from states list
          if (school.stateName != null) {
            selectedState.value = school.stateName!;
          } else {
            // Try to find state name from states list
            final state = states.firstWhereOrNull(
              (s) => s.id == school.stateId,
            );
            if (state != null) {
              selectedState.value = state.stateName;
            }
          }

          // Load cities for the state
          await loadCitiesByStateId(school.stateId!);

          // Set city after cities are loaded
          if (school.cityId != null && school.cityName != null) {
            // Wait for cities to fully load and UI to update
            await Future.delayed(const Duration(milliseconds: 500));

            // Verify city exists in the loaded cities list
            final matchingCity = cities.firstWhereOrNull(
              (c) => c.id == school.cityId,
            );

            if (matchingCity != null) {
              selectedCity.value = matchingCity.cityName;
              print(
                'City set to: ${selectedCity.value} (ID: ${matchingCity.id})',
              );
            } else {
              // Try to match by name as fallback
              final cityByName = cities.firstWhereOrNull(
                (c) => c.cityName == school.cityName,
              );
              if (cityByName != null) {
                selectedCity.value = cityByName.cityName;
                print('City set by name: ${selectedCity.value}');
              } else {
                print(
                  'City not found. Expected: ${school.cityName} (ID: ${school.cityId})',
                );
                print(
                  'Available cities: ${cities.map((c) => '${c.cityName} (ID: ${c.id})').toList()}',
                );
              }
            }
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
        Get.snackbar(
          'Success',
          'School/College deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Reload schools list
        await loadSchools();
      } else {
        errorMessage.value = response.message ?? 'Failed to delete institution';
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      errorMessage.value = 'Error deleting institution: ${e.toString()}';
      print('Error in deleteSchool: $e');
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

  // Map API institution type from API format to UI format
  String _mapInstitutionTypeFromApi(String apiType) {
    switch (apiType.toUpperCase()) {
      case 'PRIVATE_SCHOOL':
        return 'Private School';
      case 'GOVT_AIDED_SCHOOL':
      case 'GOVT_SCHOOL':
        return 'Govt / Govt Aided School';
      case 'PRIVATE_COLLEGE':
        return 'Private College';
      case 'GOVT_AIDED_COLLEGE':
      case 'GOVT_COLLEGE':
        return 'Govt / Govt Aided College';
      default:
        // If already in UI format, return as is
        if (institutionTypes.contains(apiType)) {
          return apiType;
        }
        return apiType;
    }
  }

  // Reset form
  void resetForm() {
    formKey.currentState?.reset();
    selectedDistrict.value = '';
    selectedCity.value = '';
    selectedState.value = '';
    selectedStateId.value = 0;
    selectedPincode.value = '';
    selectedInstitutionType.value = '';
    institutionNameController.clear();
    addressController.clear();
    pincodeController.clear();
    cities.clear();
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
          (school.state?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  // Generate report
  Future<void> generateReport(String reportType) async {
    if (reportDistrict.value.isEmpty || reportState.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select District and State',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      // TODO: Implement API call to generate PDF report
      Get.snackbar(
        'Info',
        'Report generation will be implemented',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error generating report: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
