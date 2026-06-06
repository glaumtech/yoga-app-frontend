import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/participant_repository.dart';
import '../../controllers/participant_controller.dart';
import '../../widgets/admin_sidebar_layout.dart';

/// Read-only participant registration details (matches PDF/HTML template).
class ParticipantRegistrationDetailsScreen extends StatefulWidget {
  final String registrationId;
  final String? participantName;
  final String? competitionName;
  final String? registrationNo;

  const ParticipantRegistrationDetailsScreen({
    super.key,
    required this.registrationId,
    this.participantName,
    this.competitionName,
    this.registrationNo,
  });

  @override
  State<ParticipantRegistrationDetailsScreen> createState() =>
      _ParticipantRegistrationDetailsScreenState();
}

class _ParticipantRegistrationDetailsScreenState
    extends State<ParticipantRegistrationDetailsScreen> {
  final _repository = ParticipantRepository();
  ParticipantController? _participantController;

  Map<String, dynamic>? _registration;
  bool _loading = true;
  String? _error;
  bool _downloadingPdf = false;

  @override
  void initState() {
    super.initState();
    _participantController = Get.isRegistered<ParticipantController>()
        ? Get.find<ParticipantController>()
        : Get.put(ParticipantController());
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetails());
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final response = await _repository.getParticipantRegistrationById(
      widget.registrationId,
    );

    if (!mounted) return;

    if (response.success && response.data != null) {
      final reg = response.data!['registration'];
      if (reg is Map<String, dynamic>) {
        setState(() {
          _registration = Map<String, dynamic>.from(reg);
          _loading = false;
        });
        return;
      }
    }

    setState(() {
      _error = response.message ?? 'Failed to load registration details';
      _loading = false;
    });
  }

  Future<void> _downloadPdf() async {
    setState(() => _downloadingPdf = true);
    try {
      await _participantController?.downloadParticipantRegistrationDetails(
        widget.registrationId,
      );
    } finally {
      if (mounted) setState(() => _downloadingPdf = false);
    }
  }

  String _text(dynamic value) {
    if (value == null) return '—';
    final s = value.toString().trim();
    return s.isEmpty ? '—' : s;
  }

  String _formatDob(dynamic value) {
    if (value == null) return '—';
    final raw = value.toString().trim();
    if (raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  String _formatGender(dynamic value) {
    final raw = _text(value).toUpperCase();
    if (raw == '—') return raw;
    if (raw == 'MALE' || raw == 'M') return 'Male';
    if (raw == 'FEMALE' || raw == 'F') return 'Female';
    return raw[0] + raw.substring(1).toLowerCase();
  }

  String _formatYesNo(dynamic value) {
    if (value == null) return '—';
    if (value is bool) return value ? 'Yes' : 'No';
    final raw = value.toString().trim().toLowerCase();
    if (raw == 'true' || raw == '1') return 'Yes';
    if (raw == 'false' || raw == '0') return 'No';
    return _text(value);
  }

  String? _photoUrl() {
    final id = _registration?['id']?.toString() ?? widget.registrationId;
    if (id.isEmpty) return null;
    return '${BaseUrl.baseUrl}${EndPoints.participantRegistrationPhoto(id)}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isWide = screenWidth >= 900;

    final reg = _registration;
    final headerName = _text(
      reg?['participantName'] ?? widget.participantName ?? 'Participant',
    );
    final headerRegNo = _text(
      reg?['registrationNo'] ?? widget.registrationNo,
    );
    final headerCompetition = _text(
      reg?['competitionName'] ?? widget.competitionName,
    );

    return AdminSidebarLayout(
      title: 'Registration details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.white,
            elevation: 1,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 16,
                vertical: 10,
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () {
                      if (context.canPop()) context.pop();
                    },
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headerName == '—' ? 'Participant' : headerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        if (headerCompetition != '—') ...[
                          const SizedBox(height: 2),
                          Text(
                            headerCompetition,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (headerRegNo != '—') ...[
                          const SizedBox(height: 2),
                          Text(
                            'Reg. No: $headerRegNo',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _downloadingPdf
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          tooltip: 'Download registration details (PDF)',
                          onPressed: _loading ? null : _downloadPdf,
                          icon: Icon(
                            Icons.picture_as_pdf_outlined,
                            color: Colors.blue.shade800,
                          ),
                        ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _buildErrorState()
                : SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 12 : 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildDetailsBody(reg!)),
                                  const SizedBox(width: 20),
                                  _buildPhotoCard(isMobile: false),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildPhotoCard(isMobile: true),
                                  const SizedBox(height: 16),
                                  _buildDetailsBody(reg!),
                                ],
                              ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 40),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Failed to load',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsBody(Map<String, dynamic> reg) {
    final competitionAddress = _text(reg['competitionAddress']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_text(reg['competitionName']) != '—' ||
            competitionAddress != '—') ...[
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                if (_text(reg['competitionName']) != '—')
                  Text(
                    _text(reg['competitionName']),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.sectionHeaderText(),
                      height: 1.35,
                    ),
                  ),
                if (competitionAddress != '—') ...[
                  const SizedBox(height: 6),
                  Text(
                    competitionAddress,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'Participant registration details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.sectionHeaderText(),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        _DetailSection(
          title: 'Participant',
          rows: [
            _DetailRow('Name', _text(reg['participantName'])),
            _DetailRow('Registration no.', _text(reg['registrationNo'])),
            _DetailRow('Date of birth', _formatDob(reg['dateOfBirth'])),
            _DetailRow('Age', _text(reg['age'])),
            _DetailRow('Gender', _formatGender(reg['sex'] ?? reg['gender'])),
            _DetailRow('Category', _text(reg['categoryName'])),
            _DetailRow('Standard / group', _text(reg['groupName'])),
            _DetailRow('Stage', _text(reg['stageName'])),
          ],
        ),
        const SizedBox(height: 14),
        _DetailSection(
          title: 'Institution & teacher',
          rows: [
            _DetailRow('Institution', _text(reg['institutionName'])),
            _DetailRow('Yoga teacher', _text(reg['yogaTeacherName'])),
            _DetailRow('Yoga teacher mobile', _text(reg['yogaTeacherCell'])),
          ],
        ),
        const SizedBox(height: 14),
        _DetailSection(
          title: 'Other',
          rows: [
            _DetailRow('Payment mode', _text(reg['paymentMode'])),
            _DetailRow(
              'Spot registration',
              _formatYesNo(reg['isSpotRegistration']),
            ),
            _DetailRow(
              'Opt for e-certificate',
              _formatYesNo(reg['optForECertificate']),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.only(top: 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            children: [
              Text(
                'Yogasana championship registration system',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppTheme.textHint),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Official receipt — keep for your records',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoCard({required bool isMobile}) {
    final url = _photoUrl();
    return Container(
      width: isMobile ? double.infinity : 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Text(
            'Participant photo',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppTheme.sectionHeaderText(),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 1,
              child: url == null
                  ? ColoredBox(
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.person,
                        size: 64,
                        color: Colors.grey.shade500,
                      ),
                    )
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => ColoredBox(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.rows});

  final String title;
  final List<_DetailRow> rows;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: AppTheme.sectionHeaderBackground(),
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppTheme.sectionHeaderText(),
                ),
              ),
            ),
            Column(
              children: [
                for (var i = 0; i < rows.length; i++)
                  _DetailFieldTableRow(
                    label: rows[i].label,
                    value: rows[i].value,
                    altBackground: i.isOdd,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;
}

class _DetailFieldTableRow extends StatelessWidget {
  const _DetailFieldTableRow({
    required this.label,
    required this.value,
    required this.altBackground,
  });

  final String label;
  final String value;
  final bool altBackground;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: altBackground ? AppColors.rowAlt : AppColors.surface,
          border: const Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: altBackground ? AppColors.rowAlt : AppColors.surface,
        border: const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 220,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
