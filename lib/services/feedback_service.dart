import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Standardized feedback service for showing success, error, info, and warning messages
class FeedbackService {
  // Private constructor to prevent instantiation
  FeedbackService._();

  /// Show success message with standardized styling
  static void showSuccess(
    String message, {
    String? title,
    Duration? duration,
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    if (Get.testMode) return; // Skip snackbars in test mode

    try {
      Get.snackbar(
        title ?? 'Success',
        message,
        snackPosition: position,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
        duration: duration ?? const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: Icon(
          Icons.check_circle_outline,
          color: Get.theme.colorScheme.onPrimary,
          size: 24,
        ),
        shouldIconPulse: false,
        animationDuration: const Duration(milliseconds: 300),
        forwardAnimationCurve: Curves.easeOutBack,
        reverseAnimationCurve: Curves.easeInBack,
      );
    } catch (e) {
      // Ignore snackbar errors in test environment
      debugPrint('FeedbackService: Error showing success snackbar: $e');
    }
  }

  /// Show error message with standardized styling
  static void showError(
    String message, {
    String? title,
    Duration? duration,
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    if (Get.testMode) return; // Skip snackbars in test mode

    try {
      Get.snackbar(
        title ?? 'Error',
        message,
        snackPosition: position,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: duration ?? const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: Icon(
          Icons.error_outline,
          color: Get.theme.colorScheme.onError,
          size: 24,
        ),
        shouldIconPulse: false,
        animationDuration: const Duration(milliseconds: 300),
        forwardAnimationCurve: Curves.easeOutBack,
        reverseAnimationCurve: Curves.easeInBack,
      );
    } catch (e) {
      // Ignore snackbar errors in test environment
      debugPrint('FeedbackService: Error showing error snackbar: $e');
    }
  }

  /// Show info message with standardized styling
  static void showInfo(
    String message, {
    String? title,
    Duration? duration,
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    if (Get.testMode) return; // Skip snackbars in test mode

    try {
      Get.snackbar(
        title ?? 'Info',
        message,
        snackPosition: position,
        backgroundColor: Get.theme.colorScheme.surfaceContainerHighest,
        colorText: Get.theme.colorScheme.onSurface,
        duration: duration ?? const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: Icon(
          Icons.info_outline,
          color: Get.theme.colorScheme.primary,
          size: 24,
        ),
        shouldIconPulse: false,
        animationDuration: const Duration(milliseconds: 300),
        forwardAnimationCurve: Curves.easeOutBack,
        reverseAnimationCurve: Curves.easeInBack,
      );
    } catch (e) {
      // Ignore snackbar errors in test environment
      debugPrint('FeedbackService: Error showing info snackbar: $e');
    }
  }

  /// Show warning message with standardized styling
  static void showWarning(
    String message, {
    String? title,
    Duration? duration,
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    if (Get.testMode) return; // Skip snackbars in test mode

    try {
      final warningColor = Colors.orange.shade600;
      Get.snackbar(
        title ?? 'Warning',
        message,
        snackPosition: position,
        backgroundColor: warningColor,
        colorText: Colors.white,
        duration: duration ?? const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.warning_outlined, color: Colors.white, size: 24),
        shouldIconPulse: false,
        animationDuration: const Duration(milliseconds: 300),
        forwardAnimationCurve: Curves.easeOutBack,
        reverseAnimationCurve: Curves.easeInBack,
      );
    } catch (e) {
      // Ignore snackbar errors in test environment
      debugPrint('FeedbackService: Error showing warning snackbar: $e');
    }
  }

  /// Show loading message (typically used with manual dismissal)
  static void showLoading(String message, {String? title, Duration? duration}) {
    if (Get.testMode) return; // Skip snackbars in test mode

    try {
      Get.snackbar(
        title ?? 'Loading',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.surfaceContainerHighest,
        colorText: Get.theme.colorScheme.onSurface,
        duration:
            duration ??
            const Duration(seconds: 10), // Longer duration for loading
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Get.theme.colorScheme.primary,
            ),
          ),
        ),
        shouldIconPulse: false,
        showProgressIndicator: false,
        animationDuration: const Duration(milliseconds: 300),
        forwardAnimationCurve: Curves.easeOutBack,
        reverseAnimationCurve: Curves.easeInBack,
      );
    } catch (e) {
      // Ignore snackbar errors in test environment
      debugPrint('FeedbackService: Error showing loading snackbar: $e');
    }
  }

  /// Dismiss any currently showing snackbar
  static void dismiss() {
    try {
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }
    } catch (e) {
      debugPrint('FeedbackService: Error dismissing snackbar: $e');
    }
  }

  /// Show CRUD operation success messages with specific formatting
  static void showCrudSuccess(String operation, String itemType) {
    final String message = getCrudSuccessMessage(operation, itemType);
    showSuccess(message);
  }

  /// Show CRUD operation error messages with specific formatting
  static void showCrudError(
    String operation,
    String itemType, [
    String? details,
  ]) {
    final String message = getCrudErrorMessage(operation, itemType, details);
    showError(message);
  }

  /// Get standardized CRUD success message
  @visibleForTesting
  static String getCrudSuccessMessage(String operation, String itemType) {
    switch (operation.toLowerCase()) {
      case 'create':
      case 'created':
        return '$itemType created successfully';
      case 'update':
      case 'updated':
        return '$itemType updated successfully';
      case 'delete':
      case 'deleted':
        return '$itemType deleted successfully';
      case 'fetch':
      case 'fetched':
      case 'load':
      case 'loaded':
        return '$itemType loaded successfully';
      default:
        return '$itemType $operation successfully';
    }
  }

  /// Get standardized CRUD error message
  @visibleForTesting
  static String getCrudErrorMessage(
    String operation,
    String itemType, [
    String? details,
  ]) {
    final String baseMessage;
    switch (operation.toLowerCase()) {
      case 'create':
      case 'creating':
        baseMessage = 'Failed to create $itemType';
        break;
      case 'update':
      case 'updating':
        baseMessage = 'Failed to update $itemType';
        break;
      case 'delete':
      case 'deleting':
        baseMessage = 'Failed to delete $itemType';
        break;
      case 'fetch':
      case 'fetching':
      case 'load':
      case 'loading':
        baseMessage = 'Failed to load $itemType';
        break;
      default:
        baseMessage = 'Failed to $operation $itemType';
    }

    if (details != null && details.isNotEmpty) {
      return '$baseMessage: $details';
    } else {
      return '$baseMessage. Please try again.';
    }
  }

  /// Show authentication success messages
  static void showAuthSuccess(String message) {
    showSuccess(message, title: 'Authentication');
  }

  /// Show authentication error messages
  static void showAuthError(String message) {
    showError(message, title: 'Authentication Error');
  }

  /// Show network error with retry option
  static void showNetworkError([String? customMessage]) {
    showError(
      customMessage ??
          'Network error occurred. Please check your connection and try again.',
      title: 'Connection Error',
      duration: const Duration(seconds: 5),
    );
  }

  /// Show validation error
  static void showValidationError(String message) {
    showWarning(message, title: 'Validation Error');
  }

  /// Show copy to clipboard confirmation
  static void showCopySuccess([String? itemName]) {
    showInfo(
      '${itemName ?? 'Content'} copied to clipboard',
      duration: const Duration(seconds: 2),
    );
  }
}
