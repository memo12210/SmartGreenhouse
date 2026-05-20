import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_endpoints.dart';
import '../storage/secure_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await ref.read(secureStorageProvider).read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 && !e.requestOptions.path.contains('/auth/refresh')) {
          try {
            // Refresh tokens logic
            final refreshToken = await ref.read(secureStorageProvider).read(key: 'refresh_token');
            if (refreshToken == null) throw Exception("No refresh token");

            final refreshResponse = await Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl)).post(
              ApiEndpoints.refresh,
              queryParameters: {'refresh_token': refreshToken},
            );

            await ref.read(secureStorageProvider).write(key: 'access_token', value: refreshResponse.data['access_token']);
            await ref.read(secureStorageProvider).write(key: 'refresh_token', value: refreshResponse.data['refresh_token']);
            
            // Re-fetch the new token and retry the original request
            final newToken = await ref.read(secureStorageProvider).read(key: 'access_token');
            final options = e.requestOptions;
            options.headers['Authorization'] = 'Bearer $newToken';
            
            final retryResponse = await dio.fetch(options);
            return handler.resolve(retryResponse);
          } catch (refreshError) {
            // Refresh failed, logout user logic (clear tokens)
            await ref.read(secureStorageProvider).delete(key: 'access_token');
            await ref.read(secureStorageProvider).delete(key: 'refresh_token');
          }
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
});
