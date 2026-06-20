class SubscriptionPackageModel {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int credits;
  final String paymentModel;
  final int? subscriptionModeId;
  final String? subscriptionType;
  final int? maxParticipantsPerCompetition;

  /// Display & rules from API (see SubscriptionPackagePresenter on server).
  final String tierLabel;
  final String tierWithPriceLine;
  final String displayLabel;
  final String creditsSummary;
  final String paymentModelLabel;
  final String? subscriptionModeName;
  final bool isAddon;
  final bool requiresSubscriptionPayment;
  final bool isEligibleForCompetitionTopUp;
  final bool isExtraFeeIncludedForCompetition;
  final bool isExtraFeeIncludedForParticipantReg;

  SubscriptionPackageModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.credits,
    required this.paymentModel,
    this.subscriptionModeId,
    this.subscriptionType,
    this.maxParticipantsPerCompetition,
    required this.tierLabel,
    required this.tierWithPriceLine,
    required this.displayLabel,
    required this.creditsSummary,
    required this.paymentModelLabel,
    this.subscriptionModeName,
    required this.isAddon,
    required this.requiresSubscriptionPayment,
    required this.isEligibleForCompetitionTopUp,
    this.isExtraFeeIncludedForCompetition = false,
    this.isExtraFeeIncludedForParticipantReg = false,
  });

  factory SubscriptionPackageModel.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0;
    }

    int parseInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    bool parseBool(dynamic v, {required bool fallback}) {
      if (v is bool) return v;
      if (v == true || v == 1 || v == '1' || v == 'true') return true;
      if (v == false || v == 0 || v == '0' || v == 'false') return false;
      return fallback;
    }

    final id = parseInt(json['id']);
    final name = json['name']?.toString() ?? '';
    final description = json['description']?.toString();
    final price = parsePrice(json['price']);
    final credits = parseInt(json['credits']);
    final paymentModel = json['paymentModel']?.toString() ?? 'ORG_SUBSCRIPTION';
    final subscriptionModeId = json['subscriptionModeId'] == null
        ? null
        : parseInt(json['subscriptionModeId']);
    final subscriptionType = json['subscriptionType']?.toString();
    final maxParticipantsPerCompetition =
        json['maxParticipantsPerCompetition'] == null
        ? null
        : parseInt(json['maxParticipantsPerCompetition']);
    final subscriptionModeName = json['subscriptionModeName']?.toString();

    final isAddon = parseBool(
      json['isAddon'],
      fallback: subscriptionType?.toUpperCase() == 'ADDON',
    );
    final requiresSubscriptionPayment = parseBool(
      json['requiresSubscriptionPayment'],
      fallback:
          paymentModel == 'ORG_SUBSCRIPTION' ||
          paymentModel == 'USER_PACK_SUBSCRIPTION',
    );
    final isEligibleForCompetitionTopUp = parseBool(
      json['isEligibleForCompetitionTopUp'],
      fallback:
          requiresSubscriptionPayment || paymentModel == 'PAY_PER_PARTICIPANT',
    );
    final isExtraFeeIncludedForCompetition = parseBool(
      json['isExtraFeeIncludedForCompetition'],
      fallback: false,
    );
    final isExtraFeeIncludedForParticipantReg = parseBool(
      json['isExtraFeeIncludedForParticipantReg'],
      fallback: false,
    );

    final tierLabel = json['tierLabel']?.toString().trim().isNotEmpty == true
        ? json['tierLabel'].toString()
        : _fallbackTierLabel(name, subscriptionType);
    final tierWithPriceLine =
        json['tierWithPriceLine']?.toString().trim().isNotEmpty == true
        ? json['tierWithPriceLine'].toString()
        : '$tierLabel — ₹${price.toStringAsFixed(0)}';
    final displayLabel =
        json['displayLabel']?.toString().trim().isNotEmpty == true
        ? json['displayLabel'].toString()
        : _fallbackDisplayLabel(name, price, credits, paymentModel);
    final creditsSummary =
        json['creditsSummary']?.toString().trim().isNotEmpty == true
        ? json['creditsSummary'].toString()
        : _fallbackCreditsSummary(price, credits, paymentModel);
    final paymentModelLabel =
        json['paymentModelLabel']?.toString().trim().isNotEmpty == true
        ? json['paymentModelLabel'].toString()
        : (subscriptionModeName?.isNotEmpty == true
              ? subscriptionModeName!
              : paymentModel);

    return SubscriptionPackageModel(
      id: id,
      name: name,
      description: description,
      price: price,
      credits: credits,
      paymentModel: paymentModel,
      subscriptionModeId: subscriptionModeId,
      subscriptionType: subscriptionType,
      maxParticipantsPerCompetition: maxParticipantsPerCompetition,
      tierLabel: tierLabel,
      tierWithPriceLine: tierWithPriceLine,
      displayLabel: displayLabel,
      creditsSummary: creditsSummary,
      paymentModelLabel: paymentModelLabel,
      subscriptionModeName: subscriptionModeName,
      isAddon: isAddon,
      requiresSubscriptionPayment: requiresSubscriptionPayment,
      isEligibleForCompetitionTopUp: isEligibleForCompetitionTopUp,
      isExtraFeeIncludedForCompetition: isExtraFeeIncludedForCompetition,
      isExtraFeeIncludedForParticipantReg: isExtraFeeIncludedForParticipantReg,
    );
  }

  static String _fallbackTierLabel(String name, String? subscriptionType) {
    if (name.contains(' - ')) {
      final parts = name.split(' - ');
      if (parts.length > 1 && parts.last.trim().isNotEmpty) {
        return parts.last.trim();
      }
    }
    if (subscriptionType != null && subscriptionType.isNotEmpty) {
      return subscriptionType
          .toLowerCase()
          .split('_')
          .map(
            (w) => w.isEmpty
                ? ''
                : '${w[0].toUpperCase()}${w.length > 1 ? w.substring(1) : ''}',
          )
          .join(' ');
    }
    return name;
  }

  static String _fallbackDisplayLabel(
    String name,
    double price,
    int credits,
    String paymentModel,
  ) {
    if (paymentModel == 'PAY_PER_PARTICIPANT') {
      return '$name — ₹${price.toStringAsFixed(0)} (per competition)';
    }
    return '$name — ₹${price.toStringAsFixed(0)} ($credits credits)';
  }

  static String _fallbackCreditsSummary(
    double price,
    int credits,
    String paymentModel,
  ) {
    if (paymentModel == 'PAY_PER_PARTICIPANT') {
      return 'On Demand fee: ₹${price.toStringAsFixed(0)} per competition';
    }
    return '$credits credits';
  }
}
