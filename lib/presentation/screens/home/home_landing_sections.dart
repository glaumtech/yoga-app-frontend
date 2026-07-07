import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/layout/home_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/competition_brochure_banner_url.dart';
import '../../../core/utils/competition_registration_url.dart';
import '../../../data/models/competition_model.dart';
import '../../../routes/app_routes.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/user_management_controller.dart';
import '../../widgets/competition_participants_qr_image.dart';
import '../../widgets/competition_registration_qr_image.dart';
import '../../widgets/footer_section.dart';
import '../../widgets/pinned_scroll_views.dart';

class HomeLandingNavBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isAuthenticated;
  final VoidCallback onLogin;
  final VoidCallback? onLogout;
  final VoidCallback? onAdmin;
  final String? userName;
  final String? userRole;
  final VoidCallback? onUserAccount;
  final bool showUserProfile;

  const HomeLandingNavBar({
    super.key,
    required this.isAuthenticated,
    required this.onLogin,
    this.onLogout,
    this.onAdmin,
    this.userName,
    this.userRole,
    this.onUserAccount,
    this.showUserProfile = false,
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
        if (showUserProfile)
          _LandingUserMenuButton(
            userName: userName,
            userRole: userRole,
            onLogout: onLogout,
            onUserAccount: onUserAccount,
          )
        else if (onLogout != null)
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

class _LandingUserMenuButton extends StatelessWidget {
  final String? userName;
  final String? userRole;
  final VoidCallback? onLogout;
  final VoidCallback? onUserAccount;

  const _LandingUserMenuButton({
    this.userName,
    this.userRole,
    this.onLogout,
    this.onUserAccount,
  });

  void _openMenu(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    const menuWidth = 228.0;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final left = (offset.dx + size.width - menuWidth).clamp(
      8.0,
      screenWidth - menuWidth - 8,
    );
    final top = offset.dy + size.height + 10;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss account menu',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (dialogContext, _, __) {
        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              child: _LandingUserMenuCard(
                userName: userName,
                userRole: userRole,
                onLogout: onLogout == null
                    ? null
                    : () {
                        Navigator.of(dialogContext).pop();
                        onLogout!();
                      },
                onUserAccount: onUserAccount == null
                    ? null
                    : () {
                        Navigator.of(dialogContext).pop();
                        onUserAccount!();
                      },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openMenu(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
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
      ),
    );
  }
}

class _LandingUserMenuCard extends StatelessWidget {
  final String? userName;
  final String? userRole;
  final VoidCallback? onLogout;
  final VoidCallback? onUserAccount;

  const _LandingUserMenuCard({
    this.userName,
    this.userRole,
    this.onLogout,
    this.onUserAccount,
  });

  @override
  Widget build(BuildContext context) {
    final name = userName?.trim().isNotEmpty == true
        ? userName!.trim()
        : 'User';
    final role = userRole?.trim() ?? '';

    return Material(
      color: Colors.white,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 228,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MenuActionRow(
              onTap: onUserAccount,
              icon: Icons.person_outline,
              iconBackground: AppTheme.primaryColor.withValues(alpha: 0.1),
              iconColor: AppTheme.primaryColor,
              title: name,
              subtitle: role.isEmpty ? null : role,
              titleColor: AppTheme.primaryColor,
              subtitleColor: AppTheme.primaryColor.withValues(alpha: 0.65),
            ),
            if (onLogout != null) ...[
              const SizedBox(height: 10),
              _MenuActionRow(
                onTap: onLogout,
                icon: Icons.logout_rounded,
                iconBackground: const Color(0xFFFFECEF),
                iconColor: const Color(0xFFE53935),
                title: 'Logout',
                titleColor: const Color(0xFFE53935),
                titleFontWeight: FontWeight.w600,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuActionRow extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color titleColor;
  final Color? subtitleColor;
  final FontWeight titleFontWeight;

  const _MenuActionRow({
    required this.onTap,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.titleColor,
    this.subtitleColor,
    this.titleFontWeight = FontWeight.w700,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: subtitle == null
                    ? Text(
                        title,
                        style: TextStyle(
                          color: titleColor,
                          fontWeight: titleFontWeight,
                          fontSize: 15,
                          height: 1.2,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: titleColor,
                              fontWeight: titleFontWeight,
                              fontSize: 15,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
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

    return Obx(() {
      final user = userController.currentUser.value;
      final isAuthenticated = userController.isAuthenticated;

      return HomeLandingNavBar(
        isAuthenticated: isAuthenticated,
        onLogin: () => context.go(AppRoutes.login),
        onLogout: isAuthenticated
            ? () async {
                await authController.signOut();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              }
            : null,
        showUserProfile: isAuthenticated,
        userName: user?.name,
        userRole: user?.userTypeName?.trim().toUpperCase(),
      );
    });
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
  String? imageAsset,
  String? videoAsset,
  String headline,
  String subtitle,
  String buttonLabel,
  _HeroSlideAction action,
});

enum _HeroSlideAction { explore, viewResults, viewCompetitions }

/// Prefetches and reuses a hero banner video so carousel revisits avoid re-init.
class _HeroVideoHandle {
  VideoPlayerController? controller;
  Future<void>? initFuture;
  bool soundOn = !kIsWeb;

  void prefetch(String assetPath) {
    if (controller != null) return;
    final videoController = VideoPlayerController.asset(assetPath);
    controller = videoController;
    initFuture = videoController.initialize().then((_) async {
      await videoController.setLooping(true);
      await videoController.setVolume(soundOn ? 1.0 : 0.0);
    });
  }

  Future<void> dispose() async {
    final videoController = controller;
    controller = null;
    initFuture = null;
    if (videoController == null) return;
    try {
      await videoController.pause();
    } catch (_) {}
    await videoController.dispose();
  }
}

class HomeHeroSection extends StatefulWidget {
  final VoidCallback onExplore;

  const HomeHeroSection({super.key, required this.onExplore});

  @override
  State<HomeHeroSection> createState() => _HomeHeroSectionState();
}

class _HomeHeroSectionState extends State<HomeHeroSection> {
  int _currentIndex = 0;
  Timer? _autoPlayTimer;
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  _HeroVideoHandle? _heroVideoHandle;

  static const Duration _videoSlideDuration = Duration(seconds: 10);
  static const Duration _imageSlideDuration = Duration(seconds: 5);

  static final List<_HeroBannerSlide> _slides = [
    (
      imageAsset: 'assets/images/banners/banner-3.jpg',
      videoAsset: 'assets/images/videos/app-inaguration.mp4',
      headline: 'Welcome to Yoga Champ',
      subtitle:
          'Celebrating the inauguration of your Yogasana competition platform.',
      buttonLabel: 'Explore Competitions',
      action: _HeroSlideAction.explore,
    ),
    (
      imageAsset: 'assets/images/banners/banner-1.jpg',
      videoAsset: null,
      headline: 'Register, Compete & Celebrate Excellence',
      subtitle:
          'Your platform for Yogasana championships — registration, scoring, and results in one place.',
      buttonLabel: 'Explore Competitions',
      action: _HeroSlideAction.explore,
    ),
    (
      imageAsset: 'assets/images/banners/banner-2.jpg',
      videoAsset: null,
      headline: 'Digital Scoring & Transparent Results',
      subtitle:
          'Jury panels, live marks entry, and published results — all managed online.',
      buttonLabel: 'View Results',
      action: _HeroSlideAction.viewResults,
    ),
    (
      imageAsset: 'assets/images/banners/banner-3.jpg',
      videoAsset: null,
      headline: 'Practice. Compete. Grow.',
      subtitle:
          'Join Yogasana championships near you — register online and showcase your talent.',
      buttonLabel: 'View Competitions',
      action: _HeroSlideAction.viewCompetitions,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _prefetchHeroVideo();
    _scheduleAutoPlay();
  }

  void _prefetchHeroVideo() {
    for (final slide in _slides) {
      final path = slide.videoAsset;
      if (path != null && path.isNotEmpty) {
        _heroVideoHandle = _HeroVideoHandle()..prefetch(path);
        break;
      }
    }
  }

  Duration _durationForSlide(int index) {
    final slide = _slides[index];
    final hasVideo = slide.videoAsset != null && slide.videoAsset!.isNotEmpty;
    return hasVideo ? _videoSlideDuration : _imageSlideDuration;
  }

  void _scheduleAutoPlay() {
    _autoPlayTimer?.cancel();
    if (_slides.length <= 1) return;

    _autoPlayTimer = Timer(_durationForSlide(_currentIndex), () {
      if (!mounted) return;
      final next = (_currentIndex + 1) % _slides.length;
      _carouselController.animateToPage(next);
    });
  }

  void _onPageChanged(int index) {
    if (!mounted) return;
    setState(() => _currentIndex = index);
    _scheduleAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
    _carouselController.stopAutoPlay();
    _heroVideoHandle?.dispose();
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
    final bannerHeight = HomeLayout.heroBannerHeight(width);

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
                    isActive: index == _currentIndex,
                    onPressed: () => _onSlideAction(slide.action),
                    videoHandle: slide.videoAsset != null
                        ? _heroVideoHandle
                        : null,
                  );
                },
                options: CarouselOptions(
                  height: bannerHeight,
                  viewportFraction: 1.0,
                  autoPlay: false,
                  autoPlayAnimationDuration: const Duration(milliseconds: 700),
                  enlargeCenterPage: false,
                  enableInfiniteScroll: _slides.length > 1,
                  onPageChanged: (index, reason) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _onPageChanged(index);
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

class _HeroSlideView extends StatefulWidget {
  final _HeroBannerSlide slide;
  final bool isMobile;
  final bool isActive;
  final VoidCallback onPressed;
  final _HeroVideoHandle? videoHandle;

  const _HeroSlideView({
    required this.slide,
    required this.isMobile,
    required this.isActive,
    required this.onPressed,
    this.videoHandle,
  });

  @override
  State<_HeroSlideView> createState() => _HeroSlideViewState();
}

class _HeroSlideViewState extends State<_HeroSlideView> {
  final GlobalKey<_HeroVideoBackgroundState> _videoKey =
      GlobalKey<_HeroVideoBackgroundState>();

  @override
  Widget build(BuildContext context) {
    final slide = widget.slide;
    final videoAsset = slide.videoAsset;
    final imageAsset = slide.imageAsset;
    final isMobile = widget.isMobile;
    final videoState = _videoKey.currentState;
    final showVideoMuteControl =
        videoAsset != null &&
        videoAsset.isNotEmpty &&
        widget.isActive &&
        videoState != null &&
        videoState.isInitialized;

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildSlideBackground(videoAsset, imageAsset),
          Positioned.fill(
            // Let the hero video mute control receive taps in the top-right corner.
            child: IgnorePointer(
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
          ),
          if (showVideoMuteControl)
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.black.withValues(alpha: 0.45),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  onPressed: () => videoState.toggleSound(),
                  tooltip: videoState.isSoundOn
                      ? 'Mute video'
                      : 'Unmute video',
                  icon: Icon(
                    videoState.isSoundOn
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    color: Colors.white,
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
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: widget.onPressed,
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
      ),
    );
  }

  Widget _buildSlideBackground(String? videoAsset, String? imageAsset) {
    if (videoAsset != null && videoAsset.isNotEmpty) {
      if (widget.isActive) {
        return _HeroVideoBackground(
          key: _videoKey,
          assetPath: videoAsset,
          posterAssetPath: imageAsset,
          isActive: true,
          sharedHandle: widget.videoHandle,
          onSoundChanged: () {
            if (mounted) setState(() {});
          },
        );
      }
      if (imageAsset != null && imageAsset.isNotEmpty) {
        return _HeroCoverImage(assetPath: imageAsset);
      }
      return ColoredBox(color: AppTheme.primaryColor);
    }

    if (imageAsset != null && imageAsset.isNotEmpty) {
      return _HeroCoverImage(assetPath: imageAsset);
    }

    return ColoredBox(color: AppTheme.primaryColor);
  }
}

class _HeroCoverImage extends StatelessWidget {
  final String assetPath;

  const _HeroCoverImage({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => ColoredBox(color: AppTheme.primaryColor),
    );
  }
}

class _HeroVideoBackground extends StatefulWidget {
  final String assetPath;
  final String? posterAssetPath;
  final bool isActive;
  final VoidCallback? onSoundChanged;
  final _HeroVideoHandle? sharedHandle;

  const _HeroVideoBackground({
    super.key,
    required this.assetPath,
    this.posterAssetPath,
    required this.isActive,
    this.onSoundChanged,
    this.sharedHandle,
  });

  @override
  State<_HeroVideoBackground> createState() => _HeroVideoBackgroundState();
}

class _HeroVideoBackgroundState extends State<_HeroVideoBackground> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _ownsController = true;
  int _initGeneration = 0;

  bool get isInitialized => _initialized;

  bool get isSoundOn => widget.sharedHandle?.soundOn ?? _localSoundOn;

  bool _localSoundOn = !kIsWeb;

  @override
  void initState() {
    super.initState();
    final sharedController = widget.sharedHandle?.controller;
    if (sharedController != null) {
      _controller = sharedController;
      _ownsController = false;
      _localSoundOn = widget.sharedHandle!.soundOn;
      _bindSharedController();
      return;
    }
    if (widget.isActive) {
      _initController();
    }
  }

  Future<void> _bindSharedController() async {
    final handle = widget.sharedHandle;
    final future = handle?.initFuture;
    if (future != null) {
      try {
        await future;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _initialized = _controller?.value.isInitialized == true;
      _localSoundOn = handle?.soundOn ?? _localSoundOn;
    });
    widget.onSoundChanged?.call();
    _syncPlayback();
  }

  @override
  void didUpdateWidget(covariant _HeroVideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _disposeController();
      if (widget.isActive) {
        _initController();
      }
      return;
    }

    if (widget.isActive && !_initialized) {
      _initController();
      return;
    }
    if (!widget.isActive && _initialized) {
      if (_ownsController) {
        _disposeController();
      } else {
        _syncPlayback();
      }
      return;
    }
    _syncPlayback();
  }

  Future<void> _initController() async {
    final generation = ++_initGeneration;
    final controller = VideoPlayerController.asset(widget.assetPath);
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted || generation != _initGeneration) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(isSoundOn ? 1.0 : 0.0);
      if (!mounted || generation != _initGeneration) {
        await controller.dispose();
        return;
      }
      setState(() => _initialized = true);
      widget.onSoundChanged?.call();
      _syncPlayback();
    } catch (_) {
      if (!mounted || generation != _initGeneration) {
        await controller.dispose();
        return;
      }
      setState(() => _initialized = false);
    }
  }

  Future<void> toggleSound() => _toggleSound();

  Future<void> _toggleSound() async {
    final controller = _controller;
    if (controller == null || !_initialized || !mounted) return;

    final enableSound = !isSoundOn;
    if (widget.sharedHandle != null) {
      widget.sharedHandle!.soundOn = enableSound;
    } else {
      _localSoundOn = enableSound;
    }
    setState(() {});
    widget.onSoundChanged?.call();
    await controller.setVolume(enableSound ? 1.0 : 0.0);
    // Re-trigger play inside the user gesture so browsers allow unmuting audio.
    if (enableSound && widget.isActive) {
      await controller.play();
    }
  }

  void _syncPlayback() {
    if (!mounted) return;
    final controller = _controller;
    if (controller == null || !_initialized) return;
    if (widget.isActive) {
      controller.setVolume(isSoundOn ? 1.0 : 0.0);
      controller.play().catchError((_) {});
    } else {
      controller.pause().catchError((_) {});
    }
  }

  void _disposeController() {
    if (!_ownsController) {
      try {
        _controller?.pause();
      } catch (_) {}
      _initialized = false;
      return;
    }
    _initGeneration++;
    final controller = _controller;
    _controller = null;
    _initialized = false;
    if (controller == null) return;
    try {
      controller.pause();
    } catch (_) {}
    controller.dispose();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _disposeController();
    } else {
      try {
        _controller?.pause();
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final videoReady = _initialized &&
        controller != null &&
        controller.value.isInitialized;
    final posterPath = widget.posterAssetPath;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (posterPath != null && posterPath.isNotEmpty)
          _HeroCoverImage(assetPath: posterPath)
        else
          ColoredBox(color: AppTheme.primaryColor),
        if (videoReady)
          AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 280),
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
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
  final bool showParticipantsQr;
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
    this.showParticipantsQr = false,
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
                showParticipantsQr: showParticipantsQr,
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
  final bool showParticipantsQr;
  final bool showShareLinkOption;
  final bool openParticipantsOnTap;

  const HomeEventCard({
    super.key,
    required this.competition,
    this.showOpenBadge = false,
    this.showRegistrationQr = false,
    this.showParticipantsQr = false,
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
                  final showRegQr = showRegistrationQr && id.isNotEmpty;
                  final showResultsQr = showParticipantsQr && id.isNotEmpty;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      if (bannerUrl != null && bannerUrl.isNotEmpty)
                        Image.network(
                          bannerUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          gaplessPlayback: true,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, __, ___) => _placeholderImage(),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return _placeholderImage(loading: true);
                          },
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
                      if (showResultsQr)
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: _ParticipantsQrBadge(
                            competitionId: id,
                            maxWidth: constraints.maxWidth,
                          ),
                        )
                      else if (showRegQr)
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

  Widget _placeholderImage({bool loading = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.88),
            AppTheme.secondaryColor,
          ],
        ),
      ),
      child: Center(
        child: loading
            ? SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              )
            : Icon(
                Icons.emoji_events_outlined,
                size: 36,
                color: Colors.white.withValues(alpha: 0.85),
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

class _ParticipantsQrBadge extends StatelessWidget {
  final String competitionId;
  final double maxWidth;

  const _ParticipantsQrBadge({
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
            CompetitionParticipantsQrImage(
              competitionId: competitionId,
              size: _qrSize,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 3),
            Text(
              'SCAN FOR RESULTS',
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

class HomeEventsCarouselSection extends StatefulWidget {
  const HomeEventsCarouselSection({super.key});

  @override
  State<HomeEventsCarouselSection> createState() =>
      _HomeEventsCarouselSectionState();
}

typedef _EventCarouselItem = ({
  String? imageAsset,
  String? videoAsset,
  String title,
  String subtitle,
});

class _HomeEventsCarouselSectionState extends State<HomeEventsCarouselSection> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  static const List<_EventCarouselItem> _items = [
    (
      imageAsset: 'assets/images/banners/banner-3.jpg',
      videoAsset: 'assets/images/videos/app-inaguration.mp4',
      title: 'App Inauguration',
      subtitle: 'Launch of the Yoga Champ platform',
    ),
    (
      imageAsset: 'assets/images/banners/banner-1.jpg',
      videoAsset: null,
      title: 'State Championships',
      subtitle: 'Register and compete at state level',
    ),
    (
      imageAsset: 'assets/images/banners/banner-2.jpg',
      videoAsset: null,
      title: 'Digital Scoring',
      subtitle: 'Transparent jury evaluation workflows',
    ),
    (
      imageAsset: 'assets/images/banners/banner-3.jpg',
      videoAsset: null,
      title: 'Practice & Grow',
      subtitle: 'Yogasana events near you',
    ),
  ];

  double _viewportFraction(double width) {
    if (width >= HomeLayout.tablet) return 0.26;
    if (width >= HomeLayout.mobile) return 0.34;
    return 0.86;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < HomeLayout.mobile;
    final padH = HomeLayout.sectionHorizontalPadding(width);
    final cardHeight = isMobile ? 240.0 : 300.0;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(padH, 36, padH, 40),
      child: Column(
        children: [
          const _SectionHeader(
            title: 'Events',
            subtitle: 'Highlights from our yoga championship journey',
          ),
          const SizedBox(height: 24),
          CarouselSlider.builder(
            carouselController: _carouselController,
            itemCount: _items.length,
            itemBuilder: (context, index, realIndex) {
              final active = index == _currentIndex;
              return _EventCarouselCard(
                item: _items[index],
                isActive: active,
                height: cardHeight,
              );
            },
            options: CarouselOptions(
              height: cardHeight + 56,
              viewportFraction: _viewportFraction(width),
              enlargeCenterPage: true,
              enlargeFactor: 0.18,
              enableInfiniteScroll: _items.length > 1,
              autoPlay: _items.length > 1,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayAnimationDuration: const Duration(milliseconds: 650),
              onPageChanged: (index, reason) {
                if (!mounted) return;
                setState(() => _currentIndex = index);
              },
            ),
          ),
          if (_items.length > 1) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_items.length, (index) {
                final active = _currentIndex == index;
                return GestureDetector(
                  onTap: () => _carouselController.animateToPage(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: active ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: active
                          ? AppTheme.primaryColor
                          : AppTheme.primaryColor.withValues(alpha: 0.25),
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _EventCarouselCard extends StatelessWidget {
  final _EventCarouselItem item;
  final bool isActive;
  final double height;

  const _EventCarouselCard({
    required this.item,
    required this.isActive,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final videoAsset = item.videoAsset;
    final imageAsset = item.imageAsset;

    return AnimatedScale(
      scale: isActive ? 1.0 : 0.94,
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (videoAsset != null && videoAsset.isNotEmpty)
                      _EventCarouselVideo(
                        assetPath: videoAsset,
                        posterAssetPath: imageAsset,
                        isActive: isActive,
                      )
                    else if (imageAsset != null && imageAsset.isNotEmpty)
                      Image.asset(
                        imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: AppTheme.primaryColor),
                      )
                    else
                      Container(color: AppTheme.primaryColor),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.72),
                          ],
                          stops: const [0.45, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 12,
                              height: 1.25,
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
      ),
    );
  }
}

class _EventCarouselVideo extends StatefulWidget {
  final String assetPath;
  final String? posterAssetPath;
  final bool isActive;

  const _EventCarouselVideo({
    required this.assetPath,
    this.posterAssetPath,
    required this.isActive,
  });

  @override
  State<_EventCarouselVideo> createState() => _EventCarouselVideoState();
}

class _EventCarouselVideoState extends State<_EventCarouselVideo> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _userStartedPlayback = false;
  int _initGeneration = 0;

  @override
  void initState() {
    super.initState();
    _ensureControllerForActiveSlide();
  }

  @override
  void didUpdateWidget(covariant _EventCarouselVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _disposeController();
      _ensureControllerForActiveSlide();
      return;
    }

    if (!widget.isActive) {
      _pauseAndDispose();
      return;
    }

    _ensureControllerForActiveSlide();
  }

  void _ensureControllerForActiveSlide() {
    if (widget.isActive && !_initialized && _controller == null) {
      _initController();
    }
  }

  Future<void> _initController() async {
    final generation = ++_initGeneration;
    final controller = VideoPlayerController.asset(widget.assetPath);
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted || generation != _initGeneration) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0);
      if (!mounted || generation != _initGeneration) {
        await controller.dispose();
        return;
      }
      setState(() => _initialized = true);
    } catch (_) {
      if (!mounted || generation != _initGeneration) {
        await controller.dispose();
        return;
      }
      setState(() => _initialized = false);
    }
  }

  Future<void> _onPlayTap() async {
    if (!widget.isActive || !mounted) return;

    if (!_initialized || _controller == null) {
      await _initController();
    }

    final controller = _controller;
    if (controller == null || !_initialized || !mounted) return;

    await controller.play();
    if (!mounted) return;
    setState(() => _userStartedPlayback = true);
  }

  void _pauseAndDispose() {
    _userStartedPlayback = false;
    _disposeController();
  }

  void _disposeController() {
    _initGeneration++;
    final controller = _controller;
    _controller = null;
    _initialized = false;
    if (controller == null) return;
    try {
      controller.pause();
    } catch (_) {}
    controller.dispose();
  }

  @override
  void dispose() {
    _pauseAndDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final videoReady = _initialized &&
        controller != null &&
        controller.value.isInitialized;
    final posterPath = widget.posterAssetPath;
    final showPlayIcon = widget.isActive && !_userStartedPlayback;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (posterPath != null && posterPath.isNotEmpty)
          Image.asset(
            posterPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                ColoredBox(color: AppTheme.primaryColor),
          )
        else
          ColoredBox(color: AppTheme.primaryColor),
        if (videoReady)
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
        if (showPlayIcon)
          Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _onPlayTap,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
            ),
          ),
      ],
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
          showParticipantsQr: true,
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
        HomeEventsCarouselSection(),
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
    return PinnedVerticalScrollView(
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
