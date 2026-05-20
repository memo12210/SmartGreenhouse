import 'user.dart';

abstract class AuthRepository {
  Future<void> login(String email, String password);
  Future<User> register(String email, String password, {String? fullName});
  Future<User> getMe();
  Future<void> logout();
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> refreshTokens();
}
