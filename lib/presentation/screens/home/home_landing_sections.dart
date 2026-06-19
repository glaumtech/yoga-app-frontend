import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/layout/home_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/competition_brochure_banner_url.dart';
import '../../../core/utils/competition_registration_url.dart';
import '../../../data/models/competition_model.dart';
import '../../../routes/app_routes.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/user_management_controller.dart';
import '../../widgets/competition_registration_qr_image.dart';
import '../../widgets/footer_section.dart';

class HomeLandingNavBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isAuthenticated;
  final VoidCallback onLogin;
  final VoidCallback? onLogout;
  final VoidCallback? onAdmin;
  final VoidCallback? onUserMenu;

  const HomeLandingNavBar({
    super.key,
    required this.isAuthenticated,
    required this.onLogin,
    this.onLogout,
    this.onAdmin,
    this.onUserMenu,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= HomeLayout.tablet;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _Logo(onTap: () => context.go(AppRoutes.home)),
              if (isWide) ...[
                const SizedBox(width: 16),
                _NavLink(
                  label: 'Home',
                  onTap: () => context.go(AppRoutes.home),
                ),
                _NavLink(
                  label: 'Competitions',
                  onTap: () => context.push(AppRoutes.competitions),
                ),
                _NavLink(
                  label: 'Results',
                  onTap: () => context.push(
                    AppRoutes.competitionsList(status: 'completed'),
                  ),
                ),
                _NavLink(
                  label: 'About Us',
                  onTap: () => context.push(AppRoutes.about),
                ),
                _NavLink(
                  label: 'Contact Us',
                  onTap: () => context.push(AppRoutes.contact),
                ),
              ],
              const Spacer(),
              _buildAuthActions(isWide),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthActions(bool isWide) {
    if (!isAuthenticated) {
      if (isWide) {
        return ElevatedButton.icon(
          onPressed: onLogin,
          icon: const Icon(Icons.login, size: 18),
          label: const Text('Login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 2,
          ),
        );
      }
      return IconButton(
        onPressed: onLogin,
        tooltip: 'Login',
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.all(10),
        ),
        icon: const Icon(Icons.login, size: 20),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onAdmin != null)
          IconButton(
            onPressed: onAdmin,
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
            tooltip: 'Dashboard',
          ),
        if (onUserMenu != null)
          IconButton(
            onPressed: onUserMenu,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_circle,
                color: Colors.white,
                size: 24,
              ),
            ),
            tooltip: 'Account',
          ),
        if (onLogout != null)
          isWide
              ? OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                )
              : IconButton(
                  onPressed: onLogout,
                  tooltip: 'Logout',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.all(10),
                  ),
                  icon: const Icon(Icons.logout, size: 20),
                ),
      ],
    );
  }
}

/// Shared landing nav bar with login/logout wired to auth controllers.
class HomeLandingAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeLandingAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final userController = Get.put(UserManagementController());
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());

    return Obx(
      () => HomeLandingNavBar(
        isAuthenticated: userController.isAuthenticated,
        onLogin: () => context.go(AppRoutes.login),
        onLogout: userController.isAuthenticated
            ? () async {
                await authController.signOut();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              }
            : null,
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final VoidCallback? onTap;

  const _Logo({this.onTap});

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.self_improvement,
        color: AppTheme.primaryColor,
        size: 28,
      ),
    );

    if (onTap == null) return icon;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: icon,
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }
}

typedef _HeroBannerSlide = ({
  String imageAsset,
  String headline,
  String subtitle,
  String buttonLabel,
  _HeroSlideAction action,
});

enum _HeroSlideAction { explore, viewResults, viewCompetitions }

class HomeHeroSection extends StatefulWidget {
  final VoidCallback onExplore;

  const HomeHeroSection({super.key, required this.onExplore});

  @override
  State<HomeHeroSection> createState() => _HomeHeroSectionState();
}

