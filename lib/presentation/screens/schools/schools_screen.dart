import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/school_model.dart';
import '../../../data/repositories/school_repository.dart';
import '../../widgets/admin_sidebar_layout.dart';
import '../../widgets/toggle_button_group.dart';
import '../../controllers/school_controller.dart';
import 'school_create_screen.dart';
import 'school_list_screen.dart';

/// Institutions Screen
/// Manages institutions list
class SchoolsScreen extends StatelessWidget {
  const SchoolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SchoolController());

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return AdminSidebarLayout(
      title: 'Institutions',
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.05),
              Colors.white,
              AppTheme.secondaryColor.withOpacity(0.03),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Toggle Buttons
              Padding(
                padding: EdgeInsets.only(
                  top: isMobile ? 8 : 10,
                  bottom: 0,
                  left: isMobile ? 16 : 24,
                  right: isMobile ? 16 : 24,
                ),
                child: Obx(
                  () => ToggleButtonGroup(
                    options: [
                      ToggleButtonOption(
                        label: controller.isEditMode.value
                            ? 'EDIT'
                            : '+ CREATE',
                      ),
                      const ToggleButtonOption(label: '≡ LIST'),
                    ],
                    selectedIndex: controller.isListView.value ? 1 : 0,
                    onTap: (index) => controller.toggleViewMode(index == 1),
                  ),
                ),
              ),
              // Content (Create Form or List View)
              Expanded(
                child: Obx(
                  () => controller.isListView.value
                      ? const SchoolListScreen()
                      : const _InstitutionPrecheckAndCreate(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstitutionPrecheckAndCreate extends StatefulWidget {
  const _InstitutionPrecheckAndCreate();

  @override
  State<_InstitutionPrecheckAndCreate> createState() =>
      _InstitutionPrecheckAndCreateState();
}

class _InstitutionPrecheckAndCreateState
    extends State<_InstitutionPrecheckAndCreate> {
  final SchoolRepository _repo = SchoolRepository();

  final TextEditingController _precheckNameController = TextEditingController();
  final TextEditingController _precheckPincodeController =
      TextEditingController();

  final RxList<SchoolModel> _suggestions = <SchoolModel>[].obs;
  final RxBool _isSearching = false.obs;
  bool _showCreateForm = false;

  @override
  void dispose() {
    _precheckNameController.dispose();
    _precheckPincodeController.dispose();
    super.dispose();
  }

  bool _isValidPincode(String v) {
    final s = v.trim();
    if (s.isEmpty) return true; // optional
    return RegExp(r'^[0-9]{6}$').hasMatch(s);
  }

  Future<void> _searchInstitutions(String query) async {
    final q = query.trim();
    final pin = _precheckPincodeController.text.trim();
    final pinReady = _isValidPincode(pin) && pin.length == 6;

    // Support two modes:
    // - Name-based: require 3+ chars
    // - Pincode-only: when pincode is complete (6 digits) even if name is empty
    if (q.length < 3 && !pinReady) {
      _suggestions.clear();
      return;
    }

    try {
      _isSearching.value = true;
      final res = await _repo.searchInstitutions(
        query: q.length >= 3 ? q : '',
        pincode: pinReady ? pin : null,
      );
      if (res.success && res.data != null) {
        var list = res.data!.institutions;
        // If API doesn't support pincode, apply client-side filter too.
        if (pinReady) {
          list = list.where((x) => x.pincode.trim() == pin).toList();
        }
        _suggestions.assignAll(list);
      } else {
        _suggestions.clear();
      }
    } catch (_) {
      _suggestions.clear();
    } finally {
      _isSearching.value = false;
    }
  }

  void _startCreateFlow(BuildContext context, SchoolController controller) {
    final name = _precheckNameController.text.trim();
    final pin = _precheckPincodeController.text.trim();
    if (name.isEmpty || name.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter at least 3 characters for institution name',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(12),
        ),
      );
      return;
    }
    if (!_isValidPincode(pin)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit pincode'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(12),
        ),
      );
      return;
    }

    controller.resetForm();
    controller.institutionNameController.text = name;
    if (pin.isNotEmpty) {
      controller.pincodeController.text = pin;
    }

    setState(() {
      _showCreateForm = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SchoolController());

    return Obx(() {
      final isEditMode = controller.isEditMode.value;

      // If edit is triggered from the list screen, show edit form directly.
      if (isEditMode || _showCreateForm) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    if (isEditMode) {
                      controller.toggleViewMode(true);
                      return;
                    }
                    setState(() {
                      _showCreateForm = false;
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: Text(isEditMode ? 'Back to list' : 'Back to search'),
                ),
              ),
            ),
            const Expanded(child: SchoolCreateScreen()),
          ],
        );
      }

      final screenWidth = MediaQuery.of(context).size.width;
      final isMobile = screenWidth < 600;
      final isTablet = screenWidth >= 600 && screenWidth < 1024;

      return SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 16),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: double.infinity),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                  'Check Institution Before Create',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                isMobile
                    ? Column(
                        children: [
                          _buildNameField(isMobile),
                          const SizedBox(height: 14),
                          _buildPincodeField(isMobile),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildNameField(isMobile)),
                          SizedBox(width: isTablet ? 12 : 16),
                          Expanded(child: _buildPincodeField(isMobile)),
                        ],
                      ),
                const SizedBox(height: 14),
                // Found results list (each row has only an edit icon)
                Obx(() {
                  if (_isSearching.value) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final list = _suggestions;
                  if (list.isEmpty) return const SizedBox.shrink();

                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: Colors.grey[200]),
                        itemBuilder: (context, index) {
                          final inst = list[index];
                          final subtitleParts = <String>[];
                          if (inst.cityName != null &&
                              inst.cityName!.trim().isNotEmpty) {
                            subtitleParts.add(inst.cityName!.trim());
                          }
                          if (inst.stateName != null &&
                              inst.stateName!.trim().isNotEmpty) {
                            subtitleParts.add(inst.stateName!.trim());
                          }
                          if (inst.pincode.trim().isNotEmpty) {
                            subtitleParts.add(inst.pincode.trim());
                          }
                          final subtitle = subtitleParts.join(' • ');

                          return ListTile(
                            dense: true,
                            title: Text(
                              inst.institutionName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: subtitle.isEmpty ? null : Text(subtitle),
                            trailing: IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                if (inst.id == null || inst.id!.isEmpty) return;
                                await controller.loadSchoolForEdit(inst.id!);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 14),
                Obx(() {
                  final searching = _isSearching.value;
                  // Always enable create (requested). Disable only while searching.
                  final canCreate = !searching;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: canCreate
                            ? () => _startCreateFlow(context, controller)
                            : null,
                        icon: const Icon(Icons.add),
                        label: const Text('Create New Institution'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildNameField(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Institution Name :',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _precheckNameController,
          onChanged: (value) {
            final q = value.trim();
            // Search when query is long enough; clear results otherwise.
            if (q.length >= 3) {
              _searchInstitutions(q);
            } else if (q.isEmpty) {
              _suggestions.clear();
            }
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
            hintText: 'Type institution name (min 3 letters)',
            suffixIcon: Obx(() {
              final hasText = _precheckNameController.text.trim().isNotEmpty;
              if (_isSearching.value) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return hasText
                  ? IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _precheckNameController.clear();
                        _suggestions.clear();
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : const Icon(Icons.search);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildPincodeField(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pincode (optional) :',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _precheckPincodeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          onChanged: (value) {
            final q = _precheckNameController.text.trim();
            final pin = value.trim();
            // Trigger API only when pincode is complete (6 digits),
            // and also when user clears pincode (to broaden results again).
            if (pin.isEmpty) {
              // If name is present, keep name-based search results; otherwise reset.
              if (q.length >= 3) {
                _searchInstitutions(q);
              } else {
                _suggestions.clear();
              }
              return;
            }

            if (pin.length == 6) {
              // Allow pincode-only search even if name is empty.
              _searchInstitutions(q);
            }
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
            hintText: 'Enter pincode to narrow results',
            counterText: '',
          ),
        ),
      ],
    );
  }
}
