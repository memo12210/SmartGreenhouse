import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/device.dart';
import '../data/device_repository.dart';

final devicesProvider = AsyncNotifierProviderFamily<DevicesController, List<Device>, String>(() {
  return DevicesController();
});

class DevicesController extends FamilyAsyncNotifier<List<Device>, String> {
  @override
  Future<List<Device>> build(String arg) async {
    return _fetch(arg);
  }

  Future<List<Device>> _fetch(String greenhouseId) async {
    return ref.read(deviceRepositoryProvider).getDevices(greenhouseId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }

  Future<void> claimDevice({
    required String macAddress,
    required String secret,
    required String greenhouseId,
    String? name,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(deviceRepositoryProvider).claimDevice(
        macAddress: macAddress,
        secret: secret,
        greenhouseId: greenhouseId,
        name: name,
      );
      return _fetch(arg);
    });
  }
}
