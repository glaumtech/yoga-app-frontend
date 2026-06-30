import '../../data/models/organization_setup_model.dart';
import '../../presentation/widgets/organization/organization_proof_image_upload.dart';

bool isBranchAdminRole(String? userTypeName, {String fallbackType = ''}) {
  final role = (userTypeName ?? fallbackType).trim().toUpperCase();
  return role == 'BRANCH_ADMIN' || role == 'BRANCH ADMIN';
}

bool _isBlank(String? value) => value == null || value.trim().isEmpty;

bool _hasValidPincode(String? value) {
  final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
  return digits.length == 6;
}

bool _hasValidPhone(String? value) {
  final digits = value?.trim().replaceAll(RegExp(r'\s+'), '') ?? '';
  return RegExp(r'^\d{10}$').hasMatch(digits);
}

bool _hasValidCommencingYear(int? year) {
  if (year == null) return false;
  return year >= 1900 && year <= 2100;
}

bool _hasValidEmail(String? value) {
  if (_isBlank(value)) return false;
  final email = value!.trim();
  return RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  ).hasMatch(email);
}

bool hasOrganizationStepMissing(BranchDtoModel branch) {
  final orgName = (branch.organizationName ?? branch.branchName).trim();
  if (_isBlank(orgName)) return true;
  if (!_hasValidCommencingYear(branch.commencingYear)) return true;
  if (!_hasValidEmail(branch.email)) return true;
  if (!_hasValidPhone(branch.phoneNo)) return true;
  if (_isBlank(branch.country)) return true;

  final hasState =
      (branch.stateId != null && branch.stateId! > 0) ||
      !_isBlank(branch.stateName);
  if (!hasState) return true;

  final hasDistrict =
      (branch.cityId != null && branch.cityId! > 0) ||
      !_isBlank(branch.cityName);
  if (!hasDistrict) return true;

  if (!_hasValidPincode(branch.pincode)) return true;
  if (_isBlank(branch.address)) return true;
  return false;
}

bool hasDocumentStepMissing(BranchDtoModel branch) {
  if (validatePanNumber(branch.panNumber) != null) return true;
  if ((branch.panImagePath ?? '').trim().isEmpty) return true;

  if (validateAadharNumber(branch.aadharNumber) != null) return true;

  final hasAadharDocument =
      (branch.aadharFrontImagePath ?? branch.aadharImagePath ?? '')
          .trim()
          .isNotEmpty;
  if (!hasAadharDocument) return true;

  if (validateIfsc(branch.bankIfsc) != null) return true;
  if (validateRequiredField(
        branch.bankAccountNumber,
        fieldName: 'Account number',
      ) !=
      null) {
    return true;
  }
  if (validateRequiredField(branch.bankBranch, fieldName: 'Bank branch') !=
      null) {
    return true;
  }
  if (validateRequiredField(branch.bankName, fieldName: 'Bank name') != null) {
    return true;
  }
  if (validateGstNumber(branch.gstNumber) != null) return true;
  return false;
}

bool hasMissingMandatoryOrganizationFields(BranchDtoModel branch) {
  return hasOrganizationStepMissing(branch) || hasDocumentStepMissing(branch);
}
