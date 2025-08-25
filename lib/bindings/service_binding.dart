import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/logging_service.dart';
import '../services/retry_service.dart';
import '../services/storage_service.dart';

/// Comprehensive service binding for all application services
/// This binding can be used when all services need to be available
class ServiceBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize all services with proper dependency order
    _initializeCoreServices();
    _initializeUtilityServices();
    _initializeBusinessServices();

    // Log service binding completion
    LoggingService.info('ServiceBinding: All services initialized');
  }

  /// Initialize core services that other services depend on
  void _initializeCoreServices() {
    // Logging service - foundation for all other services
    if (!Get.isRegistered<LoggingService>()) {
      Get.put<LoggingService>(LoggingService(), permanent: true);
    }

    // Retry service - used by network operations
    if (!Get.isRegistered<RetryService>()) {
      Get.put<RetryService>(RetryService(), permanent: true);
    }
  }

  /// Initialize utility services
  void _initializeUtilityServices() {
    // Storage service - local data persistence
    Get.lazyPut<StorageService>(() => StorageService(), fenix: true);

    // Navigation service - centralized navigation logic
    // Note: NavigationService is static, so no need to register

    // Feedback service - user feedback and notifications
    // Note: FeedbackService is static, so no need to register
  }

  /// Initialize business logic services
  void _initializeBusinessServices() {
    // Auth service - authentication and user management
    if (!Get.isRegistered<AuthService>()) {
      Get.lazyPut<AuthService>(() => AuthService(), fenix: true);
    }

    // API service - REST API operations
    if (!Get.isRegistered<ApiService>()) {
      Get.lazyPut<ApiService>(
        () => ApiService(retryService: Get.find<RetryService>()),
        fenix: true,
      );
    }
  }
}
