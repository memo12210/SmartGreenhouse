import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/device_repository.dart';
import '../domain/device.dart';

final devicesProvider =
    AsyncNotifierProviderFamily<DevicesController, List<Device>, String>(() {
  return DevicesController();
});

class DevicesController extends FamilyAsyncNotifier<List<Device>, String> {
  @override
  Future<List<Device>> build(String greenhouseId) async {
    return _fetch(greenhouseId);
  }

  Future<List<Device>> _fetch(String greenhouseId) async {
    return ref.read(deviceRepositoryProvider).getDevices(greenhouseId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }

  Future<void> registerDevice({
    required String name,
    required String serialNumber,
    required String deviceType,
    required String status,
    required String firmwareVersion,
    required String greenhouseId,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref.read(deviceRepositoryProvider).registerDevice(
            name: name,
            serialNumber: serialNumber,
            deviceType: deviceType,
            status: status,
            firmwareVersion: firmwareVersion,
            greenhouseId: greenhouseId,
          );

      return _fetch(greenhouseId);
    });
  }

  Future<void> deleteDevice({
    required String deviceId,
    required String greenhouseId,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref.read(deviceRepositoryProvider).deleteDevice(deviceId);
      return _fetch(greenhouseId);
    });
  }
}