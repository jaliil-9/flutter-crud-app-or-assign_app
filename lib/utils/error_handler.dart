import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/feedback_service.dart';
import 'connectivity_helper.dart';

/// Global error handler for managing all types of errors in the application
class ErrorHandler {
  static const String _tag = 'ErrorHandler';

  /// Initialize global error handling
  static void initialize() {
    // Set up global error handler for Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _logError(
        'Flutter Error',
        details.exception,
        details.stack,
        details.context?.toString(),
      );

      // In debug mode, use the default error handler
      if (kDebugMode) {
        FlutterError.presentError(details);
      } else {
        // In release mode, show user-friendly error
        _showUserFriendlyError('An unexpected error occurred');
      }
    };

    // Set up global error handler for async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _logError('Async Error', error, stack);

      if (!kDebugMode) {
        _showUserFriendlyError('An unexpected error occurred');
      }

      return true; // Indicates that the error was handled
    };
  }

  /// Handle API-related errors with appropriate user feedback
  static void handleApiError(dynamic error, {String? context}) {
    _logError('API Error', error, null, context);

    if (error is ApiException) {
      switch (error.statusCode) {
        case 400:
          FeedbackService.showError(
            'Invalid request. Please check your input.',
          );
          break;
        case 401:
          FeedbackService.showError(
            'Authentication required. Please log in again.',
          );
          // Could trigger logout here if needed
          break;
        case 403:
          FeedbackService.showError(
            'Access denied. You don\'t have permission for this action.',
          );
          break;
        case 404:
          FeedbackService.showError('The requested resource was not found.');
          break;
        case 408:
          FeedbackService.showNetworkError(
            'Request timeout. Please try again.',
          );
          break;
        case 429:
          FeedbackService.showError(
            'Too many requests. Please wait a moment and try again.',
          );
          break;
        case 500:
        case 502:
        case 503:
        case 504:
          FeedbackService.showError('Server error. Please try again later.');
          break;
        default:
          FeedbackService.showError(error.message);
      }
    } else {
      FeedbackService.showError(
        'Network error occurred. Please check your connection.',
      );
    }
  }

  /// Handle authentication errors
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

    FeedbackService.showAuthError(message);
  }

  /// Handle network connectivity errors
  static Future<void> handleConnectivityError({
    required VoidCallback onRetry,
    String? customMessage,
  }) async {
    final bool isConnected = await ConnectivityHelper.checkConnectivity();

    if (!isConnected) {
      FeedbackService.showNetworkError(
        customMessage ??
            'No internet connection. Please check your network settings.',
      );
    } else {
      FeedbackService.showNetworkError(
        customMessage ?? 'Network error occurred. Please try again.',
      );
    }
  }

  /// Execute an operation with automatic retry mechanism
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

        // Check connectivity before attempting
        final bool isConnected = await ConnectivityHelper.checkConnectivity();
        if (!isConnected) {
          throw const ApiException('No internet connection');
        }

        final result = await operation();

        if (attempts > 1) {
          _logInfo('Operation succeeded after $attempts attempts', context);
          FeedbackService.showSuccess('Operation completed successfully');
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
          // Final attempt failed
          if (showRetryDialog) {
            _showRetryDialog(operation, context);
          } else {
            handleApiError(error, context: context);
          }
          return null;
        }

        // Wait before retrying (exponential backoff)
        final retryDelay = Duration(
          milliseconds: delay.inMilliseconds * attempts,
        );

        _logInfo('Retrying in ${retryDelay.inMilliseconds}ms...', context);
        await Future.delayed(retryDelay);
      }
    }

    return null;
  }

  /// Show retry dialog for failed operations
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

  /// Log error with detailed information
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
        level: 1000, // Error level
      );
    } else {
      // In production, you might want to send to crash reporting service
      // like Firebase Crashlytics, Sentry, etc.
      developer.log(message, name: _tag, level: 1000);
    }
  }

  /// Log informational messages
  static void _logInfo(String message, [String? context]) {
    final String contextInfo = context != null ? ' [$context]' : '';
    final String logMessage = '$message$contextInfo';

    if (kDebugMode) {
      developer.log(logMessage, name: _tag, level: 800); // Info level
    }
  }

  /// Show user-friendly error message
  static void _showUserFriendlyError(String message) {
    // Use a delayed call to ensure the app is ready to show dialogs
    Future.delayed(const Duration(milliseconds: 100), () {
      if (Get.context != null) {
        FeedbackService.showError(message);
      }
    });
  }

  /// Handle validation errors
  static void handleValidationError(String field, String message) {
    _logInfo('Validation Error: $field - $message');
    FeedbackService.showValidationError(message);
  }

  /// Handle form submission errors
  static void handleFormError(Map<String, String> errors) {
    _logInfo('Form Errors: $errors');

    if (errors.isNotEmpty) {
      final String firstError = errors.values.first;
      FeedbackService.showValidationError(firstError);
    }
  }

  /// Check if error is recoverable (can be retried)
  static bool isRecoverableError(dynamic error) {
    if (error is ApiException) {
      // Network timeouts, server errors, and connectivity issues are recoverable
      return error.statusCode == null || // Network errors
          error.statusCode == 408 || // Timeout
          error.statusCode == 429 || // Rate limit
          (error.statusCode! >= 500 &&
              error.statusCode! < 600); // Server errors
    }

    // Check for common recoverable error patterns
    final String errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('socket');
  }

  /// Get user-friendly error message from exception
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
}
