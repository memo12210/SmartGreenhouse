import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/insights_service.dart';
import '../domain/ml_prediction_data.dart';

class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  static const Color backgroundColor = Color(0xFF0D120D);
  static const Color neonGreen = Color(0xFFB6FF5B);
  static const Color textGrey = Color(0xFF8A8F98);

  late Future<MlPredictionData> _predictionFuture;

  @override
  void initState() {
    super.initState();
    _predictionFuture = ref.read(insightsServiceProvider).getPrediction();
  }

  Future<void> _refreshPrediction() async {
    setState(() {
      _predictionFuture = ref.read(insightsServiceProvider).getPrediction();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshPrediction,
          color: neonGreen,
          child: FutureBuilder<MlPredictionData>(
            future: _predictionFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _LoadingView();
              }

              if (snapshot.hasError) {
                return _ErrorView(
                  error: snapshot.error,
                  onRetry: _refreshPrediction,
                );
              }

              final data = snapshot.data!;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildPredictionCard(data),
                    const SizedBox(height: 18),
                    _buildInfoCard(data),
                    const SizedBox(height: 22),
                    _buildSectionTitle('MODEL DETAILS'),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniCard(
                            title: 'Model Version',
                            value: data.modelVersion,
                            subtitle: 'Current ML model',
                            icon: Icons.memory_outlined,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildMiniCard(
                            title: 'Timestamp',
                            value: _shortTimestamp(data.predictionTimestamp),
                            subtitle: 'Prediction time',
                            icon: Icons.schedule_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _buildSectionTitle('INSIGHT STATUS'),
                    const SizedBox(height: 14),
                    _buildStatusCard(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _shortTimestamp(String value) {
    if (value.isEmpty) return 'Unknown';
    return value.length > 19 ? value.substring(0, 19) : value;
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'INSIGHTS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Machine learning based greenhouse prediction',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: neonGreen,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionCard(MlPredictionData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            neonGreen.withOpacity(0.18),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Predicted Yield',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${data.yieldKgPerM2.toStringAsFixed(2)} kg/m²',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: neonGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'Live Backend Prediction',
              style: TextStyle(
                color: neonGreen,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(MlPredictionData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Text(
        'The displayed value is fetched from the backend ML prediction endpoint and represents the estimated yield for the selected greenhouse scenario.',
        style: TextStyle(
          color: Colors.white.withOpacity(0.75),
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: textGrey,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildMiniCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: neonGreen, size: 20),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Integration Status',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: neonGreen, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Insights are now connected to the backend ML endpoint.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white70, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'If the model is not trained yet, this page will show a backend error state.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: _InsightsPageState.neonGreen,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object? error;
  final Future<void> Function() onRetry;

  const _ErrorView({
    required this.error,
    required this.onRetry,
  });

  String _extractMessage(Object? error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['detail'] != null) {
        return data['detail'].toString();
      }
      return error.message ?? 'Failed to fetch ML prediction.';
    }
    return error?.toString() ?? 'Unknown error';
  }

  @override
  Widget build(BuildContext context) {
    final message = _extractMessage(error);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 120,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 42,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Prediction could not be loaded',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _InsightsPageState.neonGreen,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}