import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/user_management_repository.dart';
import '../../data/repositories/competition_repository.dart';
import '../../data/models/user_management_model.dart';
import '../../data/models/user_type_model.dart';
import '../../data/models/competition_option_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/championship_style.dart';
import '../../../core/utils/storage_service.dart';
import '../../../core/utils/permission_store.dart';

class UserManagementController extends GetxController {
  final UserManagementRepository _repository = UserManagementRepository();
  final CompetitionRepository _competitionRepository = CompetitionRepository();
  final ImagePicker _imagePicker = ImagePicker();

  // State
  final RxList<UserManagementModel> users = <UserManagementModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isListView = false.obs;

  // Pagination state for /user/list
  final RxInt usersPage = 0.obs;
  final RxInt usersLimit = 10.obs;
  final RxInt usersTotal = 0.obs;
  final RxInt usersTotalPages = 0.obs;

  // Current logged-in user
  final Rx<UserManagementModel?> currentUser = Rx<UserManagementModel?>(null);

  // User types loaded from API
  final RxList<UserTypeModel> userTypesList = <UserTypeModel>[].obs;
  final RxBool isLoadingUserTypes = false.obs;

  // Stages and categories loaded from API based on competition
  final RxList<CompetitionOptionModel> availableStages =
      <CompetitionOptionModel>[].obs;
  final RxList<CompetitionOptionModel> availableCategories =
      <CompetitionOptionModel>[].obs;
  final RxBool isLoadingStagesCategories = false.obs;

  // Form Controllers
  final nameController = TextEditingController();
  final userNameController = TextEditingController();
  final passwordController = TextEditingController();
  final cellController = TextEditingController();

  /// New key whenever the user form subtree is (re)shown so we never attach one
  /// [GlobalKey] to two [Form] elements during list/form transitions (web hot reload
  /// and rapid Obx rebuilds could otherwise trigger duplicate GlobalKey assertions).
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  GlobalKey<FormState> get formKey => _formKey;

  /// Bumped whenever [_formKey] is replaced so the UI can rebuild the [Form] shell.
  final RxInt formKeyRevision = 0.obs;

  void _refreshFormKey() {
    _formKey = GlobalKey<FormState>();
    formKeyRevision.value++;
  }

  // Form State
  final RxString selectedType = 'SUB ADMIN'.obs;
  final RxString selectedEventId = ''.obs;
  final RxString selectedEventName = ''.obs;
  final RxList<String> selectedPermissions = <String>[].obs;
  final RxList<String> selectedStages = <String>[].obs;
  final RxList<String> selectedCategories = <String>[].obs;
  final RxBool selectedMale = false.obs;
  final RxBool selectedFemale = false.obs;
  final Rx<File?> photoFile = Rx<File?>(null);
  final Rx<Uint8List?> photoBytes = Rx<Uint8List?>(null);
  final RxString photoUrl = ''.obs;
  final RxBool selectedAllStage = false.obs;
  final RxBool selectedAllCategory = false.obs;
  // Edit mode state
  final Rx<UserManagementModel?> userToEdit = Rx<UserManagementModel?>(null);

  // Check if in edit mode
  bool get isEditMode => userToEdit.value != null;

  // Volunteer table state
  final RxList<VolunteerRow> volunteerRows = <VolunteerRow>[].obs;

  // Available options - now loaded from API
  // Get user types as display strings
  List<String> get userTypes {
    if (userTypesList.isEmpty) {
      // Return empty list or fallback if not loaded yet
      return [];
    }
    return userTypesList.map((type) {
      // Convert typeName to display format
      // SUB_ADMIN -> SUB ADMIN, SPOT_REG_ADMIN -> SPOT REG ADMIN(S), etc.
      final typeName = type.typeName;
      if (typeName == 'SUB_ADMIN') return 'SUB ADMIN';
      if (typeName == 'SPOT_REG_ADMIN') return 'SPOT REG ADMIN(S)';
      if (typeName == 'JURY') return 'JURY(S)';
      if (typeName == 'VOLUNTEER') return 'VOLUNTEERS';
      // Fallback: replace underscores with spaces
      return typeName.replaceAll('_', ' ');
    }).toList();
  }

