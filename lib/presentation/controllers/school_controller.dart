import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/school_model.dart';

class SchoolController extends GetxController {
  // Form controllers
  final formKey = GlobalKey<FormState>();
  final institutionNameController = TextEditingController();
  final addressController = TextEditingController();

  // Observable state
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<SchoolModel> schools = <SchoolModel>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isListView = false.obs; // Toggle between create and list view

  // Form fields
  final RxString selectedDistrict = ''.obs;
  final RxString selectedState = ''.obs;
  final RxString selectedPincode = ''.obs;
  final RxString selectedInstitutionType = ''.obs;

  // Report generation fields
  final RxString reportDistrict = ''.obs;
  final RxString reportState = ''.obs;

  // Available options
  static const List<String> states = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

  static const List<String> institutionTypes = [
    'Private School',
    'Govt / Govt Aided School',
    'Private College',
    'Govt / Govt Aided College',
  ];

  // Dummy districts - in real app, this would be loaded from API based on state
  List<String> getDistrictsForState(String state) {
    // TODO: Load districts from API based on state
    return [
      'District 1',
      'District 2',
      'District 3',
      'District 4',
      'District 5',
    ];
  }

  // Dummy pincodes - in real app, this would be loaded from API based on district
  List<String> getPincodesForDistrict(String district) {
    // TODO: Load pincodes from API based on district
    return [
      '600001',
      '600002',
      '600003',
      '600004',
      '600005',
    ];
  }

  @override
  void onInit() {
    super.onInit();
    loadSchools();
  }

  @override
  void onClose() {
    institutionNameController.dispose();
    addressController.dispose();
    super.onClose();
  }

  // Load schools
  Future<void> loadSchools() async {
    try {
      isLoading.value = true;
      // TODO: Implement API call to get schools
      // For now, using dummy data
      schools.value = [];
    } catch (e) {
      errorMessage.value = 'Error loading schools: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  // Toggle view mode
  void toggleViewMode(bool isList) {
    isListView.value = isList;
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

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final school = SchoolModel(
        institutionName: institutionNameController.text.trim(),
        address: addressController.text.trim(),
        district: selectedDistrict.value,
        state: selectedState.value,
        pincode: selectedPincode.value,
        institutionType: selectedInstitutionType.value,
      );

      // TODO: Implement API call to save school
      // await _schoolRepository.createSchool(school);

      // Add to local list for testing
      schools.add(school);

      // Reset form
      resetForm();

      Get.snackbar(
        'Success',
        'School/College added successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Reload schools list
      await loadSchools();
    } catch (e) {
      errorMessage.value = 'Error submitting school: ${e.toString()}';
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

  // Reset form
  void resetForm() {
    formKey.currentState?.reset();
    selectedDistrict.value = '';
    selectedState.value = '';
    selectedPincode.value = '';
    selectedInstitutionType.value = '';
    institutionNameController.clear();
    addressController.clear();
    errorMessage.value = '';
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
          school.district.toLowerCase().contains(query) ||
          school.state.toLowerCase().contains(query);
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

