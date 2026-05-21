import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../telemetry/domain/telemetry.dart';
import '../../telemetry/presentation/telemetry_controller.dart';
import '../domain/device.dart';
import 'device_controller.dart';

enum _TrendMetric {
  temperature,
  humidity,
  soilMoisture,
  light,
  co2,
}

class DeviceDetailPage extends ConsumerWidget {
  final Device device;

  const DeviceDetailPage({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetryAsync = ref.watch(latestTelemetryProvider(device.id));
    final isOnline = device.status == 'online';

    return GradientScaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _Header(device: device),
            const SizedBox(height: 22),

            _DeviceStatusCard(
              device: device,
              isOnline: isOnline,
            ),

            const SizedBox(height: 22),

            telemetryAsync.when(
              data: (telemetry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(
                      title: 'Latest Telemetry',
                      subtitle:
                          'Most recent sensor data received from this device.',
                    ),
                    const SizedBox(height: 14),

                    if (telemetry == null)
                      const _EmptyTelemetryCard()
                    else ...[
                      _MainTemperatureCard(
                        temperature: telemetry.temperature,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              title: 'Humidity',
                              value: telemetry.humidity,
                              unit: '%',
                              icon: Icons.water_drop_rounded,
                              color: Colors.blueAccent,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _MetricCard(
                              title: 'Soil',
                              value: telemetry.soilMoisture,
                              unit: '%',
                              icon: Icons.grass_rounded,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              title: 'Light',
                              value: telemetry.lightIntensity,
                              unit: 'lx',
                              icon: Icons.wb_sunny_rounded,
                              color: Colors.orangeAccent,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _MetricCard(
                              title: 'CO₂',
                              value: telemetry.co2,
                              unit: 'ppm',
                              icon: Icons.cloud_rounded,
                              color: Colors.purpleAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _BatteryCard(
                        batteryLevel: telemetry.batteryLevel,
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => _ErrorCard(
                message: 'Telemetry error: $error',
              ),
            ),

            const SizedBox(height: 24),

            _TelemetryTrendsSection(deviceId: device.id),

            const SizedBox(height: 24),

            const _SectionTitle(
              title: 'Device Information',
              subtitle: 'Technical details and configuration.',
            ),
            const SizedBox(height: 14),

            _InfoPanel(device: device),

            const SizedBox(height: 24),

            const _SectionTitle(
              title: 'Maintenance Actions',
              subtitle: 'Operational controls for device management.',
            ),
            const SizedBox(height: 14),

            _ActionGrid(device: device),
          ],
        ),
      ),
    );
  }
}

class _TelemetryTrendsSection extends ConsumerStatefulWidget {
  final String deviceId;

  const _TelemetryTrendsSection({
    required this.deviceId,
  });

  @override
  ConsumerState<_TelemetryTrendsSection> createState() =>
      _TelemetryTrendsSectionState();
}

class _TelemetryTrendsSectionState
    extends ConsumerState<_TelemetryTrendsSection> {
  _TrendMetric selectedMetric = _TrendMetric.temperature;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(telemetryHistoryProvider(widget.deviceId));

    return historyAsync.when(
      data: (history) {
        final orderedHistory = [...history]
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              title: 'Telemetry Trends',
              subtitle: 'Recent sensor history collected from this device.',
            ),
            const SizedBox(height: 14),
            _MetricSelector(
              selectedMetric: selectedMetric,
              onChanged: (metric) {
                setState(() {
                  selectedMetric = metric;
                });
              },
            ),
            const SizedBox(height: 14),
            if (orderedHistory.length < 2)
              const _EmptyHistoryCard()
            else
              _TrendChartCard(
                history: orderedHistory,
                metric: selectedMetric,
              ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => _ErrorCard(
        message: 'History error: $error',
      ),
    );
  }
}

class _MetricSelector extends StatelessWidget {
  final _TrendMetric selectedMetric;
  final ValueChanged<_TrendMetric> onChanged;

  const _MetricSelector({
    required this.selectedMetric,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _MetricChip(
            label: 'Temp',
            metric: _TrendMetric.temperature,
            selectedMetric: selectedMetric,
            onTap: onChanged,
          ),
          _MetricChip(
            label: 'Humidity',
            metric: _TrendMetric.humidity,
            selectedMetric: selectedMetric,
            onTap: onChanged,
          ),
          _MetricChip(
            label: 'Soil',
            metric: _TrendMetric.soilMoisture,
            selectedMetric: selectedMetric,
            onTap: onChanged,
          ),
          _MetricChip(
            label: 'Light',
            metric: _TrendMetric.light,
            selectedMetric: selectedMetric,
            onTap: onChanged,
          ),
          _MetricChip(
            label: 'CO₂',
            metric: _TrendMetric.co2,
            selectedMetric: selectedMetric,
            onTap: onChanged,
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final _TrendMetric metric;
  final _TrendMetric selectedMetric;
  final ValueChanged<_TrendMetric> onTap;

  const _MetricChip({
    required this.label,
    required this.metric,
    required this.selectedMetric,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedMetric == metric;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => onTap(metric),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.neonGreen : AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.neonGreen
                  : AppColors.neonGreen.withOpacity(0.12),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : AppColors.textGrey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendChartCard extends StatelessWidget {
  final List<Telemetry> history;
  final _TrendMetric metric;

  const _TrendChartCard({
    required this.history,
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    final values = _extractValues(history, metric);

    if (values.length < 2) {
      return const _EmptyHistoryCard();
    }

    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final avgValue = values.reduce((a, b) => a + b) / values.length;
    final latestValue = values.last;

    final metricInfo = _metricInfo(metric);

    final spots = <FlSpot>[];
    for (int i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i]));
    }

    final chartMinY = minValue == maxValue ? minValue - 1 : minValue;
    final chartMaxY = minValue == maxValue ? maxValue + 1 : maxValue;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: metricInfo.color.withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(metricInfo.icon, color: metricInfo.color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  metricInfo.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Text(
                '${latestValue.toStringAsFixed(1)} ${metricInfo.unit}',
                style: TextStyle(
                  color: metricInfo.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: chartMinY,
                maxY: chartMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.06),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: (spots.length / 4).clamp(1, 999).toDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= history.length) {
                          return const SizedBox.shrink();
                        }

                        final timestamp = history[index].timestamp;
                        final hour = timestamp.hour.toString().padLeft(2, '0');
                        final minute =
                            timestamp.minute.toString().padLeft(2, '0');

                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '$hour:$minute',
                            style: const TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (items) {
                      return items.map((item) {
                        return LineTooltipItem(
                          '${item.y.toStringAsFixed(1)} ${metricInfo.unit}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: metricInfo.color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: metricInfo.color.withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _TrendStat(
                  label: 'Latest',
                  value: latestValue,
                  unit: metricInfo.unit,
                  color: metricInfo.color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TrendStat(
                  label: 'Avg',
                  value: avgValue,
                  unit: metricInfo.unit,
                  color: AppColors.neonGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TrendStat(
                  label: 'Min',
                  value: minValue,
                  unit: metricInfo.unit,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TrendStat(
                  label: 'Max',
                  value: maxValue,
                  unit: metricInfo.unit,
                  color: Colors.orangeAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<double> _extractValues(List<Telemetry> history, _TrendMetric metric) {
    return history
        .map((telemetry) {
          switch (metric) {
            case _TrendMetric.temperature:
              return telemetry.temperature;
            case _TrendMetric.humidity:
              return telemetry.humidity;
            case _TrendMetric.soilMoisture:
              return telemetry.soilMoisture;
            case _TrendMetric.light:
              return telemetry.lightIntensity;
            case _TrendMetric.co2:
              return telemetry.co2;
          }
        })
        .whereType<double>()
        .toList();
  }

  _MetricInfo _metricInfo(_TrendMetric metric) {
    switch (metric) {
      case _TrendMetric.temperature:
        return const _MetricInfo(
          title: 'Temperature Trend',
          unit: '°C',
          icon: Icons.thermostat_rounded,
          color: Colors.orangeAccent,
        );
      case _TrendMetric.humidity:
        return const _MetricInfo(
          title: 'Humidity Trend',
          unit: '%',
          icon: Icons.water_drop_rounded,
          color: Colors.blueAccent,
        );
      case _TrendMetric.soilMoisture:
        return const _MetricInfo(
          title: 'Soil Moisture Trend',
          unit: '%',
          icon: Icons.grass_rounded,
          color: Colors.greenAccent,
        );
      case _TrendMetric.light:
        return const _MetricInfo(
          title: 'Light Intensity Trend',
          unit: 'lx',
          icon: Icons.wb_sunny_rounded,
          color: Colors.amberAccent,
        );
      case _TrendMetric.co2:
        return const _MetricInfo(
          title: 'CO₂ Trend',
          unit: 'ppm',
          icon: Icons.cloud_rounded,
          color: Colors.purpleAccent,
        );
    }
  }
}

class _TrendStat extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final Color color;

  const _TrendStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${value.toStringAsFixed(1)}$unit',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricInfo {
  final String title;
  final String unit;
  final IconData icon;
  final Color color;

  const _MetricInfo({
    required this.title,
    required this.unit,
    required this.icon,
    required this.color,
  });
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.orangeAccent.withOpacity(0.2),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.show_chart_rounded,
            color: Colors.orangeAccent,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Not enough telemetry history to draw a trend chart yet. Send at least two telemetry records for this device.',
              style: TextStyle(
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

class _Header extends StatelessWidget {
  final Device device;

  const _Header({required this.device});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.pop(context),
            child: const SizedBox(
              width: 46,
              height: 46,
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.neonGreen,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Device Detail',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                device.name,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeviceStatusCard extends StatelessWidget {
  final Device device;
  final bool isOnline;

  const _DeviceStatusCard({
    required this.device,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isOnline ? AppColors.neonGreen : Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: statusColor.withOpacity(0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.sensors_rounded,
              color: statusColor,
              size: 34,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? 'Device Online' : 'Device Offline',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  isOnline
                      ? 'This device is connected and ready to send telemetry.'
                      : 'This device is not currently sending data.',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              device.status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
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

class _MainTemperatureCard extends StatelessWidget {
  final double? temperature;

  const _MainTemperatureCard({
    required this.temperature,
  });

  @override
  Widget build(BuildContext context) {
    final tempText =
        temperature == null ? '--' : temperature!.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.neonGreen.withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.thermostat_rounded,
              color: AppColors.neonGreen,
              size: 32,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Temperature',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$tempText °C',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
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

class _MetricCard extends StatelessWidget {
  final String title;
  final double? value;
  final String unit;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value == null ? '--' : value!.toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withOpacity(0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$displayValue $unit',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _BatteryCard extends StatelessWidget {
  final double? batteryLevel;

  const _BatteryCard({
    required this.batteryLevel,
  });

  @override
  Widget build(BuildContext context) {
    final batteryText =
        batteryLevel == null ? '--' : batteryLevel!.toStringAsFixed(0);
    final isHealthy = batteryLevel == null || batteryLevel! >= 40;
    final color = isHealthy ? AppColors.neonGreen : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isHealthy
                ? Icons.battery_charging_full_rounded
                : Icons.battery_alert_rounded,
            color: color,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Battery Level',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$batteryText%',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          Text(
            isHealthy ? 'Healthy' : 'Low',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final Device device;

  const _InfoPanel({required this.device});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.neonGreen.withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          _InfoRow(label: 'Device ID', value: device.id),
          _InfoRow(label: 'Serial Number', value: device.serialNumber),
          _InfoRow(label: 'Device Type', value: device.deviceType),
          _InfoRow(label: 'Firmware', value: device.firmwareVersion ?? 'N/A'),
          _InfoRow(label: 'Status', value: device.status.toUpperCase()),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textGrey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionGrid extends ConsumerWidget {
  final Device device;

  const _ActionGrid({required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.restart_alt_rounded,
            label: 'Restart',
            onTap: () => _showCommandMessage(
              context,
              'Restart command will be sent when backend command flow is enabled.',
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _ActionTile(
            icon: Icons.tune_rounded,
            label: 'Calibrate',
            onTap: () => _showCommandMessage(
              context,
              'Calibration command will be sent when backend command flow is enabled.',
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _ActionTile(
            icon: Icons.delete_outline_rounded,
            label: 'Remove',
            danger: true,
            onTap: () => _confirmRemoveDevice(context, ref),
          ),
        ),
      ],
    );
  }

  void _showCommandMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmRemoveDevice(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text(
            'Remove Device',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to remove "${device.name}" from this greenhouse?',
            style: const TextStyle(
              color: AppColors.textGrey,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Remove',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await ref.read(devicesProvider(device.greenhouseId).notifier).deleteDevice(
            deviceId: device.id,
            greenhouseId: device.greenhouseId,
          );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${device.name} removed successfully.'),
          backgroundColor: AppColors.neonGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove device: $error'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.redAccent : AppColors.neonGreen;

    return Material(
      color: AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTelemetryCard extends StatelessWidget {
  const _EmptyTelemetryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.orangeAccent.withOpacity(0.2),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.data_usage_rounded,
            color: Colors.orangeAccent,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'No telemetry has been received from this device yet.',
              style: TextStyle(
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

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.redAccent.withOpacity(0.18),
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textGrey,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}