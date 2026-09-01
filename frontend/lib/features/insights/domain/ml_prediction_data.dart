class MlPredictionData {
  final double yieldKgPerM2;
  final String modelVersion;
  final String predictionTimestamp;

  const MlPredictionData({
    required this.yieldKgPerM2,
    required this.modelVersion,
    required this.predictionTimestamp,
  });

  factory MlPredictionData.fromJson(Map<String, dynamic> json) {
    return MlPredictionData(
      yieldKgPerM2: (json['yield_kg_per_m2'] as num).toDouble(),
      modelVersion: json['model_version']?.toString() ?? 'Unknown',
      // The persisted prediction history endpoint returns `timestamp`, while
      // the on-demand /predict endpoint returns `prediction_timestamp`.
      // Accept either so the model works with both shapes.
      predictionTimestamp: (json['timestamp'] ?? json['prediction_timestamp'])
              ?.toString() ??
          '',
    );
  }
}