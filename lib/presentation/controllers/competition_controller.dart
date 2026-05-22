import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/competition_repository.dart';
import '../../data/models/competition_model.dart';
import '../../data/models/competition_option_model.dart';

class CompetitionController extends GetxController {
  final CompetitionRepository _repository = CompetitionRepository();

  // Form controllers — keys are replaced when the form subtree is (re)shown so one
  // GlobalKey is never attached to two widgets during list/form transitions.
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  GlobalKey<FormState> get formKey => _formKey;

  final RxInt formKeyRevision = 0.obs;

  /// Bumped when any competition date changes so date [FormField]s rebuild.
  final RxInt competitionDatesRevision = 0.obs;

  static const String dateFieldStart = 'start';
  static const String dateFieldEnd = 'end';
  static const String dateFieldDisplayAd = 'displayAd';

  final RxSet<String> touchedCompetitionDateFields = <String>{}.obs;

  void _refreshFormKeys() {
    _formKey = GlobalKey<FormState>();
    formKeyRevision.value++;
  }

  void notifyCompetitionDatesChanged() {
    competitionDatesRevision.value++;
  }

  void markCompetitionDateFieldTouched(String fieldKey) {
    touchedCompetitionDateFields.add(fieldKey);
  }

  bool shouldShowCompetitionDateError(String fieldKey) {
    return hasAttemptedSubmit.value ||
        touchedCompetitionDateFields.contains(fieldKey);
  }

  void clearCompetitionDateFieldTouches() {
    touchedCompetitionDateFields.clear();
  }

  final competitionNameController = TextEditingController();
  final descriptionController = TextEditingController();
  final addressController = TextEditingController();

  // Observable state
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<CompetitionModel> competitions = <CompetitionModel>[].obs;

  /// Public list for home screen (from GET /competition/public)
  final RxList<HomeCompetitionModel> homeCompetitions =
      <HomeCompetitionModel>[].obs;
  final RxBool isLoadingHomeCompetitions = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedFilter = ''.obs;
  final RxBool isListView = false.obs; // Toggle between create and list view
  final RxBool hasAttemptedSubmit =
      false.obs; // Track if form has been submitted
  final RxBool isEditMode = false.obs; // Track if in edit/view mode
  final RxBool isViewMode = false.obs; // Track if in view-only mode
  final Rx<CompetitionModel?> competitionToEdit = Rx<CompetitionModel?>(
    null,
  ); // Competition being edited

  /// Set after successful create; used to show registration QR dialog.
  final Rx<CompetitionModel?> lastSavedCompetitionForQr =
      Rx<CompetitionModel?>(null);

  // Search controller and debounce
  final TextEditingController searchController = TextEditingController();
  Timer? _debounceTimer;

  // Pagination and sorting
  final RxInt currentPage = 1.obs;
  final RxInt itemsPerPage = 20.obs;
  final RxInt totalItems = 0.obs;
  final RxInt totalPages = 0.obs;
  final RxString sortBy =
      'createdAt'.obs; // createdAt, eventStartDate, eventEndDate
  final RxString sortOrder = 'desc'.obs; // asc, desc
  final Rx<DateTime?> eventStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> eventEndDate = Rx<DateTime?>(null);
  final Rx<DateTime?> displayAdFrom = Rx<DateTime?>(null);
  final RxBool spotRegistration = false.obs;
  final RxInt participantsPerStage = RxInt(0);
  final RxInt minimumMarks = RxInt(0);
  final RxInt maximumMarks = RxInt(0);
  // Track selected IDs (for API submission)
  final RxList<int> selectedPrizeIds = <int>[].obs;
  final RxList<int> selectedCategoryIds = <int>[].obs;
  final RxMap<String, double> categoryAmounts =
      <String, double>{}.obs; // Key: category ID as string
  final RxList<int> selectedStageIds = <int>[].obs;
  final RxMap<String, List<int>> stageGroups = <String, List<int>>{}
      .obs; // Key: stage ID as string, Value: list of group IDs

  // Helper getters for backward compatibility (for UI display)
  List<String> get selectedPrizes => selectedPrizeIds
      .map((id) {
        final option = prizeOptions.firstWhereOrNull((opt) => opt.id == id);
        return option?.name ?? '';
      })
      .where((name) => name.isNotEmpty)
      .toList();

  List<String> get selectedCategories => selectedCategoryIds
      .map((id) {
        final option = categoryOptions.firstWhereOrNull((opt) => opt.id == id);
        return option?.name ?? '';
      })
      .where((name) => name.isNotEmpty)
      .toList();

  List<String> get selectedStages => selectedStageIds
      .map((id) {
        final option = stageOptions.firstWhereOrNull((opt) => opt.id == id);
        return option?.name ?? '';
      })
      .where((name) => name.isNotEmpty)
      .toList();

  // File handling
  final Rx<XFile?> brochureFile = Rx<XFile?>(null);
  final Rx<File?> brochureFileLocal = Rx<File?>(null);
  final Rx<Uint8List?> brochureBytes = Rx<Uint8List?>(null);
  final RxString brochureUrl = ''.obs;
  final RxInt brochureUpdateTimestamp =
      0.obs; // Track brochure updates for cache-busting

  // Available options (loaded from API)
  final RxList<CompetitionOptionModel> prizeOptions =
      <CompetitionOptionModel>[].obs;
  final RxList<CompetitionOptionModel> categoryOptions =
      <CompetitionOptionModel>[].obs;
  final RxList<CompetitionOptionModel> stageOptions =
      <CompetitionOptionModel>[].obs;
  final RxList<CompetitionOptionModel> groupOptions =
      <CompetitionOptionModel>[].obs;

