import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/participant_e_certificate_download.dart';
import '../../../core/utils/participant_receipt_image_download.dart';
import '../../../data/models/participant_feedback_model.dart';
import '../../../data/models/participant_model.dart';
import '../../../data/repositories/competition_repository.dart';
import '../../../data/repositories/participant_feedback_repository.dart';
import '../../../data/repositories/participant_repository.dart';
import '../../widgets/footer_section.dart';
import '../../widgets/pinned_scroll_views.dart';
import 'home_landing_sections.dart';

/// Public list of registrations for one competition with e-certificate download.
class PublicCompetitionParticipantsScreen extends StatefulWidget {
  final String competitionId;
  final String competitionName;
  final bool isPastCompetition;

  const PublicCompetitionParticipantsScreen({
    super.key,
    required this.competitionId,
    this.competitionName = '',
    this.isPastCompetition = false,
  });

  @override
  State<PublicCompetitionParticipantsScreen> createState() =>
      _PublicCompetitionParticipantsScreenState();
}

class _PublicCompetitionParticipantsScreenState
    extends State<PublicCompetitionParticipantsScreen> {
  final ParticipantRepository _repository = ParticipantRepository();
  final CompetitionRepository _competitionRepository = CompetitionRepository();
  final ParticipantFeedbackRepository _feedbackRepository =
      ParticipantFeedbackRepository();
  final TextEditingController _searchController = TextEditingController();

  static const int _pageSize = 10;

  List<ParticipantModel> _participants = [];
  Map<int, ParticipantFeedbackModel> _publicFeedbackByRegistrationId = {};
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  int? _downloadingCertId;
  int? _downloadingDetailsId;
  bool _certificatesReleased = false;

  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _certificatesReleased = widget.isPastCompetition;
    _loadCompetitionMeta();
    _loadPublicFeedback();
    _loadParticipants();
  }

  Future<void> _loadPublicFeedback() async {
    final response = await _feedbackRepository.listPublicByCompetition(
      widget.competitionId,
    );
    if (!mounted || !response.success || response.data == null) return;
    final map = <int, ParticipantFeedbackModel>{};
    for (final item in response.data!) {
      final id = item.registrationId;
      if (id != null) {
        map[id] = item;
      }
    }
    setState(() => _publicFeedbackByRegistrationId = map);
  }

  Future<void> _loadCompetitionMeta() async {
    final competitionId = int.tryParse(widget.competitionId);
    if (competitionId == null) return;

    final response = await _competitionRepository.getCompetitionById(
      competitionId,
    );
    if (!mounted) return;

    if (response.success && response.data != null) {
      setState(() {
        _certificatesReleased = response.data!.areCertificatesAvailable;
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadParticipants({int? page}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final competitionId = int.tryParse(widget.competitionId);
    if (competitionId == null) {
      setState(() {
        _loading = false;
        _error = 'Invalid competition ID';
      });
      return;
    }

    final pageIndex = (page ?? _currentPage) - 1;
    final search = _searchQuery.trim();

    final response = await _repository.listParticipantRegistrations(
      competitionId: competitionId,
      page: pageIndex,
      limit: _pageSize,
      search: search.isEmpty ? null : search,
      order: 'desc',
    );

    if (!mounted) return;

    if (!response.success || response.data == null) {
      setState(() {
        _loading = false;
        _error = response.message ?? 'Failed to load participants';
      });
      return;
    }

    final data = response.data!;
    final registrations = data['registrations'] as List<dynamic>? ?? [];
    final list = <ParticipantModel>[];
    for (final reg in registrations) {
      if (reg is Map<String, dynamic>) {
        list.add(_mapRegistration(reg));
      }
    }

    final pagination = data['pagination'] as Map<String, dynamic>?;
    final totalPages = pagination?['totalPages'] as int? ?? 1;
    final total = pagination?['total'] as int? ?? list.length;
    final apiPage = (pagination?['page'] as int? ?? pageIndex) + 1;

    setState(() {
      _participants = list;
      _totalPages = totalPages < 1 ? 1 : totalPages;
      _totalItems = total;
      _currentPage = apiPage.clamp(1, _totalPages);
      _loading = false;
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _searchQuery = value);
      _loadParticipants(page: 1);
    });
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    setState(() => _currentPage = page);
    _loadParticipants(page: page);
  }

  ParticipantModel _mapRegistration(Map<String, dynamic> reg) {
    DateTime dob = DateTime.now();
    if (reg['dateOfBirth'] != null) {
      try {
        dob = DateTime.parse(reg['dateOfBirth'].toString());
      } catch (_) {}
    }

    int? parseId(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');

    bool parseBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v.toString().toLowerCase();
      return s == 'true' || s == '1' || s == 'yes';
    }

    return ParticipantModel(
      id: reg['id']?.toString(),
      participantName: reg['participantName']?.toString() ?? '',
      dateOfBirth: dob,
      age: reg['age'] is int ? reg['age'] as int : 0,
      gender: reg['sex']?.toString() ?? '',
      category: reg['categoryName']?.toString() ?? '',
      standard: reg['groupName']?.toString() ?? '',
      schoolName: reg['institutionName']?.toString() ?? '',
      address: '',
      yogaMasterName: reg['yogaTeacherName']?.toString() ?? '',
      yogaMasterContact: reg['yogaTeacherCell']?.toString() ?? '',
      registrationNo: reg['registrationNo']?.toString(),
      optForECertificate:
          parseBool(reg['optForECertificate']) ||
          parseBool(reg['opt_for_e_certificate']),
      certificateAvailable: (reg.containsKey('certificateAvailable') ||
              reg.containsKey('certificate_available'))
          ? parseBool(reg['certificateAvailable']) ||
              parseBool(reg['certificate_available'])
          : null,
      stageId: parseId(reg['stageId']),
      categoryId: parseId(reg['categoryId']),
      groupId: parseId(reg['groupId']),
      eventId: widget.competitionId,
    );
  }

  Future<void> _onDownloadCert(ParticipantModel p) async {
    final competitionId = int.tryParse(widget.competitionId);
    if (competitionId == null) return;

    final regId = int.tryParse(p.id ?? '');
    if (regId != null) setState(() => _downloadingCertId = regId);

    await downloadParticipantECertificate(
      context,
      p,
      competitionId: competitionId,
    );

    if (mounted) setState(() => _downloadingCertId = null);
  }

  Future<void> _onDownloadDetails(ParticipantModel p) async {
    final regId = p.id?.trim();
    if (regId == null || regId.isEmpty) return;

    final idNum = int.tryParse(regId);
    if (idNum != null) setState(() => _downloadingDetailsId = idNum);

    await downloadParticipantReceiptImageByRegistrationId(
      context,
      regId,
      seedParticipant: p,
      competitionName: widget.competitionName,
    );

    if (mounted) setState(() => _downloadingDetailsId = null);
  }

  bool _canDownloadCert(ParticipantModel p) {
    if (p.certificateAvailable == true) {
      return p.categoryId != null;
    }
    if (p.certificateAvailable == false) {
      return false;
    }
    return p.optForECertificate &&
        _certificatesReleased &&
        p.stageId != null &&
        p.categoryId != null;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.competitionName.trim().isNotEmpty
        ? widget.competitionName.trim()
        : 'Participants';
    final isNarrow = MediaQuery.sizeOf(context).width < 520;

    return Scaffold(
      appBar: const HomeLandingAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadCompetitionMeta(),
            _loadPublicFeedback(),
            _loadParticipants(page: _currentPage),
          ]);
        },
        child: PinnedVerticalScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: isNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSearchField(),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _buildPaginationControls(),
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: _buildSearchField()),
                          const SizedBox(width: 12),
                          _buildPaginationControls(),
                        ],
                      ),
              ),
              _buildBodyContent(),
              const FooterSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search by registration no. or name',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _searchDebounce?.cancel();
                  setState(() => _searchQuery = '');
                  _loadParticipants(page: 1);
                },
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
      ),
      onChanged: (v) {
        setState(() {});
        _onSearchChanged(v);
      },
    );
  }

  Widget _buildPaginationControls() {
    if (_loading && _participants.isEmpty) {
      return const SizedBox(
        width: 88,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: _currentPage > 1
                ? () => _goToPage(_currentPage - 1)
                : null,
            tooltip: 'Previous page',
          ),
          Text(
            '$_currentPage / $_totalPages',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: _currentPage < _totalPages
                ? () => _goToPage(_currentPage + 1)
                : null,
            tooltip: 'Next page',
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantSkeleton() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              radius: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 160,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: 7,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Row(
            children: [
              Container(
                width: 120,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Loading participants...',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ],
          );
        }
        return _buildParticipantSkeleton();
      },
    );
  }

  Widget _buildBodyContent() {
    if (_loading && _participants.isEmpty) {
      return _buildLoadingList();
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadParticipants(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_participants.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Center(
          child: Text(
            _searchQuery.isEmpty
                ? 'No participants registered yet'
                : 'No matching participants',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: _participants.length + 1,
      separatorBuilder: (_, index) => index < _participants.length
          ? const SizedBox(height: 10)
          : const SizedBox.shrink(),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            '$_totalItems participant${_totalItems == 1 ? '' : 's'}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
          );
        }
        final p = _participants[index - 1];
        final registrationId = int.tryParse(p.id ?? '');
        final feedback = registrationId == null
            ? null
            : _publicFeedbackByRegistrationId[registrationId];
        return _ParticipantTile(
          participant: p,
          publicFeedback: feedback,
          showCertificateDownload: _canDownloadCert(p),
          downloadingCert: _downloadingCertId == int.tryParse(p.id ?? ''),
          downloadingDetails:
              _downloadingDetailsId == int.tryParse(p.id ?? ''),
          onDownloadCert: _canDownloadCert(p)
              ? () => _onDownloadCert(p)
              : null,
          onDownloadDetails: p.id != null && p.id!.trim().isNotEmpty
              ? () => _onDownloadDetails(p)
              : null,
        );
      },
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final ParticipantModel participant;
  final ParticipantFeedbackModel? publicFeedback;
  final bool showCertificateDownload;
  final bool downloadingCert;
  final bool downloadingDetails;
  final VoidCallback? onDownloadCert;
  final VoidCallback? onDownloadDetails;

  const _ParticipantTile({
    required this.participant,
    this.publicFeedback,
    required this.showCertificateDownload,
    required this.downloadingCert,
    required this.downloadingDetails,
    this.onDownloadCert,
    this.onDownloadDetails,
  });

  @override
  Widget build(BuildContext context) {
    final feedbackText = publicFeedback?.reviewText.trim() ?? '';
    final feedbackImageUrl = publicFeedback?.absoluteImageUrl(BaseUrl.baseUrl);
    final hasFeedback =
        feedbackText.isNotEmpty || (feedbackImageUrl?.isNotEmpty ?? false);
    final isNarrow = MediaQuery.sizeOf(context).width < 720;

    final identity = Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            participant.participantName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          if (participant.registrationNo != null &&
              participant.registrationNo!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Reg: ${participant.registrationNo}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            [
              if (participant.category.isNotEmpty) participant.category,
              if (participant.standard.isNotEmpty) participant.standard,
              if (participant.schoolName.isNotEmpty) participant.schoolName,
            ].join(' · '),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
          ),
          if (hasFeedback && isNarrow) ...[
            const SizedBox(height: 10),
            _PublicFeedbackPreview(
              participantName: participant.participantName,
              reviewText: feedbackText,
              imageUrl: feedbackImageUrl,
              compact: true,
            ),
          ],
        ],
      ),
    );

    final actions = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (onDownloadDetails != null)
          downloadingDetails
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _buildDownloadAction(
                  label: 'Download receipt',
                  color: Colors.blue.shade800,
                  onPressed: onDownloadDetails!,
                ),
        if (onDownloadDetails != null &&
            showCertificateDownload &&
            onDownloadCert != null)
          const SizedBox(height: 8),
        if (showCertificateDownload && onDownloadCert != null)
          downloadingCert
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _buildDownloadAction(
                  label: 'Certificate',
                  color: AppTheme.primaryColor,
                  onPressed: onDownloadCert!,
                ),
      ],
    );

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                participant.participantName.isNotEmpty
                    ? participant.participantName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            identity,
            if (hasFeedback && !isNarrow) ...[
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: _PublicFeedbackPreview(
                  participantName: participant.participantName,
                  reviewText: feedbackText,
                  imageUrl: feedbackImageUrl,
                  compact: false,
                ),
              ),
            ],
            const SizedBox(width: 8),
            actions,
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadAction({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.download_outlined, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        alignment: Alignment.centerRight,
      ),
    );
  }
}

