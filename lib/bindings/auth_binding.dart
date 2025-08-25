import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../controllers/auth_controller.dart';
import '../services/auth_service.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AuthService>()) {
      Get.lazyPut<AuthService>(() => AuthService(), fenix: true);
    }

    if (!Get.isRegistered<AuthController>()) {
      Get.lazyPut<AuthController>(
        () => AuthController(authService: Get.find<AuthService>()),
        fenix: true,
      );
    }

    if (kDebugMode) {
      debugPrint('AuthBinding: Dependencies initialized');
    }
  }
}
