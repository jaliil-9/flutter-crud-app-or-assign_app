import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  late final GetStorage _storage;

  StorageService({GetStorage? storage}) {
    _storage = storage ?? GetStorage();
  }

  Future<void> initialize() async {
    try {
      await GetStorage.init();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StorageService: Failed to initialize - $e');
      }
      rethrow;
    }
  }

  Future<void> write(String key, dynamic value) async {
    try {
      await _storage.write(key, value);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StorageService: Failed to write key $key - $e');
      }
      rethrow;
    }
  }

  T? read<T>(String key) {
    try {
      return _storage.read<T>(key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StorageService: Failed to read key $key - $e');
      }
      return null;
    }
  }

  Future<void> remove(String key) async {
    try {
      await _storage.remove(key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StorageService: Failed to remove key $key - $e');
      }
      rethrow;
    }
  }

  bool hasData(String key) {
    try {
      return _storage.hasData(key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StorageService: Failed to check key $key - $e');
      }
      return false;
    }
  }

  Future<void> erase() async {
    try {
      await _storage.erase();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StorageService: Failed to clear data - $e');
      }
      rethrow;
    }
  }
}
