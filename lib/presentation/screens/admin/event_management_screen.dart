import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/event_model.dart';
import '../../controllers/event_controller.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/custom_loader.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/event_banner_image.dart';

class EventManagementScreen extends StatelessWidget {
  const EventManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventController = Get.find<EventController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.05),
              Colors.white,
              AppTheme.secondaryColor.withOpacity(0.03),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Back Button
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () => context.pop(),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.event_note,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Event Management',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                          ),
                          Obx(
                            () => Text(
                              '${eventController.events.length} Events',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Responsive Create Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showEventForm(context, eventController),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 12 : 16,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                if (!isMobile) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    'Create',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Body Section
              Expanded(
                child: Obx(() {
                  if (eventController.isLoading.value) {
                    return const CustomLoader(message: 'Loading events...');
                  }

                  if (eventController.events.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.event_busy,
                                size: 64,
                                color: AppTheme.primaryColor.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No Events Found',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create your first event to get started',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 32),
                            PrimaryButton(
                              text: 'Create Event',
                              icon: Icons.add,
                              onPressed: () =>
                                  _showEventForm(context, eventController),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => eventController.loadEvents(),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = isMobile
                            ? 1
                            : isTablet
                            ? 2
                            : 5;
                        final padding = isMobile ? 16.0 : 24.0;

                        return GridView.builder(
                          padding: EdgeInsets.all(padding),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: isMobile ? 0.75 : 1,
                              ),
                          itemCount: eventController.events.length,
                          itemBuilder: (context, index) {
                            final event = eventController.events[index];
                            return _buildEventCard(
                              context,
                              event,
                              eventController,
                            );
                          },
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    EventModel event,
    EventController controller,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          controller.selectEvent(event);
          context.push('/events/${event.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: event.active
                  ? [Colors.white, AppTheme.primaryColor.withOpacity(0.02)]
                  : [Colors.grey[50]!, Colors.grey[100]!],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Banner Image
              if (event.id != null)
                EventBannerImage(
                  event: event,
                  height: 175,
                  fit: BoxFit.cover,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
              // Header with status badges
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: event.active
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.event,
                        color: event.active
                            ? AppTheme.primaryColor
                            : Colors.grey[600],
                        size: 18,
                      ),
                    ),
                    const Spacer(),
                    if (event.current)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 6,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Current',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 6),
                    PopupMenuButton(
                      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(
                                Icons.edit,
                                size: 20,
                                color: AppTheme.primaryColor,
                              ),
                              SizedBox(width: 12),
                              Text('Edit'),
                            ],
                          ),
                          onTap: () => Future.delayed(
                            const Duration(milliseconds: 100),
                            () => _showEventForm(
                              context,
                              controller,
                              event: event,
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 12),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                          onTap: () => Future.delayed(
                            const Duration(milliseconds: 100),
                            () =>
                                _confirmDelete(context, controller, event.id!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: event.active
                              ? Colors.grey[900]
                              : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        event.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Date and Venue
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              DateFormat(
                                'MMM dd, yyyy',
                              ).format(event.startDate),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              event.venue,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEventForm(
    BuildContext context,
    EventController controller, {
    EventModel? event,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final dialogWidth = isMobile
        ? screenWidth * 0.95
        : isTablet
        ? 600.0
        : 700.0;

    final titleController = TextEditingController(text: event?.title ?? '');
    final descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    final venueController = TextEditingController(text: event?.venue ?? '');
    final venueAddressController = TextEditingController(
      text: event?.venueAddress ?? '',
    );
    DateTime? startDate = event?.startDate;
    DateTime? endDate = event?.endDate;
    bool active = event?.active ?? true;
    bool current = event?.current ?? false;
    final selectedCategories = <String>[];
    final selectedAgeGroups = <String>[];
    XFile? selectedBanner;
    String? existingBannerUrl = event?.bannerUrl;

    if (event != null) {
      selectedCategories.addAll(event.categories);
      selectedAgeGroups.addAll(event.ageGroups);
    }

    // Clear previous banner selection when opening form
    controller.clearBannerImage();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              width: dialogWidth,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          event == null ? Icons.add_circle : Icons.edit,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            event == null ? 'Create Event' : 'Edit Event',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Form Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title
                          TextField(
                            controller: titleController,
                            decoration: InputDecoration(
                              labelText: 'Title *',
                              prefixIcon: const Icon(Icons.title),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Description
                          TextField(
                            controller: descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Description *',
                              prefixIcon: const Icon(Icons.description),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          // Venue Row
                          if (!isMobile)
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: venueController,
                                    decoration: InputDecoration(
                                      labelText: 'Venue *',
                                      prefixIcon: const Icon(
                                        Icons.location_city,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: venueAddressController,
                                    decoration: InputDecoration(
                                      labelText: 'Venue Address',
                                      prefixIcon: const Icon(Icons.map),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                TextField(
                                  controller: venueController,
                                  decoration: InputDecoration(
                                    labelText: 'Venue *',
                                    prefixIcon: const Icon(Icons.location_city),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: venueAddressController,
                                  decoration: InputDecoration(
                                    labelText: 'Venue Address',
                                    prefixIcon: const Icon(Icons.map),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          // Banner Upload Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Event Banner',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final ImagePicker picker = ImagePicker();
                                  final XFile? image = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    maxWidth: 1920,
                                    maxHeight: 1080,
                                    imageQuality: 85,
                                  );
                                  if (image != null) {
                                    setDialogState(() {
                                      selectedBanner = image;
                                      existingBannerUrl = null;
                                    });
                                    controller.selectedBannerImage.value =
                                        image;
                                  }
                                },
                                child: Container(
                                  height: 180,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 2,
                                      style: BorderStyle.solid,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.grey[50],
                                  ),
                                  child:
                                      selectedBanner != null ||
                                          (event != null && event.id != null)
                                      ? Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              child: SizedBox.expand(
                                                child: selectedBanner != null
                                                    ? FutureBuilder<Uint8List?>(
                                                        future: selectedBanner!
                                                            .readAsBytes(),
                                                        builder: (context, snapshot) {
                                                          if (snapshot
                                                              .hasData) {
                                                            return Image.memory(
                                                              snapshot.data!,
                                                              fit: BoxFit.cover,
                                                            );
                                                          }
                                                          return const Center(
                                                            child:
                                                                CircularProgressIndicator(),
                                                          );
                                                        },
                                                      )
                                                    : event != null &&
                                                          event.id != null
                                                    ? EventBannerImage(
                                                        event: event,
                                                        fit: BoxFit.cover,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              14,
                                                            ),
                                                      )
                                                    : const SizedBox(),
                                              ),
                                            ),
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  onPressed: () {
                                                    setDialogState(() {
                                                      selectedBanner = null;
                                                      existingBannerUrl = null;
                                                    });
                                                    controller
                                                        .clearBannerImage();
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_photo_alternate,
                                              size: 48,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Tap to upload banner',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Date Row
                          if (!isMobile)
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final date = await showDatePicker(
                                        context: dialogContext,
                                        initialDate:
                                            startDate ?? DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now().add(
                                          const Duration(days: 365 * 2),
                                        ),
                                      );
                                      if (date != null) {
                                        setDialogState(() {
                                          startDate = date;
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.grey[50],
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Start Date *',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  startDate != null
                                                      ? DateFormat(
                                                          'MMM dd, yyyy',
                                                        ).format(startDate!)
                                                      : 'Select date',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final date = await showDatePicker(
                                        context: dialogContext,
                                        initialDate: endDate ?? DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now().add(
                                          const Duration(days: 365 * 2),
                                        ),
                                      );
                                      if (date != null) {
                                        setDialogState(() {
                                          endDate = date;
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.grey[50],
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'End Date *',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  endDate != null
                                                      ? DateFormat(
                                                          'MMM dd, yyyy',
                                                        ).format(endDate!)
                                                      : 'Select date',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: dialogContext,
                                      initialDate: startDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365 * 2),
                                      ),
                                    );
                                    if (date != null) {
                                      setDialogState(() {
                                        startDate = date;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey[50],
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Start Date *',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                startDate != null
                                                    ? DateFormat(
                                                        'MMM dd, yyyy',
                                                      ).format(startDate!)
                                                    : 'Select date',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: dialogContext,
                                      initialDate: endDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365 * 2),
                                      ),
                                    );
                                    if (date != null) {
                                      setDialogState(() {
                                        endDate = date;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey[50],
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'End Date *',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                endDate != null
                                                    ? DateFormat(
                                                        'MMM dd, yyyy',
                                                      ).format(endDate!)
                                                    : 'Select date',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          // Toggles
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              children: [
                                SwitchListTile(
                                  title: const Text('Active Event'),
                                  subtitle: const Text(
                                    'Event is active and visible',
                                  ),
                                  value: active,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      active = value;
                                    });
                                  },
                                ),
                                Divider(height: 1, color: Colors.grey[300]),
                                SwitchListTile(
                                  title: const Text('Current Event'),
                                  subtitle: const Text(
                                    'Mark as current/ongoing event',
                                  ),
                                  value: current,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      current = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Actions
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        PrimaryButton(
                          text: event == null ? 'Create' : 'Update',
                          onPressedAsync: () async {
                            if (titleController.text.isEmpty ||
                                descriptionController.text.isEmpty ||
                                venueController.text.isEmpty ||
                                startDate == null ||
                                endDate == null) {
                              Get.snackbar(
                                'Error',
                                'Please fill all required fields',
                              );
                              return;
                            }

                            final newEvent = EventModel(
                              id: event?.id,
                              title: titleController.text,
                              description: descriptionController.text,
                              startDate: startDate ?? DateTime.now(),
                              endDate: endDate ?? DateTime.now(),
                              venue: venueController.text,
                              venueAddress: venueAddressController.text.isEmpty
                                  ? null
                                  : venueAddressController.text,
                              categories: selectedCategories,
                              ageGroups: selectedAgeGroups,
                              active: active,
                              current: current,
                              bannerUrl: existingBannerUrl,
                            );

                            // Get the banner file to pass
                            final bannerFileToUpload =
                                selectedBanner ??
                                controller.selectedBannerImage.value;

                            print('=== Event Update Debug ===');
                            print('Event ID: ${event?.id}');
                            print(
                              'Selected Banner: ${selectedBanner?.name ?? 'null'}',
                            );
                            print(
                              'Controller Banner: ${controller.selectedBannerImage.value?.name ?? 'null'}',
                            );
                            print(
                              'Banner File to Upload: ${bannerFileToUpload?.name ?? 'null'}',
                            );

                            if (event == null) {
                              await controller.createEvent(
                                newEvent,
                                bannerFile: bannerFileToUpload,
                              );
                            } else {
                              await controller.updateEvent(
                                newEvent,
                                bannerFile: bannerFileToUpload,
                              );
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          width: 120,
                          height: 44,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    EventController controller,
    String eventId,
  ) {
    AppDialog.show(
      context,
      title: 'Delete Event',
      message: 'Are you sure you want to delete this event?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
      onConfirm: () {
        controller.deleteEvent(eventId);
        Navigator.pop(context);
      },
    );
  }
}
