import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/ml_prediction_data.dart';

final insightsServiceProvider = Provider<InsightsService>((ref) {
  return InsightsService(ref.read(dioProvider));
});

class InsightsService {
  final Dio _dio;

  InsightsService(this._dio);

  Future<MlPredictionData> getPrediction() async {
    final response = await _dio.post(
      '/api/v1/ml/predict',
      data: {
        "greenhouse_id": 1,
        "crop_type": "Tomato",
        "variety": "Cherry",
        "planting_date": "2026-03-01",
        "harvest_date": "2026-06-15",
        "days_to_maturity": 106,
        "avg_temperature_C": 24.5,
        "min_temperature_C": 18.0,
        "max_temperature_C": 30.0,
        "humidity_percent": 65.0,
        "co2_ppm": 450.0,
        "light_intensity_lux": 8200.0,
        "photoperiod_hours": 12.0,
        "irrigation_mm": 5.5,
        "fertilizer_N_kg_ha": 120.0,
        "fertilizer_P_kg_ha": 60.0,
        "fertilizer_K_kg_ha": 80.0,
        "pest_severity": 1.0,
        "soil_pH": 6.5
      },
    );

    return MlPredictionData.fromJson(response.data);
  }
}