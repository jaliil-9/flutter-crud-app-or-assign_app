import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../services/navigation_service.dart';
import '../../views/common/connectivity_banner.dart';
import '../routes/app_routes.dart';

/// Wrapper widget that handles system back button behavior
class AppWrapper extends StatelessWidget {
  final Widget child;

  const AppWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ConnectivityBanner(
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;

          await _handleBackButton();
        },
        child: child,
      ),
    );
  }

  /// Handle system back button press
  Future<void> _handleBackButton() async {
    final currentRoute = NavigationService.currentRoute;

    // Handle back navigation based on current route
    switch (currentRoute) {
      case AppRoutes.objectList:
        // On main screen, show exit confirmation
        await _showExitConfirmation();
        break;

      case AppRoutes.login:
      case AppRoutes.otpVerification:
        // On auth screens, exit app
        SystemNavigator.pop();
        break;

      default:
        // For other screens, use normal back navigation
        if (NavigationService.canGoBack()) {
          NavigationService.goBack();
        } else {
          // Fallback to object list
          NavigationService.offAllNamed(AppRoutes.objectList);
        }
    }
  }

  /// Show exit confirmation dialog
  Future<void> _showExitConfirmation() async {
    final bool? shouldExit = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }
}
