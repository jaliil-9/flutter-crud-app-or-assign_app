import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

/// Log levels
enum LogLevel {
  debug(0, 'DEBUG'),
  info(800, 'INFO'),
  warning(900, 'WARNING'),
  error(1000, 'ERROR'),
  critical(1200, 'CRITICAL');

  const LogLevel(this.value, this.name);
  final int value;
  final String name;
}

/// Service for handling application logging with different levels
class LoggingService {
  static const String _tag = 'LoggingService';
  static const String _logStorageKey = 'app_logs';
  static const int _maxLogEntries = 1000;

  static GetStorage? _storage;
  static bool _initialized = false;

  /// Initialize logging service
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      _storage = GetStorage();
      _initialized = true;

      if (kDebugMode) {
        developer.log('Logging service initialized', name: _tag);
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Failed to initialize logging service: $e', name: _tag);
      }
    }
  }

  /// Log debug message
  static void debug(String message, {String? tag, dynamic data}) {
    _log(LogLevel.debug, message, tag: tag, data: data);
  }

  /// Log info message
  static void info(String message, {String? tag, dynamic data}) {
    _log(LogLevel.info, message, tag: tag, data: data);
  }

  /// Log warning message
  static void warning(String message, {String? tag, dynamic data}) {
    _log(LogLevel.warning, message, tag: tag, data: data);
  }

  /// Log error message
  static void error(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
    dynamic data,
  }) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Log critical error message
  static void critical(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
    dynamic data,
  }) {
    _log(
      LogLevel.critical,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Internal logging method
  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
    dynamic data,
  }) {
    final String logTag = tag ?? _tag;
    final DateTime timestamp = DateTime.now();

    // Create log entry
    final Map<String, dynamic> logEntry = {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'tag': logTag,
      'message': message,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      if (data != null) 'data': data.toString(),
    };

    // Log to console in debug mode
    if (kDebugMode) {
      developer.log(
        message,
        name: logTag,
        level: level.value,
        error: error,
        stackTrace: stackTrace,
      );
    }

    // Store log entry for later retrieval
    _storeLogEntry(logEntry);

    // In production, you might want to send critical errors to a crash reporting service
    if (!kDebugMode && level == LogLevel.critical) {
      _handleCriticalError(logEntry);
    }
  }

  /// Store log entry in local storage
  static void _storeLogEntry(Map<String, dynamic> logEntry) {
    if (!_initialized || _storage == null) return;

    try {
      List<dynamic> logs = _storage!.read(_logStorageKey) ?? [];

      // Add new log entry
      logs.add(logEntry);

      // Keep only the most recent entries
      if (logs.length > _maxLogEntries) {
        logs = logs.sublist(logs.length - _maxLogEntries);
      }

      _storage!.write(_logStorageKey, logs);
    } catch (e) {
      if (kDebugMode) {
        developer.log('Failed to store log entry: $e', name: _tag);
      }
    }
  }

  /// Handle critical errors (could send to crash reporting service)
  static void _handleCriticalError(Map<String, dynamic> logEntry) {
    // In a real app, you would send this to a crash reporting service
    // like Firebase Crashlytics, Sentry, Bugsnag, etc.

    if (kDebugMode) {
      developer.log(
        'CRITICAL ERROR: ${logEntry['message']}',
        name: _tag,
        level: LogLevel.critical.value,
      );
    }

    // For now, just ensure it's stored locally
    // In production, implement crash reporting integration here
  }

  /// Get stored logs
  static List<Map<String, dynamic>> getLogs({
    LogLevel? minLevel,
    String? tag,
    DateTime? since,
    int? limit,
  }) {
    if (!_initialized || _storage == null) return [];

    try {
      List<dynamic> logs = _storage!.read(_logStorageKey) ?? [];
      List<Map<String, dynamic>> filteredLogs = logs
          .cast<Map<String, dynamic>>();

      // Filter by level
      if (minLevel != null) {
        filteredLogs = filteredLogs.where((log) {
          final String levelName = log['level'] ?? '';
          final LogLevel? logLevel = LogLevel.values
              .where((l) => l.name == levelName)
              .firstOrNull;
          return logLevel != null && logLevel.value >= minLevel.value;
        }).toList();
      }

      // Filter by tag
      if (tag != null) {
        filteredLogs = filteredLogs.where((log) {
          return log['tag']?.toString().contains(tag) ?? false;
        }).toList();
      }

      // Filter by date
      if (since != null) {
        filteredLogs = filteredLogs.where((log) {
          try {
            final DateTime logTime = DateTime.parse(log['timestamp']);
            return logTime.isAfter(since);
          } catch (e) {
            return false;
          }
        }).toList();
      }

      // Apply limit
      if (limit != null && filteredLogs.length > limit) {
        filteredLogs = filteredLogs.sublist(filteredLogs.length - limit);
      }

      return filteredLogs;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Failed to get logs: $e', name: _tag);
      }
      return [];
    }
  }

  /// Get logs as formatted string
  static String getLogsAsString({
    LogLevel? minLevel,
    String? tag,
    DateTime? since,
    int? limit,
  }) {
    final List<Map<String, dynamic>> logs = getLogs(
      minLevel: minLevel,
      tag: tag,
      since: since,
      limit: limit,
    );

    if (logs.isEmpty) {
      return 'No logs found';
    }

    final StringBuffer buffer = StringBuffer();

    for (final log in logs) {
      final String timestamp = log['timestamp'] ?? '';
      final String level = log['level'] ?? '';
      final String logTag = log['tag'] ?? '';
      final String message = log['message'] ?? '';
      final String? error = log['error'];
      final String? stackTrace = log['stackTrace'];
      final String? data = log['data'];

      buffer.writeln('[$timestamp] $level [$logTag] $message');

      if (error != null) {
        buffer.writeln('  Error: $error');
      }

      if (data != null) {
        buffer.writeln('  Data: $data');
      }

      if (stackTrace != null) {
        buffer.writeln('  Stack Trace:');
        buffer.writeln('    ${stackTrace.replaceAll('\n', '\n    ')}');
      }

      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Clear all stored logs
  static void clearLogs() {
    if (!_initialized || _storage == null) return;

    try {
      _storage!.remove(_logStorageKey);
      if (kDebugMode) {
        developer.log('Logs cleared', name: _tag);
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Failed to clear logs: $e', name: _tag);
      }
    }
  }

  /// Export logs to file (for debugging purposes)
  static Future<String?> exportLogs({
    LogLevel? minLevel,
    String? tag,
    DateTime? since,
  }) async {
    try {
      final String logsContent = getLogsAsString(
        minLevel: minLevel,
        tag: tag,
        since: since,
      );

      if (kIsWeb) {
        // For web, we can't write files directly
        // Return the content for the caller to handle
        return logsContent;
      }

      // For mobile platforms, write to a temporary file
      final Directory tempDir = Directory.systemTemp;
      final String fileName =
          'app_logs_${DateTime.now().millisecondsSinceEpoch}.txt';
      final File logFile = File('${tempDir.path}/$fileName');

      await logFile.writeAsString(logsContent);

      if (kDebugMode) {
        developer.log('Logs exported to: ${logFile.path}', name: _tag);
      }

      return logFile.path;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Failed to export logs: $e', name: _tag);
      }
      return null;
    }
  }

  /// Get log statistics
  static Map<String, int> getLogStatistics() {
    final List<Map<String, dynamic>> logs = getLogs();
    final Map<String, int> stats = {};

    for (final LogLevel level in LogLevel.values) {
      stats[level.name] = 0;
    }

    for (final log in logs) {
      final String level = log['level'] ?? '';
      if (stats.containsKey(level)) {
        stats[level] = (stats[level] ?? 0) + 1;
      }
    }

    return stats;
  }

  /// Log API request
  static void logApiRequest(
    String method,
    String url, {
    Map<String, dynamic>? headers,
    dynamic body,
    String? tag,
  }) {
    final Map<String, dynamic> requestData = {
      'method': method,
      'url': url,
      if (headers != null) 'headers': headers,
      if (body != null) 'body': body,
    };

    debug('API Request: $method $url', tag: tag ?? 'API', data: requestData);
  }

  /// Log API response
  static void logApiResponse(
    String method,
    String url,
    int statusCode, {
    dynamic body,
    Duration? duration,
    String? tag,
  }) {
    final Map<String, dynamic> responseData = {
      'method': method,
      'url': url,
      'statusCode': statusCode,
      if (body != null) 'body': body,
      if (duration != null) 'duration': '${duration.inMilliseconds}ms',
    };

    final LogLevel level = statusCode >= 400 ? LogLevel.error : LogLevel.debug;

    _log(
      level,
      'API Response: $method $url - $statusCode',
      tag: tag ?? 'API',
      data: responseData,
    );
  }

  /// Log user action
  static void logUserAction(
    String action, {
    Map<String, dynamic>? context,
    String? tag,
  }) {
    info('User Action: $action', tag: tag ?? 'USER', data: context);
  }

  /// Check if logging is initialized
  static bool get isInitialized => _initialized;
}
