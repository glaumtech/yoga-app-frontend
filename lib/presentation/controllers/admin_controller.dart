import 'package:get/get.dart';
import '../../data/models/participant_model.dart';
import '../controllers/event_controller.dart';
import '../controllers/participant_controller.dart';

class AdminController extends GetxController {
  final EventController _eventController = Get.find<EventController>();
  final ParticipantController _participantController =
      Get.find<ParticipantController>();

  final RxInt totalRegistrations = 0.obs;
  final RxInt totalEvents = 0.obs;
  final RxInt activeEvents = 0.obs;
  final RxInt pendingRegistrations = 0.obs;
  final RxList<ParticipantModel> recentRegistrations = <ParticipantModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;

      // Load events
      await _eventController.loadEvents();
      totalEvents.value = _eventController.events.length;
      activeEvents.value = _eventController.events
          .where((e) => e.active)
          .length;

      // Load participants from all events for dashboard
      // Note: Dashboard now shows data from events only
      // Participants are loaded per event, so we aggregate from all events
      totalRegistrations.value = 0;
      recentRegistrations.clear();

      // Load participants from each event
      for (final event in _eventController.events) {
        if (event.id != null) {
          await _participantController.loadParticipantsByEventId(
            event.id!,
            resetPage: true,
          );
          totalRegistrations.value += _participantController.totalItems.value;
          if (recentRegistrations.length < 5) {
            recentRegistrations.addAll(
              _participantController.participants.take(
                5 - recentRegistrations.length,
              ),
            );
          }
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load dashboard data: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshDashboard() async {
    await loadDashboardData();
  }
}
