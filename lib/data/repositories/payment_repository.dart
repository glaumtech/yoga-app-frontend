import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';
import '../models/api_response.dart';
import '../models/payment_order_model.dart';
import '../models/payment_verify_result.dart';
import '../models/subscription_mode_model.dart';
import '../models/subscription_package_model.dart';

class PaymentRepository {
  final APIService _apiService = APIService();
  static const String onDemandCompetitionPurpose = 'on_demand_competition';
  static const String registrationTicketPurpose = 'registration_ticket';

  Future<ApiResponse<Map<String, dynamic>>> getOnDemandContext() async {
    final response = await _apiService.getResponse<dynamic>(
      url: EndPoints.paymentOnDemandContext,
      apiType: APIType.aGet,
    );
    return _mapDataResponse(response);
  }

  Future<ApiResponse<List<SubscriptionModeModel>>> listSubscriptionModes({
    bool includeInactive = false,
  }) async {
    final query = includeInactive ? '?includeInactive=true' : '';
    final response = await _apiService.getResponse<dynamic>(
      url: '${EndPoints.subscriptionModes}$query',
      apiType: APIType.aGet,
    );
    if (!response.success) {
      return ApiResponse<List<SubscriptionModeModel>>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }
    final list = _extractModeList(response.data);
    return ApiResponse<List<SubscriptionModeModel>>(
      success: true,
      data: list
          .map(
            (e) => SubscriptionModeModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      statusCode: response.statusCode,
    );
  }

  Future<ApiResponse<List<SubscriptionPackageModel>>> listPackages({
    int? subscriptionModeId,
    String? paymentModel,
  }) async {
    final params = <String, String>{};
    if (subscriptionModeId != null) {
      params['subscriptionModeId'] = '$subscriptionModeId';
    }
    if (paymentModel != null && paymentModel.trim().isNotEmpty) {
      params['model'] = paymentModel.trim();
    }
    final query = params.isEmpty
        ? ''
        : '?${Uri(queryParameters: params).query}';
    final response = await _apiService.getResponse<dynamic>(
      url: '${EndPoints.paymentPackages}$query',
      apiType: APIType.aGet,
    );
    if (!response.success) {
      return ApiResponse<List<SubscriptionPackageModel>>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }
    final list = _extractPackageList(response.data);
    return ApiResponse<List<SubscriptionPackageModel>>(
      success: true,
      data: list
          .map(
            (e) => SubscriptionPackageModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      statusCode: response.statusCode,
    );
  }

  Future<ApiResponse<List<SubscriptionPackageModel>>> listAllPackages() {
    return listPackages();
  }

  Future<ApiResponse<Map<String, dynamic>>> createSubscriptionOrder({
    required int organizationId,
    required int packageId,
    int? branchId,
  }) async {
    final body = <String, dynamic>{
      'organizationId': organizationId,
      'packageId': packageId,
    };
    if (branchId != null) {
      body['branchId'] = branchId;
    }
    final response = await _apiService.getResponse<dynamic>(
      url: EndPoints.paymentSubscriptionOrder,
      apiType: APIType.aPost,
      body: body,
    );
    return _mapDataResponse(response);
  }

  Future<ApiResponse<Map<String, dynamic>>>
  createSubscriptionOrderForCurrentOrg({required int packageId}) async {
    final response = await _apiService.getResponse<dynamic>(
      url: '${EndPoints.paymentSubscriptionOrder}/current',
      apiType: APIType.aPost,
      body: {'packageId': packageId},
    );
    return _mapDataResponse(response);
  }

  Future<ApiResponse<Map<String, dynamic>>> verifySubscriptionPayment({
    required int organizationId,
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final response = await _apiService.getResponse<dynamic>(
      url: EndPoints.paymentSubscriptionVerify,
      apiType: APIType.aPost,
      body: {
        'organizationId': organizationId,
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      },
    );
    return _mapDataResponse(response);
  }

  Future<ApiResponse<Map<String, dynamic>>>
  verifySubscriptionPaymentForCurrentOrg({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final response = await _apiService.getResponse<dynamic>(
      url: '${EndPoints.paymentSubscriptionVerify}/current',
      apiType: APIType.aPost,
      body: {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      },
    );
    return _mapDataResponse(response);
  }

  List<dynamic> _extractPackageList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      if (raw['packages'] is List) {
        return List<dynamic>.from(raw['packages']);
      }
      if (raw['data'] is List) return List<dynamic>.from(raw['data']);
      final inner = raw['data'];
      if (inner is Map && inner['packages'] is List) {
        return List<dynamic>.from(inner['packages']);
      }
    }
    return const [];
  }

  List<dynamic> _extractModeList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      // API: { "success": true, "data": { "subscriptionModes": [ ... ] } }
      if (raw['subscriptionModes'] is List) {
        return List<dynamic>.from(raw['subscriptionModes']);
      }
      if (raw['data'] is List) return List<dynamic>.from(raw['data']);
      final inner = raw['data'];
      if (inner is Map && inner['subscriptionModes'] is List) {
        return List<dynamic>.from(inner['subscriptionModes']);
      }
    }
    return const [];
  }

  Future<PaymentOrderModel> createRegistrationCheckoutOrder({
    required int competitionId,
    required int categoryId,
  }) async {
    final response = await createApiOrder(
      purpose: registrationTicketPurpose,
      competitionId: competitionId,
      categoryId: categoryId,
    );
    if (!response.success || response.data == null) {
      throw Exception(response.message ?? 'Failed to create registration payment order');
    }
    return PaymentOrderModel.fromJson(response.data!);
  }