  // Static options (not loaded from API)
  static const List<int> participantsPerStageOptions = [1, 2, 3, 4, 5];
  static final List<int> marksOptions = List.generate(
    11,
    (index) => index,
  ); // 0-10

  // Helper getters to get names as strings (for backward compatibility)
  List<String> get prizeOptionNames => prizeOptions.map((e) => e.name).toList();
  List<String> get categoryOptionNames =>
      categoryOptions.map((e) => e.name).toList();
  List<String> get stageOptionNames => stageOptions.map((e) => e.name).toList();
  List<String> get groupOptionNames => groupOptions.map((e) => e.name).toList();

  // Default stage mappings (pre-selected groups when stage is first selected)
  // This will be dynamically generated based on loaded groups
  Map<String, List<String>> get defaultStageMappings {
    // Try to map stages to groups based on common patterns
    // This is a fallback if no specific mapping exists
    final Map<String, List<String>> mappings = {};
    if (stageOptionNames.isNotEmpty && groupOptionNames.isNotEmpty) {
      // Simple mapping: assign first few groups to first stage, etc.
      final groupsPerStage = (groupOptionNames.length / stageOptionNames.length)
          .ceil();
      for (int i = 0; i < stageOptionNames.length; i++) {
        final start = i * groupsPerStage;
        final end = (start + groupsPerStage).clamp(0, groupOptionNames.length);
        if (start < groupOptionNames.length) {
          mappings[stageOptionNames[i]] = groupOptionNames.sublist(start, end);
        }
      }
    }
    return mappings;
  }

  @override
  /// Load competitions for home screen (public API, no auth required for display)
  Future<void> loadCompetitionsForHome() async {
    try {
      isLoadingHomeCompetitions.value = true;
      final response = await _repository.getCompetitionsPublic();
      if (response.success && response.data != null) {
        homeCompetitions.value = response.data!;
      } else {
        homeCompetitions.clear();
      }
    } catch (e) {
      homeCompetitions.clear();
    } finally {
      isLoadingHomeCompetitions.value = false;
    }
  }

  final RxBool isLoadingRegistrationCompetition = false.obs;

  /// Loads full competition data for the public/admin registration form.
  /// Safe after logout: does not rely on a prior [loadCompetitions] admin list call.
  Future<void> ensureCompetitionLoadedForRegistration(String competitionId) async {
    final id = competitionId.trim();
    if (id.isEmpty) return;

    final existing = competitions.firstWhereOrNull((c) => c.id == id);
    final hasGroupData = existing != null &&
        ((existing.stageGroups != null && existing.stageGroups!.isNotEmpty) ||
            (existing.stageGroupLabels != null &&
                existing.stageGroupLabels!.isNotEmpty));
    if (hasGroupData) {
      return;
    }

    if (stageOptions.isEmpty || groupOptions.isEmpty) {
      await loadOptions();
    }

    isLoadingRegistrationCompetition.value = true;
    try {
      final numericId = int.tryParse(id);
      if (numericId != null) {
        final response = await _repository.getCompetitionById(numericId);
        if (response.success && response.data != null) {
          _upsertCompetition(response.data!);
          return;
        }
      }

      final home = homeCompetitions.firstWhereOrNull(
        (c) => c.id?.toString() == id,
      );
      if (home != null) {
        _upsertCompetition(_competitionFromHome(home, existing));
      }
    } catch (e) {
      print('Error loading competition for registration: $e');
    } finally {
      isLoadingRegistrationCompetition.value = false;
    }
  }

  void _upsertCompetition(CompetitionModel competition) {
    final compId = competition.id;
    if (compId == null || compId.isEmpty) {
      competitions.add(competition);
    } else {
      final index = competitions.indexWhere((c) => c.id == compId);
      if (index >= 0) {
        competitions[index] = competition;
      } else {
        competitions.add(competition);
      }
    }
    competitions.refresh();
  }

