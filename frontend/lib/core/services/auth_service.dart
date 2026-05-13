import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/auth_models.dart';

class AuthService {
  final String _baseUrl = ApiConfig.baseUrl;

  Future<AuthUser> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return AuthUser.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body)['detail'] ?? 'Registration failed';
      throw Exception(error);
    }
  }

  Future<LoginResponse> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login/access-token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      return LoginResponse.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body)['detail'] ?? 'Login failed';
      throw Exception(error);
    }
  }

  Future<AuthUser> getMe(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return AuthUser.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get user profile');
    }
  }
}
