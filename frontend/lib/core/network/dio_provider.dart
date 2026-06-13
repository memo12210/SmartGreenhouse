import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_endpoints.dart';
import '../storage/secure_storage.dart';
import '../../features/auth/presentation/auth_controller.dart';

const _accessTokenKey = 'access_token';
const _refreshTokenKey = 'refresh_token';

// Explicit type annotation: dioProvider participates in a provider reference
// cycle (dio -> authController -> authRepository -> dio). The cycle is only
// followed lazily at runtime inside onError, but the analyzer still needs an
// explicit type here to avoid a top-level inference cycle.
final Provider<Dio> dioProvider = Provider<Dio>((ref) {
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

  // Shared in-flight refresh. Concurrent 401s await the same refresh instead
  // of each hitting /auth/refresh (which would rotate single-use tokens and
  // fail every retry but the first).
  Future<bool>? refreshFuture;

  Future<bool> performRefresh() async {
    final storage = ref.read(secureStorageProvider);
    final refreshToken = await storage.read(key: _refreshTokenKey);

    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      // A bare Dio (no interceptors) so a 401 here can't recurse.
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          headers: {'Accept': 'application/json'},
        ),
      );

      final response = await refreshDio.post(
        ApiEndpoints.refresh,
        queryParameters: {'refresh_token': refreshToken},
      );

      final newAccess = response.data['access_token'];
      final newRefresh = response.data['refresh_token'];

      if (newAccess == null) return false;

      await storage.write(key: _accessTokenKey, value: newAccess);
      if (newRefresh != null) {
        await storage.write(key: _refreshTokenKey, value: newRefresh);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

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
              .read(key: _accessTokenKey);

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }

        if (kDebugMode) {
          debugPrint('REQUEST[${options.method}] => ${options.uri}');
        }

        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint(
            'RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}',
          );
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        if (kDebugMode) {
          debugPrint(
            'DIO ERROR[${e.response?.statusCode}] => ${e.requestOptions.uri} '
            '(${e.message})',
          );
        }

        final isRefreshRequest =
            e.requestOptions.path.contains('/auth/refresh');
        final isLoginRequest = e.requestOptions.path.contains('/auth/login');

        if (e.response?.statusCode == 401 &&
            !isRefreshRequest &&
            !isLoginRequest) {
          // Join (or start) the single shared refresh.
          final future = refreshFuture ??= performRefresh();
          final refreshed = await future;
          // Only the starter clears the slot, so a later 401 starts a fresh one.
          if (identical(refreshFuture, future)) {
            refreshFuture = null;
          }

          if (refreshed) {
            final newToken = await ref
                .read(secureStorageProvider)
                .read(key: _accessTokenKey);

            final options = e.requestOptions;
            options.headers['Authorization'] = 'Bearer $newToken';

            try {
              final retryResponse = await dio.fetch(options);
              return handler.resolve(retryResponse);
            } on DioException catch (retryError) {
              return handler.next(retryError);
            }
          }

          // Refresh failed: the session is no longer valid. Clear it and tell
          // the app so it routes back to login instead of showing errors.
          ref.read(authControllerProvider.notifier).sessionExpired();
        }

        return handler.next(e);
      },
    ),
  );

  return dio;
});
