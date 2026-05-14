import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:greenhouse_app/core/constants.dart';
import 'package:greenhouse_app/core/models.dart';
import 'package:greenhouse_app/core/utils/api_utils.dart';

class DeviceService {
  final String _baseUrl = ApiConfig.baseUrl;

  Future<List<Device>> getDevices(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/devices/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Device.fromJson(item)).toList();
      } else {
        throw Exception(ApiUtils.handleResponseError(response));
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(ApiUtils.handleException(e));
    }
  }

  Future<Device> claimDevice({
    required String token,
    required String macAddress,
    required String secret,
    required String greenhouseId,
    String? name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/devices/claim'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'mac_address': macAddress,
          'secret': secret,
          'greenhouse_id': greenhouseId,
          'name': name,
        }),
      );

      if (response.statusCode == 200) {
        return Device.fromJson(json.decode(response.body));
      } else {
        throw Exception(ApiUtils.handleResponseError(response));
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(ApiUtils.handleException(e));
    }
  }

  Future<Device> updateDevice({
    required String token,
    required String id,
    String? name,
    String? macAddress,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/devices/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          if (name != null) 'name': name,
          if (macAddress != null) 'mac_address': macAddress,
        }),
      );

      if (response.statusCode == 200) {
        return Device.fromJson(json.decode(response.body));
      } else {
        throw Exception(ApiUtils.handleResponseError(response));
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(ApiUtils.handleException(e));
    }
  }

  Future<void> deleteDevice(String token, String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/devices/$id'),
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
