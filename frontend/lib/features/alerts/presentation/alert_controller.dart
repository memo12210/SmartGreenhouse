import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/alert_repository.dart';
import '../domain/app_alert.dart';

final alertsProvider =
    AsyncNotifierProviderFamily<AlertsController, List<AppAlert>, String>(() {
  return AlertsController();
});

class AlertsController extends FamilyAsyncNotifier<List<AppAlert>, String> {
  @override
  Future<List<AppAlert>> build(String greenhouseId) async {
    return _fetch(greenhouseId);
  }

  Future<List<AppAlert>> _fetch(String greenhouseId) async {
    return ref.read(alertRepositoryProvider).getGreenhouseAlerts(greenhouseId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }

  Future<void> acknowledgeAlert({
    required String alertId,
    required String greenhouseId,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref.read(alertRepositoryProvider).acknowledgeAlert(alertId);
      return _fetch(greenhouseId);
    });
  }

  Future<void> dismissAlert({
    required String alertId,
    required String greenhouseId,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref.read(alertRepositoryProvider).dismissAlert(alertId);
      return _fetch(greenhouseId);
    });
  }
}