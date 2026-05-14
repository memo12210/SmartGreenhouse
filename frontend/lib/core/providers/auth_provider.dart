import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:greenhouse_app/core/models/auth_models.dart';
import 'package:greenhouse_app/core/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final _storage = const FlutterSecureStorage();

  AuthUser? _user;
  String? _token;
  bool _isLoading = false;

  AuthUser? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    _token = await _storage.read(key: 'jwt_token');
    if (_token != null) {
      try {
        _user = await _authService.getMe(_token!);
      } catch (e) {
        // Token might be expired or invalid
        await logout();
      }
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);
      _token = response.accessToken;
      await _storage.write(key: 'jwt_token', value: _token);
      _user = await _authService.getMe(_token!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.register(email, password);
      // Automatically login after registration or just navigate to login
      await login(email, password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await _storage.delete(key: 'jwt_token');
    notifyListeners();
  }
}
