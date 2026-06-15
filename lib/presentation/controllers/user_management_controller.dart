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
import '../../../core/theme/role_theme_controller.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/utils/photo_capture_service.dart';

class UserManagementController extends GetxController {
  final UserManagementRepository _repository = UserManagementRepository();
  final CompetitionRepository _competitionRepository = CompetitionRepository();
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
  /// Competition filter for the Users list tab; not cleared by [resetForm].
  final RxString usersListEventId = ''.obs;
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

  /// Parent VOLUNTEER user created on first "Add More" save in this session.
  final Set<String> _existingVolunteerNamesLower = {};

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
        final user = UserManagementModel.fromJson(userData);
        currentUser.value = user;
        if (Get.isRegistered<RoleThemeController>()) {
          Get.find<RoleThemeController>().applyThemeColor(user.themeColor);
        }
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
    if (showList) {
      final eventId = int.tryParse(usersListEventId.value);
      if (eventId != null && users.isEmpty && !isLoading.value) {
        Future.microtask(() => loadUsers(eventId: eventId));
      }
    }
  }

  @override
  void onClose() {
    // See CompetitionController.onClose — avoid dispose during logout teardown.
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

  bool isVolunteersSelectedType([String? type]) {
    final value = (type ?? selectedType.value).toUpperCase();
    return value == 'VOLUNTEERS' || value == 'VOLUNTEER';
  }

  bool _isVolunteerUser(UserManagementModel user) {
    return isVolunteersSelectedType(user.type);
  }

  // Load stages and categories for selected competition
  Future<void> loadStagesAndCategoriesForCompetition(
    String? competitionId,
  ) async {
    try {
      if (isVolunteersSelectedType()) {
        availableStages.clear();
        availableCategories.clear();
        return;
      }

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
  Future<void> pickPhoto(
    ImageSource source, {
    BuildContext? context,
  }) async {
    try {
      final XFile? image = await PhotoCaptureService.pickImage(
        source: source,
        context: context,
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
  Future<void> pickPhotoForVolunteer(
    VolunteerRow row,
    ImageSource source, {
    BuildContext? context,
  }) async {
    try {
      final XFile? image = await PhotoCaptureService.pickImage(
        source: source,
        context: context,
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

  void addVolunteerRow() {
    volunteerRows.add(VolunteerRow());
    volunteerRows.refresh();
  }

  void removeVolunteerRow(int index) {
    if (index < 0 || index >= volunteerRows.length) return;
    if (volunteerRows[index].isRegistered.value) {
      errorMessage.value = 'Saved volunteers cannot be removed here';
      return;
    }
    volunteerRows[index].dispose();
    volunteerRows.removeAt(index);
    if (volunteerRows.isEmpty) {
      addVolunteerRow();
    }
  }

  void _clearVolunteerGroupSession() {
    _existingVolunteerNamesLower.clear();
  }

  /// Loads volunteer names already registered for this competition.
  Future<void> _loadExistingVolunteerNamesForCompetition(int competitionId) async {
    _existingVolunteerNamesLower.clear();
    final userTypeId = getUserTypeId('VOLUNTEERS') ?? 4;
    final response = await _repository.getAllUsers(
      competitionId: competitionId,
      userTypeId: userTypeId,
      page: 0,
      limit: 500,
    );
    if (!response.success || response.data == null) return;

    for (final user in response.data!.users) {
      if (!_isVolunteerGroupUser(user)) continue;
      final name = user.name.trim();
      if (name.isEmpty) continue;
      if (name.startsWith('Volunteers -')) {
        for (final volunteer in user.volunteers ?? const []) {
          final volunteerName = (volunteer['volunteerName'] ?? volunteer['name'])
              ?.toString()
              .trim();
          if (volunteerName != null && volunteerName.isNotEmpty) {
            _existingVolunteerNamesLower.add(volunteerName.toLowerCase());
          }
        }
      } else {
        _existingVolunteerNamesLower.add(name.toLowerCase());
      }
    }
  }

  /// Clears volunteer rows and group session (navigation / type change).
  void resetVolunteerEntrySession() {
    _disposeVolunteerRows();
    _clearVolunteerGroupSession();
  }

  /// Same as participant bulk: one empty row ready for entry.
  Future<void> prepareVolunteerEntry() async {
    resetVolunteerEntrySession();
    addVolunteerRow();
    if (selectedEventId.value.trim().isNotEmpty &&
        errorMessage.value == 'Please select a competition') {
      errorMessage.value = '';
    }
    final competitionId = int.tryParse(selectedEventId.value.trim());
    if (competitionId != null) {
      await _loadExistingVolunteerNamesForCompetition(competitionId);
    }
  }

  bool _isVolunteerGroupUser(UserManagementModel user) {
    final typeId = getUserTypeId('VOLUNTEERS') ?? 4;
    if (user.userTypeId == typeId) return true;
    final type = user.type.toUpperCase();
    return type.contains('VOLUNTEER');
  }

  /// Saves the active row via API, marks it read-only, and appends a new row.
  Future<bool> registerCurrentVolunteer({BuildContext? context}) async {
    final eventId = selectedEventId.value.trim();
    if (eventId.isEmpty) {
      errorMessage.value = 'Please select a competition';
      return false;
    }
    if (errorMessage.value == 'Please select a competition') {
      errorMessage.value = '';
    }

    if (volunteerRows.isEmpty) {
      addVolunteerRow();
    }

    VolunteerRow? row;
    for (var i = volunteerRows.length - 1; i >= 0; i--) {
      if (!volunteerRows[i].isRegistered.value) {
        row = volunteerRows[i];
        break;
      }
    }
    if (row == null) {
      addVolunteerRow();
      row = volunteerRows.last;
    }

    if (row.isRegistered.value) {
      addVolunteerRow();
      row = volunteerRows.last;
    }

    final volunteerName = row.nameController.text.trim();
    if (volunteerName.isEmpty) {
      errorMessage.value = 'Please enter volunteer name';
      return false;
    }

    if (_existingVolunteerNamesLower.contains(volunteerName.toLowerCase())) {
      errorMessage.value = '';
      addVolunteerRow();
      volunteerRows.refresh();
      if (context != null && context.mounted) {
        SnackbarHelper.showInfo(
          context,
          'Volunteer "$volunteerName" already exists. '
          'Enter a different name in the new row below.',
        );
      }
      return false;
    }

    final form = formKey.currentState;
    if (form != null && !form.validate()) {
      errorMessage.value = '';
      return false;
    }

    final competitionId = int.tryParse(selectedEventId.value);
    if (competitionId == null) {
      errorMessage.value = 'Invalid competition ID';
      return false;
    }

    final userTypeId = getUserTypeId('VOLUNTEERS') ?? 4;
    final volunteerPassword = generateRandomPassword();
    final newVolunteer = <String, dynamic>{
      'volunteerName': volunteerName,
      'password': volunteerPassword,
      'cell': row.cellController.text.trim(),
    };

    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _loadExistingVolunteerNamesForCompetition(competitionId);

      // Login userName matches display name (must be unique across the system).
      final loginUserName = volunteerName;

      // One user account per volunteer (unique users.id); one linked volunteers row.
      final user = UserManagementModel(
        name: volunteerName,
        userName: loginUserName,
        password: volunteerPassword,
        type: 'VOLUNTEERS',
        userTypeId: userTypeId,
        competitionId: competitionId,
        volunteers: [newVolunteer],
      );

      final response = await _repository.createUser(user: user);
      if (response.success) {
        row.isRegistered.value = true;
        row.savedPassword = volunteerPassword;
        row.savedUserId = response.data?.id;
        _existingVolunteerNamesLower.add(volunteerName.toLowerCase());
        addVolunteerRow();
        volunteerRows.refresh();
        await loadUsers(eventId: competitionId);
        // Do not show list-load errors on the volunteer create form after a successful save.
        errorMessage.value = '';
        if (context != null && context.mounted) {
          SnackbarHelper.showSuccess(context, 'Volunteer saved successfully');
        } else {
          Get.snackbar(
            'Success',
            'Volunteer saved successfully',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
        return true;
      }

      final failMessage = response.message ?? 'Failed to save volunteer';
      if (failMessage.toLowerCase().contains('already exists')) {
        errorMessage.value = '';
        addVolunteerRow();
        volunteerRows.refresh();
        if (context != null && context.mounted) {
          SnackbarHelper.showInfo(
            context,
            'Volunteer "$volunteerName" already exists for this competition. '
            'Use a different name in the new row below.',
          );
        }
        return false;
      }

      errorMessage.value = failMessage;
      return false;
    } catch (e) {
      errorMessage.value = 'Error saving volunteer: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void _disposeVolunteerRows() {
    for (final row in volunteerRows) {
      row.dispose();
    }
    volunteerRows.clear();
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

      final userTypeId = getUserTypeId('VOLUNTEERS') ?? 4;

      // Volunteer numbers are assigned on the server when omitted.
      final volunteersList = validVolunteers.map((row) {
        return <String, dynamic>{
          'volunteerName': row.nameController.text.trim(),
          'password': generateRandomPassword(),
          'cell': row.cellController.text.trim(),
        };
      }).toList();

      final suffix = DateTime.now().millisecondsSinceEpoch;
      final competitionLabel = selectedEventName.value.trim().isNotEmpty
          ? selectedEventName.value.trim()
          : 'Competition $competitionId';

      final user = UserManagementModel(
        name: 'Volunteers - $competitionLabel ($suffix)',
        userName: 'volunteers_${competitionId}_$suffix',
        password: generateRandomPassword(),
        type: 'VOLUNTEERS',
        userTypeId: userTypeId,
        competitionId: competitionId,
      );

      final response = await _repository.createUser(
        user: user,
        volunteers: volunteersList,
      );

      if (response.success) {
        await loadUsers(eventId: competitionId);
        resetVolunteerEntrySession();
        resetForm();
        toggleViewMode(true);
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

  void _populateVolunteerRowsForEdit(UserManagementModel user) {
    _disposeVolunteerRows();

    final legacyGroup =
        user.name.trim().startsWith('Volunteers -') &&
        user.volunteers != null &&
        user.volunteers!.isNotEmpty;

    if (legacyGroup) {
      for (final volunteer in user.volunteers!) {
        final row = VolunteerRow();
        row.nameController.text =
            (volunteer['volunteerName'] ?? volunteer['name'])?.toString().trim() ??
            '';
        row.cellController.text = volunteer['cell']?.toString().trim() ?? '';
        volunteerRows.add(row);
      }
    } else {
      final row = VolunteerRow();
      String volunteerName = user.name.trim();
      String cell = user.cell?.trim() ?? '';
      if (user.volunteers != null && user.volunteers!.isNotEmpty) {
        final volunteer = user.volunteers!.first;
        volunteerName =
            (volunteer['volunteerName'] ?? volunteer['name'])
                ?.toString()
                .trim() ??
            volunteerName;
        cell = volunteer['cell']?.toString().trim() ?? cell;
      }
      row.nameController.text = volunteerName;
      row.cellController.text = cell;
      row.savedPassword = user.confirmPassword;
      volunteerRows.add(row);
    }

    volunteerRows.refresh();
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

    if (_isVolunteerUser(user)) {
      selectedType.value = 'VOLUNTEERS';
      _populateVolunteerRowsForEdit(user);
      photoFile.value = null;
      photoBytes.value = null;
      photoUrl.value = '';
      return;
    }

    // Set photo URL - construct full URL if we have user ID
    if (user.id != null &&
        user.displayPhotoUrl != null &&
        user.displayPhotoUrl!.isNotEmpty) {
      final photoPath = user.displayPhotoUrl!;
      if (photoPath.startsWith('http://') || photoPath.startsWith('https://')) {
        photoUrl.value = photoPath;
      } else {
        photoUrl.value = '${BaseUrl.baseUrl}${EndPoints.userPhoto(user.id!)}';
      }
    } else {
      photoUrl.value = '';
    }

    photoFile.value = null;
    photoBytes.value = null;

    if (selectedEventId.value.isNotEmpty) {
      loadStagesAndCategoriesForCompetition(selectedEventId.value);
    }
  }

  /// Updates the volunteer being edited (single-user volunteer model).
  Future<bool> updateVolunteerUser() async {
    final userId = userToEdit.value?.id;
    if (userId == null || userId.isEmpty) {
      errorMessage.value = 'Invalid volunteer user';
      return false;
    }

    if (volunteerRows.isEmpty) {
      errorMessage.value = 'No volunteer data to update';
      return false;
    }

    final row = volunteerRows.first;
    final volunteerName = row.nameController.text.trim();
    if (volunteerName.isEmpty) {
      errorMessage.value = 'Please enter volunteer name';
      return false;
    }

    final form = formKey.currentState;
    if (form != null && !form.validate()) {
      errorMessage.value = '';
      return false;
    }

    if (selectedEventId.value.isEmpty) {
      errorMessage.value = 'Please select a competition';
      return false;
    }

    final competitionId = int.tryParse(selectedEventId.value);
    if (competitionId == null) {
      errorMessage.value = 'Invalid competition ID';
      return false;
    }

    final userTypeId = getUserTypeId('VOLUNTEERS') ?? 4;
    final volunteerPayload = <String, dynamic>{
      'volunteerName': volunteerName,
      'cell': row.cellController.text.trim(),
    };
    if (row.savedPassword != null && row.savedPassword!.length >= 6) {
      volunteerPayload['password'] = row.savedPassword;
    }

    final user = UserManagementModel(
      id: userId,
      name: volunteerName,
      userName: volunteerName,
      type: 'VOLUNTEERS',
      userTypeId: userTypeId,
      competitionId: competitionId,
      competitionName: selectedEventName.value.isNotEmpty
          ? selectedEventName.value
          : null,
      volunteers: [volunteerPayload],
    );

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _repository.updateUser(
        id: userId,
        user: user,
        photoFile: row.photoFile.value,
        photoBytes: row.photoBytes.value,
        photoFileName: kIsWeb ? 'volunteer_photo.jpg' : null,
      );

      if (response.success) {
        await loadUsers(eventId: competitionId);
        errorMessage.value = '';
        resetForm();
        toggleViewMode(true);
        return true;
      }

      errorMessage.value = response.message ?? 'Failed to update volunteer';
      return false;
    } catch (e) {
      errorMessage.value = 'Error updating volunteer: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
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
    _disposeVolunteerRows();
    _clearVolunteerGroupSession();
    errorMessage.value = '';

    // Clear all text controllers
    nameController.clear();
    userNameController.clear();
    passwordController.clear();
    cellController.clear();

    _refreshFormKey();
  }

  Future<void> _applyLoginSession(Map<String, dynamic> data) async {
    final user = data['user'] as UserManagementModel?;
    if (user != null) {
      currentUser.value = user;
      if (Get.isRegistered<PermissionStore>()) {
        Get.find<PermissionStore>().setKeys(user.permissions);
      }
      if (Get.isRegistered<RoleThemeController>()) {
        Get.find<RoleThemeController>().applyThemeColor(user.themeColor);
      }
    }
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
        await _applyLoginSession(response.data as Map<String, dynamic>);
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

  Future<bool> loginWithToken({required String token}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _repository.loginWithToken(token: token);

      if (response.success && response.data != null) {
        await _applyLoginSession(response.data as Map<String, dynamic>);
        isLoading.value = false;
        return true;
      }

      errorMessage.value =
          response.message ?? 'Invalid or expired login link';
      isLoading.value = false;
      return false;
    } catch (e) {
      errorMessage.value = 'Error during login: ${e.toString()}';
      isLoading.value = false;
      return false;
    }
  }

  Future<Map<String, dynamic>?> generateJuryLoginToken(String userId) async {
    try {
      errorMessage.value = '';

      final response = await _repository.generateJuryLoginToken(userId);

      if (response.success && response.data != null) {
        return response.data;
      }

      errorMessage.value =
          response.message ?? 'Failed to generate login link';
      return null;
    } catch (e) {
      errorMessage.value = 'Error generating login link: ${e.toString()}';
      return null;
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
        if (Get.isRegistered<RoleThemeController>()) {
          Get.find<RoleThemeController>().resetToDefault();
        }
        isLoading.value = false;
        return true;
      } else {
        // Clear current user even if API call fails
        currentUser.value = null;
        if (Get.isRegistered<PermissionStore>()) {
          Get.find<PermissionStore>().setKeys(const []);
        }
        if (Get.isRegistered<RoleThemeController>()) {
          Get.find<RoleThemeController>().resetToDefault();
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
      if (Get.isRegistered<RoleThemeController>()) {
        Get.find<RoleThemeController>().resetToDefault();
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
  final RxBool isRegistered = false.obs;
  String? savedPassword;
  String? savedUserId;

  void dispose() {
    nameController.dispose();
    cellController.dispose();
  }
}
