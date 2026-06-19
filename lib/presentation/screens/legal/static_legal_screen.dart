import 'package:flutter/material.dart';

class StaticLegalScreen extends StatelessWidget {
  final String title;
  final List<String> paragraphs;

  const StaticLegalScreen({
    super.key,
    required this.title,
    required this.paragraphs,
  });

  static StaticLegalScreen? forDocType(String docType) {
    switch (docType) {
      case 'privacy':
        return const StaticLegalScreen(
          title: 'Privacy Policy',
          paragraphs: _privacyPolicy,
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
    'For privacy-related queries, email praveen.sekar@glaum.in.',
  ];

  static const _refundPolicy = [
    'Registration fees, where applicable, are set by the competition organizer. '
        'Refund eligibility depends on the specific event policy and payment method used.',
    'Online payments processed via Razorpay are subject to the organizer\'s cancellation '
        'rules. Contact the organizer before the event date for refund requests.',
    'Spot registrations and manual payments follow the organizer\'s local refund policy.',
    'For refund assistance, email praveen.sekar@glaum.in with your registration number '
        'and competition name.',
  ];

  static const _termsAndConditions = [
    'By registering for a competition on this platform, you agree to provide accurate '
        'information and comply with event rules set by the organizer.',
    'Participants must follow venue guidelines, jury instructions, and category eligibility '
        'criteria. The organizer may reject or disqualify entries that violate rules.',
    'Certificates, results, and awards are issued as per organizer policies. Glaum '
        'Technologies provides the platform and is not liable for on-ground event incidents '
        'beyond applicable law.',
    'For questions about terms, contact praveen.sekar@glaum.in.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          for (final paragraph in paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                paragraph,
                style: const TextStyle(fontSize: 15, height: 1.6),
              ),
            ),
        ],
      ),
    );
  }
}
