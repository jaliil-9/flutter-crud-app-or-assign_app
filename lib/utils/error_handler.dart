import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import 'connectivity_helper.dart';

class ErrorHandler {
  static const String _tag = 'ErrorHandler';

  static void initialize() {
    FlutterError.onError = (FlutterErrorDetails details) {
      _logError(
        'Flutter Error',
        details.exception,
        details.stack,
        details.context?.toString(),
      );

      if (kDebugMode) {
        FlutterError.presentError(details);
      } else {
        _showUserFriendlyError('An unexpected error occurred');
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _logError('Async Error', error, stack);

      if (!kDebugMode) {
        _showUserFriendlyError('An unexpected error occurred');
      }

      return true;
    };
  }

  static void handleApiError(dynamic error, {String? context}) {
    _logError('API Error', error, null, context);

    String message;
    if (error is ApiException) {
      switch (error.statusCode) {
        case 400:
          message = 'Invalid request. Please check your input.';
          break;
        case 401:
          message = 'Authentication required. Please log in again.';
          break;
        case 403:
          message =
              'Access denied. You don\'t have permission for this action.';
          break;
        case 404:
          message = 'The requested resource was not found.';
          break;
        case 408:
          message = 'Request timeout. Please try again.';
          break;
        case 429:
          message = 'Too many requests. Please wait a moment and try again.';
          break;
        case 500:
        case 502:
        case 503:
        case 504:
          message = 'Server error. Please try again later.';
          break;
        default:
          message = error.message;
      }
    } else {
      message = 'Network error occurred. Please check your connection.';
    }

    _showErrorSnackBar(message);
  }

  static void handleAuthError(dynamic error, {String? context}) {
    _logError('Auth Error', error, null, context);

    String message = 'Authentication error occurred';

    if (error.toString().contains('invalid-verification-code')) {
      message = 'Invalid verification code. Please try again.';
    } else if (error.toString().contains('session-expired')) {
      message = 'Session expired. Please request a new code.';
    } else if (error.toString().contains('too-many-requests')) {
      message = 'Too many attempts. Please wait before trying again.';
    } else if (error.toString().contains('network-request-failed')) {
      message = 'Network error. Please check your connection.';
    }

    _showErrorSnackBar(message, title: 'Authentication Error');
  }

  static Future<void> handleConnectivityError({
    required VoidCallback onRetry,
    String? customMessage,
  }) async {
    final bool isConnected = await ConnectivityHelper.checkConnectivity();

    String message;
    if (!isConnected) {
      message =
          customMessage ??
          'No internet connection. Please check your network settings.';
    } else {
      message = customMessage ?? 'Network error occurred. Please try again.';
    }

    _showErrorSnackBar(message, title: 'Connection Error');
  }

  static Future<T?> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    String? context,
    bool showRetryDialog = false,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        attempts++;
        _logInfo(
          'Executing operation (attempt $attempts/$maxRetries)',
          context,
        );

        final bool isConnected = await ConnectivityHelper.checkConnectivity();
        if (!isConnected) {
          throw const ApiException('No internet connection');
        }

        final result = await operation();

        if (attempts > 1) {
          _logInfo('Operation succeeded after $attempts attempts', context);
          _showSuccessSnackBar('Operation completed successfully');
        }

        return result;
      } catch (error) {
        _logError(
          'Operation failed (attempt $attempts/$maxRetries)',
          error,
          null,
          context,
        );

        if (attempts >= maxRetries) {
          if (showRetryDialog) {
            _showRetryDialog(operation, context);
          } else {
            handleApiError(error, context: context);
          }
          return null;
        }

        final retryDelay = Duration(
          milliseconds: delay.inMilliseconds * attempts,
        );

        _logInfo('Retrying in ${retryDelay.inMilliseconds}ms...', context);
        await Future.delayed(retryDelay);
      }
    }

    return null;
  }

  static void _showRetryDialog<T>(
    Future<T> Function() operation,
    String? context,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Operation Failed'),
        content: const Text(
          'The operation failed after multiple attempts. Would you like to try again?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Get.back();
              executeWithRetry(operation, context: context);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  static void _logError(
    String type,
    dynamic error,
    StackTrace? stackTrace, [
    String? context,
  ]) {
    final String contextInfo = context != null ? ' [$context]' : '';
    final String message = '$type$contextInfo: $error';

    if (kDebugMode) {
      developer.log(
        message,
        name: _tag,
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    } else {
      developer.log(message, name: _tag, level: 1000);
    }
  }

  static void _logInfo(String message, [String? context]) {
    final String contextInfo = context != null ? ' [$context]' : '';
    final String logMessage = '$message$contextInfo';

    if (kDebugMode) {
      developer.log(logMessage, name: _tag, level: 800);
    }
  }

  static void _showUserFriendlyError(String message) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (Get.context != null) {
        _showErrorSnackBar(message);
      }
    });
  }

  static void handleValidationError(String field, String message) {
    _logInfo('Validation Error: $field - $message');
    _showWarningSnackBar(message, title: 'Validation Error');
  }

  static void handleFormError(Map<String, String> errors) {
    _logInfo('Form Errors: $errors');

    if (errors.isNotEmpty) {
      final String firstError = errors.values.first;
      _showWarningSnackBar(firstError, title: 'Validation Error');
    }
  }

  static bool isRecoverableError(dynamic error) {
    if (error is ApiException) {
      return error.statusCode == null ||
          error.statusCode == 408 ||
          error.statusCode == 429 ||
          (error.statusCode! >= 500 && error.statusCode! < 600);
    }
    final String errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('socket');
  }

  static String getUserFriendlyMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }

    final String errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network connection error. Please check your internet connection.';
    } else if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (errorString.contains('format')) {
      return 'Invalid data format. Please check your input.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  static void _showErrorSnackBar(String message, {String? title}) {
    try {
      Get.snackbar(
        title ?? 'Error',
        message,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        icon: Icon(Icons.error_outline, color: Get.theme.colorScheme.onError),
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      debugPrint('Error showing snackbar: $e');
    }
  }

  static void _showSuccessSnackBar(String message, {String? title}) {
    try {
      Get.snackbar(
        title ?? 'Success',
        message,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
        icon: Icon(
          Icons.check_circle_outline,
          color: Get.theme.colorScheme.onPrimary,
        ),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      debugPrint('Error showing snackbar: $e');
    }
  }

  static void _showWarningSnackBar(String message, {String? title}) {
    try {
      Get.snackbar(
        title ?? 'Warning',
        message,
        backgroundColor: Colors.orange.shade600,
        colorText: Colors.white,
        icon: const Icon(Icons.warning_outlined, color: Colors.white),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      debugPrint('Error showing snackbar: $e');
    }
  }
}
