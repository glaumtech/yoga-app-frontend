import 'dart:convert';

class SetupAdminUserRequestModel {
  final String name;
  final String userName;
  final String? email;
  final String password;

  SetupAdminUserRequestModel({
    required this.name,
    required this.userName,
    this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'userName': userName,
    if (email != null && email!.trim().isNotEmpty) 'email': email!.trim(),
    'password': password,
  };
}

class OrganizationRequestModel {
  final String organizationName;
  final String? organizationCode;
  final String? paymentModel;
  final String? manualPaymentUpiId;
  final String? manualPaymentQrImagePath;
  final int? subscriptionCreditsRemaining;
  final int? packCreditsRemaining;
  final double? maintenanceFeeAmount;

  OrganizationRequestModel({
    required this.organizationName,
    this.organizationCode,
    this.paymentModel,
    this.manualPaymentUpiId,
    this.manualPaymentQrImagePath,
    this.subscriptionCreditsRemaining,
    this.packCreditsRemaining,
    this.maintenanceFeeAmount,
  });

  Map<String, dynamic> toJson() => {
    'organizationName': organizationName,
    if (organizationCode != null) 'organizationCode': organizationCode,
    if (paymentModel != null) 'paymentModel': paymentModel,
    if (manualPaymentUpiId != null) 'manualPaymentUpiId': manualPaymentUpiId,
    if (manualPaymentQrImagePath != null)
      'manualPaymentQrImagePath': manualPaymentQrImagePath,
    if (subscriptionCreditsRemaining != null)
      'subscriptionCreditsRemaining': subscriptionCreditsRemaining,
    if (packCreditsRemaining != null) 'packCreditsRemaining': packCreditsRemaining,
    if (maintenanceFeeAmount != null) 'maintenanceFeeAmount': maintenanceFeeAmount,
  };
}

class BranchRequestModel {
  final int? organizationId;
  final String branchName;
  final String? branchCode;
  final int? commencingYear;
  final String? email;
  final String? phoneNo;
  final String? mobileNo;
  final String? websiteUrl;
  final String? country;
  final int? stateId;
  final int? cityId;
  final String? address;
  final String? pincode;
  final String? theme;
  final String? panNumber;
  final String? aadharNumber;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final String? bankBranch;
  final String? bankName;
  final String? gstNumber;

  BranchRequestModel({
    this.organizationId,
    required this.branchName,
    this.branchCode,
    this.commencingYear,
    this.email,
    this.phoneNo,
    this.mobileNo,
    this.websiteUrl,
    this.country,
    this.stateId,
    this.cityId,
    this.address,
    this.pincode,
    this.theme,
    this.panNumber,
    this.aadharNumber,
    this.bankAccountNumber,
    this.bankIfsc,
    this.bankBranch,
    this.bankName,
    this.gstNumber,
  });

  Map<String, dynamic> toJson() => {
    if (organizationId != null) 'organizationId': organizationId,
    'branchName': branchName,
    if (branchCode != null) 'branchCode': branchCode,
    if (commencingYear != null) 'commencingYear': commencingYear,
    if (email != null) 'email': email,
    if (phoneNo != null) 'phoneNo': phoneNo,
    if (mobileNo != null) 'mobileNo': mobileNo,
    if (websiteUrl != null) 'websiteUrl': websiteUrl,
    if (country != null) 'country': country,
    if (stateId != null) 'stateId': stateId,
    if (cityId != null) 'cityId': cityId,
    if (address != null) 'address': address,
    if (pincode != null) 'pincode': pincode,
    if (theme != null) 'theme': theme,
    if (panNumber != null) 'panNumber': panNumber,
    if (aadharNumber != null) 'aadharNumber': aadharNumber,
    if (bankAccountNumber != null) 'bankAccountNumber': bankAccountNumber,
    if (bankIfsc != null) 'bankIfsc': bankIfsc,
    if (bankBranch != null) 'bankBranch': bankBranch,
    if (bankName != null) 'bankName': bankName,
    if (gstNumber != null) 'gstNumber': gstNumber,
  };
}

class OrganizationSetupRequestModel {
  final OrganizationRequestModel organization;
  final BranchRequestModel branch;
  final SetupAdminUserRequestModel orgAdminUser;
  final SetupAdminUserRequestModel branchAdminUser;
  final List<int>? orgAdminPermissionIds;
  final List<int>? branchAdminPermissionIds;

  OrganizationSetupRequestModel({
    required this.organization,
    required this.branch,
    required this.orgAdminUser,
    required this.branchAdminUser,
    this.orgAdminPermissionIds,
    this.branchAdminPermissionIds,
  });

