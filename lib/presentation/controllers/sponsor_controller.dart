import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/sponsor_model.dart';
import '../../data/models/competition_model.dart';
import '../../data/repositories/competition_repository.dart';

class SponsorController extends GetxController {
  final CompetitionRepository _competitionRepository = CompetitionRepository();

  // Form controllers
  final formKey = GlobalKey<FormState>();
  final sponsorNameController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final pincodeController = TextEditingController();
  final cellPhoneController = TextEditingController();
  final whatsappController = TextEditingController();
  final emailController = TextEditingController();
  final numberOfStudentsController = TextEditingController();

  // Observable state
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<SponsorModel> sponsors = <SponsorModel>[].obs;
  final RxList<CompetitionModel> competitions = <CompetitionModel>[].obs;
  final RxString selectedCompetitionId = ''.obs;
  final RxInt selectedNumberOfStudents = 0.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isListView = false.obs; // Toggle between create and list view

  @override
  void onInit() {
    super.onInit();
    loadCompetitions();
    loadSponsors();
  }

  @override
  void onClose() {
    sponsorNameController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    cellPhoneController.dispose();
    whatsappController.dispose();
    emailController.dispose();
    numberOfStudentsController.dispose();
    super.onClose();
  }

  // Load competitions for dropdown
  Future<void> loadCompetitions() async {
    try {
      isLoading.value = true;
      final result = await _competitionRepository.getAllCompetitions();
      if (result.success && result.data != null) {
        competitions.value = result.data as List<CompetitionModel>;
      }
    } catch (e) {
      errorMessage.value = 'Error loading competitions: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  // Load sponsors
  Future<void> loadSponsors() async {
    try {
      isLoading.value = true;
      // TODO: Implement API call to get sponsors
      // For now, using dummy data
      sponsors.value = [];
    } catch (e) {
      errorMessage.value = 'Error loading sponsors: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  // Get selected competition name
  String getSelectedCompetitionName() {
    if (selectedCompetitionId.value.isEmpty) return '';
    final competition = competitions.firstWhereOrNull(
      (c) => c.id == selectedCompetitionId.value,
    );
    return competition?.competitionName ?? '';
  }

  // Toggle view mode
  void toggleViewMode(bool isList) {
    isListView.value = isList;
  }

  // Submit sponsor form
  Future<void> submitSponsor() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (selectedCompetitionId.value.isEmpty) {
      errorMessage.value = 'Please select a competition';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final sponsor = SponsorModel(
        competitionId: selectedCompetitionId.value,
        competitionName: getSelectedCompetitionName(),
        numberOfStudents: selectedNumberOfStudents.value > 0
            ? selectedNumberOfStudents.value
            : int.tryParse(numberOfStudentsController.text) ?? 0,
        sponsorName: sponsorNameController.text.trim(),
        address: addressController.text.trim(),
        city: cityController.text.trim(),
        state: stateController.text.trim(),
        pincode: pincodeController.text.trim(),
        cellPhone: cellPhoneController.text.trim(),
        whatsapp: whatsappController.text.trim().isEmpty
            ? null
            : whatsappController.text.trim(),
        email: emailController.text.trim(),
      );

      // TODO: Implement API call to save sponsor
      // await _sponsorRepository.createSponsor(sponsor);
      // For now, add to local list for testing
      sponsors.add(sponsor);

      // Reset form
      resetForm();

      Get.snackbar(
        'Success',
        'Sponsor registration submitted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Reload sponsors list
      await loadSponsors();
    } catch (e) {
      errorMessage.value = 'Error submitting sponsor: ${e.toString()}';
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
    selectedCompetitionId.value = '';
    selectedNumberOfStudents.value = 0;
    sponsorNameController.clear();
    addressController.clear();
    cityController.clear();
    stateController.clear();
    pincodeController.clear();
    cellPhoneController.clear();
    whatsappController.clear();
    emailController.clear();
    numberOfStudentsController.clear();
    errorMessage.value = '';
  }

  // Get filtered sponsors based on search query
  List<SponsorModel> getFilteredSponsors() {
    if (searchQuery.value.isEmpty) {
      return sponsors;
    }
    final query = searchQuery.value.toLowerCase();
    return sponsors.where((sponsor) {
      return sponsor.sponsorName.toLowerCase().contains(query) ||
          sponsor.competitionName.toLowerCase().contains(query) ||
          sponsor.email.toLowerCase().contains(query) ||
          sponsor.cellPhone.contains(query);
    }).toList();
  }
}

