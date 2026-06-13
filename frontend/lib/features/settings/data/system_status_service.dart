import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';

/// Real system status derived from backend health endpoints.
///
/// Only includes signals the backend actually exposes: overall reachability
/// (`/health`) and whether an ML model is loaded (`/api/v1/ml/health`).
class SystemStatus {
  final bool backendOnline;
  final bool modelLoaded;

  const SystemStatus({
    required this.backendOnline,
    required this.modelLoaded,
  });
}

final systemStatusProvider =
    FutureProvider.autoDispose<SystemStatus>((ref) async {
  final dio = ref.read(dioProvider);

  bool backendOnline = false;
  bool modelLoaded = false;

  try {
    final health = await dio.get(ApiEndpoints.health);
    backendOnline = health.statusCode == 200;
  } catch (_) {
    backendOnline = false;
  }

  if (backendOnline) {
    try {
      final ml = await dio.get(ApiEndpoints.mlHealth);
      modelLoaded = ml.data is Map && ml.data['model_loaded'] == true;
    } catch (_) {
      modelLoaded = false;
    }
  }

  return SystemStatus(
    backendOnline: backendOnline,
    modelLoaded: modelLoaded,
  );
});
