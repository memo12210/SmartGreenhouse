import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/storage/secure_storage.dart';

// Explicit type annotation to break the top-level inference cycle:
// authRepository -> dio -> authController -> authRepository.
final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.read(dioProvider),
    ref.read(secureStorageProvider),
  );
});

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthRepositoryImpl(this._dio, this._storage);

  @override
  Future<void> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {
          'username': email,
          'password': password,
          'grant_type': 'password',
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      await _storage.write(
        key: 'access_token',
        value: response.data['access_token'],
      );
      await _storage.write(
        key: 'refresh_token',
        value: response.data['refresh_token'],
      );
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Login failed';
      throw Exception(message);
    }
  }

  @override
  Future<User> register(
    String email,
    String password, {
    String? fullName,
  }) async {
    try {
      final data = {
        'email': email,
        'password': password,
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
      };

      final response = await _dio.post(ApiEndpoints.register, data: data);

      return User.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Registration failed';
      throw Exception(message);
    }
  }

  @override
  Future<User> getMe() async {
    final response = await _dio.get(ApiEndpoints.me);
    return User.fromJson(response.data);
  }

  @override
  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  @override
  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  @override
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  @override
  Future<void> refreshTokens() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) throw Exception("No refresh token available");

    final response = await _dio.post(
      ApiEndpoints.refresh,
      queryParameters: {'refresh_token': refreshToken},
    );

    await _storage.write(
      key: 'access_token',
      value: response.data['access_token'],
    );
    await _storage.write(
      key: 'refresh_token',
      value: response.data['refresh_token'],
    );
  }
}