  Future<PaymentOrderModel> createStandardOrder({
    required int amountPaise,
    String currency = 'INR',
    String? receipt,
  }) async {
    final response = await _apiService.getResponse<PaymentOrderModel>(
      url: EndPoints.apiCreateOrder,
      apiType: APIType.aPost,
      body: {
        'amount': amountPaise,
        'currency': currency,
        if (receipt != null && receipt.isNotEmpty) 'receipt': receipt,
      },
      fromJson: (json) =>
          PaymentOrderModel.fromJson(json as Map<String, dynamic>),
    );
    if (!response.success || response.data == null) {
      throw Exception(response.message ?? 'Failed to create payment order');
    }
    return response.data!;
  }

  /// Marks a pending Razorpay order as FAILED (checkout cancelled or error).
  Future<void> markPaymentFailed({
    required String orderId,
    String? reason,
  }) async {
    try {
      await _apiService.getResponse<dynamic>(
        url: EndPoints.apiMarkPaymentFailed,
        apiType: APIType.aPost,
        body: {
          'orderId': orderId,
          if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        },
      );
    } catch (_) {
      // Best effort — UI already shows the failure to the user.
    }
  }

  Future<PaymentVerifyResult> verifyStandardPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final response = await _apiService.getResponse<PaymentVerifyResult>(
      url: EndPoints.apiVerifyPayment,
      apiType: APIType.aPost,
      body: {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      },
      fromJson: (json) =>
          PaymentVerifyResult.fromJson(json as Map<String, dynamic>),
    );
    if (!response.success || response.data == null) {
      throw Exception(response.message ?? 'Payment verification failed');
    }
    return response.data!;
  }

  Future<void> linkRegistrationPayment({
    required int registrationId,
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final response = await verifyRegistrationPayment(
      registrationId: registrationId,
      orderId: orderId,
      paymentId: paymentId,
      signature: signature,
    );
    if (!response.success) {
      throw Exception(
        response.message ?? 'Failed to link registration payment',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> createRegistrationOrder({
    required int competitionId,
    required int categoryId,
  }) async {
    final response = await _apiService.getResponse<dynamic>(
      url: EndPoints.paymentRegistrationOrder,
      apiType: APIType.aPost,
      body: {'competitionId': competitionId, 'categoryId': categoryId},
    );
    return _mapDataResponse(response);
  }

  Future<ApiResponse<Map<String, dynamic>>> verifyRegistrationPayment({
    required int registrationId,
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final response = await _apiService.getResponse<dynamic>(
      url: EndPoints.paymentRegistrationVerify,
      apiType: APIType.aPost,
      body: {
        'registrationId': registrationId,
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      },
    );
    return _mapDataResponse(response);
  }

  Future<ApiResponse<Map<String, dynamic>>> createApiOrder({
    int? amountPaise,
    int? competitionId,
    int? categoryId,
    String? purpose,
    String? currency,
    String? receipt,
    bool? hasAsanas,
    bool? hasChallenge,
  }) async {
    final body = <String, dynamic>{};
    if (amountPaise != null) body['amount'] = amountPaise;
    if (competitionId != null) body['competitionId'] = competitionId;
    if (categoryId != null) body['categoryId'] = categoryId;
    if (purpose != null && purpose.trim().isNotEmpty) {
      body['purpose'] = purpose.trim();
    }
    if (hasAsanas != null) body['hasAsanas'] = hasAsanas;
    if (hasChallenge != null) body['hasChallenge'] = hasChallenge;
    if (currency != null && currency.trim().isNotEmpty) {
      body['currency'] = currency.trim();
    }
    if (receipt != null && receipt.trim().isNotEmpty) {
      body['receipt'] = receipt.trim();
    }

    final response = await _apiService.getResponse<dynamic>(
      url: EndPoints.apiCreateOrder,
      apiType: APIType.aPost,
      body: body,
    );
    return _mapDataResponse(response);
  }

  Future<ApiResponse<Map<String, dynamic>>> verifyApiPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    int? competitionId,
    String? purpose,
  }) async {
    final body = <String, String>{
      'razorpay_order_id': orderId,
      'razorpay_payment_id': paymentId,
      'razorpay_signature': signature,
    };
    if (competitionId != null) {
      body['competitionId'] = '$competitionId';
    }
    if (purpose != null && purpose.trim().isNotEmpty) {
      body['purpose'] = purpose.trim();
    }

    final response = await _apiService.getResponse<dynamic>(
      url: EndPoints.apiVerifyPayment,
      apiType: APIType.aPost,
      body: body,
    );
    return _mapDataResponse(response);
  }

  Future<ApiResponse<Map<String, dynamic>>> createMaintenanceOrder(
    int competitionId,
  ) async {
    final response = await _apiService.getResponse<dynamic>(
      url: EndPoints.paymentCompetitionMaintenanceOrder(competitionId),
      apiType: APIType.aPost,
    );
    return _mapDataResponse(response);
  }

  Future<ApiResponse<Map<String, dynamic>>> verifyMaintenancePayment({
    required int competitionId,
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final response = await _apiService.getResponse<dynamic>(
      url: EndPoints.paymentCompetitionMaintenanceVerify(competitionId),
      apiType: APIType.aPost,
      body: {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      },
    );
    return _mapDataResponse(response);
  }

  ApiResponse<Map<String, dynamic>> _mapDataResponse(
    ApiResponse<dynamic> response,
  ) {
    if (!response.success) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }
    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      final inner = raw['data'];
      if (inner is Map) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: Map<String, dynamic>.from(inner),
          statusCode: response.statusCode,
        );
      }
      return ApiResponse<Map<String, dynamic>>(
        success: true,
        data: raw,
        statusCode: response.statusCode,
      );
    }
    return ApiResponse<Map<String, dynamic>>(
      success: true,
      data: const {},
      statusCode: response.statusCode,
    );
  }
}
