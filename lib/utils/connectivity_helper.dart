import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Simple helper class for checking network connectivity
class ConnectivityHelper {
  static final RxBool _isConnected = true.obs;

  /// Get current connectivity status
  static bool get isConnected => _isConnected.value;

  /// Get observable connectivity status
  static RxBool get isConnectedObs => _isConnected;

  /// Check internet connectivity
  static Future<bool> checkConnectivity() async {
    try {
      if (kIsWeb) {
        // For web, assume connection is available since we can't reliably check
        // without additional dependencies. The app will handle API errors gracefully.
        _isConnected.value = true;
        return true;
      } else {
        // Try to lookup a reliable host
        final result = await InternetAddress.lookup(
          'google.com',
        ).timeout(const Duration(seconds: 5));

        final bool connected =
            result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        _isConnected.value = connected;
        return connected;
      }
    } catch (e) {
      _isConnected.value = false;
      return false;
    }
  }
}
