import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/telemetry.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';

final telemetryRepositoryProvider = Provider<TelemetryRepository>((ref) {
  return TelemetryRepository(ref.read(dioProvider));
});

class TelemetryRepository {
  final Dio _dio;

  TelemetryRepository(this._dio);

  Future<Telemetry?> getLatestTelemetry(String deviceId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.telemetry(deviceId),
        queryParameters: {'limit': 1},
      );
      final List data = response.data;
      if (data.isEmpty) return null;
      return Telemetry.fromJson(data.first);
    } catch (e) {
      return null;
    }
  }

  Future<List<Telemetry>> getTelemetryHistory(String deviceId) async {
    final response = await _dio.get(
      ApiEndpoints.telemetry(deviceId),
      queryParameters: {'limit': 100},
    );
    return (response.data as List).map((e) => Telemetry.fromJson(e)).toList();
  }
}
