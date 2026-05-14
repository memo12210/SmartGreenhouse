import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:greenhouse_app/core/constants.dart';
import 'package:greenhouse_app/core/models/auth_models.dart';
import 'package:greenhouse_app/core/utils/api_utils.dart';

class AuthService {
  final String _baseUrl = ApiConfig.baseUrl;

  Future<AuthUser> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return AuthUser.fromJson(json.decode(response.body));
      } else {
        throw Exception(ApiUtils.handleResponseError(response));
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(ApiUtils.handleException(e));
    }
  }

  Future<LoginResponse> login(String email, String password) async {
    try {
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
        throw Exception(ApiUtils.handleResponseError(response));
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(ApiUtils.handleException(e));
    }
  }

  Future<AuthUser> getMe(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return AuthUser.fromJson(json.decode(response.body));
      } else {
        throw Exception(ApiUtils.handleResponseError(response));
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(ApiUtils.handleException(e));
    }
  }
}
