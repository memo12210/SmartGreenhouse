import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:greenhouse_app/core/constants.dart';
import 'package:greenhouse_app/core/models.dart';
import 'package:greenhouse_app/core/utils/api_utils.dart';

class GreenhouseService {
  final String _baseUrl = ApiConfig.baseUrl;

  Future<List<Greenhouse>> getGreenhouses(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/greenhouses/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Greenhouse.fromJson(item)).toList();
      } else {
        throw Exception(ApiUtils.handleResponseError(response));
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(ApiUtils.handleException(e));
    }
  }

  Future<Greenhouse> createGreenhouse(String token, String name) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/greenhouses/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'name': name}),
      );

      if (response.statusCode == 200) {
        return Greenhouse.fromJson(json.decode(response.body));
      } else {
        throw Exception(ApiUtils.handleResponseError(response));
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(ApiUtils.handleException(e));
    }
  }

  Future<Greenhouse> updateGreenhouse(String token, String id, String name) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/greenhouses/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'name': name}),
      );

      if (response.statusCode == 200) {
        return Greenhouse.fromJson(json.decode(response.body));
      } else {
        throw Exception(ApiUtils.handleResponseError(response));
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(ApiUtils.handleException(e));
    }
  }

  Future<void> deleteGreenhouse(String token, String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/greenhouses/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(ApiUtils.handleResponseError(response));
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(ApiUtils.handleException(e));
    }
  }
}
