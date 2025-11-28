import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/event_controller.dart';
import '../../widgets/event_card.dart';
import '../../widgets/custom_loader.dart';
import '../../widgets/primary_button.dart';

class EventsListScreen extends StatelessWidget {
  const EventsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventController = Get.find<EventController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog(context, eventController);
            },
          ),
        ],
      ),
      body: Obx(() {
        if (eventController.isLoading.value) {
          return const CustomLoader(message: 'Loading events...');
        }

        if (eventController.events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No events available',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for upcoming events',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            return Column(
              children: [
                // Filter Chips
                if (eventController.selectedCategory.value.isNotEmpty ||
                    eventController.selectedAgeGroup.value.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 24,
                      vertical: 8,
                    ),
                    color: Colors.grey[50],
                    child: Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (eventController
                                    .selectedCategory
                                    .value
                                    .isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Chip(
                                      label: Text(
                                        'Category: ${eventController.selectedCategory.value}',
                                      ),
                                      onDeleted: () {
                                        eventController.selectedCategory.value =
                                            '';
                                      },
                                    ),
                                  ),
                                if (eventController
                                    .selectedAgeGroup
                                    .value
                                    .isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Chip(
                                      label: Text(
                                        'Age: ${eventController.selectedAgeGroup.value}',
                                      ),
                                      onDeleted: () {
                                        eventController.selectedAgeGroup.value =
                                            '';
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => eventController.clearFilters(),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),

                // Events List
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => eventController.loadEvents(),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth <= 0) {
                          return const SizedBox.shrink();
                        }

                        final isMobile = constraints.maxWidth < 600;
                        final isTablet =
                            constraints.maxWidth >= 600 &&
                            constraints.maxWidth < 1024;

                        if (isMobile) {
                          // Mobile: Vertical list
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            itemCount: eventController.filteredEvents.length,
                            itemBuilder: (context, index) {
                              final event =
                                  eventController.filteredEvents[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: EventCard(
                                  event: event,
                                  onTap: () {
                                    eventController.selectEvent(event);
                                    context.push('/events/${event.id}');
                                  },
                                ),
                              );
                            },
                          );
                        } else if (isTablet) {
                          // Tablet: 2 columns
                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.85,
                                ),
                            itemCount: eventController.filteredEvents.length,
                            itemBuilder: (context, index) {
                              final event =
                                  eventController.filteredEvents[index];
                              return EventCard(
                                event: event,
                                onTap: () {
                                  eventController.selectEvent(event);
                                  context.push('/events/${event.id}');
                                },
                              );
                            },
                          );
                        } else {
                          // Desktop: 3 columns or horizontal scroll based on content
                          return GridView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: constraints.maxWidth > 1200 ? 32 : 16,
                              vertical: 16,
                            ),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                  childAspectRatio: 1,
                                ),
                            itemCount: eventController.filteredEvents.length,
                            itemBuilder: (context, index) {
                              final event =
                                  eventController.filteredEvents[index];
                              return EventCard(
                                event: event,
                                onTap: () {
                                  eventController.selectEvent(event);
                                  context.push('/events/${event.id}');
                                },
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }),
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return FloatingActionButton.extended(
            onPressed: () => _showFilterDialog(context, eventController),
            icon: const Icon(Icons.filter_list),
            label: Text(isMobile ? 'Filter' : 'Filter Events'),
            backgroundColor: AppTheme.primaryColor,
          );
        },
      ),
    );
  }

  void _showSearchDialog(BuildContext context, EventController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Events'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter search term',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            controller.searchQuery.value = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.searchQuery.value = '';
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          PrimaryButton(
            text: 'Search',
            onPressed: () => Navigator.pop(context),
            width: 100,
            height: 40,
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context, EventController controller) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Events'),
        contentPadding: EdgeInsets.all(isMobile ? 16 : 24),
        content: SizedBox(
          width: isMobile ? double.infinity : 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      [
                        AppConstants.categoryCommon,
                        AppConstants.categorySpecial,
                      ].map((category) {
                        return FilterChip(
                          label: Text(category),
                          selected:
                              controller.selectedCategory.value == category,
                          onSelected: (selected) {
                            controller.selectedCategory.value = selected
                                ? category
                                : '';
                          },
                        );
                      }).toList(),
                ),
                const SizedBox(height: 20),
                Text(
                  'Age Group',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.standards.map((standard) {
                    return FilterChip(
                      label: Text(standard),
                      selected: controller.selectedAgeGroup.value == standard,
                      onSelected: (selected) {
                        controller.selectedAgeGroup.value = selected
                            ? standard
                            : '';
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.clearFilters();
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
          PrimaryButton(
            text: 'Apply',
            onPressed: () => Navigator.pop(context),
            width: 100,
            height: 40,
          ),
        ],
      ),
    );
  }
}
