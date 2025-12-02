import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/participant_repository.dart';
import '../../data/models/participant_model.dart';
import '../../data/models/api_response.dart';
import '../../data/models/score_response_model.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../core/constants/app_constants.dart';

class ParticipantController extends GetxController {
  final ParticipantRepository _participantRepository = ParticipantRepository();
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RxList<ParticipantModel> participants = <ParticipantModel>[].obs;
  final RxList<ParticipantModel> myRegistrations =
      <ParticipantModel>[].obs; // User's registrations
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<ParticipantModel?> selectedParticipant = Rx<ParticipantModel?>(null);

  // Filter state
  final Rx<ParticipantFilterRequest> currentFilter =
      Rx<ParticipantFilterRequest>(ParticipantFilterRequest());
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 0.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasMorePages = false.obs;

  // Form state
  final TextEditingController nameController = TextEditingController();
  final TextEditingController schoolNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController yogaMasterNameController =
      TextEditingController();
  final TextEditingController yogaMasterContactController =
      TextEditingController();

  final Rx<DateTime?> dateOfBirth = Rx<DateTime?>(null);
  final RxString gender = ''.obs;
  final RxList<String> selectedCategories = <String>[].obs;
  final RxString standard = ''.obs;
  final Rx<File?> photoFile = Rx<File?>(null);
  final Rx<XFile?> selectedImage = Rx<XFile?>(null);
  final Rx<ParticipantModel?> participantToEdit = Rx<ParticipantModel?>(null);
  final RxString existingPhotoUrl = ''.obs;
  final RxBool isLoadingParticipant = false.obs;

  /// Get participant image URL using the participantImage API endpoint
  String? getParticipantImageUrl(String? participantId) {
    if (participantId == null || participantId.isEmpty) {
      return null;
    }
    // Use the participantImage API endpoint from app_constants
    return '${BaseUrl.baseUrl}${EndPoints.participantImage(participantId)}';
  }

  @override
  void onInit() {
    super.onInit();
    // Participants are now loaded by event ID only
  }

  @override
  void onClose() {
    nameController.dispose();
    schoolNameController.dispose();
    addressController.dispose();
    yogaMasterNameController.dispose();
    yogaMasterContactController.dispose();
    super.onClose();
  }

