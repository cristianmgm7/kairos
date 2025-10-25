import 'package:blueprint_app/core/errors/exceptions.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          message: 'Connection timeout. Please check your internet connection.',
        );

      case DioExceptionType.badResponse:
        final data = error.response?.data;
        final message =
            data is Map<String, dynamic> ? data['message'] as String? : null;
        return ServerException(
          message: message ?? 'Server error occurred',
          statusCode: error.response?.statusCode,
        );

      case DioExceptionType.cancel:
        return ServerException(
          message: 'Request was cancelled',
          statusCode: 0,
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'No internet connection. Please check your network.',
        );

      case DioExceptionType.unknown:
      case DioExceptionType.badCertificate:
        return ServerException(
          message: error.message ?? 'An unknown error occurred',
          statusCode: error.response?.statusCode,
        );
    }
  }
}