class _HomeHeroSectionState extends State<HomeHeroSection> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  static final List<_HeroBannerSlide> _slides = [
    (
      imageAsset: 'assets/images/banners/banner-1.jpg',
      headline: 'Register, Compete & Celebrate Excellence',
      subtitle:
          'Your platform for Yogasana championships — registration, scoring, and results in one place.',
      buttonLabel: 'Explore Competitions',
      action: _HeroSlideAction.explore,
    ),
    (
      imageAsset: 'assets/images/banners/banner-2.jpg',
      headline: 'Digital Scoring & Transparent Results',
      subtitle:
          'Jury panels, live marks entry, and published results — all managed online.',
      buttonLabel: 'View Results',
      action: _HeroSlideAction.viewResults,
    ),
    (
      imageAsset: 'assets/images/banners/banner-3.jpg',
      headline: 'Practice. Compete. Grow.',
      subtitle:
          'Join Yogasana championships near you — register online and showcase your talent.',
      buttonLabel: 'View Competitions',
      action: _HeroSlideAction.viewCompetitions,
    ),
  ];

  @override
  void dispose() {
    _carouselController.stopAutoPlay();
    super.dispose();
  }

  void _onSlideAction(_HeroSlideAction action) {
    if (!mounted) return;
    switch (action) {
      case _HeroSlideAction.explore:
        widget.onExplore();
      case _HeroSlideAction.viewResults:
        context.push(AppRoutes.competitionsList(status: 'completed'));
      case _HeroSlideAction.viewCompetitions:
        context.push(AppRoutes.competitions);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < HomeLayout.mobile;
    final padH = HomeLayout.sectionHorizontalPadding(width);
    final bannerHeight = isMobile ? 380.0 : 480.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(padH, 12, padH, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: bannerHeight,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CarouselSlider.builder(
                key: const ValueKey('home_hero_carousel'),
                carouselController: _carouselController,
                itemCount: _slides.length,
                itemBuilder: (context, index, realIndex) {
                  final slide = _slides[index];
                  return _HeroSlideView(
                    slide: slide,
                    isMobile: isMobile,
                    onPressed: () => _onSlideAction(slide.action),
                  );
                },
                options: CarouselOptions(
                  height: bannerHeight,
                  viewportFraction: 1.0,
                  autoPlay: _slides.length > 1,
                  autoPlayInterval: const Duration(seconds: 5),
                  autoPlayAnimationDuration: const Duration(milliseconds: 700),
                  enlargeCenterPage: false,
                  enableInfiniteScroll: _slides.length > 1,
                  onPageChanged: (index, reason) {
                    if (!mounted) return;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() => _currentIndex = index);
                    });
                  },
                ),
              ),
              if (_slides.length > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final active = _currentIndex == index;
                      return GestureDetector(
                        onTap: () {
                          if (!mounted) return;
                          _carouselController.animateToPage(index);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: active ? 28 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroSlideView extends StatelessWidget {
  final _HeroBannerSlide slide;
  final bool isMobile;
  final VoidCallback onPressed;

  const _HeroSlideView({
    required this.slide,
    required this.isMobile,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          slide.imageAsset,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => Container(color: AppTheme.primaryColor),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.42, 0.72],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 20 : 48,
            isMobile ? 28 : 40,
            isMobile ? 20 : 48,
            isMobile ? 44 : 52,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                slide.headline,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 22 : 34,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                  shadows: const [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                slide.subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: isMobile ? 14 : 16,
                  height: 1.45,
                  shadows: const [
                    Shadow(
                      color: Colors.black38,
                      blurRadius: 6,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 22 : 28,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  slide.buttonLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < HomeLayout.mobile;
    final titleStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: AppTheme.primaryColor,
      fontSize: isMobile ? 22 : 28,
      height: 1.1,
    );
    final subtitleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Colors.grey.shade600,
      fontSize: isMobile ? 13 : 15,
      height: 1.2,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, textAlign: TextAlign.center, style: titleStyle),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, textAlign: TextAlign.center, style: subtitleStyle),
        ],
      ],
    );
  }
}

class HomeEventsGridSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<HomeCompetitionModel> competitions;
  final String? viewMoreStatus;
  final bool showOpenBadge;
  final bool showRegistrationQr;
  final bool showShareLinkOption;
  final Color backgroundColor;
  final bool compactTop;

  const HomeEventsGridSection({
    super.key,
    required this.title,
    required this.competitions,
    this.subtitle,
    this.viewMoreStatus,
    this.showOpenBadge = false,
    this.showRegistrationQr = false,
    this.showShareLinkOption = false,
    this.backgroundColor = Colors.white,
    this.compactTop = false,
  });

  @override
  Widget build(BuildContext context) {
    if (competitions.isEmpty) return const SizedBox.shrink();

    final width = MediaQuery.sizeOf(context).width;
    final padH = HomeLayout.sectionHorizontalPadding(width);
    final crossCount = width >= HomeLayout.tablet
        ? 4
        : (width >= HomeLayout.mobile ? 2 : 1);
    final sectionPadV = HomeLayout.sectionVerticalPadding(width);
    final topPad = compactTop ? 12.0 : sectionPadV;
    final bottomPad = sectionPadV * 0.65;

    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: EdgeInsets.fromLTRB(padH, topPad, padH, bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: _SectionHeader(title: title, subtitle: subtitle),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: crossCount == 1 ? 1.45 : 0.95,
            ),
            itemCount: competitions.length,
            itemBuilder: (context, index) {
              return HomeEventCard(
                competition: competitions[index],
                showOpenBadge: showOpenBadge,
                showRegistrationQr: showRegistrationQr,
                showShareLinkOption: showShareLinkOption,
                openParticipantsOnTap: viewMoreStatus == 'completed',
              );
            },
          ),
          const SizedBox(height: 8),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => context.push(
                viewMoreStatus != null
                    ? AppRoutes.competitionsList(status: viewMoreStatus)
                    : AppRoutes.competitions,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.06),
                side: BorderSide(
                  color: AppTheme.primaryColor.withValues(alpha: 0.45),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('View All'),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeEventCard extends StatelessWidget {
  final HomeCompetitionModel competition;
  final bool showOpenBadge;
  final bool showRegistrationQr;
  final bool showShareLinkOption;
  final bool openParticipantsOnTap;

  const HomeEventCard({
    super.key,
    required this.competition,
    this.showOpenBadge = false,
    this.showRegistrationQr = false,
    this.showShareLinkOption = false,
    this.openParticipantsOnTap = false,
  });

  void _onCardTap(BuildContext context, String id) {
    if (id.isEmpty) return;
    if (openParticipantsOnTap) {
      context.push(
        AppRoutes.publicCompetitionParticipantsPath(
          id,
          competitionName: competition.competitionName,
          isPastCompetition: true,
        ),
      );
      return;
    }
    context.push(AppRoutes.registerCompetitionPath(id));
  }

  @override
  Widget build(BuildContext context) {
    final bannerUrl = competitionBrochureBannerUrl(competition);
    final start = competition.eventStartDate != null
        ? DateTime.tryParse(competition.eventStartDate!)
        : null;
    final dateLabel = start != null
        ? DateFormat('dd MMM yyyy').format(start)
        : 'Date TBA';
    final id = competition.idStr ?? '${competition.id}';

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _onCardTap(context, id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showQr = showRegistrationQr && id.isNotEmpty;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      if (bannerUrl != null && bannerUrl.isNotEmpty)
                        Image.network(
                          bannerUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderImage(),
                        )
                      else
                        _placeholderImage(),
                      if (showOpenBadge)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'OPEN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (showShareLinkOption && id.isNotEmpty)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _ShareRegistrationButton(
                            competition: competition,
                            competitionId: id,
                          ),
                        ),
                      if (showQr)
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: _RegistrationQrBadge(
                            competitionId: id,
                            maxWidth: constraints.maxWidth,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    competition.competitionName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.primaryColor,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          competition.address.isNotEmpty
                              ? competition.address
                              : 'Venue TBA',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: AppTheme.accentSoft(0.06),
      child: Center(
        child: Icon(
          Icons.emoji_events_outlined,
          size: 32,
          color: AppTheme.primaryColor.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _ShareRegistrationButton extends StatelessWidget {
  final HomeCompetitionModel competition;
  final String competitionId;

  const _ShareRegistrationButton({
    required this.competition,
    required this.competitionId,
  });

  void _onShare(BuildContext context) {
    final link = registrationShareUrlForCompetition(
      registrationUrl: competition.registrationUrl,
      competitionId: competitionId,
    );
    Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Registration link copied'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Register',
          onPressed: () {
            if (!context.mounted) return;
            context.push(AppRoutes.registerCompetitionPath(competitionId));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onShare(context),
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.white.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(Icons.share, size: 18, color: AppTheme.primaryColor),
        ),
      ),
    );
  }
}

class _RegistrationQrBadge extends StatelessWidget {
  final String competitionId;
  final double maxWidth;

  const _RegistrationQrBadge({
    required this.competitionId,
    required this.maxWidth,
  });

  double get _qrSize {
    if (maxWidth < 180) return 52;
    if (maxWidth < 260) return 60;
    return 68;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CompetitionRegistrationQrImage(
              competitionId: competitionId,
              size: _qrSize,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 3),
            Text(
              'SCAN TO REGISTER',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: maxWidth < 200 ? 7 : 8,
                height: 1.1,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeServicesSection extends StatefulWidget {
  const HomeServicesSection({super.key});

  @override
  State<HomeServicesSection> createState() => _HomeServicesSectionState();
}

class _HomeServicesSectionState extends State<HomeServicesSection> {
  int _tab = 0;

  static const _tabs = ['Registration', 'Competitions', 'Scoring', 'Results'];
  static const _titles = [
    'Registration Support',
    'Competition Management',
    'Jury Scoring',
    'Results & Reports',
  ];
  static const _bodies = [
    'Streamlined participant registration with online payments, category selection, and instant confirmation receipts.',
    'Create and manage yoga championships with stages, categories, brochures, and venue details in one place.',
    'Digital scoring for jury panels with real-time marks entry and transparent evaluation workflows.',
    'Publish results, download reports, and share certificates with schools and participants.',
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < HomeLayout.mobile;
    final padH = HomeLayout.sectionHorizontalPadding(width);

    return Container(
      width: double.infinity,
      color: Colors.grey.shade50,
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _SectionHeader(
            title: 'Our Services',
            subtitle: 'Everything you need to run a championship',
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_tabs.length, (i) {
                final selected = _tab == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ServiceTabChip(
                    label: _tabs[i],
                    selected: selected,
                    onTap: () => setState(() => _tab = i),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 20 : 28),
              child: isMobile
                  ? Column(
                      children: [
                        _ServiceIllustration(tab: _tab),
                        const SizedBox(height: 20),
                        _ServiceText(
                          label: _tabs[_tab],
                          title: _titles[_tab],
                          body: _bodies[_tab],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: _ServiceText(
                            label: _tabs[_tab],
                            title: _titles[_tab],
                            body: _bodies[_tab],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 4,
                          child: _ServiceIllustration(tab: _tab),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceTabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ServiceTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.primaryColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: selected ? AppTheme.primaryColor : Colors.grey.shade300,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check, size: 16, color: Colors.white),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceText extends StatelessWidget {
  final String label;
  final String title;
  final String body;

  const _ServiceText({
    required this.label,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ServiceIllustration extends StatelessWidget {
  final int tab;

  const _ServiceIllustration({required this.tab});

  static const _icons = [
    Icons.how_to_reg_outlined,
    Icons.emoji_events_outlined,
    Icons.scoreboard_outlined,
    Icons.assessment_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppTheme.accentSoft(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          _icons[tab % _icons.length],
          size: 72,
          color: AppTheme.primaryColor.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class HomeEnquireSection extends StatefulWidget {
  const HomeEnquireSection({super.key});

  @override
  State<HomeEnquireSection> createState() => _HomeEnquireSectionState();
}

class _HomeEnquireSectionState extends State<HomeEnquireSection> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your email')));
      return;
    }
    final uri = Uri(
      scheme: 'mailto',
      path: 'praveen.sekar@glaum.in',
      query: Uri(
        queryParameters: {
          'subject': '${AppConstants.appName} enquiry',
          'body': 'Email: $email',
        },
      ).query,
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open email app')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < HomeLayout.mobile;
    final padH = HomeLayout.sectionHorizontalPadding(width);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: padH, vertical: 8),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 32,
        vertical: 36,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.support_agent,
            color: Colors.white.withValues(alpha: 0.95),
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(
            'Enquire Now',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get in touch about hosting your Yogasana championship on our platform',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: isMobile ? 13 : 15,
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: isMobile
                ? Column(
                    children: [
                      _emailField(),
                      const SizedBox(height: 10),
                      SizedBox(width: double.infinity, child: _submitBtn()),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: _emailField()),
                      const SizedBox(width: 10),
                      _submitBtn(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emailField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: 'Enter your email',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _submitBtn() {
    return ElevatedButton(
      onPressed: _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text(
        'Enquire Now',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class HomeWhyChooseUsSection extends StatelessWidget {
  const HomeWhyChooseUsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < HomeLayout.mobile;
    final padH = HomeLayout.sectionHorizontalPadding(width);

    const items = [
      (
        Icons.auto_awesome,
        'Innovative Platform',
        'Modern tools for registration, scoring, and results.',
      ),
      (
        Icons.groups_outlined,
        'Expert Support',
        'Dedicated onboarding for schools and organizers.',
      ),
      (
        Icons.verified_user_outlined,
        'Reliable Service',
        'Secure payments and dependable event-day operations.',
      ),
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _SectionHeader(
            title: 'Why Choose Us',
            subtitle: 'Trusted by schools and yoga organizers',
          ),
          const SizedBox(height: 24),
          if (isMobile)
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _WhyCard(icon: item.$1, title: item.$2, body: item.$3),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items
                  .map(
                    (item) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _WhyCard(
                          icon: item.$1,
                          title: item.$2,
                          body: item.$3,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _WhyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _WhyCard({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.accentSoft(0.12),
              child: Icon(icon, color: AppTheme.primaryColor, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.4,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeNewsletterSection extends StatefulWidget {
  const HomeNewsletterSection({super.key});

  @override
  State<HomeNewsletterSection> createState() => _HomeNewsletterSectionState();
}

class _HomeNewsletterSectionState extends State<HomeNewsletterSection> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _subscribe() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your email')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Thanks for subscribing with $email')),
    );
    _emailController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < HomeLayout.mobile;
    final padH = HomeLayout.sectionHorizontalPadding(width);

    return Container(
      width: double.infinity,
      color: Colors.grey.shade50,
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: 40),
      child: Column(
        children: [
          Icon(Icons.mail_outline, color: AppTheme.primaryColor, size: 36),
          const SizedBox(height: 10),
          Text(
            'Stay Informed',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Subscribe for competition updates and registration openings',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: isMobile
                ? Column(
                    children: [
                      _field(),
                      const SizedBox(height: 10),
                      SizedBox(width: double.infinity, child: _btn()),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: _field()),
                      const SizedBox(width: 10),
                      _btn(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _field() {
    return TextField(
      controller: _emailController,
      decoration: InputDecoration(
        hintText: 'Your email address',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _btn() {
    return ElevatedButton(
      onPressed: _subscribe,
      style: AppTheme.elevatedButtonStyle,
      child: const Text('Subscribe'),
    );
  }
}

class HomeContactStrip extends StatelessWidget {
  const HomeContactStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < HomeLayout.mobile;
    final padH = HomeLayout.sectionHorizontalPadding(width);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: 32),
      color: Colors.white,
      child: isMobile
          ? const Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _SectionHeader(title: 'Contact Us'),
                SizedBox(height: 16),
                _ContactColumn(),
              ],
            )
          : const Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _SectionHeader(title: 'Contact Us'),
                SizedBox(height: 20),
                _ContactColumn(),
              ],
            ),
    );
  }
}

class _ContactColumn extends StatelessWidget {
  const _ContactColumn();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 32,
      runSpacing: 16,
      children: [
        _contactItem(Icons.email_outlined, 'Email', 'praveen.sekar@glaum.in'),
        _contactItem(Icons.phone_outlined, 'Phone', '+91 9952825358'),
        _contactItem(
          Icons.location_on_outlined,
          'Address',
          'Glaum Technologies, Kulithalai, Karur - 639 104, Tamilnadu, India.',
        ),
      ],
    );
  }

  Widget _contactItem(IconData icon, String label, String value) {
    return SizedBox(
      width: 240,
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
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeCompetitionSections extends StatelessWidget {
  final List<HomeCompetitionModel> competitions;

  const HomeCompetitionSections({super.key, required this.competitions});

  List<HomeCompetitionModel> _byStatus(String status, {int limit = 4}) {
    return competitions.where((c) => c.status == status).take(limit).toList();
  }

  List<HomeCompetitionModel> _pastSorted({int limit = 4}) {
    final past = competitions.where((c) => c.status == 'completed').toList();
    past.sort((a, b) {
      final endA = DateTime.tryParse(a.eventEndDate ?? '') ?? DateTime(1970);
      final endB = DateTime.tryParse(b.eventEndDate ?? '') ?? DateTime(1970);
      return endB.compareTo(endA);
    });
    return past.take(limit).toList();
  }

  @override
  Widget build(BuildContext context) {
    final past = _pastSorted();
    final upcoming = _byStatus('upcoming');
    final ongoing = _byStatus('ongoing');

    return Column(
      children: [
        HomeEventsGridSection(
          title: 'Live Competitions',
          subtitle: 'Happening right now',
          competitions: ongoing,
          viewMoreStatus: 'ongoing',
          showOpenBadge: true,
          showRegistrationQr: true,
          showShareLinkOption: true,
          compactTop: true,
        ),
        HomeEventsGridSection(
          title: 'Upcoming Competitions',
          subtitle: 'Register for upcoming competitions',
          competitions: upcoming,
          viewMoreStatus: 'upcoming',
          showOpenBadge: true,
          showRegistrationQr: true,
          showShareLinkOption: true,
          backgroundColor: Colors.grey.shade50,
        ),
        HomeEventsGridSection(
          title: 'Latest Results',
          subtitle: 'Previous championship outcomes',
          competitions: past,
          viewMoreStatus: 'completed',
        ),
      ],
    );
  }
}

class HomeLandingFooter extends StatelessWidget {
  const HomeLandingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        HomeServicesSection(),
        HomeEnquireSection(),
        HomeWhyChooseUsSection(),
        HomeNewsletterSection(),
        HomeContactStrip(),
        FooterSection(),
      ],
    );
  }
}

class HomeLandingBody extends StatelessWidget {
  final List<HomeCompetitionModel> competitions;
  final ScrollController? scrollController;

  const HomeLandingBody({
    super.key,
    required this.competitions,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        children: [
          HomeHeroSection(
            onExplore: () => context.push(AppRoutes.competitions),
          ),
          HomeCompetitionSections(competitions: competitions),
          const HomeLandingFooter(),
        ],
      ),
    );
  }
}
