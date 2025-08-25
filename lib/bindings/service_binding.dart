import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

import '../services/storage_service.dart';

class ServiceBinding extends Bindings {
  @override
  void dependencies() {
    _initializeCoreServices();
    _initializeUtilityServices();
    _initializeBusinessServices();
  }

  void _initializeCoreServices() {}

  /// Initialize utility services
  void _initializeUtilityServices() {
    // Storage service - local data persistence
    Get.lazyPut<StorageService>(() => StorageService(), fenix: true);
  }

  /// Initialize business logic services
  void _initializeBusinessServices() {
    if (!Get.isRegistered<AuthService>()) {
      Get.lazyPut<AuthService>(() => AuthService(), fenix: true);
    }

    if (!Get.isRegistered<ApiService>()) {
      Get.lazyPut<ApiService>(() => ApiService(), fenix: true);
    }
  }
}
