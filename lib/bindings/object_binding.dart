import 'package:get/get.dart';
import '../controllers/object_controller.dart';
import '../services/api_service.dart';
import '../services/logging_service.dart';
import '../services/retry_service.dart';

/// Binding class for object management dependencies
/// This binding is used for object-related screens (list, detail, form)
class ObjectBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize object-specific services
    _initializeServices();

    // Initialize object controllers
    _initializeControllers();

    // Log binding initialization
    LoggingService.info('ObjectBinding: Dependencies initialized');
  }

  /// Initialize services needed for object management
  void _initializeServices() {
    // API service for REST operations
    Get.lazyPut<ApiService>(
      () => ApiService(retryService: Get.find<RetryService>()),
      fenix: true,
    );
  }

  /// Initialize controllers for object management
  void _initializeControllers() {
    // Object controller for CRUD operations
    Get.lazyPut<ObjectController>(
      () => ObjectController(apiService: Get.find<ApiService>()),
      fenix: true,
    );
  }
}
