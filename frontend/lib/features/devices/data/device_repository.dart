import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/device.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(ref.read(dioProvider));
});

class DeviceRepository {
  final Dio _dio;

  DeviceRepository(this._dio);

  Future<List<Device>> getDevices(String greenhouseId) async {
    final response = await _dio.get(ApiEndpoints.greenhouseDevices(greenhouseId));
    return (response.data as List).map((e) => Device.fromJson(e)).toList();
  }

  Future<Device> claimDevice({
    required String macAddress,
    required String secret,
    required String greenhouseId,
    String? name,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.claimDevice(macAddress),
      data: {
        'secret': secret,
        'greenhouse_id': greenhouseId,
        'name': name,
      },
    );
    return Device.fromJson(response.data);
  }
}
