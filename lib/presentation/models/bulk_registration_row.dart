import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

/// Model for a single row in bulk registration table
class BulkRegistrationRow {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController dateOfBirthController;
  final Rx<DateTime?> dateOfBirth;
  final RxString gender;
  final RxString category;
  final RxString categoryMode;
  final RxString group;
  final RxString stage;
  final Rx<File?> photoFile;
  final Rx<XFile?> photoXFile;
  final Rx<Uint8List?> photoBytes;
  final RxBool isRegistered;

  BulkRegistrationRow({
    TextEditingController? nameController,
    TextEditingController? phoneController,
    TextEditingController? dateOfBirthController,
    DateTime? dateOfBirth,
    String? gender,
    String? category,
    String? categoryMode,
    String? group,
    String? stage,
    File? photoFile,
    XFile? photoXFile,
    Uint8List? photoBytes,
    bool registered = false,
  })  : nameController = nameController ?? TextEditingController(),
        phoneController = phoneController ?? TextEditingController(),
        dateOfBirthController = dateOfBirthController ?? TextEditingController(),
        dateOfBirth = Rx<DateTime?>(dateOfBirth),
        gender = RxString(gender ?? ''),
        category = RxString(category ?? ''),
        categoryMode = RxString(categoryMode ?? ''),
        group = RxString(group ?? ''),
        stage = RxString(stage ?? ''),
        photoFile = Rx<File?>(photoFile),
        photoXFile = Rx<XFile?>(photoXFile),
        photoBytes = Rx<Uint8List?>(photoBytes),
        isRegistered = registered.obs;

  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    dateOfBirthController.dispose();
  }

  /// Null when the phone is a usable 10-digit number.
  String? get phoneValidationMessage {
    final cell = phoneController.text.trim();
    if (cell.isEmpty) return 'Participant phone is required';
    if (cell.length != 10) return 'Phone number must be exactly 10 digits';
    if (RegExp(r'^(\d)\1{9}$').hasMatch(cell)) return 'Invalid phone number';
    if (cell == '9876543210' || cell == '0123456789') {
      return 'Invalid phone number';
    }
    return null;
  }

  bool get hasPhoto =>
      photoFile.value != null ||
      photoXFile.value != null ||
      (photoBytes.value != null && photoBytes.value!.isNotEmpty);

  bool get isValid {
    return nameController.text.trim().isNotEmpty &&
        phoneValidationMessage == null &&
        dateOfBirth.value != null &&
        gender.value.isNotEmpty &&
        category.value.trim().isNotEmpty &&
        group.value.isNotEmpty &&
        hasPhoto;
  }

  BulkRegistrationRow copyWith({
    TextEditingController? nameController,
    TextEditingController? phoneController,
    TextEditingController? dateOfBirthController,
    DateTime? dateOfBirth,
    String? gender,
    String? category,
    String? categoryMode,
    String? group,
    String? stage,
    File? photoFile,
    XFile? photoXFile,
    Uint8List? photoBytes,
  }) {
    return BulkRegistrationRow(
      nameController: nameController ?? this.nameController,
      phoneController: phoneController ?? this.phoneController,
      dateOfBirthController: dateOfBirthController ?? this.dateOfBirthController,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth.value,
      gender: gender ?? this.gender.value,
      category: category ?? this.category.value,
      categoryMode: categoryMode ?? this.categoryMode.value,
      group: group ?? this.group.value,
      stage: stage ?? this.stage.value,
      photoFile: photoFile ?? this.photoFile.value,
      photoXFile: photoXFile ?? this.photoXFile.value,
      photoBytes: photoBytes ?? this.photoBytes.value,
    );
  }
}

