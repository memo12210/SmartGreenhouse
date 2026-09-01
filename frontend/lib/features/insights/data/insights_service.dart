import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/ml_prediction_data.dart';

final insightsServiceProvider = Provider<InsightsService>((ref) {
  return InsightsService(ref.read(dioProvider));
});

/// Latest backend ML yield prediction for a specific greenhouse.
///
/// Returns `null` when the backend has not produced any prediction yet (e.g.
/// the model is untrained, the greenhouse metadata is incomplete, or no
/// telemetry has been received for the prediction window).
final greenhousePredictionProvider =
    FutureProvider.autoDispose.family<MlPredictionData?, String>(
  (ref, greenhouseId) {
    return ref.read(insightsServiceProvider).getLatestPrediction(greenhouseId);
  },
);

class InsightsService {
  final Dio _dio;

  InsightsService(this._dio);

  /// Fetches the most recent persisted prediction for [greenhouseId].
  ///
  /// The backend's ML worker periodically runs the yield model against each
  /// greenhouse's real metadata and aggregated telemetry and stores the
  /// result. We read that history (newest first) and surface the latest row.
  Future<MlPredictionData?> getLatestPrediction(String greenhouseId) async {
    final response = await _dio.get(
      ApiEndpoints.greenhousePredictions(greenhouseId),
      queryParameters: {'limit': 1},
    );

    final data = response.data as List<dynamic>;
    if (data.isEmpty) return null;

    return MlPredictionData.fromJson(data.first as Map<String, dynamic>);
  }
}
