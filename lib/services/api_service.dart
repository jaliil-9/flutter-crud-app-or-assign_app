import 'package:dio/dio.dart';
import '../models/api_object.dart';
import 'logging_service.dart';
import 'retry_service.dart';

/// Service class for handling REST API operations with the restful-api.dev API
class ApiService {
  late final Dio _dio;
  // ignore: unused_field
  final RetryService? _retryService;
  static const String baseUrl = 'https://api.restful-api.dev/objects';

  ApiService({Dio? dio, RetryService? retryService})
    : _retryService = retryService {
    _dio =
        dio ??
        Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

    // Add interceptors for logging and error handling (only if not injected)
    if (dio == null) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true, error: true),
      );
    }
  }

  /// Fetch all objects from the API with optional pagination support
  /// Returns a list of ApiObject instances
  Future<List<ApiObject>> getObjects({int? limit, int? offset}) async {
    return await RetryService.executeWithRetry<List<ApiObject>>(
          () async {
            final Map<String, dynamic> queryParams = {};
            if (limit != null) queryParams['limit'] = limit;
            if (offset != null) queryParams['offset'] = offset;

            LoggingService.logApiRequest('GET', baseUrl, body: queryParams);
            final DateTime startTime = DateTime.now();

            try {
              final response = await _dio.get('', queryParameters: queryParams);
              final Duration duration = DateTime.now().difference(startTime);

              LoggingService.logApiResponse(
                'GET',
                baseUrl,
                response.statusCode ?? 0,
                duration: duration,
              );

              if (response.statusCode == 200) {
                final List<dynamic> data = response.data as List<dynamic>;
                final List<ApiObject> objects = data
                    .map(
                      (json) =>
                          ApiObject.fromJson(json as Map<String, dynamic>),
                    )
                    .toList();

                LoggingService.debug('Fetched ${objects.length} objects');
                return objects;
              } else {
                throw ApiException(
                  'Failed to fetch objects',
                  response.statusCode,
                );
              }
            } on DioException catch (e) {
              final Duration duration = DateTime.now().difference(startTime);
              LoggingService.logApiResponse(
                'GET',
                baseUrl,
                e.response?.statusCode ?? 0,
                duration: duration,
              );
              throw _handleDioException(e);
            }
          },
          operationName: 'Fetch Objects',
          maxRetries: 3,
        ) ??
        [];
  }

  /// Fetch a single object by its ID
  /// Returns an ApiObject instance or throws an exception if not found
  Future<ApiObject> getObjectById(String id) async {
    return await RetryService.executeWithRetry<ApiObject>(
          () async {
            final String url = '$baseUrl/$id';
            LoggingService.logApiRequest('GET', url);
            final DateTime startTime = DateTime.now();

            try {
              final response = await _dio.get('/$id');
              final Duration duration = DateTime.now().difference(startTime);

              LoggingService.logApiResponse(
                'GET',
                url,
                response.statusCode ?? 0,
                duration: duration,
              );

              if (response.statusCode == 200) {
                final ApiObject object = ApiObject.fromJson(
                  response.data as Map<String, dynamic>,
                );
                LoggingService.debug('Fetched object with ID: $id');
                return object;
              } else if (response.statusCode == 404) {
                throw ApiException('Object with ID $id not found', 404);
              } else {
                throw ApiException(
                  'Failed to fetch object',
                  response.statusCode,
                );
              }
            } on DioException catch (e) {
              final Duration duration = DateTime.now().difference(startTime);
              LoggingService.logApiResponse(
                'GET',
                url,
                e.response?.statusCode ?? 0,
                duration: duration,
              );
              throw _handleDioException(e);
            }
          },
          operationName: 'Fetch Object by ID',
          maxRetries: 3,
        ) ??
        (throw ApiException('Failed to fetch object after retries'));
  }

  /// Create a new object
  /// Returns the created ApiObject with assigned ID
  Future<ApiObject> createObject(ApiObject object) async {
    return await RetryService.executeWithRetry<ApiObject>(
          () async {
            final Map<String, dynamic> requestData = object.toJson();
            LoggingService.logApiRequest('POST', baseUrl, body: requestData);
            final DateTime startTime = DateTime.now();

            try {
              final response = await _dio.post('', data: requestData);
              final Duration duration = DateTime.now().difference(startTime);

              LoggingService.logApiResponse(
                'POST',
                baseUrl,
                response.statusCode ?? 0,
                duration: duration,
              );

              if (response.statusCode == 200 || response.statusCode == 201) {
                final ApiObject createdObject = ApiObject.fromJson(
                  response.data as Map<String, dynamic>,
                );
                LoggingService.info(
                  'Created object with ID: ${createdObject.id}',
                );
                return createdObject;
              } else {
                throw ApiException(
                  'Failed to create object',
                  response.statusCode,
                );
              }
            } on DioException catch (e) {
              final Duration duration = DateTime.now().difference(startTime);
              LoggingService.logApiResponse(
                'POST',
                baseUrl,
                e.response?.statusCode ?? 0,
                duration: duration,
              );
              throw _handleDioException(e);
            }
          },
          operationName: 'Create Object',
          maxRetries: 2, // Fewer retries for create operations
        ) ??
        (throw ApiException('Failed to create object after retries'));
  }

  /// Update an existing object by ID
  /// Returns the updated ApiObject
  Future<ApiObject> updateObject(String id, ApiObject object) async {
    return await RetryService.executeWithRetry<ApiObject>(
          () async {
            final String url = '$baseUrl/$id';
            final Map<String, dynamic> requestData = object.toJson();
            LoggingService.logApiRequest('PUT', url, body: requestData);
            final DateTime startTime = DateTime.now();

            try {
              final response = await _dio.put('/$id', data: requestData);
              final Duration duration = DateTime.now().difference(startTime);

              LoggingService.logApiResponse(
                'PUT',
                url,
                response.statusCode ?? 0,
                duration: duration,
              );

              if (response.statusCode == 200) {
                final ApiObject updatedObject = ApiObject.fromJson(
                  response.data as Map<String, dynamic>,
                );
                LoggingService.info('Updated object with ID: $id');
                return updatedObject;
              } else if (response.statusCode == 404) {
                throw ApiException('Object with ID $id not found', 404);
              } else {
                throw ApiException(
                  'Failed to update object',
                  response.statusCode,
                );
              }
            } on DioException catch (e) {
              final Duration duration = DateTime.now().difference(startTime);
              LoggingService.logApiResponse(
                'PUT',
                url,
                e.response?.statusCode ?? 0,
                duration: duration,
              );
              throw _handleDioException(e);
            }
          },
          operationName: 'Update Object',
          maxRetries: 2, // Fewer retries for update operations
        ) ??
        (throw ApiException('Failed to update object after retries'));
  }

  /// Delete an object by ID
  /// Returns true if deletion was successful
  Future<bool> deleteObject(String id) async {
    return await RetryService.executeWithRetry<bool>(
          () async {
            final String url = '$baseUrl/$id';
            LoggingService.logApiRequest('DELETE', url);
            final DateTime startTime = DateTime.now();

            try {
              final response = await _dio.delete('/$id');
              final Duration duration = DateTime.now().difference(startTime);

              LoggingService.logApiResponse(
                'DELETE',
                url,
                response.statusCode ?? 0,
                duration: duration,
              );

              if (response.statusCode == 200) {
                LoggingService.info('Deleted object with ID: $id');
                return true;
              } else if (response.statusCode == 404) {
                throw ApiException('Object with ID $id not found', 404);
              } else {
                throw ApiException(
                  'Failed to delete object',
                  response.statusCode,
                );
              }
            } on DioException catch (e) {
              final Duration duration = DateTime.now().difference(startTime);
              LoggingService.logApiResponse(
                'DELETE',
                url,
                e.response?.statusCode ?? 0,
                duration: duration,
              );
              throw _handleDioException(e);
            }
          },
          operationName: 'Delete Object',
          maxRetries: 2, // Fewer retries for delete operations
        ) ??
        false;
  }

  /// Handle DioException and convert to ApiException
  ApiException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return ApiException(
          'Connection timeout. Please check your internet connection.',
          408,
        );
      case DioExceptionType.sendTimeout:
        return ApiException('Request timeout. Please try again.', 408);
      case DioExceptionType.receiveTimeout:
        return ApiException('Response timeout. Please try again.', 408);
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        final message = e.response?.data?['message'] ?? 'Server error occurred';
        return ApiException(message, statusCode);
      case DioExceptionType.cancel:
        return ApiException('Request was cancelled', 0);
      case DioExceptionType.connectionError:
        return ApiException(
          'No internet connection. Please check your network.',
          0,
        );
      case DioExceptionType.badCertificate:
        return ApiException('SSL certificate error', 0);
      case DioExceptionType.unknown:
        return ApiException('Network error occurred: ${e.message}', 0);
    }
  }
}

/// Custom exception class for API-related errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}
