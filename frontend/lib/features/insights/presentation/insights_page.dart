import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../greenhouse/presentation/greenhouse_controller.dart';
import '../../greenhouse/presentation/selected_greenhouse_provider.dart';
import '../data/insights_service.dart';
import '../domain/ml_prediction_data.dart';

const Color _kBackground = Color(0xFF0D120D);
const Color _kNeonGreen = Color(0xFFB6FF5B);
const Color _kTextGrey = Color(0xFF8A8F98);

class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greenhousesAsync = ref.watch(greenhousesProvider);

    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        child: greenhousesAsync.when(
          loading: () => const _LoadingView(),
          error: (error, _) => _ErrorView(
            error: error,
            onRetry: () => ref.invalidate(greenhousesProvider),
          ),
          data: (greenhouses) {
            if (greenhouses.isEmpty) {
              return _ScrollableMessage(
                onRefresh: () async => ref.invalidate(greenhousesProvider),
                icon: Icons.eco_outlined,
                title: 'No greenhouse selected',
                message:
                    'Add a greenhouse to see machine-learning yield predictions.',
              );
            }

            final greenhouse =
                ref.watch(selectedGreenhouseProvider) ?? greenhouses.first;
            final predictionAsync =
                ref.watch(greenhousePredictionProvider(greenhouse.id));

            return RefreshIndicator(
              color: _kNeonGreen,
              onRefresh: () async {
                ref.invalidate(greenhousePredictionProvider(greenhouse.id));
                // Allow the spinner to reflect the in-flight refetch.
                await ref.read(
                  greenhousePredictionProvider(greenhouse.id).future,
                );
              },
              child: predictionAsync.when(
                loading: () => const _LoadingView(),
                error: (error, _) => _ErrorView(
                  error: error,
                  onRetry: () => ref.invalidate(
                    greenhousePredictionProvider(greenhouse.id),
                  ),
                ),
                data: (data) {
                  if (data == null) {
                    return _ScrollableMessage(
                      onRefresh: () async {
                        ref.invalidate(
                          greenhousePredictionProvider(greenhouse.id),
                        );
                        await ref.read(
                          greenhousePredictionProvider(greenhouse.id).future,
                        );
                      },
                      icon: Icons.hourglass_empty_rounded,
                      title: 'No prediction yet',
                      message:
                          'A yield prediction for "${greenhouse.name}" has not been '
                          'generated yet. This requires a trained model, complete '
                          'greenhouse details (crop, variety, planting & harvest '
                          'dates) and recent telemetry from a device.',
                    );
                  }

                  return _PredictionContent(
                    greenhouseName: greenhouse.name,
                    data: data,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PredictionContent extends StatelessWidget {
  final String greenhouseName;
  final MlPredictionData data;

  const _PredictionContent({
    required this.greenhouseName,
    required this.data,
  });

  String _shortTimestamp(String value) {
    if (value.isEmpty) return 'Unknown';
    return value.length > 19 ? value.substring(0, 19) : value;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(greenhouseName: greenhouseName),
          const SizedBox(height: 24),
          _PredictionCard(data: data),
          const SizedBox(height: 18),
          const _InfoCard(),
          const SizedBox(height: 22),
          const _SectionTitle('MODEL DETAILS'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniCard(
                  title: 'Model Version',
                  value: data.modelVersion,
                  subtitle: 'Current ML model',
                  icon: Icons.memory_outlined,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _MiniCard(
                  title: 'Timestamp',
                  value: _shortTimestamp(data.predictionTimestamp),
                  subtitle: 'Prediction time',
                  icon: Icons.schedule_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionTitle('INSIGHT STATUS'),
          const SizedBox(height: 14),
          const _StatusCard(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String greenhouseName;

  const _Header({required this.greenhouseName});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'INSIGHTS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'ML yield prediction • $greenhouseName',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: _kNeonGreen,
            size: 22,
          ),
        ),
      ],
    );
  }
}

class _PredictionCard extends StatelessWidget {
  final MlPredictionData data;

  const _PredictionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _kNeonGreen.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Predicted Yield',
            style: TextStyle(color: Colors.white60, fontSize: 13),
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
              color: _kNeonGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'Live Backend Prediction',
              style: TextStyle(
                color: _kNeonGreen,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        'This value is the latest yield estimate produced by the backend ML '
        'model for the selected greenhouse, based on its crop details and the '
        'most recent telemetry collected from its devices.',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.75),
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _kTextGrey,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _MiniCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _kNeonGreen, size: 20),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
              Icon(Icons.check_circle_outline, color: _kNeonGreen, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Predictions are read from the backend ML history for this '
                  'greenhouse.',
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
                  'New predictions are produced periodically as fresh telemetry '
                  'arrives.',
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
      child: CircularProgressIndicator(color: _kNeonGreen),
    );
  }
}

/// A scrollable informational state so it works inside a [RefreshIndicator]
/// and fills the viewport for vertical centering.
class _ScrollableMessage extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final IconData icon;
  final String title;
  final String message;

  const _ScrollableMessage({
    required this.onRefresh,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _kNeonGreen,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 160,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: _kNeonGreen, size: 42),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

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
                    backgroundColor: _kNeonGreen,
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
