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
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final isAuthRequest =
            options.path.contains('/auth/login') ||
            options.path.contains('/auth/register') ||
            options.path.contains('/auth/refresh');

        if (!isAuthRequest) {
          final token = await ref
              .read(secureStorageProvider)
              .read(key: 'access_token');

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }

        // Debug logs
        // ignore: avoid_print
        print('REQUEST[${options.method}] => ${options.uri}');
        // ignore: avoid_print
        print('HEADERS => ${options.headers}');
        // ignore: avoid_print
        print('DATA => ${options.data}');

        return handler.next(options);
      },
      onResponse: (response, handler) {
        // ignore: avoid_print
        print('RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}');
        // ignore: avoid_print
        print('RESPONSE DATA => ${response.data}');
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        // ignore: avoid_print
        print('DIO ERROR => ${e.requestOptions.uri}');
        // ignore: avoid_print
        print('DIO ERROR MESSAGE => ${e.message}');
        // ignore: avoid_print
        print('DIO ERROR RESPONSE => ${e.response?.data}');

        final isRefreshRequest = e.requestOptions.path.contains('/auth/refresh');
        final isLoginRequest = e.requestOptions.path.contains('/auth/login');

        if (e.response?.statusCode == 401 && !isRefreshRequest && !isLoginRequest) {
          try {
            final refreshToken = await ref
                .read(secureStorageProvider)
                .read(key: 'refresh_token');

            if (refreshToken == null || refreshToken.isEmpty) {
              throw Exception("No refresh token");
            }

            final refreshDio = Dio(
              BaseOptions(
                baseUrl: ApiEndpoints.baseUrl,
                headers: {
                  'Accept': 'application/json',
                },
              ),
            );

            final refreshResponse = await refreshDio.post(
              ApiEndpoints.refresh,
              queryParameters: {'refresh_token': refreshToken},
            );

            await ref.read(secureStorageProvider).write(
                  key: 'access_token',
                  value: refreshResponse.data['access_token'],
                );
            await ref.read(secureStorageProvider).write(
                  key: 'refresh_token',
                  value: refreshResponse.data['refresh_token'],
                );

            final newToken = await ref
                .read(secureStorageProvider)
                .read(key: 'access_token');

            final options = e.requestOptions;
            options.headers['Authorization'] = 'Bearer $newToken';

            final retryResponse = await dio.fetch(options);
            return handler.resolve(retryResponse);
          } catch (_) {
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