  /// Load user's registrations for a specific event
  Future<void> loadMyRegistrations(String eventId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final filter = ParticipantFilterRequest(page: 0, size: 50);
      final response = await _participantRepository.getParticipantsByEventId(
        eventId: eventId,
        filter: filter,
      );

      if (response.success && response.data != null) {
        myRegistrations.value = response.data!.participants;
      } else {
        errorMessage.value = response.message ?? 'Failed to load registrations';
      }

      isLoading.value = false;
    } catch (e) {
      errorMessage.value = 'Failed to load registrations: ${e.toString()}';
      isLoading.value = false;
    }
  }

  Future<void> loadParticipantsByEventId(
    String eventId, {
    ParticipantFilterRequest? filter,
    bool resetPage = false,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Update filter if provided
      if (filter != null) {
        currentFilter.value = filter;
      }

      // Reset page if needed
      if (resetPage) {
        currentPage.value = 1;
        currentFilter.value = currentFilter.value.copyWith(page: 0);
      }

      ParticipantFilterRequest filterToUse;
      // Convert 1-indexed currentPage to 0-indexed API page
      final apiPage = currentPage.value > 0 ? currentPage.value - 1 : 0;
      filterToUse = currentFilter.value.copyWith(page: apiPage);

      final response = await _participantRepository.getParticipantsByEventId(
        eventId: eventId,
        filter: filterToUse,
      );

      if (response.success && response.data != null) {
        final filterData = response.data!;

        if (resetPage || currentPage.value == 1) {
          participants.value = filterData.participants;
        } else {
          // Append for pagination
          participants.addAll(filterData.participants);
        }

        currentPage.value = filterData.currentPage + 1;
        totalPages.value = filterData.totalPages;
        totalItems.value = filterData.totalItems;
        hasMorePages.value = currentPage.value < filterData.totalPages;
      } else {
        errorMessage.value = response.message ?? 'Failed to load participants';
        if (resetPage || currentPage.value == 1) {
          participants.clear();
        }
      }

      isLoading.value = false;
    } catch (e) {
      errorMessage.value = 'An error occurred: ${e.toString()}';
      isLoading.value = false;
    }
  }

  Future<void> loadNextPage(String eventId) async {
    if (hasMorePages.value && !isLoading.value) {
      currentPage.value++;
      await loadParticipantsByEventId(eventId, resetPage: false);
    }
  }

  void resetFilter() {
    currentFilter.value = ParticipantFilterRequest();
    currentPage.value = 1;
    totalPages.value = 1;
    totalItems.value = 0;
    hasMorePages.value = false;
    participants.clear();
  }

  Future<bool> createParticipant({
    required ParticipantModel participant,
    File? photoFile,
    XFile? photoXFile,
    required String eventId,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _participantRepository.createParticipant(
        participant: participant,
        photoFile: photoFile,
        photoXFile: photoXFile,
        eventId: eventId,
      );

      if (response.success && response.data != null) {
        participants.add(response.data!);
        isLoading.value = false;
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to create participant';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: ${e.toString()}';
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> updateParticipant({
    required String id,
    required ParticipantModel participant,
    dynamic photoFile, // File on mobile, null on web
    XFile? photoXFile,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _participantRepository.updateParticipant(
        id: id,
        participant: participant,
        photoFile: photoFile,
        photoXFile: photoXFile,
      );

      if (response.success && response.data != null) {
        final index = participants.indexWhere((p) => p.id == id);
        if (index != -1) {
          participants[index] = response.data!;
        }
        isLoading.value = false;
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to update participant';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: ${e.toString()}';
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> deleteParticipant(String id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _participantRepository.deleteParticipant(id);

      if (response.success) {
        participants.removeWhere((p) => p.id == id);
        isLoading.value = false;
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to delete participant';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: ${e.toString()}';
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> updateScores({
    required String id,
    required Map<String, double> juryScores,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _participantRepository.updateScores(
        id: id,
        juryScores: juryScores,
      );

      if (response.success && response.data != null) {
        final index = participants.indexWhere((p) => p.id == id);
        if (index != -1) {
          participants[index] = response.data!;
        }
        isLoading.value = false;
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to update scores';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: ${e.toString()}';
      isLoading.value = false;
      return false;
    }
  }

  Future<ApiResponse<ScoreResponseModel>> getParticipantScoresByEventId(
    String eventId,
  ) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _participantRepository
          .getParticipantScoresByEventId(eventId);

      isLoading.value = false;
      return response;
    } catch (e) {
      errorMessage.value = 'An error occurred: ${e.toString()}';
      isLoading.value = false;
      return ApiResponse(
        success: false,
        message: 'Error fetching scores: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<SingleParticipantScoreResponseModel>>
  getParticipantScoresByParticipantId(
    String eventId,
    String participantId,
  ) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _participantRepository
          .getParticipantScoresByParticipantId(eventId, participantId);

      isLoading.value = false;
      return response;
    } catch (e) {
      errorMessage.value = 'An error occurred: ${e.toString()}';
      isLoading.value = false;
      return ApiResponse(
        success: false,
        message: 'Error fetching participant score: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> saveScores({
    required String eventId,
    required List<Map<String, dynamic>> scoreOfParticipants,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _participantRepository.saveScores(
        eventId: eventId,
        scoreOfParticipants: scoreOfParticipants,
      );

      isLoading.value = false;
      return response;
    } catch (e) {
      errorMessage.value = 'An error occurred: ${e.toString()}';
      isLoading.value = false;
      return ApiResponse(
        success: false,
        message: 'Error saving scores: ${e.toString()}',
      );
    }
  }

  Future<bool> updateParticipantStatus(String id, String status) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _participantRepository.updateParticipantStatus(
        id: id,
        status: status,
      );

      if (response.success) {
        // Note: Participants reload should be handled by the calling screen with eventId
        Get.snackbar(
          'Success',
          'Participant status updated to ${status.toUpperCase()}',
        );
        isLoading.value = false;
        return true;
      } else {
        errorMessage.value =
            response.message ?? 'Failed to update participant status';
        Get.snackbar('Error', errorMessage.value);
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value =
          'Failed to update participant status: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
      isLoading.value = false;
      return false;
    }
  }

  void setSelectedParticipant(ParticipantModel? participant) {
    selectedParticipant.value = participant;
  }

  // Form management methods
  Future<void> pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        selectedImage.value = image;
        photoFile.value = File(image.path);
      }
    } catch (e) {
      errorMessage.value = 'Failed to pick image: ${e.toString()}';
    }
  }

  Future<void> takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        selectedImage.value = image;
        photoFile.value = File(image.path);
      }
    } catch (e) {
      errorMessage.value = 'Failed to take photo: ${e.toString()}';
    }
  }

  Future<void> selectDateOfBirth(BuildContext context) async {
    // Use existing dateOfBirth if available, otherwise default to 10 years ago
    final DateTime initialDate =
        dateOfBirth.value ??
        DateTime.now().subtract(const Duration(days: 365 * 10));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
    );

    if (picked != null) {
      dateOfBirth.value = picked;
    }
  }

  void setGender(String? value) {
    gender.value = value ?? '';
  }

  void toggleCategory(String categoryValue) {
    if (selectedCategories.contains(categoryValue)) {
      selectedCategories.remove(categoryValue);
    } else {
      selectedCategories.add(categoryValue);
    }
  }

  bool isCategorySelected(String categoryValue) {
    return selectedCategories.contains(categoryValue);
  }

  void setStandard(String? value) {
    standard.value = value ?? '';
  }

  void resetForm() {
    nameController.clear();
    schoolNameController.clear();
    addressController.clear();
    yogaMasterNameController.clear();
    yogaMasterContactController.clear();
    dateOfBirth.value = null;
    gender.value = '';
    selectedCategories.clear();
    standard.value = '';
    photoFile.value = null;
    selectedImage.value = null;
    errorMessage.value = '';
    participantToEdit.value = null;
    existingPhotoUrl.value = '';
    isLoadingParticipant.value = false;
    // Reset form state
    formKey.currentState?.reset();
  }

  /// Initialize form for registration screen
  /// Handles reset logic for both new registration and edit mode
  void initializeRegistrationForm(String? participantId) {
    if (participantId != null && participantId.isNotEmpty) {
      // For edit mode: only reset if this is a different participant
      final currentEditId = participantToEdit.value?.id;
      if (currentEditId != participantId) {
        // Clear all form data first
        _clearFormData();

        // Fetch participant data after first frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          formKey.currentState?.reset();
          fetchParticipantById(participantId);
        });
      }
    } else {
      // For new registration: always reset form
      _clearFormData();

      // Reset form state after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        formKey.currentState?.reset();
      });
    }
  }

  /// Clear all form controllers and reactive values
  void _clearFormData() {
    nameController.clear();
    schoolNameController.clear();
    addressController.clear();
    yogaMasterNameController.clear();
    yogaMasterContactController.clear();
    dateOfBirth.value = null;
    gender.value = '';
    selectedCategories.clear();
    standard.value = '';
    photoFile.value = null;
    selectedImage.value = null;
    errorMessage.value = '';
    existingPhotoUrl.value = '';
    isLoadingParticipant.value = false;
    participantToEdit.value = null;
  }

  /// Fetch participant details by ID from API
  Future<bool> fetchParticipantById(String participantId) async {
    try {
      isLoadingParticipant.value = true;
      errorMessage.value = '';

      final response = await _participantRepository.getParticipantById(
        participantId,
      );

      if (response.success && response.data != null) {
        initializeFormForEdit(response.data!);
        isLoadingParticipant.value = false;
        return true;
      } else {
        errorMessage.value =
            response.message ?? 'Failed to fetch participant details';
        isLoadingParticipant.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error loading participant: ${e.toString()}';
      isLoadingParticipant.value = false;
      return false;
    }
  }

  /// Initialize form with participant data for editing
  void initializeFormForEdit(ParticipantModel participant) {
    print('Initializing form for edit: ${participant.participantName}');
    print('Participant ID: ${participant.id}');

    // Set participant to edit first (this sets isEditMode to true)
    participantToEdit.value = participant;

    // Use participantImage API endpoint to get image URL
    // Set photo URL after participantToEdit to ensure isEditMode is true
    if (participant.id != null && participant.id!.isNotEmpty) {
      final imageUrl = getParticipantImageUrl(participant.id);
      existingPhotoUrl.value = imageUrl ?? '';
      print('Photo URL from API: ${existingPhotoUrl.value}');
      print('Participant ID: ${participant.id}');
      print('Is Edit Mode: ${isEditMode}');
    } else {
      // Fallback to photoUrl if ID is not available
      existingPhotoUrl.value = participant.photoUrl ?? '';
      print('Photo URL from model: ${existingPhotoUrl.value}');
    }

    // Set form fields
    nameController.text = participant.participantName;
    schoolNameController.text = participant.schoolName;
    addressController.text = participant.address;
    standard.value = participant.standard;
    gender.value = participant.gender;
    dateOfBirth.value = participant.dateOfBirth;

    // Set category - handle comma-separated categories
    selectedCategories.clear();
    if (participant.category.isNotEmpty) {
      final categories = participant.category
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      for (final cat in categories) {
        if (cat == AppConstants.categoryCommon ||
            cat == AppConstants.categorySpecial) {
          selectedCategories.add(cat);
        }
      }
    }

    // Set yoga master info
    yogaMasterNameController.text = participant.yogaMasterName;
    yogaMasterContactController.text = participant.yogaMasterContact;

    print(
      'Form initialized - Name: ${nameController.text}, Photo URL: ${existingPhotoUrl.value}',
    );
  }

  /// Build ParticipantModel from current form data
  ParticipantModel buildParticipantModelFromForm(String? participantId) {
    final age = app_date_utils.AppDateUtils.calculateAge(dateOfBirth.value!);

    // Combine selected categories into a comma-separated string
    final categoryString = selectedCategories.join(', ');

    return ParticipantModel(
      id: participantId,
      participantName: nameController.text.trim().toUpperCase(),
      dateOfBirth: dateOfBirth.value!,
      age: age,
      gender: gender.value,
      category: categoryString,
      standard: standard.value,
      schoolName: schoolNameController.text.trim(),
      address: addressController.text.trim(),
      yogaMasterName: yogaMasterNameController.text.trim(),
      yogaMasterContact: yogaMasterContactController.text.trim(),
    );
  }

  /// Get image bytes from selected image
  Future<Uint8List?> getImageBytes() async {
    try {
      // Use selectedImage (XFile) which works on both web and mobile
      if (selectedImage.value != null) {
        return await selectedImage.value!.readAsBytes();
      }
    } catch (e) {
      print('Error reading image bytes: $e');
    }
    return null;
  }

  /// Submit update form for existing participant
  Future<bool> submitUpdateForm(String participantId) async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    if (dateOfBirth.value == null) {
      errorMessage.value = 'Please select date of birth';
      return false;
    }

    if (gender.value.isEmpty) {
      errorMessage.value = 'Please select gender';
      return false;
    }

    if (selectedCategories.isEmpty) {
      errorMessage.value = 'Please select at least one category';
      return false;
    }

    if (standard.value.isEmpty) {
      errorMessage.value = 'Please select standard/group';
      return false;
    }

    final participant = buildParticipantModelFromForm(participantId);

    final success = await updateParticipant(
      id: participantId,
      participant: participant,
      photoFile: photoFile.value,
      photoXFile: selectedImage.value,
    );

    // Don't reload participants list after update
    // The calling screen (e.g., event details) will handle refreshing its own list
    // This prevents unnecessary API calls to event-based endpoints

    return success;
  }

  /// Check if form is in edit mode
  bool get isEditMode => participantToEdit.value != null;

  Future<bool> submitRegistrationForm({required String eventId}) async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    if (dateOfBirth.value == null) {
      errorMessage.value = 'Please select date of birth';
      return false;
    }

    if (gender.value.isEmpty) {
      errorMessage.value = 'Please select gender';
      return false;
    }

    if (selectedCategories.isEmpty) {
      errorMessage.value = 'Please select at least one category';
      return false;
    }

    if (standard.value.isEmpty) {
      errorMessage.value = 'Please select standard/group';
      return false;
    }

    final age = app_date_utils.AppDateUtils.calculateAge(dateOfBirth.value!);

    // Combine selected categories into a comma-separated string
    final categoryString = selectedCategories.join(', ');

    final participant = ParticipantModel(
      participantName: nameController.text.trim().toUpperCase(),
      dateOfBirth: dateOfBirth.value!,
      age: age,
      gender: gender.value,
      category: categoryString,
      standard: standard.value,
      schoolName: schoolNameController.text.trim(),
      address: addressController.text.trim(),
      yogaMasterName: yogaMasterNameController.text.trim(),
      yogaMasterContact: yogaMasterContactController.text.trim(),
    );

    final success = await createParticipant(
      participant: participant,
      photoFile: photoFile.value,
      photoXFile: selectedImage.value,
      eventId: eventId,
    );

    if (success) {
      await loadParticipantsByEventId(eventId, resetPage: true);
      resetForm();
    }

    return success;
  }

  void reset() {
    participants.clear();
    myRegistrations.clear();
    selectedParticipant.value = null;
    participantToEdit.value = null;
    isLoading.value = false;
    errorMessage.value = '';
    currentFilter.value = ParticipantFilterRequest();
    currentPage.value = 1;
    totalPages.value = 0;
    totalItems.value = 0;
    hasMorePages.value = false;
    resetForm();
  }
}
