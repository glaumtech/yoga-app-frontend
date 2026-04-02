import 'package:get/get.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';

class PermissionStore extends GetxService {
  final RxSet<String> _keys = <String>{}.obs;

  Set<String> get keys => _keys;
  bool get isEmpty => _keys.isEmpty;

  Future<PermissionStore> init() async {
    loadFromStorage();
    return this;
  }

  void loadFromStorage() {
    final stored = StorageService.getStringList(AppConstants.permissionKeysKey);
    setKeys(stored);
  }

  void setKeys(Iterable<String> keys) {
    final normalized = keys
        .map((e) => e.toString().trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toSet();
    _keys
      ..clear()
      ..addAll(normalized);
  }

  bool has(String permissionKey) {
    final k = permissionKey.trim().toUpperCase();
    if (k.isEmpty) return false;
    return _keys.contains(k);
  }

  bool hasAny(Iterable<String> permissionKeys) {
    for (final k in permissionKeys) {
      if (has(k)) return true;
    }
    return false;
  }
}

