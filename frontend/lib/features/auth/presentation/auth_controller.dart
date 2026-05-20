import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository_impl.dart';
import '../domain/auth_repository.dart';
import 'auth_state.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.read(authRepositoryProvider));
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AuthInitial()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final token = await _repository.getAccessToken();
    if (token != null) {
      try {
        final user = await _repository.getMe();
        state = Authenticated(user);
      } catch (e) {
        state = const Unauthenticated();
      }
    } else {
      state = const Unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      await _repository.login(email, password);
      final user = await _repository.getMe();
      state = Authenticated(user);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      state = AuthError(message);
      // Revert to Unauthenticated after showing error to allow retry
      await Future.delayed(const Duration(milliseconds: 100));
      if (state is AuthError) {
        state = const Unauthenticated();
      }
    }
  }

  Future<void> register(String email, String password, {String? fullName}) async {
    state = const AuthLoading();
    try {
      await _repository.register(email, password, fullName: fullName);
      await login(email, password);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      state = AuthError(message);
      await Future.delayed(const Duration(milliseconds: 100));
      if (state is AuthError) {
        state = const Unauthenticated();
      }
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const Unauthenticated();
  }
}
