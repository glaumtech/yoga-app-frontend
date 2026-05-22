import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/user_management_controller.dart';
import '../../controllers/competition_controller.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/layout/home_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/permission_store.dart';
import '../../../routes/app_routes.dart';
import '../../widgets/footer_section.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/competition_card.dart';
import '../../widgets/competition_registration_qr_image.dart';
import '../../widgets/banner_slider.dart';
import '../../../data/models/competition_model.dart';
import '../../../core/utils/competition_registration_url.dart';

class _BannerData {
  final String id;
  final String title;
  final DateTime startDate;
  final String venue;
  final String? venueAddress;
  final List<String> categories;
  final String? registrationUrl;

  _BannerData({
    required this.id,
    required this.title,
    required this.startDate,
    required this.venue,
    this.venueAddress,
    required this.categories,
    this.registrationUrl,
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
      registrationUrl: c.registrationUrl,
    );
  }
}

void _copyBannerRegistrationLink(
  BuildContext context,
  String competitionId, {
  String? registrationUrl,
}) {
  final link = registrationShareUrlForCompetition(
    registrationUrl: registrationUrl,
    competitionId: competitionId,
  );
  Clipboard.setData(ClipboardData(text: link));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Registration link copied'),
      duration: Duration(seconds: 2),
    ),
  );
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
                      final isAuthenticated = userController.isAuthenticated;
                      final permissionStore =
                          Get.isRegistered<PermissionStore>()
                          ? Get.find<PermissionStore>()
                          : Get.put(PermissionStore());

                      final isAdminLoggedIn = permissionStore.has(
                        'SHOW_DASHBOARD_ICON_ON_HOME_SCREEN',
                      );
                      final isJuryLoggedIn = permissionStore.has(
                        'SHOW_JURY_SCREEN',
                      );

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
                            if (isAdminLoggedIn)
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
                                    if (!context.mounted) break;
                                    // Admins: user creation / management screen
                                    if (isAdminLoggedIn) {
                                      context.push(AppRoutes.userManagement);
                                      break;
                                    }
                                    if (isJuryLoggedIn) {
                                      context.go(AppRoutes.juryScoring);
                                      break;
                                    }
                                    // Other logged-in users: participant dashboard
                                    context.push(AppRoutes.home);
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
                      _buildBannerSliderSection(context),
                      _buildBannerSection(context, competitionController),
                      _buildCurrentEventsSection(
                        context,
                        competitionController,
                      ),
                      _buildUpcomingEventsSection(
                        context,
                        competitionController,
                      ),
                      _buildPastEventsSection(
                        context,
                        competitionController,
                      ),
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
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final isNarrow = w < HomeLayout.mobile;
        final contentPad = w < HomeLayout.mobile
            ? 16.0
            : (w < HomeLayout.tablet ? 22.0 : 28.0);

        return Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: HomeLayout.heroBannerMinHeight(w),
          ),
          margin: EdgeInsets.symmetric(
            horizontal: HomeLayout.sectionHorizontalPadding(w),
            vertical: 8,
          ),
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
                        padding: EdgeInsets.all(contentPad),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBannerHeroHeader(
                              context,
                              bannerEvent,
                              isNarrow,
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
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
                            _buildBannerDateVenueRow(
                              context,
                              bannerEvent,
                              isNarrow,
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
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
                            Builder(
                              builder: (context) {
                                final permissionStore =
                                    Get.isRegistered<PermissionStore>()
                                    ? Get.find<PermissionStore>()
                                    : Get.put(PermissionStore());
                                final showJuryScreen = permissionStore.has(
                                  'SHOW_ADD_SCORE',
                                );

                                if (isNarrow) {
                                  // Full-width buttons on small screens (parent gives bounded width)
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: PrimaryButton(
                                                text: 'Register Now!',
                                                icon: Icons.person_add,
                                                onPressed: () {
                                                  context.push(
                                                    AppRoutes.registerCompetitionPath(
                                                      bannerEvent.id,
                                                    ),
                                                  );
                                                },
                                                width: double.infinity,
                                                height: 50,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Material(
                                              color: Colors.white.withOpacity(
                                                0.22,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: IconButton(
                                                tooltip:
                                                    'Share registration link',
                                                onPressed: () =>
                                                    _copyBannerRegistrationLink(
                                                      context,
                                                      bannerEvent.id,
                                                      registrationUrl:
                                                          bannerEvent
                                                              .registrationUrl,
                                                    ),
                                                icon: const Icon(
                                                  Icons.share,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (showJuryScreen) ...[
                                          const SizedBox(height: 12),
                                          PrimaryButton(
                                            text: 'Add Score',
                                            icon: Icons.score,
                                            onPressed: () {
                                              context.push(
                                                AppRoutes.juryScoring,
                                              );
                                            },
                                            width: double.infinity,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // View Event button hidden for now
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
                                        const SizedBox(width: 10),
                                        Material(
                                          color: Colors.white.withOpacity(0.22),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: IconButton(
                                            tooltip: 'Share registration link',
                                            onPressed: () =>
                                                _copyBannerRegistrationLink(
                                                  context,
                                                  bannerEvent.id,
                                                  registrationUrl:
                                                      bannerEvent.registrationUrl,
                                                ),
                                            icon: const Icon(
                                              Icons.share,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        if (showJuryScreen) ...[
                                          const SizedBox(width: 16),
                                          // Add Score Button (Judge only)
                                          PrimaryButton(
                                            text: 'Add Score',
                                            icon: Icons.score,
                                            onPressed: () {
                                              context.push(
                                                AppRoutes.juryScoring,
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
                  padding: EdgeInsets.all(w < HomeLayout.mobile ? 28 : 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.self_improvement,
                        size: w < HomeLayout.mobile ? 64 : 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppConstants.appName,
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Harmony • Balance • Excellence',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildBannerHeroHeader(
    BuildContext context,
    _BannerData bannerEvent,
    bool isNarrow,
  ) {
    final titleStyle = isNarrow
        ? Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            height: 1.2,
          )
        : Theme.of(context).textTheme.displayMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            height: 1.2,
          );
    final qrSize = isNarrow ? 88.0 : 100.0;
    final tagline = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.yellow[400]?.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'BE PART OF INDIA\'S BIGGEST YOGA CELEBRATION',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(bannerEvent.title.toUpperCase(), style: titleStyle),
        const SizedBox(height: 12),
        tagline,
      ],
    );
    final qrBlock = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
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
            child: CompetitionRegistrationQrImage(
              competitionId: bannerEvent.id,
              size: qrSize,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'SCAN FOR\nREGISTRATION',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleBlock,
          const SizedBox(height: 20),
          Center(child: qrBlock),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 16),
        qrBlock,
      ],
    );
  }

  Widget _buildBannerDateVenueRow(
    BuildContext context,
    _BannerData bannerEvent,
    bool isNarrow,
  ) {
    final dateChild = _buildBannerDetail(
      context,
      Icons.calendar_today,
      'Competition Date',
      DateFormat('EEEE, MMMM dd, yyyy').format(bannerEvent.startDate),
    );
    final venueChild = _buildBannerDetail(
      context,
      Icons.location_on,
      'Venue',
      bannerEvent.venue,
    );
    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [dateChild, const SizedBox(height: 12), venueChild],
      );
    }
    return Row(
      children: [
        Expanded(child: dateChild),
        const SizedBox(width: 16),
        Expanded(child: venueChild),
      ],
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

    return _buildHomeCompetitionsListSection(
      context,
      competitions: currentCompetitions,
      title: 'Current Competitions',
      subtitle: 'Competitions happening now',
      backgroundColor: Colors.grey.shade50,
      itemKeyPrefix: 'current_comp',
      showRegistrationQr: true,
      viewMoreStatus: 'ongoing',
    );
  }

  Widget _buildPastEventsSection(
    BuildContext context,
    CompetitionController controller,
  ) {
    final past = controller.homeCompetitions
        .where((c) => c.status == 'completed')
        .toList();
    past.sort((a, b) {
      final endA = DateTime.tryParse(a.eventEndDate ?? '') ?? DateTime(1970);
      final endB = DateTime.tryParse(b.eventEndDate ?? '') ?? DateTime(1970);
      return endB.compareTo(endA);
    });
    final pastCompetitions = past.take(4).toList();

    return _buildHomeCompetitionsListSection(
      context,
      competitions: pastCompetitions,
      title: 'Past Events',
      subtitle: 'Previous competitions',
      backgroundColor: Colors.grey.shade50,
      itemKeyPrefix: 'past_comp',
      showStatusBadge: false,
      showRegistrationButton: false,
      showViewParticipantsButton: true,
      viewMoreStatus: 'completed',
    );
  }

  Widget _buildHomeCompetitionsListSection(
    BuildContext context, {
    required List<HomeCompetitionModel> competitions,
    required String title,
    String? subtitle,
    required Color backgroundColor,
    required String itemKeyPrefix,
    bool showRegistrationQr = false,
    bool showShareLinkOption = false,
    bool showStatusBadge = true,
    bool showRegistrationButton = true,
    bool showViewParticipantsButton = false,
    String? viewMoreStatus,
  }) {
    if (competitions.isEmpty) {
      return const SizedBox.shrink();
    }

    final idOf = (HomeCompetitionModel c) => c.idStr ?? '${c.id}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final padH = HomeLayout.sectionHorizontalPadding(w);
        final padV = HomeLayout.sectionVerticalPadding(w);
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: padV, horizontal: padH),
          color: backgroundColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SectionHeader(
                      title: title,
                      subtitle: subtitle,
                      showDivider: false,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(
                      AppRoutes.competitionsList(status: viewMoreStatus),
                    ),
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

                  final cw = constraints.maxWidth;
                  final isMobile = cw < HomeLayout.mobile;
                  final isTablet =
                      cw >= HomeLayout.mobile && cw < HomeLayout.tablet;

                  Widget buildCard(HomeCompetitionModel competition) {
                    return CompetitionCard(
                      competition: competition,
                      showRegistrationQr: showRegistrationQr,
                      showShareLinkOption: showShareLinkOption,
                      showStatusBadge: showStatusBadge,
                      showRegistrationButton: showRegistrationButton,
                      showViewParticipantsButton: showViewParticipantsButton,
                    );
                  }

                  if (isMobile) {
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: competitions.length,
                      itemBuilder: (context, index) {
                        final competition = competitions[index];
                        return Padding(
                          key: ValueKey(
                            '${itemKeyPrefix}_${idOf(competition)}_$index',
                          ),
                          padding: const EdgeInsets.only(bottom: 16),
                          child: buildCard(competition),
                        );
                      },
                    );
                  } else if (isTablet) {
                    final crossCount = HomeLayout.competitionGridCrossAxisCount(
                      cw,
                    );
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio:
                            HomeLayout.competitionGridChildAspectRatio(
                              crossCount,
                            ),
                      ),
                      itemCount: competitions.length,
                      itemBuilder: (context, index) {
                        final competition = competitions[index];
                        return CompetitionCard(
                          key: ValueKey(
                            '${itemKeyPrefix}_${idOf(competition)}_$index',
                          ),
                          competition: competition,
                          showRegistrationQr: showRegistrationQr,
                          showShareLinkOption: showShareLinkOption,
                          showStatusBadge: showStatusBadge,
                          showRegistrationButton: showRegistrationButton,
                          showViewParticipantsButton: showViewParticipantsButton,
                        );
                      },
                    );
                  } else {
                    return SizedBox(
                      height: HomeLayout.competitionCarouselHeight(cw),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        itemExtent: HomeLayout.competitionCarouselItemExtent(
                          cw,
                        ),
                        itemCount: competitions.length,
                        itemBuilder: (context, index) {
                          final competition = competitions[index];
                          return Padding(
                            key: ValueKey(
                              '${itemKeyPrefix}_${idOf(competition)}_$index',
                            ),
                            padding: const EdgeInsets.only(right: 16),
                            child: buildCard(competition),
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
      },
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
      return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final padH = HomeLayout.sectionHorizontalPadding(w);
          final padV = HomeLayout.sectionVerticalPadding(w);
          return Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: padV, horizontal: padH),
            color: Colors.white,
            child: Column(
              children: [
                SectionHeader(
                  title: 'Upcoming Competitions',
                  showDivider: false,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(w < HomeLayout.mobile ? 24 : 32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: w < HomeLayout.mobile ? 56 : 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No upcoming competitions',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later for upcoming competitions',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final padH = HomeLayout.sectionHorizontalPadding(w);
        final padV = HomeLayout.sectionVerticalPadding(w);
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: padV, horizontal: padH),
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
                      title: 'Upcoming Competitions',
                      subtitle: 'Future competitions',
                      showDivider: false,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(
                      AppRoutes.competitionsList(status: 'upcoming'),
                    ),
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

                  final cw = constraints.maxWidth;
                  final isMobile = cw < HomeLayout.mobile;
                  final isTablet =
                      cw >= HomeLayout.mobile && cw < HomeLayout.tablet;

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
                            showShareLinkOption: true,
                            showRegistrationQr: true,
                          ),
                        );
                      },
                    );
                  } else if (isTablet) {
                    final crossCount = HomeLayout.competitionGridCrossAxisCount(
                      cw,
                    );
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio:
                            HomeLayout.competitionGridChildAspectRatio(
                              crossCount,
                            ),
                      ),
                      itemCount: upcomingCompetitions.length,
                      itemBuilder: (context, index) {
                        final competition = upcomingCompetitions[index];
                        return CompetitionCard(
                          key: ValueKey(
                            'upcoming_comp_${idOf(competition)}_$index',
                          ),
                          competition: competition,
                          showShareLinkOption: true,
                          showRegistrationQr: true,
                        );
                      },
                    );
                  } else {
                    return SizedBox(
                      height: HomeLayout.competitionCarouselHeight(cw),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        itemExtent: HomeLayout.competitionCarouselItemExtent(
                          cw,
                        ),
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
                              showShareLinkOption: true,
                              showRegistrationQr: true,
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
      },
    );
  }
}