  static const List<String> permissions = ['CREATE', 'EDIT', 'DELETE'];

  // Get stages as display strings (loaded from API)
  List<String> get stages {
    return availableStages.map((stage) => stage.name).toList();
  }

  // Get categories as display strings (loaded from API)
  List<String> get categories {
    return availableCategories.map((category) => category.name).toList();
  }

  @override
  void onInit() {
    super.onInit();
    // Initialize with 4 volunteer rows
    volunteerRows.value = List.generate(4, (index) => VolunteerRow());
    // Load current user from storage
    loadCurrentUser();
    // Load user types from API
    loadUserTypes();
  }

  // Load current user from storage
  Future<void> loadCurrentUser() async {
    try {
      final userJson = StorageService.getString(AppConstants.userKey);
      if (userJson != null && userJson.isNotEmpty) {
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        currentUser.value = UserManagementModel.fromJson(userData);
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  // Load user types from API
  Future<void> loadUserTypes() async {
    try {
      isLoadingUserTypes.value = true;
      final response = await _repository.getUserTypes();

      if (response.success && response.data != null) {
        userTypesList.value = response.data!;
      } else {
        print('Failed to load user types: ${response.message}');
        // Keep empty list if API fails
        userTypesList.value = [];
      }
    } catch (e) {
      print('Error loading user types: $e');
      userTypesList.value = [];
    } finally {
      isLoadingUserTypes.value = false;
    }
  }

  void toggleViewMode(bool showList) {
    if (!showList) {
      _refreshFormKey();
    }
    isListView.value = showList;
  }

  @override
  void onClose() {
    nameController.dispose();
    userNameController.dispose();
    passwordController.dispose();
    cellController.dispose();
    super.onClose();
  }

  // Get filtered users
  List<UserManagementModel> get filteredUsers {
    if (searchQuery.value.isEmpty) {
      return users;
    }
    return users.where((user) {
      final query = searchQuery.value.toLowerCase();
      return user.name.toLowerCase().contains(query) ||
          (user.userName?.toLowerCase().contains(query) ?? false) ||
          user.type.toLowerCase().contains(query) ||
          (user.eventName?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  // Load users
  Future<void> loadUsers({
    int? eventId,
    int? userTypeId,
    String? roleType,
    String? search,
    int page = 0,
    int limit = 10,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _repository.getAllUsers(
        competitionId: eventId != null && eventId > 0 ? eventId : null,
        userTypeId: userTypeId,
        roleType: roleType,
        search: search,
        page: page,
        limit: limit,
      );

      if (response.success && response.data != null) {
        final paged = response.data!;
        users.value = paged.users;
        final p = paged.pagination;
        if (p != null) {
          usersPage.value = p.page;
          usersLimit.value = p.limit;
          usersTotal.value = p.total;
          usersTotalPages.value = p.totalPages;
        } else {
          usersPage.value = page;
          usersLimit.value = limit;
          usersTotal.value = paged.users.length;
          usersTotalPages.value = 1;
        }
      } else {
        errorMessage.value = response.message ?? 'Failed to load users';
      }
    } catch (e) {
      errorMessage.value = 'Error loading users: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  // Helper method to get userTypeId from type string
  int? getUserTypeId(String type) {
    // First try to find in loaded user types
    final typeUpper = type.toUpperCase();
    for (final userType in userTypesList) {
      final typeNameUpper = userType.typeName.toUpperCase();
      // Check exact match or display format match
      if (typeNameUpper == typeUpper ||
          typeNameUpper.replaceAll('_', ' ') == typeUpper ||
          (typeNameUpper == 'SUB_ADMIN' && typeUpper == 'SUB ADMIN') ||
          (typeNameUpper == 'SPOT_REG_ADMIN' &&
              (typeUpper == 'SPOT REG ADMIN(S)' ||
                  typeUpper == 'SPOT REG ADMIN')) ||
          (typeNameUpper == 'JURY' &&
              (typeUpper == 'JURY(S)' || typeUpper == 'JURY')) ||
          (typeNameUpper == 'VOLUNTEER' &&
              (typeUpper == 'VOLUNTEERS' || typeUpper == 'VOLUNTEER'))) {
        return userType.id;
      }
    }

    // Fallback to hard-coded mapping if user types not loaded yet
    switch (typeUpper) {
      case 'SUB ADMIN':
        return 1;
      case 'SPOT REG ADMIN(S)':
      case 'SPOT REG ADMIN':
        return 2;
      case 'JURY(S)':
      case 'JURY':
        return 3;
      case 'VOLUNTEERS':
      case 'VOLUNTEER':
        return 4;
      default:
        return null;
    }
  }

  // Helper method to map stage names to IDs
  List<int> getStageIds(List<String> stageNames) {
    final ids = <int>[];
    for (final stageName in stageNames) {
      final stage = availableStages.firstWhereOrNull(
        (s) => s.name.toUpperCase() == stageName.toUpperCase(),
      );
      if (stage != null) {
        ids.add(stage.id);
      }
    }
    return ids;
  }

  // Helper method to map category names to IDs
  List<int> getCategoryIds(List<String> categoryNames) {
    final ids = <int>[];
    for (final categoryName in categoryNames) {
      final category = availableCategories.firstWhereOrNull(
        (c) => c.name.toUpperCase() == categoryName.toUpperCase(),
      );
      if (category != null) {
        ids.add(category.id);
      }
    }
    return ids;
  }

  static const String _championsCategoryName = 'CHAMPIONS';

  /// When competition uses winner-based Champions, add CHAMPIONS for jury allotment.
  Future<void> _appendChampionsCategoryForWinnerStyle(int competitionId) async {
    final compResponse =
        await _competitionRepository.getCompetitionById(competitionId);
    if (!compResponse.success || compResponse.data == null) return;

    final style = ChampionshipStyle.fromApiValue(
      compResponse.data!.championshipStyle,
    );
    if (style != ChampionshipStyle.fromFirstPlaceWinners) return;

    final hasChampions = availableCategories.any(
      (c) => c.name.trim().toUpperCase() == _championsCategoryName,
    );
    if (hasChampions) return;

    final allResponse = await _competitionRepository.getAllCategories();
    if (!allResponse.success || allResponse.data == null) return;

    final champions = allResponse.data!.firstWhereOrNull(
      (c) => c.name.trim().toUpperCase() == _championsCategoryName,
    );
    if (champions != null) {
      availableCategories.add(champions);
      availableCategories.refresh();
    }
  }

  // Load stages and categories for selected competition
  Future<void> loadStagesAndCategoriesForCompetition(
    String? competitionId,
  ) async {
    try {
      if (competitionId == null || competitionId.isEmpty) {
        // Clear stages and categories if no competition selected
        availableStages.clear();
        availableCategories.clear();
        return;
      }

      isLoadingStagesCategories.value = true;

      // Parse competition ID
      final competitionIdInt = int.tryParse(competitionId);
      if (competitionIdInt == null) {
        availableStages.clear();
        availableCategories.clear();
        isLoadingStagesCategories.value = false;
        return;
      }

      // Fetch stages and categories for the competition in parallel
      final results = await Future.wait([
        _competitionRepository.getStagesByCompetition(competitionIdInt),
        _competitionRepository.getCategoriesByCompetition(competitionIdInt),
      ]);

      // Update stages
      if (results[0].success && results[0].data != null) {
        availableStages.value = results[0].data!;
      } else {
        print('Failed to load stages: ${results[0].message}');
        availableStages.clear();
      }

      // Update categories
      if (results[1].success && results[1].data != null) {
        availableCategories.value = results[1].data!;
        await _appendChampionsCategoryForWinnerStyle(competitionIdInt);
      } else {
        print('Failed to load categories: ${results[1].message}');
        availableCategories.clear();
      }
    } catch (e) {
      print('Error loading stages and categories: $e');
      // Clear on error
      availableStages.clear();
      availableCategories.clear();
    } finally {
      isLoadingStagesCategories.value = false;
    }
  }

  // Toggle permission
  void togglePermission(String permission) {
    if (selectedPermissions.contains(permission)) {
      selectedPermissions.remove(permission);
    } else {
      selectedPermissions.add(permission);
    }
  }

  // Toggle stage
  void toggleStage(String stage) {
    if (selectedStages.contains(stage)) {
      selectedStages.remove(stage);
    } else {
      selectedStages.add(stage);
    }
  }

  // Toggle category
  void toggleCategory(String category) {
    if (selectedCategories.contains(category)) {
      selectedCategories.remove(category);
    } else {
      selectedCategories.add(category);
    }
  }

  Future<void> _applyPickedUserPhoto(XFile image) async {
    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      photoBytes.value = bytes;
      photoUrl.value = 'web_image';
      photoFile.value = null;
    } else {
      photoFile.value = File(image.path);
      photoBytes.value = null;
      photoUrl.value = image.path;
    }
  }

  Future<void> _applyPickedVolunteerPhoto(VolunteerRow row, XFile image) async {
    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      row.photoBytes.value = bytes;
      row.photoUrl.value = 'web_image';
      row.photoFile.value = null;
    } else {
      row.photoFile.value = File(image.path);
      row.photoBytes.value = null;
      row.photoUrl.value = image.path;
    }
  }

  // Pick or capture user photo (gallery or camera).
  Future<void> pickPhoto(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image != null) {
        await _applyPickedUserPhoto(image);
      }
    } catch (e) {
      errorMessage.value = source == ImageSource.camera
          ? 'Error taking photo: ${e.toString()}'
          : 'Error picking image: ${e.toString()}';
    }
  }

  // Pick or capture volunteer row photo (gallery or camera).
  Future<void> pickPhotoForVolunteer(VolunteerRow row, ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image != null) {
        await _applyPickedVolunteerPhoto(row, image);
      }
    } catch (e) {
      errorMessage.value = source == ImageSource.camera
          ? 'Error taking photo: ${e.toString()}'
          : 'Error picking image: ${e.toString()}';
    }
  }

  // Add volunteer row
  void addVolunteerRow() {
    volunteerRows.add(VolunteerRow());
  }

  // Remove volunteer row
  void removeVolunteerRow(int index) {
    if (volunteerRows.length > 1) {
      volunteerRows.removeAt(index);
    }
  }

  // Generate random password
  String generateRandomPassword() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final password = StringBuffer();
    for (int i = 0; i < 8; i++) {
      password.write(chars[(random + i) % chars.length]);
    }
    return password.toString();
  }

  // Generate volunteer number
  String generateVolunteerNo(int index) {
    return 'VOL-${(index + 1).toString().padLeft(3, '0')}';
  }

  // Create user
  Future<bool> createUser() async {
    try {
      if (!formKey.currentState!.validate()) {
        return false;
      }

      if (selectedEventId.value.isEmpty) {
        errorMessage.value = 'Please select a competition';
        return false;
      }
      if (selectedType.value == 'JURY(S)' &&
          !selectedMale.value &&
          !selectedFemale.value) {
        errorMessage.value = 'Please select at least one gender option';
        return false;
      }

      isLoading.value = true;
      errorMessage.value = '';

      final competitionId = int.tryParse(selectedEventId.value);
      if (competitionId == null) {
        errorMessage.value = 'Invalid competition ID';
        isLoading.value = false;
        return false;
      }

      final userTypeId = getUserTypeId(selectedType.value);
      if (userTypeId == null) {
        errorMessage.value = 'Invalid user type';
        isLoading.value = false;
        return false;
      }

      // Convert stages and categories to IDs
      // TODO: Get actual IDs from CompetitionController
      final stageIds = getStageIds(selectedStages.toList());
      final categoryIds = getCategoryIds(selectedCategories.toList());

      final user = UserManagementModel(
        name: nameController.text.trim(),
        userName: userNameController.text.trim(),
        password: generateRandomPassword(),
        type: selectedType.value, // For backward compatibility
        userTypeId: userTypeId,
        competitionId: competitionId,
        competitionName: selectedEventName.value.isNotEmpty
            ? selectedEventName.value
            : null,
        permissions: selectedPermissions.toList(), // For backward compatibility
        stages: selectedStages.toList(), // For backward compatibility
        categories: selectedCategories.toList(), // For backward compatibility
        stagesObj: stageIds.isNotEmpty
            ? stageIds.map((id) => {'id': id}).toList()
            : null,
        categoriesObj: categoryIds.isNotEmpty
            ? categoryIds.map((id) => {'id': id}).toList()
            : null,
        male: selectedType.value == 'JURY(S)' ? selectedMale.value : null,
        female: selectedType.value == 'JURY(S)' ? selectedFemale.value : null,
        cell: cellController.text.trim().isNotEmpty
            ? cellController.text.trim()
            : null,
      );

      // Check if in edit mode
      if (isEditMode && userToEdit.value?.id != null) {
        // Update existing user
        final response = await updateUser(userToEdit.value!.id!);
        return response;
      } else {
        // Create new user
        final response = await _repository.createUser(
          user: user,
          photoFile: photoFile.value,
          photoBytes: photoBytes.value,
          photoFileName: kIsWeb ? 'user_photo.jpg' : null,
        );

        if (response.success) {
          final eventIdInt = int.tryParse(selectedEventId.value);
          await loadUsers(eventId: eventIdInt);
          resetForm();
          return true;
        } else {
          errorMessage.value = response.message ?? 'Failed to create user';
          return false;
        }
      }
    } catch (e) {
      errorMessage.value = 'Error creating user: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Create volunteers
  Future<bool> createVolunteers() async {
    try {
      if (selectedEventId.value.isEmpty) {
        errorMessage.value = 'Please select a competition';
        return false;
      }

      // Validate volunteer rows
      final validVolunteers = volunteerRows
          .where((row) => row.nameController.text.trim().isNotEmpty)
          .toList();

      if (validVolunteers.isEmpty) {
        errorMessage.value = 'Please enter at least one volunteer name';
        return false;
      }

      isLoading.value = true;
      errorMessage.value = '';

      final competitionId = int.tryParse(selectedEventId.value);
      if (competitionId == null) {
        errorMessage.value = 'Invalid competition ID';
        isLoading.value = false;
        return false;
      }

      // Prepare volunteers array in new format
      final volunteersList = validVolunteers.asMap().entries.map((entry) {
        final index = entry.key;
        final row = entry.value;
        return <String, dynamic>{
          'volunteerNo': generateVolunteerNo(index),
          'volunteerName': row.nameController.text.trim(),
          'password': generateRandomPassword(),
          'cell': row.cellController.text.trim().isNotEmpty
              ? row.cellController.text.trim()
              : '',
        };
      }).toList();

      // Create a user with VOLUNTEERS type and volunteers array
      final user = UserManagementModel(
        name: 'Volunteers Group', // Placeholder name
        password: generateRandomPassword(),
        type: 'VOLUNTEERS',
        userTypeId: 4,
        competitionId: competitionId,
      );

      final response = await _repository.createUser(
        user: user,
        volunteers: volunteersList,
      );

      if (response.success) {
        await loadUsers(eventId: competitionId);
        resetForm();
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to create volunteers';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error creating volunteers: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Initialize form for edit
  void initializeFormForEdit(UserManagementModel user) {
    _refreshFormKey();
    userToEdit.value = user;
    nameController.text = user.name;
    userNameController.text = user.userName ?? '';
    selectedType.value = user.type;
    selectedEventId.value = user.displayEventId?.toString() ?? '';
    selectedEventName.value = user.displayEventName ?? '';
    selectedPermissions.value = user.permissions.toList();
    selectedStages.value = user.stages.toList();
    selectedCategories.value = user.categories.toList();
    selectedMale.value = user.male ?? false;
    selectedFemale.value = user.female ?? false;
    if (user.cell != null) {
      cellController.text = user.cell!;
    }

    // Set photo URL - construct full URL if we have user ID
    if (user.id != null &&
        user.displayPhotoUrl != null &&
        user.displayPhotoUrl!.isNotEmpty) {
      final photoPath = user.displayPhotoUrl!;
      // If it's already a full URL, use it; otherwise construct it
      if (photoPath.startsWith('http://') || photoPath.startsWith('https://')) {
        photoUrl.value = photoPath;
      } else {
        // Construct full URL using the user photo endpoint
        // Import BaseUrl and EndPoints at the top of the file
        photoUrl.value = '${BaseUrl.baseUrl}${EndPoints.userPhoto(user.id!)}';
      }
    } else {
      photoUrl.value = '';
    }

    // Clear local photo files when loading existing user
    photoFile.value = null;
    photoBytes.value = null;

    // Load stages and categories for the selected competition
    // This is important for edit mode so that stages and categories are available
    if (selectedEventId.value.isNotEmpty) {
      loadStagesAndCategoriesForCompetition(selectedEventId.value);
    }
  }

  // Update user
  Future<bool> updateUser(String userId) async {
    try {
      if (!formKey.currentState!.validate()) {
        return false;
      }

      if (selectedEventId.value.isEmpty) {
        errorMessage.value = 'Please select a competition';
        return false;
      }
      if (selectedType.value == 'JURY(S)' &&
          !selectedMale.value &&
          !selectedFemale.value) {
        errorMessage.value = 'Please select at least one gender option';
        return false;
      }

      isLoading.value = true;
      errorMessage.value = '';

      final competitionId = int.tryParse(selectedEventId.value);
      if (competitionId == null) {
        errorMessage.value = 'Invalid competition ID';
        isLoading.value = false;
        return false;
      }

      final userTypeId = getUserTypeId(selectedType.value);
      if (userTypeId == null) {
        errorMessage.value = 'Invalid user type';
        isLoading.value = false;
        return false;
      }

      // Convert stages and categories to IDs
      final stageIds = getStageIds(selectedStages.toList());
      final categoryIds = getCategoryIds(selectedCategories.toList());

      // In edit mode, only include password if it's been changed (not empty and not placeholder)
      // Since password field is disabled, we don't send password unless explicitly provided
      final passwordValue = passwordController.text.trim();
      final shouldUpdatePassword =
          passwordValue.isNotEmpty &&
          passwordValue != 'XXXXXXXX' &&
          passwordValue.length >= 6;

      final user = UserManagementModel(
        id: userId,
        name: nameController.text.trim(),
        userName: userNameController.text.trim(),
        password: shouldUpdatePassword
            ? passwordValue
            : null, // Only update password if valid new password provided
        type: selectedType.value,
        userTypeId: userTypeId,
        competitionId: competitionId,
        competitionName: selectedEventName.value.isNotEmpty
            ? selectedEventName.value
            : null,
        permissions: selectedPermissions.toList(),
        stages: selectedStages.toList(),
        categories: selectedCategories.toList(),
        stagesObj: stageIds.isNotEmpty
            ? stageIds.map((id) => {'id': id}).toList()
            : null,
        categoriesObj: categoryIds.isNotEmpty
            ? categoryIds.map((id) => {'id': id}).toList()
            : null,
        male: selectedType.value == 'JURY(S)' ? selectedMale.value : null,
        female: selectedType.value == 'JURY(S)' ? selectedFemale.value : null,
        cell: cellController.text.trim().isNotEmpty
            ? cellController.text.trim()
            : null,
      );

      final response = await _repository.updateUser(
        id: userId,
        user: user,
        photoFile: photoFile.value,
        photoBytes: photoBytes.value,
        photoFileName: kIsWeb ? 'user_photo.jpg' : null,
      );

      if (response.success) {
        final eventIdInt = int.tryParse(selectedEventId.value);
        await loadUsers(eventId: eventIdInt);
        resetForm();
        toggleViewMode(true);
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to update user';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error updating user: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _repository.deleteUser(userId);

      if (response.success) {
        users.removeWhere((user) => user.id == userId);
        // Reload users list
        final eventId = selectedEventId.value.isNotEmpty
            ? int.tryParse(selectedEventId.value)
            : null;
        await loadUsers(eventId: eventId);
        isLoading.value = false;
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to delete user';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error deleting user: ${e.toString()}';
      isLoading.value = false;
      return false;
    }
  }

  // Reset form
  void resetForm() {
    // Clear all reactive values first
    userToEdit.value = null;
    selectedType.value = 'SUB ADMIN';
    selectedEventId.value = '';
    selectedEventName.value = '';
    selectedPermissions.clear();
    selectedStages.clear();
    selectedCategories.clear();
    selectedAllStage.value = false;
    selectedAllCategory.value = false;
    selectedMale.value = false;
    selectedFemale.value = false;
    photoFile.value = null;
    photoBytes.value = null;
    photoUrl.value = '';
    volunteerRows.value = List.generate(4, (index) => VolunteerRow());
    errorMessage.value = '';

    // Clear all text controllers
    nameController.clear();
    userNameController.clear();
    passwordController.clear();
    cellController.clear();

    _refreshFormKey();
  }

  // Login user
  Future<bool> login({
    required String name,
    required String password,
    int? competitionId,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _repository.login(
        name: name,
        password: password,
        competitionId: competitionId,
      );

      if (response.success && response.data != null) {
        // Extract and store user data
        final data = response.data as Map<String, dynamic>;
        final user = data['user'] as UserManagementModel?;
        if (user != null) {
          currentUser.value = user;
          if (Get.isRegistered<PermissionStore>()) {
            Get.find<PermissionStore>().setKeys(user.permissions);
          }
        }
        isLoading.value = false;
        return true;
      } else {
        errorMessage.value = response.message ?? 'Login failed';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error during login: ${e.toString()}';
      isLoading.value = false;
      return false;
    }
  }

  // Logout user
  Future<bool> logout() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _repository.logout();

      if (response.success) {
        // Clear current user
        currentUser.value = null;
        if (Get.isRegistered<PermissionStore>()) {
          Get.find<PermissionStore>().setKeys(const []);
        }
        isLoading.value = false;
        return true;
      } else {
        // Clear current user even if API call fails
        currentUser.value = null;
        if (Get.isRegistered<PermissionStore>()) {
          Get.find<PermissionStore>().setKeys(const []);
        }
        errorMessage.value = response.message ?? 'Logout failed';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      // Clear current user on error
      currentUser.value = null;
      if (Get.isRegistered<PermissionStore>()) {
        Get.find<PermissionStore>().setKeys(const []);
      }
      errorMessage.value = 'Error during logout: ${e.toString()}';
      isLoading.value = false;
      return false;
    }
  }

  // Check if user has permission
  bool hasPermission(String permission) {
    if (currentUser.value == null) return false;
    final permissionsObj = currentUser.value!.permissionsObj;
    if (permissionsObj != null) {
      return permissionsObj[permission.toUpperCase()] ?? false;
    }
    // Fallback to list format
    return currentUser.value!.permissions.any(
      (p) => p.toUpperCase() == permission.toUpperCase(),
    );
  }

  // Check if user is authenticated
  bool get isAuthenticated => currentUser.value != null;

  // Get user photo URL
  String? get userPhotoUrl {
    if (currentUser.value == null) return null;
    final photo = currentUser.value!.photo ?? currentUser.value!.photoUrl;
    if (photo == null || photo.isEmpty) return null;

    // If it's already a full URL, return as is
    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      return photo;
    }

    // Otherwise, construct full URL
    // Remove leading slash if present
    final cleanPhoto = photo.startsWith('/') ? photo.substring(1) : photo;
    return '${BaseUrl.baseUrl}/$cleanPhoto';
  }
}

// Volunteer row model for table
class VolunteerRow {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController cellController = TextEditingController();
  final Rx<File?> photoFile = Rx<File?>(null);
  final Rx<Uint8List?> photoBytes = Rx<Uint8List?>(null);
  final RxString photoUrl = ''.obs;

  void dispose() {
    nameController.dispose();
    cellController.dispose();
  }
}
