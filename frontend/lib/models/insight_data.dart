class InsightData {
  final String predictedYield;
  final double confidence;
  final String riskLevel;
  final String climateStatus;
  final String irrigationStatus;
  final String pestRisk;
  final String recommendation;
  final String lastUpdated;
  final double yieldTrend;
  final double healthScore;

  const InsightData({
    required this.predictedYield,
    required this.confidence,
    required this.riskLevel,
    required this.climateStatus,
    required this.irrigationStatus,
    required this.pestRisk,
    required this.recommendation,
    required this.lastUpdated,
    required this.yieldTrend,
    required this.healthScore,
  });
}