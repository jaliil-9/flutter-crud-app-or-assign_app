import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Helper class for managing network connectivity
class ConnectivityHelper {
  static const String _tag = 'ConnectivityHelper';
  static Timer? _connectivityTimer;
  static final RxBool _isConnected = true.obs;
  static final RxBool _isChecking = false.obs;

  /// Get current connectivity status
  static bool get isConnected => _isConnected.value;

  /// Get observable connectivity status
  static RxBool get isConnectedObs => _isConnected;

  /// Get checking status
  static bool get isChecking => _isChecking.value;

  /// Get observable checking status
  static RxBool get isCheckingObs => _isChecking;

  /// Initialize connectivity monitoring
  static void initialize() {
    // Start periodic connectivity checks
    startPeriodicCheck();

    // Perform initial connectivity check
    checkConnectivity();
  }

  /// Check internet connectivity
  static Future<bool> checkConnectivity() async {
    if (_isChecking.value) {
      return _isConnected.value;
    }

    _isChecking.value = true;

    try {
      // For web platform, use a different approach
      if (kIsWeb) {
        return await _checkConnectivityWeb();
      } else {
        return await _checkConnectivityMobile();
      }
    } catch (e) {
      if (kDebugMode) {
        print('$_tag: Connectivity check failed: $e');
      }
      _isConnected.value = false;
      return false;
    } finally {
      _isChecking.value = false;
    }
  }

  /// Check connectivity for mobile platforms
  static Future<bool> _checkConnectivityMobile() async {
    try {
      // Try to lookup a reliable host
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));

      final bool connected =
          result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      _isConnected.value = connected;

      if (kDebugMode) {
        print('$_tag: Mobile connectivity check - Connected: $connected');
      }

      return connected;
    } on SocketException catch (_) {
      _isConnected.value = false;
      if (kDebugMode) {
        print('$_tag: Mobile connectivity check - No internet connection');
      }
      return false;
    } on TimeoutException catch (_) {
      _isConnected.value = false;
      if (kDebugMode) {
        print('$_tag: Mobile connectivity check - Connection timeout');
      }
      return false;
    }
  }

  /// Check connectivity for web platform
  static Future<bool> _checkConnectivityWeb() async {
    try {
      // For web, assume connection is available since we can't reliably check
      // without additional dependencies. The app will handle API errors gracefully.
      _isConnected.value = true;

      if (kDebugMode) {
        print('$_tag: Web connectivity check - Assumed connected');
      }

      return true;
    } catch (e) {
      _isConnected.value = false;
      if (kDebugMode) {
        print('$_tag: Web connectivity check failed: $e');
      }
      return false;
    }
  }

  /// Start periodic connectivity checking
  static void startPeriodicCheck({
    Duration interval = const Duration(seconds: 30),
  }) {
    stopPeriodicCheck(); // Stop any existing timer

    _connectivityTimer = Timer.periodic(interval, (timer) {
      checkConnectivity();
    });

    if (kDebugMode) {
      print(
        '$_tag: Started periodic connectivity check (${interval.inSeconds}s interval)',
      );
    }
  }

  /// Stop periodic connectivity checking
  static void stopPeriodicCheck() {
    _connectivityTimer?.cancel();
    _connectivityTimer = null;

    if (kDebugMode) {
      print('$_tag: Stopped periodic connectivity check');
    }
  }

  /// Wait for internet connection to be available
  static Future<bool> waitForConnection({
    Duration timeout = const Duration(seconds: 30),
    Duration checkInterval = const Duration(seconds: 2),
  }) async {
    final Completer<bool> completer = Completer<bool>();
    Timer? timeoutTimer;
    Timer? checkTimer;

    // Set up timeout
    timeoutTimer = Timer(timeout, () {
      checkTimer?.cancel();
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    // Check connectivity periodically
    checkTimer = Timer.periodic(checkInterval, (timer) async {
      final bool connected = await checkConnectivity();
      if (connected && !completer.isCompleted) {
        timer.cancel();
        timeoutTimer?.cancel();
        completer.complete(true);
      }
    });

    // Check immediately
    final bool initialCheck = await checkConnectivity();
    if (initialCheck && !completer.isCompleted) {
      checkTimer.cancel();
      timeoutTimer.cancel();
      completer.complete(true);
    }

    return completer.future;
  }

  /// Execute a function when internet connection is available
  static Future<T?> executeWhenConnected<T>(
    Future<T> Function() operation, {
    Duration timeout = const Duration(seconds: 30),
    String? errorMessage,
  }) async {
    // Check if already connected
    if (await checkConnectivity()) {
      return await operation();
    }

    // Wait for connection
    final bool connected = await waitForConnection(timeout: timeout);

    if (connected) {
      return await operation();
    } else {
      throw Exception(
        errorMessage ?? 'Operation failed: No internet connection available',
      );
    }
  }

  /// Show connectivity status to user
  static void showConnectivityStatus() {
    if (_isConnected.value) {
      Get.snackbar(
        'Connection Restored',
        'Internet connection is now available',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.wifi, color: Colors.white),
      );
    } else {
      Get.snackbar(
        'No Internet Connection',
        'Please check your network settings',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.wifi_off, color: Colors.white),
      );
    }
  }

  /// Listen to connectivity changes
  static StreamSubscription<bool> listenToConnectivityChanges(
    Function(bool isConnected) onConnectivityChanged,
  ) {
    bool previousState = _isConnected.value;

    return _isConnected.listen((bool currentState) {
      if (currentState != previousState) {
        previousState = currentState;
        onConnectivityChanged(currentState);

        if (kDebugMode) {
          print('$_tag: Connectivity changed - Connected: $currentState');
        }
      }
    });
  }

  /// Get connectivity status as string
  static String getConnectivityStatusText() {
    if (_isChecking.value) {
      return 'Checking connection...';
    } else if (_isConnected.value) {
      return 'Connected';
    } else {
      return 'No internet connection';
    }
  }

  /// Dispose resources
  static void dispose() {
    stopPeriodicCheck();
    if (kDebugMode) {
      print('$_tag: Disposed connectivity helper');
    }
  }
}
