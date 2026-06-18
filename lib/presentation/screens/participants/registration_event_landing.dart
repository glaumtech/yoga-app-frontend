import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/competition_registration_url.dart';
import '../../../core/utils/venue_map_helper.dart';
import '../../../data/models/competition_model.dart';
import '../../controllers/competition_controller.dart';
import '../../controllers/participant_controller.dart';
import '../../widgets/venue_map_preview.dart';

class RegistrationSectionTitle extends StatelessWidget {
  final String title;

  const RegistrationSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.textColor,
              fontSize: 22,
            ),
      ),
    );
  }
}

class RegistrationEventHeader extends StatelessWidget {
  final HomeCompetitionModel competition;

  const RegistrationEventHeader({super.key, required this.competition});

  @override
  Widget build(BuildContext context) {
    final address = competition.address.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          competition.competitionName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
                height: 1.15,
              ),
        ),
        if (address.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined, size: 20, color: Colors.grey.shade700),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class RegistrationEventHighlights extends StatelessWidget {
  const RegistrationEventHighlights({super.key});

  static const _items = [
    (Icons.badge_outlined, 'Participant ID'),
    (Icons.emoji_events_outlined, 'Competition scoring'),
    (Icons.workspace_premium_outlined, 'Certificates'),
    (Icons.leaderboard_outlined, 'Published results'),
    (Icons.photo_camera_outlined, 'Event photos'),
    (Icons.eco_outlined, 'E-Certificate option'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RegistrationSectionTitle('Event Highlights'),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth < 480 ? 2 : 3;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.8,
              ),
              itemBuilder: (context, index) {
                final item = _items[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(item.$1, size: 22, color: AppTheme.primaryColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.$2,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class RegistrationCategoryCards extends StatelessWidget {
  final HomeCompetitionModel competition;
  final CompetitionModel? fullCompetition;
  final CompetitionController competitionController;
  final ParticipantController participantController;
  final VoidCallback onRegisterTap;

  const RegistrationCategoryCards({
    super.key,
    required this.competition,
    required this.fullCompetition,
    required this.competitionController,
    required this.participantController,
    required this.onRegisterTap,
  });

  double? _feeForCategory(String categoryName) {
    final categoryId = competitionController.getCategoryIdByName(categoryName);
    if (categoryId != null) {
      final fromHome = competition.categoryAmounts[categoryId.toString()];
      if (fromHome != null && fromHome > 0) return fromHome;
      final id = competition.id?.toString() ?? '';
      if (id.isNotEmpty) {
        final fee = competitionController.resolveCategoryFeeRupees(id, categoryId);
        if (fee > 0) return fee;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final categories = competition.categories;
    if (categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RegistrationSectionTitle('Choose Your Category'),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth < 600
                ? constraints.maxWidth
                : (constraints.maxWidth / categories.length.clamp(1, 4))
                    .clamp(220.0, 280.0);

            return Obx(() {
              final selected = participantController.selectedCategories.isNotEmpty
                  ? participantController.selectedCategories.first
                  : null;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: categories.map((category) {
                  final fee = _feeForCategory(category);
                  final isSelected = selected == category;

                  return SizedBox(
                    width: constraints.maxWidth < 600 ? double.infinity : cardWidth,
                    child: _CategoryCard(
                      categoryName: category,
                      fee: fee,
                      isSelected: isSelected,
                      onRegister: () {
                        participantController.selectedCategories.value = [category];
                        participantController.validateRegistrationFormOnFieldChange();
                        onRegisterTap();
                      },
                    ),
                  );
                }).toList(),
              );
            });
          },
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String categoryName;
  final double? fee;
  final bool isSelected;
  final VoidCallback onRegister;

  const _CategoryCard({
    required this.categoryName,
    required this.fee,
    required this.isSelected,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? AppTheme.primaryColor
              : AppTheme.primaryColor.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            categoryName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textColor,
            ),
          ),
          if (fee != null && fee! > 0) ...[
            const SizedBox(height: 10),
            Text(
              '₹ ${fee!.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Register',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RegistrationEventSidebar extends StatelessWidget {
  final HomeCompetitionModel competition;
  final CompetitionModel? fullCompetition;
  final VoidCallback onRegisterTap;

  const RegistrationEventSidebar({
    super.key,
    required this.competition,
    required this.fullCompetition,
    required this.onRegisterTap,
  });

  String? _eventDateDisplay() {
    final start = fullCompetition?.eventStartDate ??
        DateTime.tryParse(competition.eventStartDate ?? '');
    if (start == null) {
      final raw = competition.eventStartDate?.trim();
      return raw != null && raw.isNotEmpty ? raw : null;
    }

    final end = fullCompetition?.eventEndDate ??
        DateTime.tryParse(competition.eventEndDate ?? '');
    final formatter = DateFormat('MMMM d, yyyy');
    final dayFormatter = DateFormat('EEEE');
    final startText = '${formatter.format(start)} - ${dayFormatter.format(start)}';
    if (end == null ||
        (start.year == end.year && start.month == end.month && start.day == end.day)) {
      return startText;
    }
    return '$startText – ${formatter.format(end)}';
  }

  String? _eventTimeDisplay() {
    final full = fullCompetition;
    final start = full?.eventStartTime?.trim();
    final end = full?.eventEndTime?.trim() ?? competition.eventEndTime?.trim();
    if (start != null && start.isNotEmpty) {
      if (end != null && end.isNotEmpty) return '$start – $end';
      return start;
    }
    if (end != null && end.isNotEmpty) return end;
    return null;
  }

  Future<void> _copyLink(BuildContext context) async {
    final id = competition.id?.toString() ?? '';
    if (id.isEmpty) return;
    final url = registrationShareUrlForCompetition(
      registrationUrl: competition.registrationUrl,
      competitionId: id,
    );
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registration link copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = _eventDateDisplay();
    final time = _eventTimeDisplay();
    final address = competition.address.trim();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRegisterTap,
              icon: const Icon(Icons.edit_note, size: 20),
              label: const Text(
                'Register',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 20),
            VenueMapPreview(
              address: address,
              height: 200,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  final url = VenueMapHelper.googleMapsUrl(address);
                  if (url == null) return;
                  final uri = Uri.tryParse(url);
                  if (uri == null) return;
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Open in Google Maps'),
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (address.isNotEmpty)
            _SidebarRow(
              icon: Icons.location_on_outlined,
              title: 'Location',
              value: address,
            ),
          if (date != null)
            _SidebarRow(
              icon: Icons.calendar_today_outlined,
              title: 'Date',
              value: date,
            ),
          if (time != null)
            _SidebarRow(
              icon: Icons.schedule_outlined,
              title: 'Time',
              value: time,
            ),
          const Divider(height: 32),
          _SidebarRow(
            icon: Icons.email_outlined,
            title: 'Registration Support',
            value: 'praveen.sekar@glaum.in',
            onTap: () => launchUrl(Uri.parse('mailto:praveen.sekar@glaum.in')),
          ),
          _SidebarRow(
            icon: Icons.phone_outlined,
            title: 'Phone',
            value: '+91 9952825358',
            onTap: () => launchUrl(Uri.parse('tel:+919952825358')),
          ),
          const SizedBox(height: 16),
          const Text(
            'Share',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              _ShareChip(
                icon: Icons.link,
                color: AppTheme.primaryColor,
                onTap: () => _copyLink(context),
              ),
              _ShareChip(
                icon: Icons.email_outlined,
                color: Colors.red.shade600,
                onTap: () => launchUrl(Uri.parse('mailto:praveen.sekar@glaum.in')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SidebarRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _SidebarRow({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: child);
  }
}

class _ShareChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ShareChip({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
