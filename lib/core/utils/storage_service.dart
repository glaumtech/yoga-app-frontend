import 'dart:convert';
import 'package:get_storage/get_storage.dart';

class StorageService {
  static GetStorage? _storage;
  static bool _initialized = false;

  static Future<void> init() async {
    if (!_initialized) {
      await GetStorage.init();
      _storage = GetStorage();
      _initialized = true;
    }
  }

  static GetStorage get _instance {
    if (_storage == null) {
      throw Exception(
        'StorageService not initialized. Call StorageService.init() first.',
      );
    }
    return _storage!;
  }

  static Future<void> setString(String key, String value) async {
    await _instance.write(key, value);
  }

  static String? getString(String key) {
    try {
      return _instance.read<String>(key);
    } catch (e) {
      print('Error reading string from storage: $e');
      return null;
    }
  }

  static Future<void> setBool(String key, bool value) async {
    await _instance.write(key, value);
  }

  static bool? getBool(String key) {
    try {
      return _instance.read<bool>(key);
    } catch (e) {
      print('Error reading bool from storage: $e');
      return null;
    }
  }

  static Future<void> setObject(String key, Map<String, dynamic> value) async {
    try {
      await _instance.write(key, jsonEncode(value));
    } catch (e) {
      print('Error writing object to storage: $e');
      rethrow;
    }
  }

  static Map<String, dynamic>? getObject(String key) {
    try {
      final value = _instance.read<String>(key);
      if (value == null) return null;
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (e) {
      print('Error reading object from storage: $e');
      return null;
    }
  }

  static Future<void> remove(String key) async {
    await _instance.remove(key);
  }

  static Future<void> clear() async {
    await _instance.erase();
  }
}
