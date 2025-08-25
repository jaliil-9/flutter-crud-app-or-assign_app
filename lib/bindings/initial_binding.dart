import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../controllers/auth_controller.dart';
import '../controllers/theme_controller.dart';
import '../services/auth_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    _initializeCoreServices();
    _initializeGlobalControllers();
  }

  void _initializeCoreServices() {
    Get.put<AuthService>(AuthService(), permanent: true);

    if (kDebugMode) {
      debugPrint('InitialBinding: Core services initialized');
    }
  }

  void _initializeGlobalControllers() {
    Get.put<ThemeController>(ThemeController(), permanent: true);

    Get.put<AuthController>(
      AuthController(authService: Get.find<AuthService>()),
      permanent: true,
    );
  }
}
