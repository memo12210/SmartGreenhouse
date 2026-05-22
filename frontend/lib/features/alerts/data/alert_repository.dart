import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/app_alert.dart';

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  return AlertRepository(ref.read(dioProvider));
});

class AlertRepository {
  final Dio _dio;

  AlertRepository(this._dio);

  Future<List<AppAlert>> getGreenhouseAlerts(String greenhouseId) async {
    final response = await _dio.get(
      ApiEndpoints.greenhouseAlerts(greenhouseId),
    );

    return (response.data as List)
        .map((item) => AppAlert.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AppAlert> acknowledgeAlert(String alertId) async {
    final response = await _dio.post(
      ApiEndpoints.acknowledgeAlert(alertId),
    );

    return AppAlert.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> dismissAlert(String alertId) async {
    await _dio.delete(
      ApiEndpoints.dismissAlert(alertId),
    );
  }
}