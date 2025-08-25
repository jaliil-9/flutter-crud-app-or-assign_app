import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/object_controller.dart';
import '../controllers/theme_controller.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/logging_service.dart';

/// Comprehensive controller binding for all application controllers
/// This binding ensures proper controller lifecycle management
class ControllerBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize controllers with proper lifecycle management
    _initializeGlobalControllers();
    _initializeFeatureControllers();

    // Log controller binding completion
    LoggingService.info('ControllerBinding: All controllers initialized');
  }

  /// Initialize controllers that should persist globally
  void _initializeGlobalControllers() {
    // Theme controller - manages app-wide theme state
    if (!Get.isRegistered<ThemeController>()) {
      Get.put<ThemeController>(ThemeController(), permanent: true);
    }

    // Auth controller - manages global authentication state
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(
        AuthController(authService: Get.find<AuthService>()),
        permanent: true,
      );
    }
  }

  /// Initialize feature-specific controllers with proper lifecycle
  void _initializeFeatureControllers() {
    // Object controller - manages CRUD operations
    // Using lazyPut with fenix for automatic recreation when needed
    Get.lazyPut<ObjectController>(
      () => ObjectController(apiService: Get.find<ApiService>()),
      fenix: true,
    );
  }
}

/// Base controller class that provides common functionality
/// All controllers should extend this for consistent lifecycle management
abstract class BaseController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    LoggingService.info('$runtimeType: Controller initialized');
  }

  @override
  void onReady() {
    super.onReady();
    LoggingService.info('$runtimeType: Controller ready');
  }

  @override
  void onClose() {
    LoggingService.info('$runtimeType: Controller disposed');
    super.onClose();
  }

  /// Handle errors consistently across all controllers
  void handleError(dynamic error, {String? context}) {
    final errorMessage = context != null
        ? '$context: ${error.toString()}'
        : error.toString();

    LoggingService.error('$runtimeType: $errorMessage');

    // You can add additional error handling logic here
    // such as showing user-friendly error messages
  }

  /// Log info messages with controller context
  void logInfo(String message) {
    LoggingService.info('$runtimeType: $message');
  }

  /// Log warning messages with controller context
  void logWarning(String message) {
    LoggingService.warning('$runtimeType: $message');
  }
}
