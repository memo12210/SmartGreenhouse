import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/device.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(ref.read(dioProvider));
});

class DeviceRepository {
  final Dio _dio;

  DeviceRepository(this._dio);

  Future<List<Device>> getDevices(String greenhouseId) async {
    final response = await _dio.get(
      ApiEndpoints.greenhouseDevices(greenhouseId),
    );

    return (response.data as List)
        .map((item) => Device.fromJson(item))
        .toList();
  }

  Future<Device> registerDevice({
    required String name,
    required String serialNumber,
    required String deviceType,
    required String status,
    required String firmwareVersion,
    required String greenhouseId,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.devices,
      data: {
        'name': name,
        'serial_number': serialNumber,
        'device_type': deviceType,
        'status': status,
        'firmware_version': firmwareVersion,
        'greenhouse_id': greenhouseId,
      },
    );

    return Device.fromJson(response.data);
  }

  Future<void> deleteDevice(String deviceId) async {
    await _dio.delete('${ApiEndpoints.devices}$deviceId');
  }
}