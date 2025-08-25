import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/theme_controller.dart';
import '../services/auth_service.dart';
import '../services/logging_service.dart';
import '../services/retry_service.dart';

/// Initial binding that sets up global dependencies
/// This ensures core services and controllers are available globally
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize core services first (these are singletons that should persist)
    _initializeCoreServices();

    // Initialize global controllers
    _initializeGlobalControllers();
  }

  /// Initialize core services that should be available globally
  void _initializeCoreServices() {
    // Logging service - should be available everywhere
    Get.put<LoggingService>(LoggingService(), permanent: true);

    // Retry service - used for network operations
    Get.put<RetryService>(RetryService(), permanent: true);

    // Auth service - core authentication functionality
    Get.put<AuthService>(AuthService(), permanent: true);
  }

  /// Initialize global controllers that should persist across the app
  void _initializeGlobalControllers() {
    // Theme controller - manages app theme state
    Get.put<ThemeController>(ThemeController(), permanent: true);

    // Auth controller - manages authentication state globally
    Get.put<AuthController>(
      AuthController(authService: Get.find<AuthService>()),
      permanent: true,
    );
  }
}
