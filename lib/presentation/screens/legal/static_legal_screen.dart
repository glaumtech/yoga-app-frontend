import 'package:flutter/material.dart';

import '../../../data/repositories/legal_document_repository.dart';

class StaticLegalScreen extends StatefulWidget {
  final String title;
  final List<String> paragraphs;
  final String? docType;

  const StaticLegalScreen({
    super.key,
    required this.title,
    required this.paragraphs,
    this.docType,
  });

  static StaticLegalScreen? forDocType(String docType) {
    switch (docType) {
      case 'privacy':
        return const StaticLegalScreen(
          title: 'Privacy Policy',
          paragraphs: _privacyPolicy,
          docType: 'privacy',
        );
      case 'refund':
        return const StaticLegalScreen(
          title: 'Refund and Cancellation Policy',
          paragraphs: _refundPolicy,
        );
      case 'terms':
        return const StaticLegalScreen(
          title: 'Terms and Conditions',
          paragraphs: _termsAndConditions,
          docType: 'terms',
        );
      default:
        return null;
    }
  }

  static const _privacyPolicy = [
    'Glaum Technologies respects your privacy. Information collected during competition '
        'registration (name, contact details, institution, photos, and certificates) is '
        'used only to administer events, scoring, results, and certificates.',
    'We do not sell personal data to third parties. Data may be shared with event '
        'organizers, jury members, and payment processors strictly for competition operations.',
    'You may contact us to request correction or deletion of your registration data, '
        'subject to legal and operational requirements.',
    'For privacy-related queries, email praveen@glaum.in.',
  ];

  static const _refundPolicy = [
    'Registration fees, where applicable, are set by the competition organizer. '
        'Refund eligibility depends on the specific event policy and payment method used.',
    'Online payments processed via Razorpay are subject to the organizer\'s cancellation '
        'rules. Contact the organizer before the event date for refund requests.',
    'Spot registrations and manual payments follow the organizer\'s local refund policy.',
    'For refund assistance, contact the Competition Organizer with your registration '
        'number and competition name.',
  ];

  static const _termsAndConditions = [
    'By registering for a competition on this platform, you agree to provide accurate '
        'information and comply with event rules set by the organizer.',
    'Participants must follow venue guidelines, jury instructions, and category eligibility '
        'criteria. The organizer may reject or disqualify entries that violate rules.',
    'Certificates, results, and awards are issued as per organizer policies. Glaum '
        'Technologies provides the platform and is not liable for on-ground event incidents '
        'beyond applicable law.',
    'For questions about terms, contact praveen@glaum.in.',
  ];

  static const _refundBoldPhrase = 'contact the Competition Organizer';

  @override
  State<StaticLegalScreen> createState() => _StaticLegalScreenState();
}

class _StaticLegalScreenState extends State<StaticLegalScreen> {
  late String _title;
  late List<String> _paragraphs;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _paragraphs = List<String>.from(widget.paragraphs);
    final docType = widget.docType;
    if (docType != null && (docType == 'terms' || docType == 'privacy')) {
      _loadFromApi(docType);
    }
  }

  Future<void> _loadFromApi(String docType) async {
    setState(() => _loading = true);
    try {
      final resp = await LegalDocumentRepository().getLegalDocument(docType);
      if (!mounted) return;
      if (resp.success && resp.data != null) {
        final data = resp.data!;
        final title = data['title']?.toString();
        final paragraphs = (data['paragraphs'] as List?)
                ?.map((e) => e.toString())
                .where((e) => e.trim().isNotEmpty)
                .toList() ??
            const <String>[];
        if (title != null && title.trim().isNotEmpty) {
          _title = title.trim();
        }
        if (paragraphs.isNotEmpty) {
          _paragraphs = paragraphs;
        }
      }
    } catch (_) {
      // Keep hardcoded fallback content.
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: 15,
      height: 1.6,
      color: Theme.of(context).textTheme.bodyLarge?.color,
    );

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                for (final paragraph in _paragraphs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildParagraph(paragraph, textStyle),
                  ),
              ],
            ),
    );
  }

  Widget _buildParagraph(String paragraph, TextStyle textStyle) {
    if (!paragraph.contains(StaticLegalScreen._refundBoldPhrase)) {
      return Text(paragraph, style: textStyle);
    }

    final parts = paragraph.split(StaticLegalScreen._refundBoldPhrase);
    return Text.rich(
      TextSpan(
        style: textStyle,
        children: [
          TextSpan(text: parts[0]),
          TextSpan(
            text: StaticLegalScreen._refundBoldPhrase,
            style: textStyle.copyWith(fontWeight: FontWeight.bold),
          ),
          if (parts.length > 1) TextSpan(text: parts[1]),
        ],
      ),
    );
  }
}
