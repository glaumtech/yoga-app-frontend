import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/user_management_controller.dart';
import '../../controllers/competition_controller.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../../widgets/footer_section.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/competition_card.dart';
import '../../widgets/banner_slider.dart';
import '../../../data/models/competition_model.dart';

class _BannerData {
  final String id;
  final String title;
  final DateTime startDate;
  final String venue;
  final String? venueAddress;
  final List<String> categories;

  _BannerData({
    required this.id,
    required this.title,
    required this.startDate,
    required this.venue,
    this.venueAddress,
    required this.categories,
  });

  static _BannerData? fromCompetition(HomeCompetitionModel c) {
    if (c.idStr == null) return null;
    final start = c.eventStartDate != null
        ? (DateTime.tryParse(c.eventStartDate!) ?? DateTime.now())
        : DateTime.now();
    return _BannerData(
      id: c.idStr!,
      title: c.competitionName,
      startDate: start,
      venue: c.address,
      venueAddress: c.address.isNotEmpty ? c.address : null,
      categories: c.categories,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final authController = Get.find<AuthController>();
      final userController = Get.put(UserManagementController());
      final competitionController = Get.put(CompetitionController());

      // Load competitions for home (public API)
      if (competitionController.homeCompetitions.isEmpty &&
          !competitionController.isLoadingHomeCompetitions.value) {
        competitionController.loadCompetitionsForHome();
      }
      return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // App Logo
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.self_improvement,
                        color: AppTheme.primaryColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // App Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Yogasana',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                          ),
                          Text(
                            'Championship 2025',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ),
                    // Action Buttons
                    Obx(() {
                      final currentUser = userController.currentUser.value;
                      final isAuthenticated = userController.isAuthenticated;
                      final userTypeName =
                          currentUser?.userTypeName ?? currentUser?.type ?? '';
                      final userTypeUpper = userTypeName.toUpperCase();

                      // Check specific user types: SUB_ADMIN and SPOT_REG_ADMIN have admin access
                      final userIsAdmin =
                          userTypeUpper == 'SUB_ADMIN' ||
                          userTypeUpper == 'SPOT_REG_ADMIN' ||
                          userTypeUpper.contains('SUB ADMIN') ||
                          userTypeUpper.contains('SPOT REG ADMIN');

                      // JURY has judge/jury access
                      final userIsJudge =
                          userTypeUpper == 'JURY' ||
                          userTypeUpper.contains('JURY') ||
                          userTypeUpper.contains('JUDGE');

                      // Debug logging
                      debugPrint('User type: $userTypeName');
                      debugPrint('Is Judge: $userIsJudge');
                      debugPrint('Is Admin: $userIsAdmin');

                      if (!isAuthenticated) {
                        // Login Button
                        return ElevatedButton.icon(
                          onPressed: () {
                            debugPrint(
                              'Login button pressed - isAuthenticated: $isAuthenticated, context.mounted: ${context.mounted}',
                            );
                            context.go(AppRoutes.login);
                          },
                          icon: const Icon(Icons.login, size: 18),
                          label: const Text('Login'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 2,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        );
                      } else {
                        // User Menu
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!userIsAdmin && !userIsJudge)
                              IconButton(
                                icon: const Icon(Icons.dashboard),
                                color: Colors.white,
                                tooltip: 'Dashboard',
                                onPressed: () =>
                                    context.push(AppRoutes.userDashboard),
                              ),
                            if (userIsAdmin)
                              IconButton(
                                icon: const Icon(Icons.admin_panel_settings),
                                color: Colors.white,
                                tooltip: 'Admin Dashboard',
                                onPressed: () =>
                                    context.push(AppRoutes.adminDashboard),
                              ),
                            PopupMenuButton<String>(
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.account_circle,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              tooltip: 'User Menu',
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 8,
                              color: Colors.white,
                              offset: const Offset(0, 10),
                              position: PopupMenuPosition.under,
                              onSelected: (value) async {
                                switch (value) {
                                  case 'profile':
                                    // TODO: Navigate to profile
                                    break;
                                  case 'logout':
                                    // Sign out first
                                    await authController.signOut();
                                    // Then navigate if the context is still valid
                                    if (context.mounted) {
                                      context.go(AppRoutes.login);
                                    }
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'profile',
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.person,
                                          size: 18,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              userController
                                                      .currentUser
                                                      .value
                                                      ?.name ??
                                                  'Profile',
                                              style: const TextStyle(
                                                color: AppTheme.primaryColor,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (userController
                                                    .currentUser
                                                    .value
                                                    ?.userTypeName !=
                                                null)
                                              Text(
                                                userController
                                                    .currentUser
                                                    .value!
                                                    .userTypeName!,
                                                style: TextStyle(
                                                  color: AppTheme.primaryColor
                                                      .withOpacity(0.7),
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'logout',
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.logout,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Logout',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Obx(() {
            // Show loading indicator while competitions are loading
            if (competitionController.isLoadingHomeCompetitions.value &&
                competitionController.homeCompetitions.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Banner Slider Section
                      _buildBannerSliderSection(context),

                      // Banner Section (Competition Details)
                      _buildBannerSection(context, competitionController),

                      // Current Competitions Section
                      _buildCurrentEventsSection(
                        context,
                        competitionController,
                      ),

                      // Upcoming Competitions Section
                      _buildUpcomingEventsSection(
                        context,
                        competitionController,
                      ),

                      // Footer
                      const FooterSection(),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      );
    } catch (e) {
      // Fallback UI if there's an error
      debugPrint('Error building HomeScreen: $e');
      return Scaffold(
        appBar: AppBar(title: const Text(AppConstants.appName)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading home screen',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildBannerSliderSection(BuildContext context) {
    // List of banner image paths - only include existing images
    final bannerImages = <String>[];

    // Check which banner images exist (you can add more as needed)
    // For now, we'll use a fallback approach
    try {
      // Try to add banner images if they exist
      // If images don't exist, the BannerSlider will show fallback UI
      bannerImages.add('assets/images/banners/banner1.jpg');
      bannerImages.add('assets/images/banners/banner2.jpg');
    } catch (e) {
      debugPrint('Error loading banner images: $e');
    }

    // If no banner images, return empty container
    if (bannerImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: BannerSlider(
        bannerImages: bannerImages,
        height: 400,
        onBannerTap: (index) {
          // Handle banner tap if needed
          debugPrint('Banner $index tapped');
        },
      ),
    );
  }

  Widget _buildBannerSection(
    BuildContext context,
    CompetitionController controller,
  ) {
    // Get the featured competition (first ongoing or upcoming)
    final bannerCompetition = controller.homeCompetitions.isNotEmpty
        ? controller.homeCompetitions.firstWhereOrNull(
                (c) => c.status == 'ongoing' || c.status == 'upcoming',
              ) ??
              controller.homeCompetitions.first
        : null;
    final bannerEvent = bannerCompetition != null
        ? _BannerData.fromCompetition(bannerCompetition)
        : null;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 500),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.secondaryColor,
            AppTheme.primaryColor.withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: bannerEvent != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Decorative Background Elements
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Title and QR Code
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Main Title
                                  Text(
                                    bannerEvent.title.toUpperCase(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                          height: 1.2,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Tagline
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.yellow[400]?.withOpacity(
                                        0.9,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'BE PART OF INDIA\'S BIGGEST YOGA CELEBRATION',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // QR Code Section
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.qr_code,
                                      size: 50,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'SCAN FOR\nREGISTRATION',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Slogan
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.celebration,
                                color: Colors.yellow[300],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your Championship, Your Moment! Don\'t Miss the Date!',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Event Details Grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildBannerDetail(
                                context,
                                Icons.calendar_today,
                                'Event Date',
                                DateFormat(
                                  'EEEE, MMMM dd, yyyy',
                                ).format(bannerEvent.startDate),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildBannerDetail(
                                context,
                                Icons.location_on,
                                'Venue',
                                bannerEvent.venue,
                              ),
                            ),
                          ],
                        ),
                        if (bannerEvent.venueAddress != null) ...[
                          const SizedBox(height: 12),
                          _buildBannerDetail(
                            context,
                            Icons.map,
                            'Address',
                            bannerEvent.venueAddress!,
                          ),
                        ],
                        const SizedBox(height: 20),
                        // Categories and Age Groups
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...bannerEvent.categories.map((category) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  category,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Action Buttons
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile = constraints.maxWidth < 600;
                            final userCtrl =
                                Get.find<UserManagementController>();
                            final currentUser = userCtrl.currentUser.value;
                            final userTypeName =
                                currentUser?.userTypeName ??
                                currentUser?.type ??
                                '';
                            final userTypeUpper = userTypeName.toUpperCase();
                            final userIsJudge =
                                userTypeUpper == 'JURY' ||
                                userTypeUpper.contains('JURY') ||
                                userTypeUpper.contains('JUDGE');

                            if (isMobile) {
                              // Mobile: Stack vertically
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // View Event Button
                                    PrimaryButton(
                                      text: 'View Event',
                                      icon: Icons.visibility,
                                      onPressed: () {
                                        context.push(
                                          '/events/${bannerEvent.id}',
                                        );
                                      },
                                      width: 220,
                                      height: 50,
                                    ),
                                    const SizedBox(height: 12),
                                    // Register Button
                                    PrimaryButton(
                                      text: 'Register Now!',
                                      icon: Icons.person_add,
                                      onPressed: () {
                                        context.push(
                                          AppRoutes.registerCompetitionPath(
                                            bannerEvent.id,
                                          ),
                                        );
                                      },
                                      width: 220,
                                      height: 50,
                                    ),
                                    if (userIsJudge) ...[
                                      const SizedBox(height: 12),
                                      // Add Score Button (Judge only)
                                      PrimaryButton(
                                        text: 'Add Score',
                                        icon: Icons.score,
                                        onPressed: () {
                                          context.pushNamed(
                                            'assigned-participants',
                                            pathParameters: {
                                              'eventId': bannerEvent.id
                                                  .toString(),
                                            },
                                          );
                                        },
                                        width: 220,
                                        height: 50,
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            } else {
                              // Desktop/Tablet: Side by side
                              return Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // View Event Button
                                    PrimaryButton(
                                      text: 'View Event',
                                      icon: Icons.visibility,
                                      onPressed: () {
                                        context.push(
                                          '/events/${bannerEvent.id}',
                                        );
                                      },
                                      width: 220,
                                      height: 50,
                                    ),
                                    const SizedBox(width: 16),
                                    // Register Button
                                    PrimaryButton(
                                      text: 'Register Now!',
                                      icon: Icons.person_add,
                                      onPressed: () {
                                        context.push(
                                          AppRoutes.registerCompetitionPath(
                                            bannerEvent.id,
                                          ),
                                        );
                                      },
                                      width: 220,
                                      height: 50,
                                    ),
                                    if (userIsJudge) ...[
                                      const SizedBox(width: 16),
                                      // Add Score Button (Judge only)
                                      PrimaryButton(
                                        text: 'Add Score',
                                        icon: Icons.score,
                                        onPressed: () {
                                          context.pushNamed(
                                            'assigned-participants',
                                            pathParameters: {
                                              'eventId': bannerEvent.id
                                                  .toString(),
                                            },
                                          );
                                        },
                                        width: 220,
                                        height: 50,
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.self_improvement, size: 80, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Harmony • Balance • Excellence',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBannerDetail(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentEventsSection(
    BuildContext context,
    CompetitionController controller,
  ) {
    final currentCompetitions = controller.homeCompetitions
        .where((c) => c.status == 'ongoing')
        .take(4)
        .toList();

    if (currentCompetitions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SectionHeader(
                  title: 'Current Events',
                  subtitle: 'Events happening soon',
                  showDivider: false,
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.events),
                child: const Text('View More'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth <= 0) {
                return const SizedBox.shrink();
              }

              final isMobile = constraints.maxWidth < 600;
              final isTablet =
                  constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
              final idOf = (HomeCompetitionModel c) => c.idStr ?? '${c.id}';

              if (isMobile) {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: currentCompetitions.length,
                  itemBuilder: (context, index) {
                    final competition = currentCompetitions[index];
                    return Padding(
                      key: ValueKey('current_comp_${idOf(competition)}_$index'),
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CompetitionCard(
                        competition: competition,
                        onTap: () =>
                            context.push('/events/${idOf(competition)}'),
                      ),
                    );
                  },
                );
              } else if (isTablet) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: currentCompetitions.length,
                  itemBuilder: (context, index) {
                    final competition = currentCompetitions[index];
                    return CompetitionCard(
                      key: ValueKey('current_comp_${idOf(competition)}_$index'),
                      competition: competition,
                      onTap: () => context.push('/events/${idOf(competition)}'),
                    );
                  },
                );
              } else {
                return SizedBox(
                  height: 320,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemExtent: constraints.maxWidth * 0.35,
                    itemCount: currentCompetitions.length,
                    itemBuilder: (context, index) {
                      final competition = currentCompetitions[index];
                      return Padding(
                        key: ValueKey(
                          'current_comp_${idOf(competition)}_$index',
                        ),
                        padding: const EdgeInsets.only(right: 16),
                        child: CompetitionCard(
                          competition: competition,
                          onTap: () =>
                              context.push('/events/${idOf(competition)}'),
                        ),
                      );
                    },
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventsSection(
    BuildContext context,
    CompetitionController controller,
  ) {
    final upcomingCompetitions = controller.homeCompetitions
        .where((c) => c.status == 'upcoming')
        .take(4)
        .toList();
    final idOf = (HomeCompetitionModel c) => c.idStr ?? '${c.id}';

    if (upcomingCompetitions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        color: Colors.white,
        child: Column(
          children: [
            SectionHeader(title: 'Upcoming Events', showDivider: false),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No upcoming events',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for upcoming competitions',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SectionHeader(
                  title: 'Upcoming Events',
                  subtitle: 'Future competitions',
                  showDivider: false,
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.events),
                child: const Text('View More'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth <= 0) {
                return const SizedBox.shrink();
              }

              final isMobile = constraints.maxWidth < 600;
              final isTablet =
                  constraints.maxWidth >= 600 && constraints.maxWidth < 1024;

              if (isMobile) {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: upcomingCompetitions.length,
                  itemBuilder: (context, index) {
                    final competition = upcomingCompetitions[index];
                    return Padding(
                      key: ValueKey(
                        'upcoming_comp_${idOf(competition)}_$index',
                      ),
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CompetitionCard(
                        competition: competition,
                        onTap: () =>
                            context.push('/events/${idOf(competition)}'),
                      ),
                    );
                  },
                );
              } else if (isTablet) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: upcomingCompetitions.length,
                  itemBuilder: (context, index) {
                    final competition = upcomingCompetitions[index];
                    return CompetitionCard(
                      key: ValueKey(
                        'upcoming_comp_${idOf(competition)}_$index',
                      ),
                      competition: competition,
                      onTap: () => context.push('/events/${idOf(competition)}'),
                    );
                  },
                );
              } else {
                return SizedBox(
                  height: 320,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemExtent: constraints.maxWidth * 0.35,
                    itemCount: upcomingCompetitions.length,
                    itemBuilder: (context, index) {
                      final competition = upcomingCompetitions[index];
                      return Padding(
                        key: ValueKey(
                          'upcoming_comp_${idOf(competition)}_$index',
                        ),
                        padding: const EdgeInsets.only(right: 16),
                        child: CompetitionCard(
                          competition: competition,
                          onTap: () =>
                              context.push('/events/${idOf(competition)}'),
                        ),
                      );
                    },
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
