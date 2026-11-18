import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/participant_feedback_model.dart';
import '../../data/repositories/participant_feedback_repository.dart';

Future<void> showPublicFeedbackListDialog({
  required BuildContext context,
  required String competitionId,
  required String competitionName,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _PublicFeedbackListDialog(
      competitionId: competitionId,
      competitionName: competitionName,
    ),
  );
}

class _PublicFeedbackListDialog extends StatefulWidget {
  final String competitionId;
  final String competitionName;

  const _PublicFeedbackListDialog({
    required this.competitionId,
    required this.competitionName,
  });

  @override
  State<_PublicFeedbackListDialog> createState() =>
      _PublicFeedbackListDialogState();
}

class _PublicFeedbackListDialogState extends State<_PublicFeedbackListDialog> {
  static const int _pageSize = 5;

  final ParticipantFeedbackRepository _repository =
      ParticipantFeedbackRepository();

  bool _loading = true;
  String? _error;
  List<ParticipantFeedbackModel> _feedbacks = const [];
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  int get _pageCount {
    if (_feedbacks.isEmpty) return 1;
    return ((_feedbacks.length - 1) ~/ _pageSize) + 1;
  }

  List<ParticipantFeedbackModel> get _pageItems {
    final start = _page * _pageSize;
    if (start >= _feedbacks.length) return const [];
    final end = (start + _pageSize).clamp(0, _feedbacks.length);
    return _feedbacks.sublist(start, end);
  }

  int get _rangeStart => _feedbacks.isEmpty ? 0 : _page * _pageSize + 1;

  int get _rangeEnd {
    if (_feedbacks.isEmpty) return 0;
    final end = (_page + 1) * _pageSize;
    return end > _feedbacks.length ? _feedbacks.length : end;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final response = await _repository.listPublicByCompetition(
      widget.competitionId,
    );
    if (!mounted) return;
    if (!response.success || response.data == null) {
      setState(() {
        _loading = false;
        _error = response.message ?? 'Failed to load reviews';
        _feedbacks = const [];
        _page = 0;
      });
      return;
    }
    setState(() {
      _loading = false;
      _feedbacks = response.data!;
      _page = 0;
    });
  }

  void _showFeedback(ParticipantFeedbackModel feedback) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _FeedbackDetailDialog(feedback: feedback),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final dialogWidth = width < 760 ? width - 24 : 720.0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const Divider(height: 1),
            if (_loading)
              const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _buildMessage(
                context,
                _error!,
                action: TextButton(onPressed: _load, child: const Text('Retry')),
              )
            else if (_feedbacks.isEmpty)
              _buildMessage(context, 'No public reviews yet.')
            else
              _buildTable(context),
            const Divider(height: 1),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.rate_review_outlined,
              size: 18,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reviews',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                    height: 1.1,
                  ),
                ),
                if (widget.competitionName.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.competitionName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(BuildContext context, String message, {Widget? action}) {
    return SizedBox(
      height: 180,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
            ),
          ),
          if (action != null) ...[const SizedBox(height: 8), action],
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    final items = _pageItems;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _tableRow(
          context,
          index: 'S.No',
          participant: 'Participant',
          review: 'Review',
        ),
        for (var i = 0; i < items.length; i++)
          _ReviewTableRow(
            indexLabel: '${_page * _pageSize + i + 1}',
            name: (items[i].participantName ?? '').trim(),
            review: _previewText(items[i].reviewText),
            onView: () => _showFeedback(items[i]),
          ),
      ],
    );
  }

  Widget _tableRow(
    BuildContext context, {
    required String index,
    required String participant,
    required String review,
  }) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Colors.grey[600],
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
    );
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 44, child: Text(index, style: style)),
          Expanded(flex: 4, child: Text(participant, style: style)),
          Expanded(flex: 7, child: Text(review, style: style)),
          SizedBox(
            width: 88,
            child: Align(
              alignment: Alignment.center,
              child: Text('View', style: style),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final countLabel = _feedbacks.isEmpty
        ? ''
        : 'Showing $_rangeStart–$_rangeEnd of ${_feedbacks.length}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
      child: Row(
        children: [
          if (countLabel.isNotEmpty)
            Text(
              countLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          const Spacer(),
          if (_feedbacks.length > _pageSize) ...[
            IconButton(
              tooltip: 'Previous page',
              visualDensity: VisualDensity.compact,
              onPressed: _page > 0 ? () => setState(() => _page -= 1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              '${_page + 1} / $_pageCount',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              tooltip: 'Next page',
              visualDensity: VisualDensity.compact,
              onPressed: _page + 1 < _pageCount
                  ? () => setState(() => _page += 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
            const SizedBox(width: 4),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static String _previewText(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class _ReviewTableRow extends StatefulWidget {
  final String indexLabel;
  final String name;
  final String review;
  final VoidCallback onView;

  const _ReviewTableRow({
    required this.indexLabel,
    required this.name,
    required this.review,
    required this.onView,
  });

  @override
  State<_ReviewTableRow> createState() => _ReviewTableRowState();
}

class _ReviewTableRowState extends State<_ReviewTableRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.name.isEmpty ? 'Participant' : widget.name;
    final initial = name.substring(0, 1).toUpperCase();

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: _hover ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
        child: InkWell(
          onTap: widget.onView,
          child: Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    widget.indexLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                        child: Text(
                          initial,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F2933),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 7,
                  child: Text(
                    widget.review,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 88,
                  child: Align(
                    alignment: Alignment.center,
                    child: OutlinedButton(
                      onPressed: widget.onView,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(
                          color: AppTheme.primaryColor.withOpacity(0.45),
                        ),
                        minimumSize: const Size(72, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('View'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackDetailDialog extends StatelessWidget {
  final ParticipantFeedbackModel feedback;

  const _FeedbackDetailDialog({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final imageUrl = feedback.absoluteImageUrl(BaseUrl.baseUrl);
    final name = (feedback.participantName ?? '').trim();
    final review = feedback.reviewText.trim();
    final initial = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
    final width = MediaQuery.sizeOf(context).width;
    final dialogWidth = width < 560 ? width - 32 : 480.0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Feedback',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          name.isEmpty ? 'Participant' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.6,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (imageUrl != null && imageUrl.isNotEmpty) ...[
                      _FeedbackImage(url: imageUrl),
                      const SizedBox(height: 14),
                    ],
                    if (review.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F7F4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.12),
                          ),
                        ),
                        child: Text(
                          review,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                height: 1.5,
                                color: const Color(0xFF243028),
                              ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackImage extends StatefulWidget {
  final String url;

  const _FeedbackImage({required this.url});

  @override
  State<_FeedbackImage> createState() => _FeedbackImageState();
}

class _FeedbackImageState extends State<_FeedbackImage> {
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        widget.url,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_failed) setState(() => _failed = true);
          });
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