  CompetitionModel _competitionFromHome(
    HomeCompetitionModel home,
    CompetitionModel? existing,
  ) {
    DateTime parseDate(String? value) {
      if (value == null || value.isEmpty) return DateTime.now();
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    return CompetitionModel(
      id: home.id?.toString(),
      competitionName: home.competitionName,
      description: home.description,
      address: home.address,
      eventStartDate: parseDate(home.eventStartDate),
      eventEndDate: parseDate(home.eventEndDate),
      displayAdFrom: home.displayAdFrom != null
          ? parseDate(home.displayAdFrom)
          : null,
      categories: home.categories.isNotEmpty
          ? List<String>.from(home.categories)
          : existing?.categories,
      categoryIds: existing?.categoryIds,
      categoryAmounts: home.categoryAmounts.isNotEmpty
          ? Map<String, double>.from(home.categoryAmounts)
          : existing?.categoryAmounts,
      stageGroups: existing?.stageGroups,
      stageIds: existing?.stageIds,
      stages: existing?.stages,
      brochureUrl: home.brochureUrl ?? existing?.brochureUrl,
    );
  }

  void onInit() {
    super.onInit();
    // Initialize search controller text
    searchController.text = searchQuery.value;
    // Initialize search controller listener
    searchController.addListener(_onSearchChanged);
    // Load options from API
    loadOptions();
  }

  // Load all options (categories, prizes, stages, groups) from API
  Future<void> loadOptions() async {
    try {
      // Load all options in parallel
      final results = await Future.wait([
        _repository.getAllCategories(),
        _repository.getAllPrizes(),
        _repository.getAllStages(),
        _repository.getAllGroups(),
      ]);

      // Update categories
      if (results[0].success && results[0].data != null) {
        categoryOptions.value = results[0].data!;
      }

      // Update prizes
      if (results[1].success && results[1].data != null) {
        prizeOptions.value = results[1].data!;
      }

      // Update stages
      if (results[2].success && results[2].data != null) {
        stageOptions.value = results[2].data!;
      }

      // Update groups
      if (results[3].success && results[3].data != null) {
        groupOptions.value = results[3].data!;
      }
    } catch (e) {
      print('Error loading options: $e');
      // Fallback to empty lists if API fails
    }
  }

  // Load specific option type (optimized for single option reload)
  Future<void> reloadCategoryOptions() async {
    try {
      final response = await _repository.getAllCategories();
      if (response.success && response.data != null) {
        categoryOptions.value = response.data!;
      }
    } catch (e) {
      print('Error reloading categories: $e');
    }
  }

  Future<void> reloadPrizeOptions() async {
    try {
      final response = await _repository.getAllPrizes();
      if (response.success && response.data != null) {
        prizeOptions.value = response.data!;
      }
    } catch (e) {
      print('Error reloading prizes: $e');
    }
  }

  Future<void> reloadStageOptions() async {
    try {
      final response = await _repository.getAllStages();
      if (response.success && response.data != null) {
        stageOptions.value = response.data!;
      }
    } catch (e) {
      print('Error reloading stages: $e');
    }
  }

  Future<void> reloadGroupOptions() async {
    try {
      final response = await _repository.getAllGroups();
      if (response.success && response.data != null) {
        groupOptions.value = response.data!;
      }
    } catch (e) {
      print('Error reloading groups: $e');
    }
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    competitionNameController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    searchController.dispose();
    super.onClose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      updateSearch(searchController.text);
    });
  }

  // Pick brochure file
  Future<void> pickBrochure() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (file != null) {
        // Validate file size (max 10MB)
        final fileSize = await file.length();
        const maxSize = 10 * 1024 * 1024; // 10MB in bytes

        if (fileSize > maxSize) {
          errorMessage.value = 'Brochure file size must be less than 10MB';
          Get.snackbar('Error', errorMessage.value);
          return;
        }

        // Validate file type (images: jpg, jpeg, png, pdf)
        final fileName = file.name.toLowerCase();
        final validExtensions = ['.jpg', '.jpeg', '.png', '.pdf'];
        final isValidType = validExtensions.any(
          (ext) => fileName.endsWith(ext),
        );

        if (!isValidType) {
          errorMessage.value =
              'Brochure must be an image (JPG, PNG) or PDF file';
          Get.snackbar('Error', errorMessage.value);
          return;
        }

        if (kIsWeb) {
          final bytes = await file.readAsBytes();
          brochureBytes.value = bytes;
          brochureFile.value = null;
          brochureFileLocal.value = null;
          brochureUrl.value = 'web_file';
        } else {
          brochureFile.value = file;
          brochureFileLocal.value = File(file.path);
          brochureBytes.value = null;
          brochureUrl.value = file.path;
        }
        errorMessage.value = ''; // Clear error on success
      }
    } catch (e) {
      errorMessage.value = 'Error picking brochure: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
    }
  }

  // Validate brochure is uploaded
  bool validateBrochure() {
    final hasBrochure =
        brochureFile.value != null ||
        brochureFileLocal.value != null ||
        brochureBytes.value != null;

    if (!hasBrochure) {
      errorMessage.value = 'Please upload a brochure';
      return false;
    }
    return true;
  }

  // Helper methods to get ID from name
  int? getPrizeIdByName(String name) {
    try {
      return prizeOptions.firstWhere((opt) => opt.name == name).id;
    } catch (e) {
      return null;
    }
  }

  int? getCategoryIdByName(String name) {
    try {
      return categoryOptions.firstWhere((opt) => opt.name == name).id;
    } catch (e) {
      return null;
    }
  }

  int? getStageIdByName(String name) {
    try {
      final option = stageOptions.firstWhere((opt) => opt.name == name);
      if (option.id == 0) {
        print(
          'getStageIdByName: Stage "$name" has invalid ID: ${option.id}. Available stages: ${stageOptions.map((e) => '${e.id}:${e.name}').toList()}',
        );
        return null;
      }
      return option.id;
    } catch (e) {
      print(
        'getStageIdByName: Stage "$name" not found. Available stages: ${stageOptions.map((e) => '${e.id}:${e.name}').toList()}',
      );
      return null;
    }
  }

  int? getGroupIdByName(String name) {
    try {
      final option = groupOptions.firstWhere((opt) => opt.name == name);
      if (option.id == 0) {
        print(
          'getGroupIdByName: Group "$name" has invalid ID: ${option.id}. Available groups: ${groupOptions.map((e) => '${e.id}:${e.name}').toList()}',
        );
        return null;
      }
      return option.id;
    } catch (e) {
      print(
        'getGroupIdByName: Group "$name" not found. Available groups: ${groupOptions.map((e) => '${e.id}:${e.name}').toList()}',
      );
      return null;
    }
  }

  // Helper methods to get name from ID
  String? getPrizeNameById(int id) {
    try {
      return prizeOptions.firstWhere((opt) => opt.id == id).name;
    } catch (e) {
      return null;
    }
  }

  String? getCategoryNameById(int id) {
    try {
      return categoryOptions.firstWhere((opt) => opt.id == id).name;
    } catch (e) {
      return null;
    }
  }

  String? getStageNameById(int id) {
    try {
      return stageOptions.firstWhere((opt) => opt.id == id).name;
    } catch (e) {
      return null;
    }
  }

  String? getGroupNameById(int id) {
    try {
      return groupOptions.firstWhere((opt) => opt.id == id).name;
    } catch (e) {
      return null;
    }
  }

  // Toggle prize selection (by name for UI, stores ID internally)
  void togglePrize(String prizeName) {
    final prizeId = getPrizeIdByName(prizeName);
    if (prizeId == null) return;

    if (selectedPrizeIds.contains(prizeId)) {
      selectedPrizeIds.remove(prizeId);
    } else {
      selectedPrizeIds.add(prizeId);
    }
  }

  // Add custom prize (by name for UI, stores ID internally)
  Future<bool> addCustomPrize(String prizeName, {String? description}) async {
    if (prizeName.isEmpty) return false;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _repository.createPrize(
        name: prizeName,
        description: description,
      );

      if (response.success && response.data != null) {
        // Reload only prizes to include the new one
        await reloadPrizeOptions();
        // Force UI update of options list
        prizeOptions.refresh();

        Get.snackbar('Success', 'Prize "$prizeName" created successfully');
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to create prize';
        Get.snackbar('Error', errorMessage.value);
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error creating prize: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Toggle category selection (by name for UI, stores ID internally)
  void toggleCategory(String categoryName) {
    final categoryId = getCategoryIdByName(categoryName);
    if (categoryId == null) return;

    final categoryIdStr = categoryId.toString();
    if (selectedCategoryIds.contains(categoryId)) {
      selectedCategoryIds.remove(categoryId);
      categoryAmounts.remove(categoryIdStr);
    } else {
      selectedCategoryIds.add(categoryId);
      categoryAmounts[categoryIdStr] = 0.0;
    }
  }

  // Add custom category (by name for UI, stores ID internally)
  Future<bool> addCustomCategory(
    String categoryName, {
    String? description,
  }) async {
    if (categoryName.isEmpty) return false;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _repository.createCategory(
        name: categoryName,
        description: description,
      );

      if (response.success && response.data != null) {
        // Reload only categories to include the new one
        await reloadCategoryOptions();
        // Force UI update of options list
        categoryOptions.refresh();

        Get.snackbar(
          'Success',
          'Category "$categoryName" created successfully',
        );
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to create category';
        Get.snackbar('Error', errorMessage.value);
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error creating category: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update category amount (by name for UI, stores with ID as key)
  void updateCategoryAmount(String categoryName, double amount) {
    final categoryId = getCategoryIdByName(categoryName);
    if (categoryId != null) {
      categoryAmounts[categoryId.toString()] = amount;
    }
  }

  // Toggle stage selection (by name for UI, stores ID internally)
  void toggleStage(String stageName) {
    final stageId = getStageIdByName(stageName);
    if (stageId == null) return;

    final stageIdStr = stageId.toString();
    if (selectedStageIds.contains(stageId)) {
      selectedStageIds.remove(stageId);
      stageGroups.remove(stageIdStr);
    } else {
      selectedStageIds.add(stageId);
      // Initialize with default mapping if available and not already set
      if (!stageGroups.containsKey(stageIdStr)) {
        if (defaultStageMappings.containsKey(stageName)) {
          // Check if default groups are already assigned to other stages
          final defaultGroupNames = defaultStageMappings[stageName]!;
          final defaultGroupIds = defaultGroupNames
              .map((name) => getGroupIdByName(name))
              .where((id) => id != null)
              .cast<int>()
              .where((groupId) {
                // Check if group is not assigned to any other stage
                return !stageGroups.values.any(
                  (groupIds) => groupIds.contains(groupId),
                );
              })
              .toList();
          stageGroups[stageIdStr] = defaultGroupIds;
        } else {
          // For custom stages, initialize with empty list
          stageGroups[stageIdStr] = [];
        }
      }
    }
  }

  // Add custom stage (by name for UI, stores ID internally)
  Future<bool> addCustomStage(String stageName, {String? description}) async {
    if (stageName.isEmpty) return false;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _repository.createStage(
        name: stageName,
        description: description,
      );

      if (response.success && response.data != null) {
        // Reload only stages to include the new one
        await reloadStageOptions();
        // Force UI update of options list
        stageOptions.refresh();

        Get.snackbar('Success', 'Stage "$stageName" created successfully');
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to create stage';
        Get.snackbar('Error', errorMessage.value);
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error creating stage: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Set groups for a stage (by name for UI, stores with ID as key)
  void setStageGroups(String stageName, List<String> groupNames) {
    final stageId = getStageIdByName(stageName);
    if (stageId == null || stageId == 0) {
      print(
        'setStageGroups: Stage name "$stageName" not found or invalid. Available stages: ${stageOptions.map((e) => '${e.id}:${e.name}').toList()}',
      );
      return;
    }

    final groupIds = groupNames
        .map((name) {
          final id = getGroupIdByName(name);
          if (id == null || id == 0) {
            print(
              'setStageGroups: Group name "$name" not found or invalid. Available groups: ${groupOptions.map((e) => '${e.id}:${e.name}').toList()}',
            );
          }
          return id;
        })
        .where((id) => id != null && id != 0)
        .cast<int>()
        .toList();

    stageGroups[stageId.toString()] = groupIds;
    print(
      'setStageGroups: Set groups for stage "$stageName" (ID: $stageId): $groupIds',
    );
  }

  // Get groups for a stage (by name, returns names)
  List<String> getStageGroups(String stageName) {
    if (stageName.isEmpty) {
      print('getStageGroups: Empty stage name');
      return [];
    }

    final stageId = getStageIdByName(stageName);
    if (stageId == null) {
      print(
        'getStageGroups: Stage name "$stageName" not found. Available stages: ${stageOptions.map((e) => e.name).toList()}',
      );
      return [];
    }

    print('getStageGroups: Stage "$stageName" -> ID: $stageId');
    print('getStageGroups: Current stageGroups map: $stageGroups');

    final groupIds = stageGroups[stageId.toString()] ?? [];
    print('getStageGroups: Group IDs for stage $stageId: $groupIds');

    if (groupIds.isEmpty) {
      print('getStageGroups: No groups assigned to stage $stageId');
      return [];
    }

    // Convert group IDs to names
    final groupNames = groupIds
        .map((id) {
          final name = getGroupNameById(id);
          if (name == null) {
            print(
              'getStageGroups: Group ID $id not found. Available groups: ${groupOptions.map((e) => '${e.id}:${e.name}').toList()}',
            );
          }
          return name;
        })
        .where((name) => name != null)
        .cast<String>()
        .toList();

    print(
      'getStageGroups: Final group names for stage "$stageName": $groupNames',
    );
    return groupNames;
  }

  // Get all available groups (all groups are available for all stages)
  List<String> getAllAvailableGroups() {
    return List<String>.from(groupOptionNames);
  }

  // Add custom group (by name for UI, stores ID internally)
  Future<bool> addCustomGroup(String groupName, {String? description}) async {
    if (groupName.isEmpty) return false;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _repository.createGroup(
        name: groupName,
        description: description,
      );

      if (response.success && response.data != null) {
        // Reload only groups to include the new one
        await reloadGroupOptions();
        // Force UI update of options list
        groupOptions.refresh();

        Get.snackbar('Success', 'Group "$groupName" created successfully');
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to create group';
        Get.snackbar('Error', errorMessage.value);
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error creating group: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Check if a group is assigned to another stage (by name)
  String? getStageForGroup(String groupName) {
    final groupId = getGroupIdByName(groupName);
    if (groupId == null) return null;

    for (final entry in stageGroups.entries) {
      if (entry.value.contains(groupId)) {
        final stageId = int.tryParse(entry.key);
        if (stageId != null) {
          return getStageNameById(stageId);
        }
      }
    }
    return null;
  }

  // Check if a group is available (not assigned to any other stage)
  bool isGroupAvailable(String groupName, String currentStageName) {
    final groupId = getGroupIdByName(groupName);
    final currentStageId = getStageIdByName(currentStageName);
    if (groupId == null || currentStageId == null) return false;

    final assignedStage = getStageForGroup(groupName);
    return assignedStage == null || assignedStage == currentStageName;
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String? validateEventStartDate(
    DateTime? value, {
    bool requireWhenEmpty = false,
  }) {
    if (value == null) {
      if (requireWhenEmpty ||
          shouldShowCompetitionDateError(dateFieldStart)) {
        return 'Please select event start date';
      }
      return null;
    }
    final start = _dateOnly(value);
    final end = eventEndDate.value;
    if (end != null && _dateOnly(end).isBefore(start)) {
      return 'Start date must be on or before end date';
    }
    final ad = displayAdFrom.value;
    if (ad != null && _dateOnly(ad).isAfter(start)) {
      return 'Start date must be on or after display ad date';
    }
    return null;
  }

  String? validateEventEndDate(
    DateTime? value, {
    bool requireWhenEmpty = false,
  }) {
    if (value == null) {
      if (requireWhenEmpty || shouldShowCompetitionDateError(dateFieldEnd)) {
        return 'Please select event end date';
      }
      return null;
    }
    final end = _dateOnly(value);
    final start = eventStartDate.value;
    if (start != null && end.isBefore(_dateOnly(start))) {
      return 'End date must be on or after start date';
    }
    return null;
  }

  String? validateDisplayAdFrom(
    DateTime? value, {
    bool requireWhenEmpty = false,
  }) {
    if (value == null) {
      if (requireWhenEmpty ||
          shouldShowCompetitionDateError(dateFieldDisplayAd)) {
        return 'Please select display ad from date';
      }
      return null;
    }
    final ad = _dateOnly(value);
    final start = eventStartDate.value;
    if (start != null && ad.isAfter(_dateOnly(start))) {
      return 'Display ad date must be on or before event start date';
    }
    return null;
  }

  String? validateCompetitionDates({bool forSubmit = false}) {
    return validateEventStartDate(
          eventStartDate.value,
          requireWhenEmpty: forSubmit,
        ) ??
        validateEventEndDate(
          eventEndDate.value,
          requireWhenEmpty: forSubmit,
        ) ??
        validateDisplayAdFrom(
          displayAdFrom.value,
          requireWhenEmpty: forSubmit,
        );
  }

  void alertCompetitionDateValidationIssue() {
    final message = validateCompetitionDates();
    if (message == null) return;
    final hasAnyDate =
        eventStartDate.value != null ||
        eventEndDate.value != null ||
        displayAdFrom.value != null;
    if (!hasAnyDate) return;
    Get.snackbar(
      'Invalid date',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  // Create competition
  Future<bool> createCompetition() async {
    try {
      hasAttemptedSubmit.value = true;
      notifyCompetitionDatesChanged();
      if (!formKey.currentState!.validate()) {
        return false;
      }

      final dateError = validateCompetitionDates(forSubmit: true);
      if (dateError != null) {
        errorMessage.value = dateError;
        Get.snackbar('Error', dateError);
        return false;
      }

      if (participantsPerStage.value <= 0) {
        errorMessage.value = 'Please select participants per stage';
        Get.snackbar('Error', errorMessage.value);
        return false;
      }

      if (selectedCategoryIds.isEmpty) {
        errorMessage.value = 'Please select at least one category';
        Get.snackbar('Error', errorMessage.value);
        return false;
      }

      if (selectedStageIds.isEmpty) {
        errorMessage.value = 'Please select at least one stage';
        Get.snackbar('Error', errorMessage.value);
        return false;
      }

      if (selectedPrizeIds.isEmpty) {
        errorMessage.value = 'Please select at least one prize';
        Get.snackbar('Error', errorMessage.value);
        return false;
      }

      // Validate brochure upload
      if (!validateBrochure()) {
        Get.snackbar('Error', errorMessage.value);
        return false;
      }

      isLoading.value = true;
      errorMessage.value = '';

      final competition = CompetitionModel(
        competitionName: competitionNameController.text.trim(),
        description: descriptionController.text.trim(),
        address: addressController.text.trim(),
        eventStartDate: eventStartDate.value!,
        eventEndDate: eventEndDate.value!,
        displayAdFrom: displayAdFrom.value,
        spotRegistration: spotRegistration.value,
        participantsPerStage: participantsPerStage.value > 0
            ? participantsPerStage.value
            : null,
        minimumMarks: minimumMarks.value > 0 ? minimumMarks.value : null,
        maximumMarks: maximumMarks.value > 0 ? maximumMarks.value : null,
        prizeIds: selectedPrizeIds.where((id) => id > 0).toList(),
        categoryIds: selectedCategoryIds.where((id) => id > 0).toList(),
        categoryAmounts: Map<String, double>.from(categoryAmounts),
        stageIds: selectedStageIds.where((id) => id > 0).toList(),
        stageGroups: Map<String, List<int>>.from(stageGroups),
      );

      final response = await _repository.createCompetition(
        competition: competition,
        brochureFile: brochureFile.value,
        brochureFileLocal: brochureFileLocal.value,
        brochureBytes: brochureBytes.value,
      );

      if (response.success && response.data != null) {
        lastSavedCompetitionForQr.value = response.data;
        await loadCompetitions(resetPage: true);
        clearForm();
        Get.snackbar('Success', 'Competition created successfully');
        toggleViewMode(true);
        return true;
      } else {
        lastSavedCompetitionForQr.value = null;
        errorMessage.value = response.message ?? 'Failed to create competition';
        Get.snackbar('Error', errorMessage.value);
        return false;
      }
    } catch (e) {
      lastSavedCompetitionForQr.value = null;
      errorMessage.value = 'Error creating competition: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void clearLastSavedCompetitionForQr() {
    lastSavedCompetitionForQr.value = null;
  }

  // Update competition
  Future<bool> updateCompetition() async {
    try {
      if (competitionToEdit.value == null) {
        errorMessage.value = 'No competition selected for update';
        Get.snackbar('Error', errorMessage.value);
        return false;
      }

      hasAttemptedSubmit.value = true;
      notifyCompetitionDatesChanged();
      if (!formKey.currentState!.validate()) {
        return false;
      }

      final dateError = validateCompetitionDates(forSubmit: true);
      if (dateError != null) {
        errorMessage.value = dateError;
        Get.snackbar('Error', dateError);
        return false;
      }

      if (participantsPerStage.value <= 0) {
        errorMessage.value = 'Please select participants per stage';
        Get.snackbar('Error', errorMessage.value);
        return false;
      }

      if (selectedCategoryIds.isEmpty) {
        errorMessage.value = 'Please select at least one category';
        Get.snackbar('Error', errorMessage.value);
        return false;
      }

      if (selectedStageIds.isEmpty) {
        errorMessage.value = 'Please select at least one stage';
        Get.snackbar('Error', errorMessage.value);
        return false;
      }

      if (selectedPrizeIds.isEmpty) {
        errorMessage.value = 'Please select at least one prize';
        Get.snackbar('Error', errorMessage.value);
        return false;
      }

      // Brochure validation - optional for update (only if new file is selected)
      final hasNewBrochure =
          brochureFile.value != null ||
          brochureFileLocal.value != null ||
          brochureBytes.value != null;

      isLoading.value = true;
      errorMessage.value = '';

      final competition = CompetitionModel(
        id: competitionToEdit.value!.id,
        competitionName: competitionNameController.text.trim(),
        description: descriptionController.text.trim(),
        address: addressController.text.trim(),
        eventStartDate: eventStartDate.value!,
        eventEndDate: eventEndDate.value!,
        displayAdFrom: displayAdFrom.value,
        spotRegistration: spotRegistration.value,
        participantsPerStage: participantsPerStage.value > 0
            ? participantsPerStage.value
            : null,
        minimumMarks: minimumMarks.value > 0 ? minimumMarks.value : null,
        maximumMarks: maximumMarks.value > 0 ? maximumMarks.value : null,
        prizeIds: selectedPrizeIds.where((id) => id > 0).toList(),
        categoryIds: selectedCategoryIds.where((id) => id > 0).toList(),
        categoryAmounts: Map<String, double>.from(categoryAmounts),
        stageIds: selectedStageIds.where((id) => id > 0).toList(),
        stageGroups: Map<String, List<int>>.from(stageGroups),
      );

      final response = await _repository.updateCompetition(
        competition: competition,
        brochureFile: hasNewBrochure ? brochureFile.value : null,
        brochureFileLocal: hasNewBrochure ? brochureFileLocal.value : null,
        brochureBytes: hasNewBrochure ? brochureBytes.value : null,
      );

      if (response.success) {
        if (response.data != null) {
          competitionToEdit.value = response.data;
        }
        // Update timestamp to force brochure reload after update
        brochureUpdateTimestamp.value = DateTime.now().millisecondsSinceEpoch;

        if (hasNewBrochure) {
          brochureFile.value = null;
          brochureFileLocal.value = null;
          brochureBytes.value = null;
        }

        await loadCompetitions(resetPage: false);
        clearForm();
        Get.snackbar('Success', 'Competition updated successfully');
        toggleViewMode(true);
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to update competition';
        Get.snackbar('Error', errorMessage.value);
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error updating competition: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Load competitions list
  Future<void> loadCompetitions({bool resetPage = false}) async {
    await _yieldPastBuildIfNeeded();
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Reset to first page if requested
      if (resetPage) {
        currentPage.value = 1;
      }

      final response = await _repository.getAllCompetitions(
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        status: selectedFilter.value.isNotEmpty ? selectedFilter.value : null,
        page: currentPage.value > 0
            ? currentPage.value - 1
            : 0, // API uses 0-based indexing
        limit: itemsPerPage.value,
        sortBy: sortBy.value,
        order: sortOrder.value,
      );

      if (response.success && response.data != null) {
        final listResponse = response.data!;
        competitions.value = listResponse.competitions;

        // Update pagination info from API response
        if (listResponse.pagination != null) {
          final pagination = listResponse.pagination!;
          currentPage.value =
              (pagination['page'] as int? ?? 0) + 1; // Convert to 1-based
          totalItems.value = pagination['total'] as int? ?? 0;
          totalPages.value = pagination['totalPages'] as int? ?? 0;
          itemsPerPage.value = pagination['limit'] as int? ?? 20;
        } else {
          // Fallback: estimate pagination if not provided
          if (competitions.isNotEmpty) {
            if (competitions.length < itemsPerPage.value) {
              totalPages.value = currentPage.value;
            } else {
              totalPages.value = currentPage.value + 1;
            }
            totalItems.value = competitions.length;
          } else {
            totalPages.value = 0;
            totalItems.value = 0;
          }
        }

        // If no competitions returned and not first page, go back to first page
        if (competitions.isEmpty && currentPage.value > 1) {
          currentPage.value = 1;
          return loadCompetitions();
        }
      } else {
        errorMessage.value = response.message ?? 'Failed to fetch competitions';
        competitions.value = [];
        totalPages.value = 0;
        totalItems.value = 0;
      }
    } catch (e) {
      errorMessage.value = 'Error fetching competitions: ${e.toString()}';
      competitions.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  /// When [loadCompetitions] is started from [StatelessWidget.build], the HTTP
  /// stack on web can resolve in the same frame; GetX then notifies [Obx]
  /// during build ("markNeedsBuild called during build").
  static Future<void> _yieldPastBuildIfNeeded() async {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      return;
    }
    await SchedulerBinding.instance.endOfFrame;
  }

  // Go to next page
  void nextPage() {
    if (currentPage.value < totalPages.value) {
      currentPage.value++;
      loadCompetitions();
    }
  }

  // Go to previous page
  void previousPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
      loadCompetitions();
    }
  }

  // Go to specific page
  void goToPage(int page) {
    if (page >= 1 && page <= totalPages.value) {
      currentPage.value = page;
      loadCompetitions();
    }
  }

  // Update sort
  void updateSort(String newSortBy, String newOrder) {
    sortBy.value = newSortBy;
    sortOrder.value = newOrder;
    loadCompetitions(resetPage: true);
  }

  // Update search query and reload
  void updateSearch(String query) {
    searchQuery.value = query;
    loadCompetitions(resetPage: true);
  }

  // Update filter and reload
  void updateFilter(String filter) {
    selectedFilter.value = filter;
    loadCompetitions(resetPage: true);
  }

  // Clear search
  void clearSearch() {
    searchController.clear();
    updateSearch('');
  }

  // Load competition data into form for editing/viewing
  Future<void> loadCompetitionForEdit(
    CompetitionModel competition, {
    bool isView = false,
  }) async {
    // Ensure options are loaded before converting IDs to names
    if (stageOptions.isEmpty || groupOptions.isEmpty) {
      print('loadCompetitionForEdit: Options not loaded yet, loading now...');
      await loadOptions();
    }

    _loadCompetitionData(competition, isView: isView);
  }

  void _loadCompetitionData(
    CompetitionModel competition, {
    bool isView = false,
  }) {
    isEditMode.value = !isView; // true for edit, false for view
    isViewMode.value = isView; // true for view-only
    competitionToEdit.value = competition;

    // Load data into form fields
    competitionNameController.text = competition.competitionName;
    descriptionController.text = competition.description;
    addressController.text = competition.address;
    eventStartDate.value = competition.eventStartDate;
    eventEndDate.value = competition.eventEndDate;
    displayAdFrom.value = competition.displayAdFrom;
    spotRegistration.value = competition.spotRegistration;
    participantsPerStage.value = competition.participantsPerStage ?? 0;
    minimumMarks.value = competition.minimumMarks ?? 0;
    maximumMarks.value = competition.maximumMarks ?? 0;
    // Load IDs if available, otherwise convert names to IDs
    if (competition.prizeIds != null && competition.prizeIds!.isNotEmpty) {
      selectedPrizeIds.value = List<int>.from(competition.prizeIds!);
    } else if (competition.prizes != null && competition.prizes!.isNotEmpty) {
      // Convert names to IDs
      selectedPrizeIds.value = competition.prizes!
          .map((name) => getPrizeIdByName(name))
          .where((id) => id != null)
          .cast<int>()
          .toList();
    } else {
      selectedPrizeIds.clear();
    }

    if (competition.categoryIds != null &&
        competition.categoryIds!.isNotEmpty) {
      selectedCategoryIds.value = List<int>.from(competition.categoryIds!);
      // Load category amounts with IDs as keys
      // API might return categoryAmounts with names or IDs as keys, convert to IDs
      if (competition.categoryAmounts != null &&
          competition.categoryAmounts!.isNotEmpty) {
        categoryAmounts.value = {};
        for (final entry in competition.categoryAmounts!.entries) {
          final keyStr = entry.key.toString();
          int? categoryId;

          // Try to parse as int first (if it's already an ID)
          final parsedId = int.tryParse(keyStr);
          if (parsedId != null && selectedCategoryIds.contains(parsedId)) {
            // Key is already a category ID
            categoryId = parsedId;
          } else {
            // Key is likely a category name, convert to ID
            categoryId = getCategoryIdByName(keyStr);
          }

          if (categoryId != null) {
            categoryAmounts[categoryId.toString()] = entry.value;
          }
        }
      } else {
        categoryAmounts.clear();
      }
    } else if (competition.categories != null &&
        competition.categories!.isNotEmpty) {
      // Convert names to IDs
      selectedCategoryIds.value = competition.categories!
          .map((name) => getCategoryIdByName(name))
          .where((id) => id != null)
          .cast<int>()
          .toList();
      // Convert category amounts from names to IDs
      if (competition.categoryAmounts != null) {
        categoryAmounts.value = {};
        for (final entry in competition.categoryAmounts!.entries) {
          final categoryId = getCategoryIdByName(entry.key);
          if (categoryId != null) {
            categoryAmounts[categoryId.toString()] = entry.value;
          }
        }
      } else {
        categoryAmounts.clear();
      }
    } else {
      selectedCategoryIds.clear();
      categoryAmounts.clear();
    }

    if (competition.stageIds != null && competition.stageIds!.isNotEmpty) {
      selectedStageIds.value = List<int>.from(competition.stageIds!);
      // Load stage groups with IDs
      // API returns stageGroupsById with stage IDs as keys (already in correct format)
      if (competition.stageGroups != null &&
          competition.stageGroups!.isNotEmpty) {
        // Since stageGroupsById already has stage IDs as keys, we can use them directly
        stageGroups.value = Map<String, List<int>>.from(
          competition.stageGroups!,
        );
        print('_loadCompetitionData: Loaded stageGroups: $stageGroups');
        print('_loadCompetitionData: Selected stage IDs: $selectedStageIds');
        print(
          '_loadCompetitionData: Available stage options: ${stageOptions.map((e) => '${e.id}:${e.name}').toList()}',
        );
        print(
          '_loadCompetitionData: Available group options: ${groupOptions.map((e) => '${e.id}:${e.name}').toList()}',
        );
      } else {
        stageGroups.clear();
        print('_loadCompetitionData: No stageGroups found in competition data');
      }
    } else if (competition.stages != null && competition.stages!.isNotEmpty) {
      // Convert names to IDs
      selectedStageIds.value = competition.stages!
          .map((name) => getStageIdByName(name))
          .where((id) => id != null)
          .cast<int>()
          .toList();
      // Convert stage groups from names to IDs
      if (competition.stageGroups != null) {
        stageGroups.value = {};
        for (final entry in competition.stageGroups!.entries) {
          final stageId = getStageIdByName(entry.key);
          if (stageId != null) {
            // Convert group names to IDs
            final groupIds = (entry.value as List)
                .map((item) {
                  if (item is String) {
                    return getGroupIdByName(item);
                  } else if (item is int) {
                    return item;
                  }
                  return null;
                })
                .where((id) => id != null)
                .cast<int>()
                .toList();
            stageGroups[stageId.toString()] = groupIds;
          }
        }
      } else {
        stageGroups.clear();
      }
    } else {
      selectedStageIds.clear();
      stageGroups.clear();
    }

    // Load brochure URL if available
    if (competition.brochureUrl != null &&
        competition.brochureUrl!.isNotEmpty) {
      brochureUrl.value = competition.brochureUrl!;
    }

    // Switch to create view
    isListView.value = false;
    _refreshFormKeys();
  }

  // View competition details - redirect to form with data (read-only)
  Future<void> viewCompetition(
    BuildContext context,
    CompetitionModel competition,
  ) async {
    await loadCompetitionForEdit(competition, isView: true);
  }

  // Edit competition - redirect to form with data (editable)
  Future<void> editCompetition(
    BuildContext context,
    CompetitionModel competition,
  ) async {
    await loadCompetitionForEdit(competition, isView: false);
  }

  // Delete competition — DELETE /competition/{id}
  void deleteCompetition(BuildContext context, CompetitionModel competition) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Competition'),
        content: Text(
          'Are you sure you want to delete "${competition.competitionName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final id = competition.id?.trim();
              if (id == null || id.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid competition ID'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              isLoading.value = true;
              try {
                final result = await _repository.deleteCompetition(id);
                if (result.success) {
                  await loadCompetitions();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result.message ?? 'Competition deleted successfully',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result.message ?? 'Failed to delete competition',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } finally {
                isLoading.value = false;
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Get filtered competitions (now handled by API, but kept for backward compatibility)
  List<CompetitionModel> get filteredCompetitions {
    // API now handles filtering, so just return the competitions list
    return List<CompetitionModel>.from(competitions);
  }

  // Toggle view mode
  void toggleViewMode(bool isList) {
    isListView.value = isList;
    if (isList) {
      // Reset edit mode when switching to list view
      isEditMode.value = false;
      competitionToEdit.value = null;
      loadCompetitions();
    } else {
      _refreshFormKeys();
      // Clear form when switching to create view (if not in edit mode)
      if (!isEditMode.value) {
        clearForm(refreshFormKeys: false);
      }
    }
  }

  // Clear form
  void clearForm({bool refreshFormKeys = true}) {
    if (refreshFormKeys) {
      _refreshFormKeys();
    }

    // Clear text controllers first
    competitionNameController.clear();
    descriptionController.clear();
    addressController.clear();

    // Clear reactive values
    eventStartDate.value = null;
    eventEndDate.value = null;
    displayAdFrom.value = null;
    spotRegistration.value = false;
    participantsPerStage.value = 0;
    minimumMarks.value = 0;
    maximumMarks.value = 0;
    selectedPrizeIds.clear();
    selectedCategoryIds.clear();
    categoryAmounts.clear();
    selectedStageIds.clear();
    stageGroups.clear();
    brochureFile.value = null;
    brochureFileLocal.value = null;
    brochureBytes.value = null;
    brochureUrl.value = '';
    errorMessage.value = '';
    hasAttemptedSubmit.value = false;
    clearCompetitionDateFieldTouches();
    isEditMode.value = false;
    isViewMode.value = false;
    competitionToEdit.value = null;
  }
}
