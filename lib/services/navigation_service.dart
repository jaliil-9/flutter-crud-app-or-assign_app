import 'package:get/get.dart';
import '../app/routes/app_routes.dart';

/// Service to handle navigation operations and provide navigation utilities
class NavigationService {
  /// Navigate to object detail screen with proper parameter passing
  static void toObjectDetail(String objectId) {
    Get.toNamed(AppRoutes.objectDetailWithId(objectId));
  }

  /// Navigate to object edit screen with proper parameter passing
  static void toObjectEdit(String objectId) {
    Get.toNamed(AppRoutes.objectEditWithId(objectId));
  }

  /// Navigate to object form screen for creating new object
  static void toObjectForm() {
    Get.toNamed(AppRoutes.objectForm);
  }

  /// Navigate to object list screen
  static void toObjectList() {
    Get.toNamed(AppRoutes.objectList);
  }

  /// Navigate to login screen and clear navigation stack
  static void toLogin() {
    Get.offAllNamed(AppRoutes.login);
  }

  /// Navigate to OTP verification screen with arguments
  static void toOTPVerification({
    required String phoneNumber,
    required String verificationId,
  }) {
    Get.toNamed(
      AppRoutes.otpVerification,
      arguments: {'phoneNumber': phoneNumber, 'verificationId': verificationId},
    );
  }

  /// Go back to previous screen
  static void goBack() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    } else {
      // If can't go back, navigate to object list as fallback
      Get.offAllNamed(AppRoutes.objectList);
    }
  }

  /// Check if we can go back
  static bool canGoBack() {
    return Get.key.currentState?.canPop() ?? false;
  }

  /// Navigate back with result
  static void goBackWithResult<T>(T result) {
    Get.back(result: result);
  }

  /// Replace current route with new route
  static void offNamed(String routeName, {dynamic arguments}) {
    Get.offNamed(routeName, arguments: arguments);
  }

  /// Replace all routes with new route
  static void offAllNamed(String routeName, {dynamic arguments}) {
    Get.offAllNamed(routeName, arguments: arguments);
  }

  /// Get current route name
  static String? get currentRoute => Get.currentRoute;

  /// Get route parameters
  static Map<String, String> get parameters =>
      Get.parameters.map((key, value) => MapEntry(key, value ?? ''));

  /// Get route arguments
  static dynamic get arguments => Get.arguments;

  /// Check if current route is a specific route
  static bool isCurrentRoute(String routeName) {
    return Get.currentRoute == routeName;
  }

  /// Handle deep link navigation
  static void handleDeepLink(String path) {
    // Parse the path and navigate accordingly
    if (path.startsWith('/objects/') && path.contains('/edit')) {
      // Extract object ID from path like '/objects/123/edit'
      final parts = path.split('/');
      if (parts.length >= 3) {
        final objectId = parts[2];
        toObjectEdit(objectId);
      }
    } else if (path.startsWith('/objects/') && !path.contains('/edit')) {
      // Extract object ID from path like '/objects/123'
      final parts = path.split('/');
      if (parts.length >= 3) {
        final objectId = parts[2];
        toObjectDetail(objectId);
      }
    } else if (path == '/objects') {
      toObjectList();
    } else if (path == '/login') {
      toLogin();
    } else {
      // Default fallback
      Get.toNamed(path);
    }
  }
}
