import 'package:get/get.dart';
import 'service_binding.dart';
import 'controller_binding.dart';
import '../services/logging_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/object_controller.dart';
import '../controllers/theme_controller.dart';

/// Main comprehensive binding that sets up all dependencies
/// This can be used when you need all services and controllers available
class MainBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize services first
    ServiceBinding().dependencies();

    // Then initialize controllers
    ControllerBinding().dependencies();

    // Log main binding completion
    LoggingService.info('MainBinding: All dependencies initialized');
  }
}

/// Lightweight binding for testing or minimal setups
class TestBinding extends Bindings {
  @override
  void dependencies() {
    // Only initialize essential services for testing
    Get.put<LoggingService>(LoggingService(), permanent: true);
  }
}

/// Binding utilities for dependency management
class BindingUtils {
  /// Check if all required dependencies are registered
  static bool areCoreDependenciesRegistered() {
    return Get.isRegistered<LoggingService>();
  }

  /// Reset all dependencies (useful for testing)
  static void resetAllDependencies() {
    Get.reset();
  }

  /// Get dependency registration status
  static Map<String, bool> getDependencyStatus() {
    return {
      'LoggingService': Get.isRegistered<LoggingService>(),
      'AuthService': Get.isRegistered<AuthService>(),
      'ApiService': Get.isRegistered<ApiService>(),
      'AuthController': Get.isRegistered<AuthController>(),
      'ObjectController': Get.isRegistered<ObjectController>(),
      'ThemeController': Get.isRegistered<ThemeController>(),
    };
  }

  /// Log current dependency status
  static void logDependencyStatus() {
    final status = getDependencyStatus();

    LoggingService.info('Dependency Status:');
    status.forEach((key, value) {
      LoggingService.info('  $key: ${value ? "✓" : "✗"}');
    });
  }
}
