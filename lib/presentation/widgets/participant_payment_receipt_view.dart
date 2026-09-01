import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/participant_model.dart';

/// Payment-success receipt card (matches post-registration confirmation UI).
class ParticipantPaymentReceiptView extends StatelessWidget {
  static const Color headerGreen = Color(0xFF18A558);
  static const Color pageBackground = Color(0xFFF3F4F6);

  final ParticipantModel? participant;
  final DateTime? timestamp;
  final bool includeOuterBackground;

  const ParticipantPaymentReceiptView({
    super.key,
    this.participant,
    this.timestamp,
    this.includeOuterBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final ts = timestamp ?? participant?.createdAt ?? DateTime.now();
    final dateFormat = DateFormat('dd-MM-yyyy');
    final timeFormat = DateFormat('HH:mm:ss');
    final hasParticipant = participant != null;
    final hasPayment = hasParticipant && _hasPaymentDetails(participant!);
    final detailItems = _buildDetailItems(
      hasParticipant: hasParticipant,
      hasPayment: hasPayment,
      date: dateFormat.format(ts),
      time: timeFormat.format(ts),
    );

    final receiptCard = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ReceiptHeader(
            title: hasPayment ? 'Payment successful!' : 'Registration successful!',
            orderIdLabel: _orderIdLabel(participant),
            amountLabel: hasPayment && participant?.amount != null
                ? '₹${participant!.amount!.toStringAsFixed(0)}'
                : null,
          ),
          const _ReceiptWaveDivider(
            topColor: headerGreen,
            bottomColor: Colors.white,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
            child: _DetailGrid(items: detailItems),
          ),
        ],
      ),
    );

    if (!includeOuterBackground) {
      return receiptCard;
    }

    return Container(
      width: double.infinity,
      color: pageBackground,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: receiptCard,
          ),
        ),
      ),
    );
  }

  List<_DetailItem> _buildDetailItems({
    required bool hasParticipant,
    required bool hasPayment,
    required String date,
    required String time,
  }) {
    final items = <_DetailItem>[
      _DetailItem(label: 'Date', value: date),
      _DetailItem(label: 'Time', value: time),
    ];

    if (!hasParticipant) {
      items.add(_DetailItem(label: 'Status', value: 'Saved successfully'));
      return items;
    }

    if (_text(participant!.registrationNo).isNotEmpty) {
      items.add(
        _DetailItem(
          label: 'Registration No',
          value: _text(participant!.registrationNo),
          emphasize: true,
        ),
      );
    }
    if (_text(participant!.competitionName).isNotEmpty) {
      items.add(
        _DetailItem(
          label: 'Competition',
          value: _text(participant!.competitionName),
        ),
      );
    }
    items.add(
      _DetailItem(label: 'Participant', value: participant!.participantName),
    );

    if (hasPayment) {
      if (_text(participant!.paymentMode).isNotEmpty) {
        items.add(
          _DetailItem(
            label: 'Payment method',
            value: _formatPaymentMode(participant!),
          ),
        );
      }
      if (_text(participant!.paymentStatus).isNotEmpty) {
        items.add(
          _DetailItem(
            label: 'Status',
            value: _formatPaymentStatus(participant!.paymentStatus!),
          ),
        );
      }
      if (participant!.amount != null) {
        items.add(
          _DetailItem(
            label: 'Total amount',
            value: '₹${participant!.amount!.toStringAsFixed(0)}',
            emphasize: true,
          ),
        );
      }
    } else {
      items.add(_DetailItem(label: 'Status', value: 'Registered'));
    }

    return items;
  }

  static String _text(String? value) => value?.trim() ?? '';

  static String _orderIdLabel(ParticipantModel? p) {
    if (p == null) return 'Reference: —';
    final paymentId = _text(p.razorpayPaymentId);
    if (paymentId.isNotEmpty) return 'Order id: $paymentId';
    final orderId = _text(p.razorpayOrderId);
    if (orderId.isNotEmpty) return 'Order id: $orderId';
    final regNo = _text(p.registrationNo);
    if (regNo.isNotEmpty) return 'Registration no: $regNo';
    return 'Reference: —';
  }

  static bool _hasPaymentDetails(ParticipantModel p) {
    return _text(p.paymentMode).isNotEmpty ||
        _text(p.paymentStatus).isNotEmpty ||
        p.amount != null ||
        _text(p.razorpayPaymentId).isNotEmpty;
  }

  static String _formatPaymentMode(ParticipantModel p) {
    final mode = _text(p.paymentMode);
    switch (mode.toUpperCase()) {
      case 'ONLINE':
        return 'Online (Razorpay)';
      case 'GPAY':
        return 'GPay';
      case 'CASH':
        return 'Cash';
      default:
        return mode;
    }
  }

  static String _formatPaymentStatus(String status) {
    final normalized = status.trim().toUpperCase();
    if (normalized == 'PAID' ||
        normalized == 'SUCCESS' ||
        normalized == 'SUCCESSFUL') {
      return 'Successful';
    }
    return status;
  }
}

class _DetailItem {
  final String label;
  final String value;
  final bool emphasize;

  const _DetailItem({
    required this.label,
    required this.value,
    this.emphasize = false,
  });
}

class _ReceiptHeader extends StatelessWidget {
  final String title;
  final String orderIdLabel;
  final String? amountLabel;

  const _ReceiptHeader({
    required this.title,
    required this.orderIdLabel,
    this.amountLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: ParticipantPaymentReceiptView.headerGreen,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 18),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: ParticipantPaymentReceiptView.headerGreen,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            orderIdLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          if (amountLabel != null) ...[
            const SizedBox(height: 18),
            Text(
              amountLabel!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 34,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReceiptWaveDivider extends StatelessWidget {
  final Color topColor;
  final Color bottomColor;

  const _ReceiptWaveDivider({
    required this.topColor,
    required this.bottomColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      width: double.infinity,
      child: CustomPaint(
        painter: _ReceiptWavePainter(
          topColor: topColor,
          bottomColor: bottomColor,
        ),
      ),
    );
  }
}

class _ReceiptWavePainter extends CustomPainter {
  final Color topColor;
  final Color bottomColor;

  _ReceiptWavePainter({
    required this.topColor,
    required this.bottomColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final topPaint = Paint()..color = topColor;
    final bottomPaint = Paint()..color = bottomColor;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bottomPaint);

    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.5, 0)
      ..quadraticBezierTo(size.width * 0.75, -size.height, size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, topPaint);
  }

  @override
  bool shouldRepaint(covariant _ReceiptWavePainter oldDelegate) {
    return oldDelegate.topColor != topColor ||
        oldDelegate.bottomColor != bottomColor;
  }
}

class _DetailGrid extends StatelessWidget {
  final List<_DetailItem> items;

  const _DetailGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final left = items[i];
      final right = i + 1 < items.length ? items[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _DetailCell(item: left)),
              const SizedBox(width: 14),
              Expanded(
                child: right == null
                    ? const SizedBox.shrink()
                    : _DetailCell(item: right),
              ),
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }
}

class _DetailCell extends StatelessWidget {
  final _DetailItem item;

  const _DetailCell({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: item.emphasize ? FontWeight.w700 : FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
