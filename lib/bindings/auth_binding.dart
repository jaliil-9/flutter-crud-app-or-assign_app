import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../services/auth_service.dart';
import '../services/logging_service.dart';

/// Binding class for authentication-related dependencies
/// This binding is used for authentication screens (login, OTP verification)
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Auth-related services and controllers are already registered globally
    // in InitialBinding, so we just ensure they're available

    // Ensure AuthService is available (should already be registered globally)
    if (!Get.isRegistered<AuthService>()) {
      Get.lazyPut<AuthService>(() => AuthService(), fenix: true);
    }

    // Ensure AuthController is available (should already be registered globally)
    if (!Get.isRegistered<AuthController>()) {
      Get.lazyPut<AuthController>(
        () => AuthController(authService: Get.find<AuthService>()),
        fenix: true,
      );
    }

    // Log binding initialization
    LoggingService.info('AuthBinding: Dependencies initialized');
  }
}
