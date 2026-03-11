import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import 'storage_service.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

class ApiClient {
  final Dio _dio;
  final StorageService _storage;

  ApiClient({required Dio dio, required StorageService storage})
    : _dio = dio,
      _storage = storage {
    _dio.options = BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      sendTimeout: const Duration(milliseconds: AppConstants.sendTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _storage.clearToken();
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      // Debug: Print POST request
      print('=== API POST REQUEST ===');
      print('Path: $path');
      print('Data: $data');
      print('========================');

      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      // Debug: Print error
      print('=== API POST ERROR ===');
      print('Error: $e');
      print('Response: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');
      print('======================');
      throw _handleError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  AppException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          message: 'Connection timeout. Please check your internet connection.',
          originalError: error,
        );
      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'No internet connection. Please check your network.',
          originalError: error,
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        String message = 'Something went wrong';

        if (data is Map<String, dynamic>) {
          message = data['message'] ?? data['error'] ?? message;
        }

        if (statusCode == 401) {
          return AuthException(
            message: message,
            statusCode: statusCode,
            originalError: error,
          );
        } else if (statusCode == 404) {
          return NotFoundException(
            message: message,
            statusCode: statusCode,
            originalError: error,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return ServerException(
            message: message,
            statusCode: statusCode,
            originalError: error,
          );
        } else if (statusCode == 422 && data is Map<String, dynamic>) {
          return ValidationException(
            message: message,
            fieldErrors: _parseFieldErrors(data),
            statusCode: statusCode,
            originalError: error,
          );
        }
        return AppException(
          message: message,
          statusCode: statusCode,
          originalError: error,
        );
      case DioExceptionType.cancel:
        return AppException(message: 'Request cancelled', originalError: error);
      default:
        return AppException(
          message: 'Something went wrong',
          originalError: error,
        );
    }
  }

  Map<String, String>? _parseFieldErrors(Map<String, dynamic> data) {
    if (data.containsKey('errors') && data['errors'] is Map) {
      final errors = data['errors'] as Map<String, dynamic>;
      return errors.map((key, value) {
        if (value is List && value.isNotEmpty) {
          return MapEntry(key, value.first.toString());
        }
        return MapEntry(key, value.toString());
      });
    }
    return null;
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageServiceProvider);
  return ApiClient(dio: dio, storage: storage);
});
