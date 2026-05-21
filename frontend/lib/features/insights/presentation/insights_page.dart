import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../devices/presentation/device_controller.dart';
import '../../greenhouse/presentation/greenhouse_controller.dart';
import '../../greenhouse/presentation/greenhouse_selector_sheet.dart';
import '../../greenhouse/presentation/selected_greenhouse_provider.dart';
import '../../telemetry/domain/telemetry.dart';
import '../../telemetry/presentation/telemetry_controller.dart';

class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greenhousesAsync = ref.watch(greenhousesProvider);

    return GradientScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          child: greenhousesAsync.when(
            data: (greenhouses) {
              if (greenhouses.isEmpty) {
                return const _EmptyState(
                  icon: Icons.eco_outlined,
                  title: 'No Greenhouse Found',
                  message:
                      'Add a greenhouse to activate AI-supported insights and recommendations.',
                );
              }

              final selectedGreenhouse =
                  ref.watch(selectedGreenhouseProvider) ?? greenhouses.first;

              final devicesAsync = ref.watch(
                devicesProvider(selectedGreenhouse.id),
              );

              return devicesAsync.when(
                data: (devices) {
                  if (devices.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        _InsightsHeader(
                          greenhouseName: selectedGreenhouse.name,
                          location: selectedGreenhouse.location,
                          onSelectGreenhouse: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (_) => const GreenhouseSelectorSheet(),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        const _EmptyState(
                          icon: Icons.sensors_off_rounded,
                          title: 'No Device Connected',
                          message:
                              'Connect an ESP32 sensor device to generate risk analysis and smart recommendations.',
                        ),
                      ],
                    );
                  }

                  final primaryDevice = devices.first;
                  final telemetryAsync = ref.watch(
                    latestTelemetryProvider(primaryDevice.id),
                  );

                  return telemetryAsync.when(
                    data: (telemetry) {
                      final analysis = _InsightAnalysis.fromTelemetry(telemetry);

                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          _InsightsHeader(
                            greenhouseName: selectedGreenhouse.name,
                            location: selectedGreenhouse.location,
                            onSelectGreenhouse: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                builder: (_) => const GreenhouseSelectorSheet(),
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          _InsightSummaryCard(
                            status: analysis.overallStatus,
                            description: analysis.overallDescription,
                            statusColor: analysis.overallColor,
                            deviceName: primaryDevice.name,
                          ),

                          const SizedBox(height: 18),

                          _RiskCard(
                            title: 'Frost Risk',
                            value: analysis.frostRisk.label,
                            description: analysis.frostRisk.description,
                            icon: Icons.ac_unit_rounded,
                            statusColor: analysis.frostRisk.color,
                          ),

                          const SizedBox(height: 14),

                          _RiskCard(
                            title: 'Irrigation Need',
                            value: analysis.irrigationNeed.label,
                            description: analysis.irrigationNeed.description,
                            icon: Icons.water_drop_rounded,
                            statusColor: analysis.irrigationNeed.color,
                          ),

                          const SizedBox(height: 14),

                          _RiskCard(
                            title: 'Heat Stress',
                            value: analysis.heatStress.label,
                            description: analysis.heatStress.description,
                            icon: Icons.thermostat_rounded,
                            statusColor: analysis.heatStress.color,
                          ),

                          const SizedBox(height: 14),

                          _RiskCard(
                            title: 'Battery Health',
                            value: analysis.batteryHealth.label,
                            description: analysis.batteryHealth.description,
                            icon: Icons.battery_charging_full_rounded,
                            statusColor: analysis.batteryHealth.color,
                          ),

                          const SizedBox(height: 24),

                          Text(
                            'Smart Recommendations',
                            style:
                                Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),

                          const SizedBox(height: 12),

                          ...analysis.recommendations.map(
                            (recommendation) => _RecommendationTile(
                              icon: recommendation.icon,
                              text: recommendation.text,
                              color: recommendation.color,
                            ),
                          ),

                          const SizedBox(height: 24),

                          _DataSourceCard(
                            hasTelemetry: telemetry != null,
                            deviceName: primaryDevice.name,
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, _) => Center(
                      child: Text(
                        'Insight error: $error',
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Text(
                    'Device error: $error',
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, _) => Center(
              child: Text(
                'Greenhouse error: $error',
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InsightsHeader extends StatelessWidget {
  final String greenhouseName;
  final String? location;
  final VoidCallback onSelectGreenhouse;

  const _InsightsHeader({
    required this.greenhouseName,
    required this.location,
    required this.onSelectGreenhouse,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = location == null || location!.isEmpty
        ? greenhouseName
        : '$greenhouseName • $location';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI-Supported Analysis',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Insights',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onSelectGreenhouse,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    const Icon(
                      Icons.eco_rounded,
                      color: AppColors.neonGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        subtitle,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textGrey,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.neonGreen.withOpacity(0.18),
            ),
          ),
          child: const Icon(
            Icons.insights_rounded,
            color: AppColors.neonGreen,
          ),
        ),
      ],
    );
  }
}

class _InsightSummaryCard extends StatelessWidget {
  final String status;
  final String description;
  final Color statusColor;
  final String deviceName;

  const _InsightSummaryCard({
    required this.status,
    required this.description,
    required this.statusColor,
    required this.deviceName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: statusColor.withOpacity(0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.eco_rounded,
              color: statusColor,
              size: 30,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Source: $deviceName',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskCard extends StatelessWidget {
  final String title;
  final String value;
  final String description;
  final IconData icon;
  final Color statusColor;

  const _RiskCard({
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: statusColor.withOpacity(0.22),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: statusColor,
            size: 30,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _RecommendationTile({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textGrey,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataSourceCard extends StatelessWidget {
  final bool hasTelemetry;
  final String deviceName;

  const _DataSourceCard({
    required this.hasTelemetry,
    required this.deviceName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.neonGreen.withOpacity(0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasTelemetry ? Icons.check_circle_rounded : Icons.info_outline,
            color: hasTelemetry ? AppColors.neonGreen : Colors.orangeAccent,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              hasTelemetry
                  ? 'Insights are generated from the latest telemetry received from $deviceName.'
                  : 'No telemetry has been received yet. Once sensor data arrives, insights will be generated automatically.',
              style: const TextStyle(
                color: AppColors.textGrey,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 90),
        Icon(
          icon,
          color: AppColors.textGrey,
          size: 70,
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textGrey,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _InsightAnalysis {
  final String overallStatus;
  final String overallDescription;
  final Color overallColor;

  final _RiskLevel frostRisk;
  final _RiskLevel irrigationNeed;
  final _RiskLevel heatStress;
  final _RiskLevel batteryHealth;

  final List<_Recommendation> recommendations;

  const _InsightAnalysis({
    required this.overallStatus,
    required this.overallDescription,
    required this.overallColor,
    required this.frostRisk,
    required this.irrigationNeed,
    required this.heatStress,
    required this.batteryHealth,
    required this.recommendations,
  });

  factory _InsightAnalysis.fromTelemetry(Telemetry? telemetry) {
    if (telemetry == null) {
      return _InsightAnalysis(
        overallStatus: 'Waiting for Sensor Data',
        overallDescription:
            'No telemetry has been received yet. Risk analysis will be activated after the first sensor reading.',
        overallColor: Colors.orangeAccent,
        frostRisk: const _RiskLevel(
          label: 'N/A',
          description: 'Frost risk cannot be calculated without temperature data.',
          color: Colors.orangeAccent,
        ),
        irrigationNeed: const _RiskLevel(
          label: 'N/A',
          description:
              'Irrigation need cannot be calculated without soil moisture data.',
          color: Colors.orangeAccent,
        ),
        heatStress: const _RiskLevel(
          label: 'N/A',
          description: 'Heat stress cannot be calculated without temperature data.',
          color: Colors.orangeAccent,
        ),
        batteryHealth: const _RiskLevel(
          label: 'N/A',
          description: 'Battery health cannot be calculated without device data.',
          color: Colors.orangeAccent,
        ),
        recommendations: const [
          _Recommendation(
            icon: Icons.sensors_rounded,
            text:
                'Wait for the first telemetry package or check whether the device is online.',
            color: Colors.orangeAccent,
          ),
        ],
      );
    }

    final temperature = telemetry.temperature;
    final soilMoisture = telemetry.soilMoisture;
    final humidity = telemetry.humidity;
    final battery = telemetry.batteryLevel;

    final frostRisk = _calculateFrostRisk(temperature);
    final irrigationNeed = _calculateIrrigationNeed(soilMoisture);
    final heatStress = _calculateHeatStress(temperature);
    final batteryHealth = _calculateBatteryHealth(battery);

    final risks = [frostRisk, irrigationNeed, heatStress, batteryHealth];
    final hasHighRisk = risks.any((risk) => risk.label == 'High');
    final hasMediumRisk = risks.any((risk) => risk.label == 'Medium');

    final overallStatus = hasHighRisk
        ? 'Action Required'
        : hasMediumRisk
            ? 'Monitor Closely'
            : 'Stable Conditions';

    final overallColor = hasHighRisk
        ? Colors.redAccent
        : hasMediumRisk
            ? Colors.orangeAccent
            : AppColors.neonGreen;

    final overallDescription = hasHighRisk
        ? 'One or more risk factors require attention. Review recommendations below.'
        : hasMediumRisk
            ? 'The greenhouse is mostly stable, but some parameters should be monitored.'
            : 'Current environmental conditions are within a safe operating range.';

    final recommendations = <_Recommendation>[];

    if (temperature != null && temperature <= 5) {
      recommendations.add(
        const _Recommendation(
          icon: Icons.ac_unit_rounded,
          text:
              'Temperature is low. Consider activating frost protection or heating systems.',
          color: Colors.redAccent,
        ),
      );
    }

    if (temperature != null && temperature >= 30) {
      recommendations.add(
        const _Recommendation(
          icon: Icons.air_rounded,
          text:
              'Temperature is high. Increase ventilation and monitor heat stress.',
          color: Colors.orangeAccent,
        ),
      );
    }

    if (soilMoisture != null && soilMoisture < 35) {
      recommendations.add(
        const _Recommendation(
          icon: Icons.water_drop_rounded,
          text:
              'Soil moisture is below the recommended range. Irrigation may be needed.',
          color: Colors.orangeAccent,
        ),
      );
    }

    if (humidity != null && humidity > 80) {
      recommendations.add(
        const _Recommendation(
          icon: Icons.coronavirus_rounded,
          text:
              'Humidity is high. Monitor fungal disease risk and improve air circulation.',
          color: Colors.orangeAccent,
        ),
      );
    }

    if (battery != null && battery < 25) {
      recommendations.add(
        const _Recommendation(
          icon: Icons.battery_alert_rounded,
          text:
              'Device battery is low. Check power supply or replace the battery soon.',
          color: Colors.redAccent,
        ),
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        const _Recommendation(
          icon: Icons.check_circle_rounded,
          text:
              'No critical action is required. Continue monitoring live greenhouse conditions.',
          color: AppColors.neonGreen,
        ),
      );
    }

    return _InsightAnalysis(
      overallStatus: overallStatus,
      overallDescription: overallDescription,
      overallColor: overallColor,
      frostRisk: frostRisk,
      irrigationNeed: irrigationNeed,
      heatStress: heatStress,
      batteryHealth: batteryHealth,
      recommendations: recommendations,
    );
  }

  static _RiskLevel _calculateFrostRisk(double? temperature) {
    if (temperature == null) {
      return const _RiskLevel(
        label: 'N/A',
        description: 'Temperature data is not available.',
        color: Colors.orangeAccent,
      );
    }

    if (temperature <= 3) {
      return const _RiskLevel(
        label: 'High',
        description: 'Temperature is close to freezing level.',
        color: Colors.redAccent,
      );
    }

    if (temperature <= 7) {
      return const _RiskLevel(
        label: 'Medium',
        description: 'Temperature is low. Frost conditions should be monitored.',
        color: Colors.orangeAccent,
      );
    }

    return const _RiskLevel(
      label: 'Low',
      description: 'Current temperature does not indicate immediate frost risk.',
      color: AppColors.neonGreen,
    );
  }

  static _RiskLevel _calculateIrrigationNeed(double? soilMoisture) {
    if (soilMoisture == null) {
      return const _RiskLevel(
        label: 'N/A',
        description: 'Soil moisture data is not available.',
        color: Colors.orangeAccent,
      );
    }

    if (soilMoisture < 25) {
      return const _RiskLevel(
        label: 'High',
        description: 'Soil moisture is very low. Irrigation is recommended.',
        color: Colors.redAccent,
      );
    }

    if (soilMoisture < 40) {
      return const _RiskLevel(
        label: 'Medium',
        description: 'Soil moisture is slightly below the optimal range.',
        color: Colors.orangeAccent,
      );
    }

    return const _RiskLevel(
      label: 'Low',
      description: 'Soil moisture is within a healthy range.',
      color: AppColors.neonGreen,
    );
  }

  static _RiskLevel _calculateHeatStress(double? temperature) {
    if (temperature == null) {
      return const _RiskLevel(
        label: 'N/A',
        description: 'Temperature data is not available.',
        color: Colors.orangeAccent,
      );
    }

    if (temperature >= 35) {
      return const _RiskLevel(
        label: 'High',
        description: 'Temperature is high and may cause plant heat stress.',
        color: Colors.redAccent,
      );
    }

    if (temperature >= 30) {
      return const _RiskLevel(
        label: 'Medium',
        description: 'Temperature is elevated. Ventilation may be required.',
        color: Colors.orangeAccent,
      );
    }

    return const _RiskLevel(
      label: 'Low',
      description: 'Temperature levels are within a safe range.',
      color: AppColors.neonGreen,
    );
  }

  static _RiskLevel _calculateBatteryHealth(double? batteryLevel) {
    if (batteryLevel == null) {
      return const _RiskLevel(
        label: 'N/A',
        description: 'Battery level data is not available.',
        color: Colors.orangeAccent,
      );
    }

    if (batteryLevel < 20) {
      return const _RiskLevel(
        label: 'High',
        description: 'Battery level is critically low.',
        color: Colors.redAccent,
      );
    }

    if (batteryLevel < 40) {
      return const _RiskLevel(
        label: 'Medium',
        description: 'Battery level is decreasing and should be monitored.',
        color: Colors.orangeAccent,
      );
    }

    return const _RiskLevel(
      label: 'Good',
      description: 'Device battery level is healthy.',
      color: AppColors.neonGreen,
    );
  }
}

class _RiskLevel {
  final String label;
  final String description;
  final Color color;

  const _RiskLevel({
    required this.label,
    required this.description,
    required this.color,
  });
}

class _Recommendation {
  final IconData icon;
  final String text;
  final Color color;

  const _Recommendation({
    required this.icon,
    required this.text,
    required this.color,
  });
}