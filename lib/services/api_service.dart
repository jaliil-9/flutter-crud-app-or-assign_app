import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/api_object.dart';

class ApiService {
  late final Dio _dio;
  static const String _baseUrl = 'https://api.restful-api.dev/objects';

  ApiService({Dio? dio}) {
    _dio =
        dio ??
        Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

    if (dio == null && kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  Future<T> _request<T>(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<List<ApiObject>> getObjects({int? limit, int? offset}) async {
    try {
      final response = await _request(
        () => _dio.get('', queryParameters: {'limit': limit, 'offset': offset}),
      );
      return (response as List)
          .map((json) => ApiObject.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to fetch objects: $e');
      }
      rethrow;
    }
  }

  Future<ApiObject> getObjectById(String id) async {
    try {
      final response = await _request(() => _dio.get('/$id'));
      return ApiObject.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to fetch object by ID: $e');
      }
      rethrow;
    }
  }

  Future<ApiObject> createObject(ApiObject object) async {
    try {
      final response = await _request(
        () => _dio.post('', data: object.toJson()),
      );
      return ApiObject.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to create object: $e');
      }
      rethrow;
    }
  }

  Future<ApiObject> updateObject(String id, ApiObject object) async {
    try {
      final response = await _request(
        () => _dio.put('/$id', data: object.toJson()),
      );
      return ApiObject.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to update object: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteObject(String id) async {
    try {
      await _request(() => _dio.delete('/$id'));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to delete object: $e');
      }
      rethrow;
    }
  }

  ApiException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('Request timeout. Please try again.', 408);
      case DioExceptionType.badResponse:
        return ApiException(
          e.response?.data?['message'] ?? 'Server error',
          e.response?.statusCode,
        );
      case DioExceptionType.cancel:
        return ApiException('Request was cancelled', 0);
      default:
        return ApiException('Network error occurred: ${e.message}', 0);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}
