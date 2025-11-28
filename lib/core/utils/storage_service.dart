import 'dart:convert';
import 'package:get_storage/get_storage.dart';

class StorageService {
  static final GetStorage _storage = GetStorage();

  static void init() {
    GetStorage.init();
  }

  static Future<void> setString(String key, String value) async {
    await _storage.write(key, value);
  }

  static String? getString(String key) {
    return _storage.read<String>(key);
  }

  static Future<void> setBool(String key, bool value) async {
    await _storage.write(key, value);
  }

  static bool? getBool(String key) {
    return _storage.read<bool>(key);
  }

  static Future<void> setObject(String key, Map<String, dynamic> value) async {
    await _storage.write(key, jsonEncode(value));
  }

  static Map<String, dynamic>? getObject(String key) {
    final value = _storage.read<String>(key);
    if (value == null) return null;
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  static Future<void> remove(String key) async {
    await _storage.remove(key);
  }

  static Future<void> clear() async {
    await _storage.erase();
  }
}
