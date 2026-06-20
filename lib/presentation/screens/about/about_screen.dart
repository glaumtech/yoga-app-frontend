import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/layout/home_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../../controllers/user_management_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/footer_section.dart';
import '../home/home_landing_sections.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  int _testimonialIndex = 0;
  final CarouselSliderController _testimonialController =
      CarouselSliderController();

  static const _progressItems = [
    (label: 'Online Registrations', value: 0.90),
    (label: 'Scoring & Results', value: 0.95),
    (label: 'Certificate Delivery', value: 0.85),
  ];

  static const _testimonials = [
    (
      title: 'From the Organizers of State Yoga Championship:',
      quote:
          'The platform made registration and jury scoring seamless. '
          'Parents and schools could follow results online without any confusion.',
      name: 'Organizing Committee',
      role: 'State Yoga Championship',
    ),
    (
      title: 'From a School Yoga Coordinator:',
      quote:
          'Bulk registration, participant photos, and bonafide uploads in one '
          'place saved our team hours of manual work before every event.',
      name: 'School Coordinator',
      role: 'Inter-School Yogasana Meet',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final userController = Get.put(UserManagementController());
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < HomeLayout.mobile;
    final padH = HomeLayout.sectionHorizontalPadding(width);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Obx(
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
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1140),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padH, 32, padH, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildWhyChooseSection(context, isMobile),
                      const SizedBox(height: 48),
                      _buildAboutSection(context, isMobile),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            _buildTestimonialsSection(context, isMobile, padH),
            const FooterSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWhyChooseSection(BuildContext context, bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWhyChooseText(context),
          const SizedBox(height: 24),
          _buildWhyChooseImage(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _buildWhyChooseText(context)),
        const SizedBox(width: 40),
        Expanded(child: _buildWhyChooseImage()),
      ],
    );
  }

  Widget _buildWhyChooseText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Why Choose Us?',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We help Yoga Organizers and Championship Directors',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textBody,
                height: 1.25,
              ),
        ),
        const SizedBox(height: 28),
        ..._progressItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _ProgressBarRow(
              label: item.label,
              value: item.value,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWhyChooseImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Image.asset(
            'assets/images/banners/banner-3.jpg',
            fit: BoxFit.cover,
            height: 280,
            width: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              height: 280,
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              alignment: Alignment.center,
              child: Icon(
                Icons.self_improvement,
                size: 72,
                color: AppTheme.primaryColor.withValues(alpha: 0.5),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.35),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, bool isMobile) {
    return Column(
      children: [
        Text(
          'About ${AppConstants.appName}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textBody,
              ),
        ),
        const SizedBox(height: 24),
        _buildTeamIllustration(),
        const SizedBox(height: 28),
        Text(
          'Glaum Technologies builds digital platforms for Yogasana championships '
          'across India. From online participant registration and jury scoring to '
          'published results and e-certificates, we help organizers run fair, '
          'transparent events with less paperwork and more time for the sport.\n\n'
          'Our team combines event operations experience with modern software so '
          'schools, districts, and associations can focus on athletes — not admin work. '
          'Whether you host a local meet or a state-level championship, we provide '
          'reliable tools backed by responsive support.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.7,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamIllustration() {
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _teamAvatar(Icons.person, AppTheme.primaryColor),
              const SizedBox(width: 8),
              _teamAvatar(Icons.person_outline, AppTheme.secondaryColor),
              const SizedBox(width: 8),
              _teamAvatar(Icons.groups, AppTheme.primaryColor),
              const SizedBox(width: 8),
              _teamAvatar(Icons.school_outlined, AppTheme.secondaryColor),
            ],
          ),
          Positioned(
            left: 24,
            bottom: 20,
            child: Icon(Icons.eco, size: 48, color: AppTheme.primaryColor.withValues(alpha: 0.25)),
          ),
          Positioned(
            right: 24,
            bottom: 20,
            child: Icon(Icons.eco, size: 48, color: AppTheme.primaryColor.withValues(alpha: 0.25)),
          ),
        ],
      ),
    );
  }

  Widget _teamAvatar(IconData icon, Color color) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildTestimonialsSection(
    BuildContext context,
    bool isMobile,
    double padH,
  ) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF5F7FA),
      padding: EdgeInsets.fromLTRB(padH, 48, padH, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              Text(
                'Overheard from our Yoga Organizers',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textBody,
                    ),
              ),
              const SizedBox(height: 28),
              CarouselSlider.builder(
                carouselController: _testimonialController,
                itemCount: _testimonials.length,
                itemBuilder: (context, index, realIndex) {
                  final item = _testimonials[index];
                  return _TestimonialCard(
                    title: item.title,
                    quote: item.quote,
                    name: item.name,
                    role: item.role,
                  );
                },
                options: CarouselOptions(
                  height: isMobile ? 320 : 280,
                  viewportFraction: 1.0,
                  enableInfiniteScroll: _testimonials.length > 1,
                  onPageChanged: (index, reason) {
                    setState(() => _testimonialIndex = index);
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_testimonials.length, (index) {
                  final active = _testimonialIndex == index;
                  return GestureDetector(
                    onTap: () => _testimonialController.animateToPage(index),
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
          ),
        ),
      ),
    );
  }
}

class _ProgressBarRow extends StatelessWidget {
  final String label;
  final double value;

  const _ProgressBarRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final String title;
  final String quote;
  final String name;
  final String role;

  const _TestimonialCard({
    required this.title,
    required this.quote,
    required this.name,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '"$quote"',
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.grey.shade700,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                  child: Icon(Icons.person, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      role,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
