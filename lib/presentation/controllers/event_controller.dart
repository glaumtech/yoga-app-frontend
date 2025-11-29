import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/event_repository.dart';

class EventController extends GetxController {
  final EventRepository _eventRepository = EventRepository();
  final RxList<EventModel> events = <EventModel>[].obs;
  final Rx<EventModel?> selectedEvent = Rx<EventModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Filters
  final RxString selectedCategory = ''.obs;
  final RxString selectedAgeGroup = ''.obs;
  final RxString searchQuery = ''.obs;

  // Banner image picker
  final ImagePicker _imagePicker = ImagePicker();
  final Rx<XFile?> selectedBannerImage = Rx<XFile?>(null);

  @override
  void onInit() {
    super.onInit();
    loadEvents();
  }

  Future<void> loadEvents() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _eventRepository.getAllEvents();

      if (response.success && response.data != null) {
        events.value = response.data!;
      } else {
        errorMessage.value = response.message ?? 'Failed to load events';
        Get.snackbar('Error', errorMessage.value);
      }
    } catch (e) {
      errorMessage.value = 'Failed to load events: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadEventById(String id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _eventRepository.getEventById(id);

      if (response.success && response.data != null) {
        selectedEvent.value = response.data!;
      } else {
        errorMessage.value = response.message ?? 'Failed to load event';
        Get.snackbar('Error', errorMessage.value);
      }
    } catch (e) {
      errorMessage.value = 'Failed to load event: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  List<EventModel> get filteredEvents {
    var filtered = events.toList();

    if (selectedCategory.value.isNotEmpty) {
      filtered = filtered.where((event) {
        return event.categories.contains(selectedCategory.value);
      }).toList();
    }

    if (selectedAgeGroup.value.isNotEmpty) {
      filtered = filtered.where((event) {
        return event.ageGroups.contains(selectedAgeGroup.value);
      }).toList();
    }

    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((event) {
        return event.title.toLowerCase().contains(query) ||
            event.description.toLowerCase().contains(query) ||
            event.venue.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  void selectEvent(EventModel event) {
    selectedEvent.value = event;
  }

  void clearFilters() {
    selectedCategory.value = '';
    selectedAgeGroup.value = '';
    searchQuery.value = '';
  }

  Future<void> pickBannerImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        selectedBannerImage.value = image;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: ${e.toString()}');
    }
  }

  void clearBannerImage() {
    selectedBannerImage.value = null;
  }

  Future<void> createEvent(EventModel event, {XFile? bannerFile}) async {
    try {
      print('=== createEvent called ===');
      print('Event title: ${event.title}');
      print(
        'Banner file: ${bannerFile?.name ?? selectedBannerImage.value?.name ?? 'none'}',
      );

      isLoading.value = true;
      errorMessage.value = '';

      final response = await _eventRepository.createEvent(
        event: event,
        bannerFile: bannerFile ?? selectedBannerImage.value,
      );

      print('=== createEvent response received ===');
      print('Success: ${response.success}');
      print('Message: ${response.message}');

      if (response.success && response.data != null) {
        // Reload events to ensure count and list are in sync
        await loadEvents();
        clearBannerImage();
        Get.snackbar('Success', 'Event created successfully');
      } else {
        errorMessage.value = response.message ?? 'Failed to create event';
        Get.snackbar('Error', errorMessage.value);
      }
    } catch (e) {
      errorMessage.value = 'Failed to create event: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateEvent(EventModel event, {XFile? bannerFile}) async {
    try {
      if (event.id == null) {
        errorMessage.value = 'Event ID is required for update';
        Get.snackbar('Error', errorMessage.value);
        return;
      }

      isLoading.value = true;
      errorMessage.value = '';

      final response = await _eventRepository.updateEvent(
        id: event.id!,
        event: event,
        bannerFile: bannerFile ?? selectedBannerImage.value,
      );

      if (response.success && response.data != null) {
        // Reload events to ensure count and list are in sync
        await loadEvents();
        clearBannerImage();
        Get.snackbar('Success', 'Event updated successfully');
      } else {
        errorMessage.value = response.message ?? 'Failed to update event';
        Get.snackbar('Error', errorMessage.value);
      }
    } catch (e) {
      errorMessage.value = 'Failed to update event: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _eventRepository.deleteEvent(eventId);

      if (response.success) {
        // Reload events to ensure count and list are in sync
        await loadEvents();
        Get.snackbar('Success', 'Event deleted successfully');
      } else {
        errorMessage.value = response.message ?? 'Failed to delete event';
        Get.snackbar('Error', errorMessage.value);
      }
    } catch (e) {
      errorMessage.value = 'Failed to delete event: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  void reset() {
    events.clear();
    selectedEvent.value = null;
    isLoading.value = false;
    errorMessage.value = '';
    selectedCategory.value = '';
    selectedAgeGroup.value = '';
    searchQuery.value = '';
    selectedBannerImage.value = null;
  }
}
