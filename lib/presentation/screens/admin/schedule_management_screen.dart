import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/event_controller.dart';
import '../../widgets/section_header.dart';
import '../../widgets/custom_loader.dart';

class ScheduleManagementScreen extends StatelessWidget {
  const ScheduleManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventController = Get.find<EventController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Management')),
      body: Obx(() {
        if (eventController.isLoading.value) {
          return const CustomLoader(message: 'Loading schedule...');
        }

        if (eventController.events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No events scheduled',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create events to manage schedules',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Group events by date
        final eventsByDate = <DateTime, List<dynamic>>{};
        for (var event in eventController.events) {
          final date = DateTime(
            event.startDate.year,
            event.startDate.month,
            event.startDate.day,
          );
          if (!eventsByDate.containsKey(date)) {
            eventsByDate[date] = [];
          }
          eventsByDate[date]!.add(event);
        }

        final sortedDates = eventsByDate.keys.toList()..sort();

        return RefreshIndicator(
          onRefresh: () => eventController.loadEvents(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionHeader(
                title: 'Event Schedule',
                subtitle: '${eventController.events.length} events',
                showDivider: false,
              ),
              const SizedBox(height: 16),
              ...sortedDates.map((date) {
                final events = eventsByDate[date]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        DateFormat('EEEE, MMMM dd, yyyy').format(date),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    ...events.map((event) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 4,
                            height: double.infinity,
                            color: event.active
                                ? AppTheme.primaryColor
                                : Colors.grey,
                          ),
                          title: Text(
                            event.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${DateFormat('hh:mm a').format(event.startDate)} - ${DateFormat('hh:mm a').format(event.endDate)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      event.venue,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: event.active
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Active',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                )
                              : null,
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                );
              }),
            ],
          ),
        );
      }),
    );
  }
}
