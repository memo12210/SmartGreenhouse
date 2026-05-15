import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:greenhouse_app/core/constants.dart';
import 'package:greenhouse_app/core/models.dart';

class TelemetryService {
  Future<Telemetry> getLatestTelemetry(String token, String deviceId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/devices/$deviceId/telemetry/latest'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Telemetry.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('No telemetry data available for this device');
    } else {
      throw Exception('Failed to load telemetry data');
    }
  }
}