  Map<String, dynamic> toJson() => {
    'organization': organization.toJson(),
    'branch': branch.toJson(),
    'orgAdminUser': orgAdminUser.toJson(),
    'branchAdminUser': branchAdminUser.toJson(),
    if (orgAdminPermissionIds != null)
      'orgAdminPermissionIds': orgAdminPermissionIds,
    if (branchAdminPermissionIds != null)
      'branchAdminPermissionIds': branchAdminPermissionIds,
  };

  /// Convenience for multipart `data` field.
  String toDataField() => jsonEncode(toJson());
}

class OrganizationDtoModel {
  final int id;
  final String organizationName;
  final String? organizationCode;

  OrganizationDtoModel({
    required this.id,
    required this.organizationName,
    this.organizationCode,
  });

  factory OrganizationDtoModel.fromJson(Map<String, dynamic> json) {
    return OrganizationDtoModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      organizationName: json['organizationName']?.toString() ?? '',
      organizationCode: json['organizationCode']?.toString(),
    );
  }
}

class BranchDtoModel {
  final int id;
  final int organizationId;
  final String? organizationName;
  final String branchName;
  final String? branchCode;
  final int? commencingYear;
  final String? email;
  final String? phoneNo;
  final String? mobileNo;
  final String? websiteUrl;
  final String? country;
  final int? stateId;
  final int? cityId;
  final String? stateName;
  final String? cityName;
  final String? address;
  final String? pincode;
  final String? theme;
  final String? logoPath;
  final String? panNumber;
  final String? panImagePath;
  final String? aadharNumber;
  final String? aadharImagePath;
  final String? aadharFrontImagePath;
  final String? aadharBackImagePath;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final String? bankBranch;
  final String? bankName;
  final String? gstNumber;

  BranchDtoModel({
    required this.id,
    required this.organizationId,
    this.organizationName,
    required this.branchName,
    this.branchCode,
    this.commencingYear,
    this.email,
    this.phoneNo,
    this.mobileNo,
    this.websiteUrl,
    this.country,
    this.stateId,
    this.cityId,
    this.stateName,
    this.cityName,
    this.address,
    this.pincode,
    this.theme,
    this.logoPath,
    this.panNumber,
    this.panImagePath,
    this.aadharNumber,
    this.aadharImagePath,
    this.aadharFrontImagePath,
    this.aadharBackImagePath,
    this.bankAccountNumber,
    this.bankIfsc,
    this.bankBranch,
    this.bankName,
    this.gstNumber,
  });

  factory BranchDtoModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    int? parseNullableInt(dynamic v) =>
        v == null ? null : (v is int ? v : int.tryParse(v.toString()));

    return BranchDtoModel(
      id: parseInt(json['id']),
      organizationId: parseInt(json['organizationId']),
      organizationName: json['organizationName']?.toString(),
      branchName: json['branchName']?.toString() ?? '',
      branchCode: json['branchCode']?.toString(),
      commencingYear: parseNullableInt(json['commencingYear']),
      email: json['email']?.toString(),
      phoneNo: json['phoneNo']?.toString(),
      mobileNo: json['mobileNo']?.toString(),
      websiteUrl: json['websiteUrl']?.toString(),
      country: json['country']?.toString(),
      stateId: parseNullableInt(json['stateId']),
      cityId: parseNullableInt(json['cityId']),
      stateName: json['stateName']?.toString(),
      cityName: json['cityName']?.toString(),
      address: json['address']?.toString(),
      pincode: json['pincode']?.toString(),
      theme: json['theme']?.toString(),
      logoPath: json['logoPath']?.toString(),
      panNumber: json['panNumber']?.toString(),
      panImagePath: json['panImagePath']?.toString(),
      aadharNumber: json['aadharNumber']?.toString(),
      aadharImagePath: json['aadharImagePath']?.toString(),
      aadharFrontImagePath: json['aadharFrontImagePath']?.toString(),
      aadharBackImagePath: json['aadharBackImagePath']?.toString(),
      bankAccountNumber: json['bankAccountNumber']?.toString(),
      bankIfsc: json['bankIfsc']?.toString(),
      bankBranch: json['bankBranch']?.toString(),
      bankName: json['bankName']?.toString(),
      gstNumber: json['gstNumber']?.toString(),
    );
  }
}

class OrganizationSetupFoundationRequestModel {
  final OrganizationRequestModel organization;
  final BranchRequestModel branch;
  final int? selectedPackageId;
  final String? checkoutMethod;