class _PublicFeedbackPreview extends StatelessWidget {
  final String participantName;
  final String reviewText;
  final String? imageUrl;
  final bool compact;

  const _PublicFeedbackPreview({
    required this.participantName,
    required this.reviewText,
    this.imageUrl,
    this.compact = false,
  });

  void _showFeedback(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 8, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  'Feedback',
                  style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.close),
                tooltip: 'Close',
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (participantName.trim().isNotEmpty)
                    Text(
                      participantName,
                      style: Theme.of(dialogContext).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  if (imageUrl != null && imageUrl!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 160,
                          alignment: Alignment.center,
                          color: Colors.grey.shade100,
                          child: Icon(
                            Icons.image_outlined,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (reviewText.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      reviewText,
                      style: Theme.of(dialogContext).textTheme.bodyMedium
                          ?.copyWith(height: 1.45, color: Colors.grey[800]),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final showThumb = !compact && imageUrl != null && imageUrl!.isNotEmpty;

    return Material(
      color: const Color(0xFFF3F7F2),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => _showFeedback(context),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(compact ? 8 : 10, 6, 2, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.18)),
          ),
          child: Row(
            children: [
              if (showThumb) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 44,
                      height: 44,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.image_outlined, color: Colors.grey[500]),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: compact
                    ? Text(
                        'View feedback',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Feedback',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          if (reviewText.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              reviewText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[800],
                                    height: 1.35,
                                  ),
                            ),
                          ],
                        ],
                      ),
              ),
              IconButton(
                onPressed: () => _showFeedback(context),
                tooltip: 'View feedback',
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(
                  Icons.visibility_outlined,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
