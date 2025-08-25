import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'service_binding.dart';
import 'controller_binding.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/object_controller.dart';
import '../controllers/theme_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    ServiceBinding().dependencies();
    ControllerBinding().dependencies();

    if (kDebugMode) {
      debugPrint('MainBinding: All dependencies initialized');
    }
  }
}

class TestBinding extends Bindings {
  @override
  void dependencies() {
    if (kDebugMode) {
      debugPrint('TestBinding: Minimal dependencies initialized');
    }
  }
}

class BindingUtils {
  static bool areCoreDependenciesRegistered() {
    return Get.isRegistered<AuthService>() && Get.isRegistered<ApiService>();
  }

  static void resetAllDependencies() {
    Get.reset();
  }

  static Map<String, bool> getDependencyStatus() {
    return {
      'AuthService': Get.isRegistered<AuthService>(),
      'ApiService': Get.isRegistered<ApiService>(),
      'AuthController': Get.isRegistered<AuthController>(),
      'ObjectController': Get.isRegistered<ObjectController>(),
      'ThemeController': Get.isRegistered<ThemeController>(),
    };
  }

  static void logDependencyStatus() {
    if (kDebugMode) {
      final status = getDependencyStatus();
      debugPrint('Dependency Status:');
      status.forEach((key, value) {
        debugPrint('  $key: ${value ? "✓" : "✗"}');
      });
    }
  }
}