  OrganizationSetupFoundationRequestModel({
    required this.organization,
    required this.branch,
    this.selectedPackageId,
    this.checkoutMethod,
  });

  Map<String, dynamic> toJson() => {
    'organization': organization.toJson(),
    'branch': branch.toJson(),
    if (selectedPackageId != null) 'selectedPackageId': selectedPackageId,
    if (checkoutMethod != null) 'checkoutMethod': checkoutMethod,
  };

  String toDataField() => jsonEncode(toJson());
}

class OrganizationSetupFoundationResponseModel {
  final OrganizationDtoModel organization;
  final BranchDtoModel branch;

  OrganizationSetupFoundationResponseModel({
    required this.organization,
    required this.branch,
  });

  factory OrganizationSetupFoundationResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return OrganizationSetupFoundationResponseModel(
      organization: OrganizationDtoModel.fromJson(
        Map<String, dynamic>.from(json['organization'] as Map),
      ),
      branch: BranchDtoModel.fromJson(
        Map<String, dynamic>.from(json['branch'] as Map),
      ),
    );
  }
}

class OrganizationSetupFoundationWithPaymentResponseModel {
  final OrganizationSetupFoundationResponseModel foundation;
  final Map<String, dynamic> paymentOrder;

  OrganizationSetupFoundationWithPaymentResponseModel({
    required this.foundation,
    required this.paymentOrder,
  });

  factory OrganizationSetupFoundationWithPaymentResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final Map<String, dynamic> foundationJson;
    if (json['foundation'] is Map) {
      foundationJson = Map<String, dynamic>.from(json['foundation'] as Map);
    } else {
      foundationJson = <String, dynamic>{
        'organization': json['organization'],
        'branch': json['branch'],
      };
    }
    return OrganizationSetupFoundationWithPaymentResponseModel(
      foundation: OrganizationSetupFoundationResponseModel.fromJson(
        foundationJson,
      ),
      paymentOrder:
          json['paymentOrder'] is Map
              ? Map<String, dynamic>.from(json['paymentOrder'] as Map)
              : <String, dynamic>{},
    );
  }
}

/// Foundation + admin users — single atomic setup request.
class OrganizationSetupCompleteRequestModel {
  final OrganizationRequestModel organization;
  final BranchRequestModel branch;
  final int? selectedPackageId;
  final String? checkoutMethod;
  final SetupAdminUserRequestModel orgAdminUser;
  final SetupAdminUserRequestModel branchAdminUser;
  final List<int>? orgAdminPermissionIds;
  final List<int>? branchAdminPermissionIds;

  OrganizationSetupCompleteRequestModel({
    required this.organization,
    required this.branch,
    this.selectedPackageId,
    this.checkoutMethod,
    required this.orgAdminUser,
    required this.branchAdminUser,
    this.orgAdminPermissionIds,
    this.branchAdminPermissionIds,
  });

  Map<String, dynamic> toJson() => {
    'organization': organization.toJson(),
    'branch': branch.toJson(),
    if (selectedPackageId != null) 'selectedPackageId': selectedPackageId,
    if (checkoutMethod != null) 'checkoutMethod': checkoutMethod,
    'orgAdminUser': orgAdminUser.toJson(),
    'branchAdminUser': branchAdminUser.toJson(),
    if (orgAdminPermissionIds != null)
      'orgAdminPermissionIds': orgAdminPermissionIds,
    if (branchAdminPermissionIds != null)
      'branchAdminPermissionIds': branchAdminPermissionIds,
  };

  String toDataField() => jsonEncode(toJson());
}

class OrganizationSetupAdminsRequestModel {
  final int organizationId;
  final int branchId;
  final SetupAdminUserRequestModel orgAdminUser;
  final SetupAdminUserRequestModel branchAdminUser;
  final List<int>? orgAdminPermissionIds;
  final List<int>? branchAdminPermissionIds;

  OrganizationSetupAdminsRequestModel({
    required this.organizationId,
    required this.branchId,
    required this.orgAdminUser,
    required this.branchAdminUser,
    this.orgAdminPermissionIds,
    this.branchAdminPermissionIds,
  });

  Map<String, dynamic> toJson() => {
    'organizationId': organizationId,
    'branchId': branchId,
    'orgAdminUser': orgAdminUser.toJson(),
    'branchAdminUser': branchAdminUser.toJson(),
    if (orgAdminPermissionIds != null)
      'orgAdminPermissionIds': orgAdminPermissionIds,
    if (branchAdminPermissionIds != null)
      'branchAdminPermissionIds': branchAdminPermissionIds,
  };
}

