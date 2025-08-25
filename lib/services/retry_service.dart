import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/connectivity_helper.dart';
import '../utils/error_handler.dart';
import 'feedback_service.dart';

/// Service for handling retry mechanisms with exponential backoff
class RetryService {
  static const String _tag = 'RetryService';

  /// Retry configuration
  static const int defaultMaxRetries = 3;
  static const Duration defaultInitialDelay = Duration(seconds: 1);
  static const double defaultBackoffMultiplier = 2.0;
  static const Duration defaultMaxDelay = Duration(seconds: 30);

  /// Execute operation with retry mechanism and exponential backoff
  static Future<T?> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = defaultMaxRetries,
    Duration initialDelay = defaultInitialDelay,
    double backoffMultiplier = defaultBackoffMultiplier,
    Duration maxDelay = defaultMaxDelay,
    String? operationName,
    bool requiresConnectivity = true,
    bool showProgressToUser = false,
    List<Type>? retryableExceptions,
  }) async {
    int attempts = 0;
    Duration currentDelay = initialDelay;
    String opName = operationName ?? 'Operation';

    while (attempts < maxRetries) {
      attempts++;

      try {
        if (kDebugMode) {
          print('$_tag: Executing $opName (attempt $attempts/$maxRetries)');
        }

        // Check connectivity if required
        if (requiresConnectivity) {
          final bool isConnected = await ConnectivityHelper.checkConnectivity();
          if (!isConnected) {
            throw Exception('No internet connection');
          }
        }

        // Show progress to user if requested
        if (showProgressToUser && attempts > 1) {
          FeedbackService.showInfo('Retrying $opName... (attempt $attempts)');
        }

        // Execute the operation
        final result = await operation();

        // Success - log if it took multiple attempts
        if (attempts > 1) {
          if (kDebugMode) {
            print('$_tag: $opName succeeded after $attempts attempts');
          }
          if (showProgressToUser) {
            FeedbackService.showSuccess('$opName completed successfully');
          }
        }

        return result;
      } catch (error) {
        if (kDebugMode) {
          print(
            '$_tag: $opName failed (attempt $attempts/$maxRetries): $error',
          );
        }

        // Check if this is the last attempt
        if (attempts >= maxRetries) {
          if (kDebugMode) {
            print('$_tag: $opName failed after $maxRetries attempts');
          }

          // Handle the final error
          if (showProgressToUser) {
            ErrorHandler.handleApiError(error, context: opName);
          }

          rethrow;
        }

        // Check if error is retryable
        if (!_isRetryableError(error, retryableExceptions)) {
          if (kDebugMode) {
            print('$_tag: $opName failed with non-retryable error: $error');
          }

          if (showProgressToUser) {
            ErrorHandler.handleApiError(error, context: opName);
          }

          rethrow;
        }

        // Calculate delay with jitter to avoid thundering herd
        final Duration delayWithJitter = _calculateDelayWithJitter(
          currentDelay,
        );

        if (kDebugMode) {
          print(
            '$_tag: Retrying $opName in ${delayWithJitter.inMilliseconds}ms...',
          );
        }

        // Wait before retrying
        await Future.delayed(delayWithJitter);

        // Update delay for next attempt (exponential backoff)
        currentDelay = Duration(
          milliseconds: min(
            (currentDelay.inMilliseconds * backoffMultiplier).round(),
            maxDelay.inMilliseconds,
          ),
        );
      }
    }

    return null; // This should never be reached
  }

  /// Execute operation with user-controlled retry
  static Future<T?> executeWithUserRetry<T>(
    Future<T> Function() operation, {
    String? operationName,
    String? errorTitle,
    String? errorMessage,
    bool requiresConnectivity = true,
  }) async {
    String opName = operationName ?? 'Operation';

    try {
      // Check connectivity if required
      if (requiresConnectivity) {
        final bool isConnected = await ConnectivityHelper.checkConnectivity();
        if (!isConnected) {
          await _showConnectivityRetryDialog(operation, opName);
          return null;
        }
      }

      return await operation();
    } catch (error) {
      if (kDebugMode) {
        print('$_tag: $opName failed: $error');
      }

      // Show retry dialog to user
      return await _showRetryDialog<T>(
        operation,
        opName,
        errorTitle ?? 'Operation Failed',
        errorMessage ?? ErrorHandler.getUserFriendlyMessage(error),
        requiresConnectivity,
      );
    }
  }

  /// Execute multiple operations with retry
  static Future<List<T?>> executeMultipleWithRetry<T>(
    List<Future<T> Function()> operations, {
    int maxRetries = defaultMaxRetries,
    Duration initialDelay = defaultInitialDelay,
    String? operationName,
    bool failFast = false,
    bool showProgressToUser = false,
  }) async {
    final List<T?> results = [];
    String opName = operationName ?? 'Batch operation';

    if (showProgressToUser) {
      FeedbackService.showInfo('Executing $opName...');
    }

    for (int i = 0; i < operations.length; i++) {
      try {
        final result = await executeWithRetry<T>(
          operations[i],
          maxRetries: maxRetries,
          initialDelay: initialDelay,
          operationName: '$opName ${i + 1}/${operations.length}',
          showProgressToUser: showProgressToUser,
        );
        results.add(result);
      } catch (error) {
        if (failFast) {
          if (showProgressToUser) {
            FeedbackService.showError('$opName failed at step ${i + 1}');
          }
          rethrow;
        } else {
          results.add(null);
          if (kDebugMode) {
            print('$_tag: $opName step ${i + 1} failed, continuing...');
          }
        }
      }
    }

    if (showProgressToUser) {
      final int successCount = results.where((r) => r != null).length;
      FeedbackService.showInfo(
        '$opName completed: $successCount/${operations.length} successful',
      );
    }

    return results;
  }

  /// Check if an error is retryable
  static bool _isRetryableError(
    dynamic error,
    List<Type>? retryableExceptions,
  ) {
    // If specific retryable exceptions are provided, check against them
    if (retryableExceptions != null) {
      return retryableExceptions.any((type) => error.runtimeType == type);
    }

    // Default retryable error logic
    return ErrorHandler.isRecoverableError(error);
  }

  /// Calculate delay with jitter to avoid thundering herd problem
  static Duration _calculateDelayWithJitter(Duration baseDelay) {
    final Random random = Random();
    final int jitterMs = random.nextInt(1000); // 0-1000ms jitter
    return Duration(milliseconds: baseDelay.inMilliseconds + jitterMs);
  }

  /// Show retry dialog to user
  static Future<T?> _showRetryDialog<T>(
    Future<T> Function() operation,
    String operationName,
    String title,
    String message,
    bool requiresConnectivity,
  ) async {
    final Completer<T?> completer = Completer<T?>();

    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            if (!ConnectivityHelper.isConnected) ...[
              Row(
                children: [
                  Icon(
                    Icons.wifi_off,
                    color: Get.theme.colorScheme.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No internet connection',
                    style: TextStyle(
                      color: Get.theme.colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              completer.complete(null);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Get.back();
              try {
                final result = await executeWithUserRetry<T>(
                  operation,
                  operationName: operationName,
                  requiresConnectivity: requiresConnectivity,
                );
                completer.complete(result);
              } catch (error) {
                completer.complete(null);
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    return completer.future;
  }

  /// Show connectivity retry dialog
  static Future<T?> _showConnectivityRetryDialog<T>(
    Future<T> Function() operation,
    String operationName,
  ) async {
    final Completer<T?> completer = Completer<T?>();

    Get.dialog(
      AlertDialog(
        title: const Text('No Internet Connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 48, color: Get.theme.colorScheme.error),
            const SizedBox(height: 16),
            const Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              completer.complete(null);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Get.back();

              // Wait for connection with loading indicator
              FeedbackService.showInfo('Checking connection...');

              final bool connected = await ConnectivityHelper.waitForConnection(
                timeout: const Duration(seconds: 10),
              );

              if (connected) {
                try {
                  final result = await operation();
                  completer.complete(result);
                } catch (error) {
                  completer.complete(
                    await executeWithUserRetry<T>(
                      operation,
                      operationName: operationName,
                    ),
                  );
                }
              } else {
                FeedbackService.showNetworkError(
                  'Still no internet connection. Please try again later.',
                );
                completer.complete(null);
              }
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    return completer.future;
  }

  /// Create a retryable wrapper for a function
  static Future<T> Function() createRetryableOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = defaultMaxRetries,
    Duration initialDelay = defaultInitialDelay,
    String? operationName,
    bool showProgressToUser = false,
  }) {
    return () => executeWithRetry<T>(
      operation,
      maxRetries: maxRetries,
      initialDelay: initialDelay,
      operationName: operationName,
      showProgressToUser: showProgressToUser,
    ).then((result) => result!);
  }
}
