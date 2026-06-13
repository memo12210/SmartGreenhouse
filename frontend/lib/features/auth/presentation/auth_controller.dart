import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository_impl.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';
import 'auth_state.dart';

/// Holds the last transient auth error message (e.g. a failed login), kept
/// separate from [AuthState] so the auth *status* state machine never has to
/// carry/clear an error. UI listens to this and consumes (nulls) it after
/// showing it.
final authErrorProvider = StateProvider<String?>((ref) => null);

// Explicit type annotation to break the top-level inference cycle introduced
// by the network layer (dioProvider) propagating logout through this provider.
final StateNotifierProvider<AuthController, AuthState> authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.read(authRepositoryProvider),
    onAuthError: (message) =>
        ref.read(authErrorProvider.notifier).state = message,
  );
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  // Named `onAuthError` (not `onError`) to avoid clashing with
  // StateNotifier.onError.
  final void Function(String message)? onAuthError;

  AuthController(this._repository, {this.onAuthError})
      : super(const AuthInitial()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final token = await _repository.getAccessToken();
    if (token == null) {
      state = const Unauthenticated();
      return;
    }

    try {
      final user = await _fetchMeWithRetry();
      state = Authenticated(user);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        // The interceptor already tried to refresh; reaching here means the
        // session is genuinely invalid. Clear the stored tokens.
        await _repository.logout();
      }
      // For transient/network/5xx failures we keep the tokens so the session
      // can be restored on the next launch with connectivity.
      state = const Unauthenticated();
    } catch (_) {
      state = const Unauthenticated();
    }
  }

  /// Calls `getMe`, retrying a few times on transient (non-auth) errors so a
  /// brief network blip at startup doesn't drop the user to the login screen.
  Future<User> _fetchMeWithRetry() async {
    const maxAttempts = 3;
    DioException? lastError;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await _repository.getMe();
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        // Don't retry genuine auth failures.
        if (status == 401 || status == 403) rethrow;
        lastError = e;
        if (attempt < maxAttempts - 1) {
          await Future.delayed(Duration(milliseconds: 400 * (attempt + 1)));
        }
      }
    }

    throw lastError!;
  }

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      await _repository.login(email, password);
      final user = await _repository.getMe();
      state = Authenticated(user);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      // Status returns to Unauthenticated (re-enables the form); the error is
      // surfaced via the separate error channel for the UI to display.
      state = const Unauthenticated();
      onAuthError?.call(message);
    }
  }

  Future<void> register(String email, String password, {String? fullName}) async {
    state = const AuthLoading();
    try {
      await _repository.register(email, password, fullName: fullName);
      await login(email, password);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      state = const Unauthenticated();
      onAuthError?.call(message);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const Unauthenticated();
  }

  /// Invoked by the network layer when a token refresh fails (the session can
  /// no longer be renewed). Clears credentials and routes the app to login.
  void sessionExpired() {
    if (state is Unauthenticated) return;
    // Fire-and-forget token clearing; the state change is what drives the UI.
    _repository.logout();
    state = const Unauthenticated();
  }
}
