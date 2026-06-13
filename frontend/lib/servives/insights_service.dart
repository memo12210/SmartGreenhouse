import '../models/insight_data.dart';

class InsightsService {
  Future<InsightData> getMockInsights() async {
    await Future.delayed(const Duration(milliseconds: 800));

    return const InsightData(
      predictedYield: '84%',
      confidence: 0.91,
      riskLevel: 'Low Risk',
      climateStatus: 'Stable',
      irrigationStatus: 'Needs Optimization',
      pestRisk: 'Moderate',
      recommendation:
          'Increase irrigation slightly over the next 3 days and continue monitoring leaf surfaces for early pest activity.',
      lastUpdated: 'Just now',
      yieldTrend: 8.4,
      healthScore: 87,
    );
  }
}