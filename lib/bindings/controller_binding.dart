import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../controllers/auth_controller.dart';
import '../controllers/object_controller.dart';
import '../controllers/theme_controller.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ControllerBinding extends Bindings {
  @override
  void dependencies() {
    _initializeGlobalControllers();
    _initializeFeatureControllers();

    if (kDebugMode) {
      debugPrint('ControllerBinding: All controllers initialized');
    }
  }

  void _initializeGlobalControllers() {
    if (!Get.isRegistered<ThemeController>()) {
      Get.put<ThemeController>(ThemeController(), permanent: true);
    }

    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(
        AuthController(authService: Get.find<AuthService>()),
        permanent: true,
      );
    }
  }

  void _initializeFeatureControllers() {
    Get.lazyPut<ObjectController>(
      () => ObjectController(apiService: Get.find<ApiService>()),
      fenix: true,
    );
  }
}

abstract class BaseController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    if (kDebugMode) {
      debugPrint('$runtimeType: Controller initialized');
    }
  }

  @override
  void onReady() {
    super.onReady();
    if (kDebugMode) {
      debugPrint('$runtimeType: Controller ready');
    }
  }

  @override
  void onClose() {
    if (kDebugMode) {
      debugPrint('$runtimeType: Controller disposed');
    }
    super.onClose();
  }

  void handleError(dynamic error, {String? context}) {
    final errorMessage = context != null
        ? '$context: ${error.toString()}'
        : error.toString();

    if (kDebugMode) {
      debugPrint('$runtimeType: $errorMessage');
    }

    Get.snackbar(
      'Error',
      'Something went wrong. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
