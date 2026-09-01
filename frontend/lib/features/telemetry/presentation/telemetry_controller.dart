import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/telemetry_repository.dart';
import '../domain/telemetry.dart';

// autoDispose: when no widget is watching a device's telemetry (e.g. after
// navigating away from its detail page), the controller is disposed and its
// polling timer cancelled instead of leaking and polling forever.
final latestTelemetryProvider = StateNotifierProvider.autoDispose
    .family<TelemetryController, AsyncValue<Telemetry?>, String>(
  (ref, deviceId) {
    return TelemetryController(
      ref.read(telemetryRepositoryProvider),
      deviceId,
    );
  },
);

final telemetryHistoryProvider = FutureProvider.autoDispose
    .family<List<Telemetry>, String>((ref, deviceId) async {
  return ref.read(telemetryRepositoryProvider).getTelemetryHistory(deviceId);
});

class TelemetryController extends StateNotifier<AsyncValue<Telemetry?>> {
  final TelemetryRepository _repository;
  final String _deviceId;

  Timer? _timer;
  AppLifecycleListener? _lifecycleListener;
  bool _paused = false;
  int _consecutiveErrors = 0;

  static const Duration _baseInterval = Duration(seconds: 5);
  static const Duration _maxInterval = Duration(seconds: 60);

  TelemetryController(
    this._repository,
    this._deviceId,
  ) : super(const AsyncLoading()) {
    // Pause polling while the app is backgrounded; resume (and fetch
    // immediately) when it returns to the foreground.
    _lifecycleListener = AppLifecycleListener(
      onPause: _onAppPaused,
      onResume: _onAppResumed,
    );
    fetchLatest();
  }

  void _onAppPaused() {
    _paused = true;
    _timer?.cancel();
  }

  void _onAppResumed() {
    if (!_paused) return;
    _paused = false;
    fetchLatest();
  }

  Future<void> fetchLatest() async {
    final result = await AsyncValue.guard(
      () => _repository.getLatestTelemetry(_deviceId),
    );

    if (!mounted) return;
    state = result;

    _consecutiveErrors = result.hasError ? _consecutiveErrors + 1 : 0;
    _scheduleNext();
  }

  void _scheduleNext() {
    _timer?.cancel();
    if (_paused || !mounted) return;

    // Exponential backoff (capped) while requests keep failing, so a flaky
    // connection or down backend isn't hammered every 5 seconds.
    final multiplier = 1 << _consecutiveErrors.clamp(0, 4); // 1, 2, 4, 8, 16
    final nextMs = (_baseInterval.inMilliseconds * multiplier)
        .clamp(_baseInterval.inMilliseconds, _maxInterval.inMilliseconds);

    _timer = Timer(Duration(milliseconds: nextMs), fetchLatest);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycleListener?.dispose();
    super.dispose();
  }
}
