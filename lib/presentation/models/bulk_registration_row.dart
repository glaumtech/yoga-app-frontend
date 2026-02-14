import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

/// Model for a single row in bulk registration table
class BulkRegistrationRow {
  final TextEditingController nameController;
  final TextEditingController dateOfBirthController;
  final Rx<DateTime?> dateOfBirth;
  final RxString gender;
  final RxString group;
  final Rx<File?> photoFile;
  final Rx<XFile?> photoXFile;
  final Rx<Uint8List?> photoBytes;

  BulkRegistrationRow({
    TextEditingController? nameController,
    TextEditingController? dateOfBirthController,
    DateTime? dateOfBirth,
    String? gender,
    String? group,
    File? photoFile,
    XFile? photoXFile,
    Uint8List? photoBytes,
  })  : nameController = nameController ?? TextEditingController(),
        dateOfBirthController = dateOfBirthController ?? TextEditingController(),
        dateOfBirth = Rx<DateTime?>(dateOfBirth),
        gender = RxString(gender ?? ''),
        group = RxString(group ?? ''),
        photoFile = Rx<File?>(photoFile),
        photoXFile = Rx<XFile?>(photoXFile),
        photoBytes = Rx<Uint8List?>(photoBytes);

  void dispose() {
    nameController.dispose();
    dateOfBirthController.dispose();
  }

  bool get isValid {
    return nameController.text.trim().isNotEmpty &&
        dateOfBirth.value != null &&
        gender.value.isNotEmpty &&
        group.value.isNotEmpty;
  }

  BulkRegistrationRow copyWith({
    TextEditingController? nameController,
    TextEditingController? dateOfBirthController,
    DateTime? dateOfBirth,
    String? gender,
    String? group,
    File? photoFile,
    XFile? photoXFile,
    Uint8List? photoBytes,
  }) {
    return BulkRegistrationRow(
      nameController: nameController ?? this.nameController,
      dateOfBirthController: dateOfBirthController ?? this.dateOfBirthController,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth.value,
      gender: gender ?? this.gender.value,
      group: group ?? this.group.value,
      photoFile: photoFile ?? this.photoFile.value,
      photoXFile: photoXFile ?? this.photoXFile.value,
      photoBytes: photoBytes ?? this.photoBytes.value,
    );
  }
}

