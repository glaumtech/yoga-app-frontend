import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/layout/home_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../../controllers/competition_controller.dart';
import '../../controllers/user_management_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/footer_section.dart';
import '../../widgets/searchable_dropdown_field.dart';
import '../home/home_landing_sections.dart';
import '../../widgets/pinned_scroll_views.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  static const _supportEmail = 'praveen.sekar@glaum.in';
  static const _phone = '+91 9952825358';
  static const _address =
      'Glaum Technologies, Kulithalai, Karur - 639 104, Tamilnadu, India.';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _callbackEmailController = TextEditingController();

  String? _userType;
  String? _querySubtype;
  String? _selectedEvent;
  String? _attachedFileName;

  static const _userTypes = [
    'Participant',
    'School / Institution',
    'Event Organizer',
    'Jury Member',
    'Other',
  ];

  static const _querySubtypes = [
    'Registration',
    'Payment',
    'Results & Certificates',
    'Scoring / Jury',
    'Technical Support',
    'Other',
  ];

  static const _whyChooseItems = [
    (
      Icons.timer_outlined,
      'Accurate Scoring & Results',
      'Live jury marks entry with transparent, published results for every category.',
    ),
    (
      Icons.emoji_events_outlined,
      'Elevate Your Championship',
      'Professional registration pages, QR codes, and brochures for your Yogasana event.',
    ),
    (
      Icons.route_outlined,
      'Effortless Start to Finish',
      'From online registration to certificates — one platform for the full event cycle.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Get.isRegistered<CompetitionController>()) {
        Get.put(CompetitionController());
      }
      Get.find<CompetitionController>().ensureHomeCompetitionsLoaded();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _callbackEmailController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      suffixIcon: suffix,
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _attachedFileName = result.files.first.name);
    }
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userType == null || _querySubtype == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select user type and query type')),
      );
      return;
    }

    final body = [
      'Name: ${_nameController.text.trim()}',
      'User Type: $_userType',
      'Query Type: $_querySubtype',
      'Event: ${_selectedEvent ?? 'Not event specific'}',
      'Email: ${_emailController.text.trim()}',
      if (_attachedFileName != null) 'Attachment: $_attachedFileName',
      '',
      'Description:',
      _descriptionController.text.trim(),
    ].join('\n');

    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: Uri(
        queryParameters: {
          'subject': '${AppConstants.appName} support ticket',
          'body': body,
        },
      ).query,
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening email app to send your ticket')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app')),
      );
    }
  }

  Future<void> _requestCallback() async {
    final email = _callbackEmailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: Uri(
        queryParameters: {
          'subject': '${AppConstants.appName} callback request',
          'body': 'Please call me back regarding hosting a Yogasana championship.\n\nEmail: $email',
        },
      ).query,
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

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
      body: PinnedVerticalScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1140),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padH, 32, padH, 0),
                  child: Column(
                    children: [
                      Text(
                        'Contact Us',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Have a question about registration, payments, or your event? '
                        'Choose the right channel below or submit a ticket and our team will respond.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.55,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildQueryInfoBoxes(isMobile),
                      const SizedBox(height: 40),
                      _buildTicketSection(context, isMobile),
                      const SizedBox(height: 40),
                      _buildContactDetailsRow(isMobile),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            _buildEnquireSection(isMobile, padH),
            _buildWhyChooseSection(isMobile, padH),
            const FooterSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildQueryInfoBoxes(bool isMobile) {
    final boxes = [
      (
        'Registration & Event Related Queries',
        'Questions about participant registration, categories, bonafide certificates, '
            'or a specific competition should be directed to the event organizer. '
            'Use the form below and select the relevant event.',
      ),
      (
        'Platform Queries (Payments & Scoring)',
        'For payment issues, maintenance fees, jury login, scoring, results publication, '
            'or technical problems with ${AppConstants.appName}, submit a ticket below '
            'or email $_supportEmail.',
      ),
    ];

    if (isMobile) {
      return Column(
        children: boxes
            .map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _InfoBox(title: b.$1, body: b.$2),
              ),
            )
            .toList(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: boxes
          .map(
            (b) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _InfoBox(title: b.$1, body: b.$2),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTicketSection(BuildContext context, bool isMobile) {
    final formCard = _buildTicketForm(context);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTicketIntro(),
          const SizedBox(height: 20),
          formCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildTicketIntro()),
        const SizedBox(width: 32),
        Expanded(flex: 2, child: formCard),
      ],
    );
  }

  Widget _buildTicketIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SUBMIT A TICKET',
          style: TextStyle(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Have a query or want to ask? Fill out the form to get in touch with us.',
          style: TextStyle(
            fontSize: 15,
            height: 1.55,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTicketForm(BuildContext context) {
    final competitionController = Get.find<CompetitionController>();

    return Card(
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _formRow(
                isMobile: true,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: _fieldDecoration('Name'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _formRow(
                isMobile: MediaQuery.sizeOf(context).width < HomeLayout.mobile,
                children: [
                  DropdownButtonFormField<String>(
                    value: _userType,
                    decoration: _fieldDecoration('User Type'),
                    hint: const Text('Select'),
                    items: _userTypes
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _userType = v),
                  ),
                  DropdownButtonFormField<String>(
                    value: _querySubtype,
                    decoration: _fieldDecoration('Query Subtype'),
                    hint: const Text('Select'),
                    items: _querySubtypes
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _querySubtype = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Obx(() {
                final events = competitionController.homeCompetitions
                    .where((c) => c.competitionName.trim().isNotEmpty)
                    .toList();
                return SearchableDropdownField(
                  selectedValue: _selectedEvent,
                  labelText: 'Event',
                  hintText: 'Not event specific',
                  emptyOptionLabel: 'Not event specific',
                  emptyOptionValue: 'Not event specific',
                  fillColor: Colors.white,
                  items: events
                      .map(
                        (c) => SearchableDropdownItem(
                          value: c.competitionName,
                          label: c.competitionName,
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedEvent = v),
                );
              }),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _fieldDecoration('Email'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: Text(
                    _attachedFileName ?? 'Choose File',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: _fieldDecoration('Description'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _submitTicket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'SUBMIT',
                    style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formRow({
    required bool isMobile,
    required List<Widget> children,
  }) {
    if (isMobile || children.length == 1) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            children[i],
          ],
        ],
      );
    }
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: children[i]),
        ],
      ],
    );
  }

  Widget _buildContactDetailsRow(bool isMobile) {
    final items = [
      _ContactDetailBlock(
        title: 'Address',
        value: _address,
        icon: Icons.location_on_outlined,
      ),
      _ContactDetailBlock(
        title: 'Email',
        value: _supportEmail,
        icon: Icons.email_outlined,
        onTap: () => launchUrl(Uri.parse('mailto:$_supportEmail')),
      ),
      _ContactDetailBlock(
        title: 'Social Media',
        value: '',
        icon: Icons.share_outlined,
        socialRow: true,
      ),
    ];

    if (isMobile) {
      return Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: item,
              ),
            )
            .toList(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: item,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEnquireSection(bool isMobile, double padH) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(padH, 0, padH, 32),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: isMobile
              ? Column(
                  children: [
                    _enquireCopy(context),
                    const SizedBox(height: 24),
                    _callbackForm(isMobile),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _enquireCopy(context)),
                    const SizedBox(width: 32),
                    Expanded(child: _callbackForm(isMobile)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _enquireCopy(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.support_agent, color: Colors.white.withValues(alpha: 0.95), size: 40),
        const SizedBox(height: 12),
        Text(
          'Enquire Now',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'Get in touch about hosting your Yogasana championship on our platform',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'From registration and jury scoring to published results and certificates — '
          'we help organizers run professional events with less admin work.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _callbackForm(bool isMobile) {
    return isMobile
        ? Column(
            children: [
              _callbackEmailField(),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: _callbackButton()),
            ],
          )
        : Row(
            children: [
              Expanded(child: _callbackEmailField()),
              const SizedBox(width: 12),
              _callbackButton(),
            ],
          );
  }

  Widget _callbackEmailField() {
    return TextField(
      controller: _callbackEmailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: 'Your Email',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _callbackButton() {
    return ElevatedButton(
      onPressed: _requestCallback,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A2744),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text(
        'Request Call Back',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildWhyChooseSection(bool isMobile, double padH) {
    return Padding(
      padding: EdgeInsets.fromLTRB(padH, 8, padH, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: Column(
            children: [
              Text(
                'Why Choose Us',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 28),
              if (isMobile)
                ..._whyChooseItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _WhyChooseCard(
                      icon: item.$1,
                      title: item.$2,
                      body: item.$3,
                    ),
                  ),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _whyChooseItems
                      .map(
                        (item) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: _WhyChooseCard(
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
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String title;
  final String body;

  const _InfoBox({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
      ),
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
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactDetailBlock extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final bool socialRow;

  const _ContactDetailBlock({
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
    this.socialRow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 10),
        if (socialRow)
          Row(
            children: [
              _SocialIcon(
                icon: Icons.public,
                onTap: () => launchUrl(
                  Uri.parse('https://glaum.in'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              const SizedBox(width: 10),
              _SocialIcon(
                icon: Icons.email_outlined,
                onTap: () => launchUrl(Uri.parse('mailto:praveen.sekar@glaum.in')),
              ),
              const SizedBox(width: 10),
              _SocialIcon(
                icon: Icons.phone_outlined,
                onTap: () => launchUrl(Uri.parse('tel:+919952825358')),
              ),
            ],
          )
        else
          InkWell(
            onTap: onTap,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Colors.grey.shade700,
                      decoration: onTap != null ? TextDecoration.underline : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SocialIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 16, color: AppTheme.primaryColor),
      ),
    );
  }
}

class _WhyChooseCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _WhyChooseCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 36, color: AppTheme.primaryColor),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
