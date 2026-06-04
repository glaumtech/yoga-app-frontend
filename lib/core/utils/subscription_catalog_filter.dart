import '../../data/models/subscription_mode_model.dart';
import '../../data/models/subscription_package_model.dart';

/// Shared filtering and display ordering for subscription catalog UI.
class SubscriptionCatalogFilter {
  SubscriptionCatalogFilter._();

  /// Yearly → User pack → Per Participant.
  static const List<String> modeKeyOrder = [
    'ORG_SUBSCRIPTION',
    'USER_PACK_SUBSCRIPTION',
    'PAY_PER_PARTICIPANT',
  ];

  /// Basic → Standard → Pro → maintenance → other.
  static const List<String> tierTypeOrder = [
    'BASIC',
    'STANDARD',
    'PRO',
    'BASIC_MAINTENANCE',
  ];

  static int modeSortIndex(String modeKey) {
    final i = modeKeyOrder.indexOf(modeKey.toUpperCase());
    return i >= 0 ? i : modeKeyOrder.length;
  }

  static int tierSortIndex(String? subscriptionType) {
    if (subscriptionType == null || subscriptionType.isEmpty) {
      return tierTypeOrder.length;
    }
    final i = tierTypeOrder.indexOf(subscriptionType.toUpperCase());
    return i >= 0 ? i : tierTypeOrder.length;
  }

  static List<SubscriptionModeModel> sortModes(
    Iterable<SubscriptionModeModel> modes,
  ) {
    final list = List<SubscriptionModeModel>.from(modes);
    list.sort((a, b) {
      final byKey = modeSortIndex(a.modeKey).compareTo(modeSortIndex(b.modeKey));
      if (byKey != 0) return byKey;
      return a.name.compareTo(b.name);
    });
    return list;
  }

  static List<SubscriptionPackageModel> sortPackages(
    Iterable<SubscriptionPackageModel> packages,
  ) {
    final list = List<SubscriptionPackageModel>.from(packages);
    list.sort((a, b) {
      final byTier =
          tierSortIndex(a.subscriptionType).compareTo(tierSortIndex(b.subscriptionType));
      if (byTier != 0) return byTier;
      return a.price.compareTo(b.price);
    });
    return list;
  }

  static List<SubscriptionPackageModel> apply(
    Iterable<SubscriptionPackageModel> packages, {
    bool excludeAddons = false,
    int? subscriptionModeId,
    String? paymentModel,
  }) {
    return packages.where((pkg) {
      if (excludeAddons && pkg.isAddon) return false;
      if (subscriptionModeId != null &&
          pkg.subscriptionModeId != null &&
          pkg.subscriptionModeId != subscriptionModeId) {
        return false;
      }
      if (paymentModel != null &&
          paymentModel.isNotEmpty &&
          pkg.paymentModel != paymentModel) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Packages shown during initial organization creation (no addon tiers).
  static List<SubscriptionPackageModel> forOrganizationSetup(
    Iterable<SubscriptionPackageModel> packages, {
    int? subscriptionModeId,
    String? paymentModel,
  }) {
    return sortPackages(
      apply(
        packages,
        excludeAddons: true,
        subscriptionModeId: subscriptionModeId,
        paymentModel: paymentModel,
      ),
    );
  }
}
