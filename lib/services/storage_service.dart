import 'package:get_storage/get_storage.dart';
import 'logging_service.dart';

/// Service for local data storage using GetStorage
class StorageService {
  late final GetStorage _storage;

  StorageService({GetStorage? storage}) {
    _storage = storage ?? GetStorage();
  }

  /// Initialize storage service
  Future<void> initialize() async {
    try {
      await GetStorage.init();
      LoggingService.info('StorageService: Initialized successfully');
    } catch (e) {
      LoggingService.error('StorageService: Failed to initialize - $e');
      rethrow;
    }
  }

  /// Store a value with the given key
  Future<void> write(String key, dynamic value) async {
    try {
      await _storage.write(key, value);
      LoggingService.info('StorageService: Stored data for key: $key');
    } catch (e) {
      LoggingService.error('StorageService: Failed to write key $key - $e');
      rethrow;
    }
  }

  /// Read a value by key
  T? read<T>(String key) {
    try {
      final value = _storage.read<T>(key);
      LoggingService.info('StorageService: Read data for key: $key');
      return value;
    } catch (e) {
      LoggingService.error('StorageService: Failed to read key $key - $e');
      return null;
    }
  }

  /// Remove a value by key
  Future<void> remove(String key) async {
    try {
      await _storage.remove(key);
      LoggingService.info('StorageService: Removed data for key: $key');
    } catch (e) {
      LoggingService.error('StorageService: Failed to remove key $key - $e');
      rethrow;
    }
  }

  /// Check if a key exists
  bool hasData(String key) {
    try {
      return _storage.hasData(key);
    } catch (e) {
      LoggingService.error('StorageService: Failed to check key $key - $e');
      return false;
    }
  }

  /// Clear all stored data
  Future<void> erase() async {
    try {
      await _storage.erase();
      LoggingService.info('StorageService: Cleared all data');
    } catch (e) {
      LoggingService.error('StorageService: Failed to clear data - $e');
      rethrow;
    }
  }

  /// Get all keys
  Iterable<String> getKeys() {
    try {
      return _storage.getKeys();
    } catch (e) {
      LoggingService.error('StorageService: Failed to get keys - $e');
      return [];
    }
  }

  /// Get all values
  Iterable<dynamic> getValues() {
    try {
      return _storage.getValues();
    } catch (e) {
      LoggingService.error('StorageService: Failed to get values - $e');
      return [];
    }
  }

  /// Listen to changes for a specific key
  void listenKey(String key, Function(dynamic) callback) {
    try {
      _storage.listenKey(key, callback);
      LoggingService.info('StorageService: Listening to key: $key');
    } catch (e) {
      LoggingService.error('StorageService: Failed to listen to key $key - $e');
    }
  }

  /// Dispose resources
  void dispose() {
    try {
      // GetStorage doesn't require explicit disposal
      LoggingService.info('StorageService: Disposed');
    } catch (e) {
      LoggingService.error('StorageService: Error during disposal - $e');
    }
  }
}
