import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/user_management_repository.dart';
import '../../data/models/user_management_model.dart';
import '../../data/models/event_model.dart';

class UserManagementController extends GetxController {
  final UserManagementRepository _repository = UserManagementRepository();

  // State
  final RxList<UserManagementModel> users = <UserManagementModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isListView = false.obs;

  // Form Controllers
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final cellController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // Form State
  final RxString selectedType = 'SUB ADMIN'.obs;
  final RxString selectedEventId = ''.obs;
  final RxString selectedEventName = ''.obs;
  final RxList<String> selectedPermissions = <String>[].obs;
  final RxList<String> selectedStages = <String>[].obs;
  final RxList<String> selectedCategories = <String>[].obs;
  final Rx<File?> photoFile = Rx<File?>(null);
  final Rx<Uint8List?> photoBytes = Rx<Uint8List?>(null);
  final RxString photoUrl = ''.obs;

  // Volunteer table state
  final RxList<VolunteerRow> volunteerRows = <VolunteerRow>[].obs;

  // Available options
  static const List<String> userTypes = [
    'SUB ADMIN',
    'SPOT REG ADMIN(S)',
    'JURY(S)',
    'VOLUNTEERS',
  ];

  static const List<String> permissions = ['CREATE', 'EDIT', 'DELETE'];
  static const List<String> stages = [
    'STAGE 1',
    'STAGE 2',
    'STAGE 3',
    'STAGE 4',
    'STAGE 5',
    'STAGE 6',
  ];
  static const List<String> categories = ['COMMON', 'SPECIAL', 'CHAMPIONS'];

  @override
  void onInit() {
    super.onInit();
    // Initialize with 4 volunteer rows
    volunteerRows.value = List.generate(4, (index) => VolunteerRow());
    // Load dummy data
    _loadDummyData();
  }

  void toggleViewMode(bool showList) {
    isListView.value = showList;
  }

  // Load dummy data for testing
  void _loadDummyData() {
    users.value = [
      UserManagementModel(
        id: '1',
        name: 'John Doe',
        type: 'SUB ADMIN',
        eventId: 1,
        eventName: 'Yoga Championship 2024',
        permissions: ['CREATE', 'EDIT', 'DELETE'],
        stages: [],
        categories: [],
        photoUrl: null,
      ),
      UserManagementModel(
        id: '2',
        name: 'Jane Smith',
        type: 'SPOT REG ADMIN(S)',
        eventId: 1,
        eventName: 'Yoga Championship 2024',
        permissions: ['CREATE', 'EDIT'],
        stages: [],
        categories: [],
        photoUrl: null,
      ),
      UserManagementModel(
        id: '3',
        name: 'Robert Johnson',
        type: 'JURY(S)',
        eventId: 1,
        eventName: 'Yoga Championship 2024',
        permissions: [],
        stages: ['STAGE 1', 'STAGE 2', 'STAGE 3'],
        categories: ['COMMON', 'SPECIAL'],
        photoUrl: null,
      ),
      UserManagementModel(
        id: '4',
        name: 'Emily Davis',
        type: 'VOLUNTEERS',
        eventId: 1,
        eventName: 'Yoga Championship 2024',
        permissions: [],
        stages: [],
        categories: [],
        cell: '9876543210',
        volunteerNo: 'VOL-001',
        photoUrl: null,
      ),
      UserManagementModel(
        id: '5',
        name: 'Michael Brown',
        type: 'VOLUNTEERS',
        eventId: 1,
        eventName: 'Yoga Championship 2024',
        permissions: [],
        stages: [],
        categories: [],
        cell: '9876543211',
        volunteerNo: 'VOL-002',
        photoUrl: null,
      ),
      UserManagementModel(
        id: '6',
        name: 'Sarah Wilson',
        type: 'SUB ADMIN',
        eventId: 2,
        eventName: 'Regional Yoga Competition',
        permissions: ['CREATE', 'DELETE'],
        stages: [],
        categories: [],
        photoUrl: null,
      ),
    ];
  }

