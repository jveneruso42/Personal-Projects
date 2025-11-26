/// Dio HTTP client service with authentication interceptor.
///
/// Provides a configured Dio instance with:
/// - Automatic Bearer token injection from auth state
/// - Request/response logging in debug mode
/// - Error handling and transformation
/// - Base URL configuration

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

/// Provider for Dio instance with auth interceptor
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add auth interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Get auth token from provider
        final authState = ref.read(authProvider);
        if (authState.accessToken != null) {
          options.headers['Authorization'] = 'Bearer ${authState.accessToken}';
        }

        if (kDebugMode) {
          print('🌐 REQUEST[${options.method}] => ${options.uri}');
          print('Headers: ${options.headers}');
        }

        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print(
            '✅ RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}',
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          print(
            '❌ ERROR[${error.response?.statusCode}] => ${error.requestOptions.uri}',
          );
          print('Message: ${error.message}');
        }

        // Handle 401 unauthorized - could trigger re-authentication
        if (error.response?.statusCode == 401) {
          // Token expired or invalid
          // Could emit event to logout user or refresh token
        }

        return handler.next(error);
      },
    ),
  );

  // Add logging interceptor in debug mode
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        requestHeader: false,
        responseHeader: false,
      ),
    );
  }

  return dio;
});
