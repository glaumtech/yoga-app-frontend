import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/participant_e_certificate_download.dart';
import '../../../data/models/participant_model.dart';
import '../../../data/repositories/participant_repository.dart';
import '../../widgets/app_navbar.dart';
import '../../widgets/footer_section.dart';

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
  final TextEditingController _searchController = TextEditingController();

  static const int _pageSize = 10;

  List<ParticipantModel> _participants = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  int? _downloadingId;

  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
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

    int? parseId(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '');

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
      optForECertificate: parseBool(reg['optForECertificate']) ||
          parseBool(reg['opt_for_e_certificate']),
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
    if (regId != null) setState(() => _downloadingId = regId);

    await downloadParticipantECertificate(
      context,
      p,
      competitionId: competitionId,
    );

    if (mounted) setState(() => _downloadingId = null);
  }

  bool _canDownloadCert(ParticipantModel p) {
    return widget.isPastCompetition &&
        p.optForECertificate &&
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
      appBar: AppNavbar(title: title),
      body: Column(
        children: [
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
          Expanded(child: _buildBody()),
          const FooterSection(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search by name, registration no., school…',
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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

  Widget _buildBody() {
    if (_loading && _participants.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadParticipants(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_participants.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty
              ? 'No participants registered yet'
              : 'No matching participants',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadParticipants(page: _currentPage),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: _participants.length + 1,
        separatorBuilder: (_, index) => index < _participants.length
            ? const SizedBox(height: 10)
            : const SizedBox.shrink(),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Text(
              '$_totalItems participant${_totalItems == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
            );
          }
          final p = _participants[index - 1];
          return _ParticipantTile(
            participant: p,
            showCertificateDownload: widget.isPastCompetition,
            downloading: _downloadingId == int.tryParse(p.id ?? ''),
            onDownload: _canDownloadCert(p) ? () => _onDownloadCert(p) : null,
          );
        },
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final ParticipantModel participant;
  final bool showCertificateDownload;
  final bool downloading;
  final VoidCallback? onDownload;

  const _ParticipantTile({
    required this.participant,
    required this.showCertificateDownload,
    required this.downloading,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
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
            Expanded(
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
                      if (participant.category.isNotEmpty)
                        participant.category,
                      if (participant.standard.isNotEmpty)
                        participant.standard,
                      if (participant.schoolName.isNotEmpty)
                        participant.schoolName,
                    ].join(' · '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            if (showCertificateDownload && onDownload != null)
              downloading
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : TextButton.icon(
                      onPressed: onDownload,
                      icon: Icon(
                        Icons.download_outlined,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      label: Text(
                        'Certificate',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}