  @override
  void onClose() {
    nameController.dispose();
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
          user.type.toLowerCase().contains(query) ||
          (user.eventName?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  // Load users
  Future<void> loadUsers({int? eventId}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _repository.getAllUsers(
        eventId: eventId != null && eventId > 0 ? eventId : null,
      );

      if (response.success && response.data != null) {
        users.value = response.data!;
      } else {
        errorMessage.value = response.message ?? 'Failed to load users';
      }
    } catch (e) {
      errorMessage.value = 'Error loading users: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  // Set selected event
  void setSelectedEvent(EventModel? event) {
    if (event != null && event.id != null) {
      selectedEventId.value = event.id!;
      selectedEventName.value = event.title;
    } else {
      selectedEventId.value = '';
      selectedEventName.value = '';
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

  // Pick photo
  Future<void> pickPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          // For web, read bytes
          final bytes = await image.readAsBytes();
          photoBytes.value = bytes;
          photoUrl.value =
              'web_image'; // Placeholder to indicate image is selected
        } else {
          // For mobile/desktop, use File
          photoFile.value = File(image.path);
          photoUrl.value = image.path;
        }
      }
    } catch (e) {
      errorMessage.value = 'Error picking image: ${e.toString()}';
    }
  }

  // Pick photo for volunteer row
  Future<void> pickPhotoForVolunteer(VolunteerRow row) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          // For web, read bytes
          final bytes = await image.readAsBytes();
          row.photoBytes.value = bytes;
          row.photoUrl.value =
              'web_image'; // Placeholder to indicate image is selected
        } else {
          // For mobile/desktop, use File
          row.photoFile.value = File(image.path);
          row.photoUrl.value = image.path;
        }
      }
    } catch (e) {
      errorMessage.value = 'Error picking image: ${e.toString()}';
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

      isLoading.value = true;
      errorMessage.value = '';

      final eventIdInt = int.tryParse(selectedEventId.value);
      final user = UserManagementModel(
        name: nameController.text.trim(),
        password: generateRandomPassword(),
        type: selectedType.value,
        eventId: eventIdInt,
        eventName: selectedEventName.value.isNotEmpty
            ? selectedEventName.value
            : null,
        permissions: selectedPermissions.toList(),
        stages: selectedStages.toList(),
        categories: selectedCategories.toList(),
        cell: cellController.text.trim().isNotEmpty
            ? cellController.text.trim()
            : null,
      );

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

      final volunteers = validVolunteers.asMap().entries.map((entry) {
        final index = entry.key;
        final row = entry.value;
        final eventIdInt = int.tryParse(selectedEventId.value);
        return UserManagementModel(
          name: row.nameController.text.trim(),
          password: generateRandomPassword(),
          type: 'VOLUNTEERS',
          eventId: eventIdInt,
          eventName: selectedEventName.value.isNotEmpty
              ? selectedEventName.value
              : null,
          cell: row.cellController.text.trim().isNotEmpty
              ? row.cellController.text.trim()
              : null,
          volunteerNo: generateVolunteerNo(index),
        );
      }).toList();

      final eventIdInt = int.tryParse(selectedEventId.value);
      if (eventIdInt == null) {
        errorMessage.value = 'Invalid event ID';
        return false;
      }

      final response = await _repository.createVolunteers(
        volunteers: volunteers,
        eventId: eventIdInt,
      );

      if (response.success) {
        await loadUsers(eventId: eventIdInt);
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

  // Reset form
  void resetForm() {
    nameController.clear();
    passwordController.clear();
    cellController.clear();
    selectedType.value = 'SUB ADMIN';
    selectedEventId.value = '';
    selectedEventName.value = '';
    selectedPermissions.clear();
    selectedStages.clear();
    selectedCategories.clear();
    photoFile.value = null;
    photoBytes.value = null;
    photoUrl.value = '';
    volunteerRows.value = List.generate(4, (index) => VolunteerRow());
    errorMessage.value = '';
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
