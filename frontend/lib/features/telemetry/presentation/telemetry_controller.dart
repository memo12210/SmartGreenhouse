import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/telemetry_repository.dart';
import '../domain/telemetry.dart';

final latestTelemetryProvider =
    StateNotifierProvider.family<TelemetryController, AsyncValue<Telemetry?>, String>(
  (ref, deviceId) {
    return TelemetryController(
      ref.read(telemetryRepositoryProvider),
      deviceId,
    );
  },
);

final telemetryHistoryProvider =
    FutureProvider.family<List<Telemetry>, String>((ref, deviceId) async {
  return ref.read(telemetryRepositoryProvider).getTelemetryHistory(deviceId);
});

class TelemetryController extends StateNotifier<AsyncValue<Telemetry?>> {
  final TelemetryRepository _repository;
  final String _deviceId;
  Timer? _timer;

  TelemetryController(
    this._repository,
    this._deviceId,
  ) : super(const AsyncLoading()) {
    fetchLatest();
    _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => fetchLatest(),
    );
  }

  Future<void> fetchLatest() async {
    final result = await AsyncValue.guard(
      () => _repository.getLatestTelemetry(_deviceId),
    );

    if (mounted) {
      state = result;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}