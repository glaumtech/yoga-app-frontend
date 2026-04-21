import 'dart:convert';

import 'package:yoga_champ/data/models/user_management_model.dart';

class SetupAdminUserRequestModel {
  final String name;
  final String userName;
  final String password;

  SetupAdminUserRequestModel({
    required this.name,
    required this.userName,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'userName': userName,
    'password': password,
  };
}

class OrganizationRequestModel {
  final String organizationName;
  final String? organizationCode;

  OrganizationRequestModel({
    required this.organizationName,
    this.organizationCode,
  });

  Map<String, dynamic> toJson() => {
    'organizationName': organizationName,
    if (organizationCode != null) 'organizationCode': organizationCode,
  };
}

class BranchRequestModel {
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

  BranchRequestModel({
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
  });

  Map<String, dynamic> toJson() => {
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
    );
  }
}

class OrganizationSetupResponseModel {
  final OrganizationDtoModel organization;
  final BranchDtoModel branch;
  final UserManagementModel orgAdminUser;
  final UserManagementModel branchAdminUser;

  OrganizationSetupResponseModel({
    required this.organization,
    required this.branch,
    required this.orgAdminUser,
    required this.branchAdminUser,
  });

  factory OrganizationSetupResponseModel.fromJson(Map<String, dynamic> json) {
    return OrganizationSetupResponseModel(
      organization: OrganizationDtoModel.fromJson(
        Map<String, dynamic>.from(json['organization'] as Map),
      ),
      branch: BranchDtoModel.fromJson(
        Map<String, dynamic>.from(json['branch'] as Map),
      ),
      orgAdminUser: UserManagementModel.fromJson(
        Map<String, dynamic>.from(json['orgAdminUser'] as Map),
      ),
      branchAdminUser: UserManagementModel.fromJson(
        Map<String, dynamic>.from(json['branchAdminUser'] as Map),
      ),
    );
  }
}
