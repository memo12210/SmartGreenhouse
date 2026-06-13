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
    // Errors are intentionally NOT swallowed: a failed request must surface as
    // an error state (handled by AsyncValue.guard in the controller) so it is
    // distinguishable from a successful response that simply has no telemetry.
    final response = await _dio.get(
      ApiEndpoints.telemetry(deviceId),
      queryParameters: {'limit': 1},
    );
    final List data = response.data as List;
    if (data.isEmpty) return null;
    return Telemetry.fromJson(data.first);
  }

  Future<List<Telemetry>> getTelemetryHistory(String deviceId) async {
    final response = await _dio.get(
      ApiEndpoints.telemetry(deviceId),
      queryParameters: {'limit': 100},
    );
    return (response.data as List).map((e) => Telemetry.fromJson(e)).toList();
  }
}
