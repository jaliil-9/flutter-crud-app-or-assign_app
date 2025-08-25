import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../controllers/object_controller.dart';
import '../services/api_service.dart';

class ObjectBinding extends Bindings {
  @override
  void dependencies() {
    _initializeServices();
    _initializeControllers();

    if (kDebugMode) {
      debugPrint('ObjectBinding: Dependencies initialized');
    }
  }

  void _initializeServices() {
    Get.lazyPut<ApiService>(() => ApiService(), fenix: true);
  }

  void _initializeControllers() {
    Get.lazyPut<ObjectController>(
      () => ObjectController(apiService: Get.find<ApiService>()),
      fenix: true,
    );
  }
}
