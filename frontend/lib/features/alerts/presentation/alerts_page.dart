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

enum AlertSeverity { critical, warning, info }

class AlertItem {
  final String title;
  final String message;
  final String time;
  final String category;
  final AlertSeverity severity;
  final bool isResolved;
  final String greenhouseName;
  final String recommendedAction;

  const AlertItem({
    required this.title,
    required this.message,
    required this.time,
    required this.category,
    required this.severity,
    required this.isResolved,
    required this.greenhouseName,
    required this.recommendedAction,
  });
}

class AlertsPage extends ConsumerStatefulWidget {
  const AlertsPage({super.key});

  @override
  ConsumerState<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends ConsumerState<AlertsPage> {
  int selectedFilter = 0;

  List<AlertItem> _filterAlerts(List<AlertItem> alerts) {
    switch (selectedFilter) {
      case 1:
        return alerts
            .where(
              (alert) =>
                  alert.severity == AlertSeverity.critical &&
                  !alert.isResolved,
            )
            .toList();
      case 2:
        return alerts
            .where(
              (alert) =>
                  alert.severity == AlertSeverity.warning && !alert.isResolved,
            )
            .toList();
      case 3:
        return alerts.where((alert) => alert.isResolved).toList();
      default:
        return alerts;
    }
  }

  @override
  Widget build(BuildContext context) {
    final greenhousesAsync = ref.watch(greenhousesProvider);

    return GradientScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          child: greenhousesAsync.when(
            data: (greenhouses) {
              if (greenhouses.isEmpty) {
                return const _EmptyState(
                  title: 'No Greenhouse Found',
                  message:
                      'Add a greenhouse to activate alert monitoring and system warnings.',
                  icon: Icons.eco_outlined,
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
                    final alerts = _buildNoDeviceAlerts(
                      greenhouseName: selectedGreenhouse.name,
                    );

                    return _AlertsContent(
                      greenhouseName: selectedGreenhouse.name,
                      location: selectedGreenhouse.location,
                      alerts: alerts,
                      filteredAlerts: _filterAlerts(alerts),
                      selectedFilter: selectedFilter,
                      onFilterChanged: (index) {
                        setState(() {
                          selectedFilter = index;
                        });
                      },
                      onSelectGreenhouse: () {
                        _showGreenhouseSelector(context);
                      },
                    );
                  }

                  final primaryDevice = devices.first;
                  final telemetryAsync = ref.watch(
                    latestTelemetryProvider(primaryDevice.id),
                  );

                  return telemetryAsync.when(
                    data: (telemetry) {
                      final alerts = _buildTelemetryAlerts(
                        telemetry: telemetry,
                        greenhouseName: selectedGreenhouse.name,
                        deviceName: primaryDevice.name,
                        deviceStatus: primaryDevice.status,
                      );

                      return _AlertsContent(
                        greenhouseName: selectedGreenhouse.name,
                        location: selectedGreenhouse.location,
                        alerts: alerts,
                        filteredAlerts: _filterAlerts(alerts),
                        selectedFilter: selectedFilter,
                        onFilterChanged: (index) {
                          setState(() {
                            selectedFilter = index;
                          });
                        },
                        onSelectGreenhouse: () {
                          _showGreenhouseSelector(context);
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, _) => _ErrorState(
                      message: 'Telemetry error: $error',
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => _ErrorState(
                  message: 'Device error: $error',
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, _) => _ErrorState(
              message: 'Greenhouse error: $error',
            ),
          ),
        ),
      ),
    );
  }

  void _showGreenhouseSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const GreenhouseSelectorSheet(),
    );
  }

  List<AlertItem> _buildNoDeviceAlerts({
    required String greenhouseName,
  }) {
    return [
      AlertItem(
        title: 'No Device Connected',
        message:
            'This greenhouse does not have an active sensor device. Live monitoring cannot start until a device is added.',
        time: 'Now',
        category: 'Device',
        severity: AlertSeverity.info,
        isResolved: false,
        greenhouseName: greenhouseName,
        recommendedAction: 'Add an ESP32 sensor device from the Devices page.',
      ),
    ];
  }

  List<AlertItem> _buildTelemetryAlerts({
    required Telemetry? telemetry,
    required String greenhouseName,
    required String deviceName,
    required String deviceStatus,
  }) {
    final alerts = <AlertItem>[];

    if (deviceStatus != 'online') {
      alerts.add(
        AlertItem(
          title: 'Device Offline',
          message:
              '$deviceName is not currently online. Telemetry updates may be delayed.',
          time: 'Now',
          category: 'Device',
          severity: AlertSeverity.warning,
          isResolved: false,
          greenhouseName: greenhouseName,
          recommendedAction:
              'Check device power, Wi-Fi/MQTT connection, and firmware status.',
        ),
      );
    }

    if (telemetry == null) {
      alerts.add(
        AlertItem(
          title: 'Waiting for Sensor Data',
          message:
              'No telemetry has been received from $deviceName yet. Alerts will become more accurate after the first sensor reading.',
          time: 'Now',
          category: 'Telemetry',
          severity: AlertSeverity.info,
          isResolved: false,
          greenhouseName: greenhouseName,
          recommendedAction:
              'Make sure the ESP32 is powered on and publishing telemetry.',
        ),
      );

      return alerts;
    }

    final temperature = telemetry.temperature;
    final humidity = telemetry.humidity;
    final soilMoisture = telemetry.soilMoisture;
    final battery = telemetry.batteryLevel;
    final co2 = telemetry.co2;

    if (temperature != null && temperature >= 35) {
      alerts.add(
        AlertItem(
          title: 'Critical Heat Stress',
          message:
              'Temperature reached ${temperature.toStringAsFixed(1)} °C. This may cause plant heat stress.',
          time: 'Latest reading',
          category: 'Temperature',
          severity: AlertSeverity.critical,
          isResolved: false,
          greenhouseName: greenhouseName,
          recommendedAction:
              'Increase ventilation, check shading, and monitor temperature closely.',
        ),
      );
    } else if (temperature != null && temperature >= 30) {
      alerts.add(
        AlertItem(
          title: 'High Temperature',
          message:
              'Temperature is ${temperature.toStringAsFixed(1)} °C. Ventilation may be required.',
          time: 'Latest reading',
          category: 'Temperature',
          severity: AlertSeverity.warning,
          isResolved: false,
          greenhouseName: greenhouseName,
          recommendedAction:
              'Open ventilation or activate cooling if temperature keeps rising.',
        ),
      );
    }

    if (temperature != null && temperature <= 3) {
      alerts.add(
        AlertItem(
          title: 'Critical Frost Risk',
          message:
              'Temperature dropped to ${temperature.toStringAsFixed(1)} °C. Frost damage may occur.',
          time: 'Latest reading',
          category: 'Temperature',
          severity: AlertSeverity.critical,
          isResolved: false,
          greenhouseName: greenhouseName,
          recommendedAction:
              'Activate heating or frost protection immediately.',
        ),
      );
    } else if (temperature != null && temperature <= 7) {
      alerts.add(
        AlertItem(
          title: 'Low Temperature Warning',
          message:
              'Temperature is ${temperature.toStringAsFixed(1)} °C. Frost risk should be monitored.',
          time: 'Latest reading',
          category: 'Temperature',
          severity: AlertSeverity.warning,
          isResolved: false,
          greenhouseName: greenhouseName,
          recommendedAction:
              'Prepare frost protection if the temperature continues to decrease.',
        ),
      );
    }

    if (soilMoisture != null && soilMoisture < 25) {
      alerts.add(
        AlertItem(
          title: 'Critical Soil Moisture',
          message:
              'Soil moisture dropped to ${soilMoisture.toStringAsFixed(0)}%. Irrigation is urgently recommended.',
          time: 'Latest reading',
          category: 'Soil',
          severity: AlertSeverity.critical,
          isResolved: false,
          greenhouseName: greenhouseName,
          recommendedAction:
              'Start irrigation and verify that the soil sensor is working correctly.',
        ),
      );
    } else if (soilMoisture != null && soilMoisture < 40) {
      alerts.add(
        AlertItem(
          title: 'Low Soil Moisture',
          message:
              'Soil moisture is ${soilMoisture.toStringAsFixed(0)}%. Irrigation may be needed soon.',
          time: 'Latest reading',
          category: 'Soil',
          severity: AlertSeverity.warning,
          isResolved: false,
          greenhouseName: greenhouseName,
          recommendedAction:
              'Schedule irrigation if soil moisture continues to decrease.',
        ),
      );
    }

    if (humidity != null && humidity > 85) {
      alerts.add(
        AlertItem(
          title: 'High Humidity',
          message:
              'Humidity reached ${humidity.toStringAsFixed(0)}%. Fungal disease risk may increase.',
          time: 'Latest reading',
          category: 'Humidity',
          severity: AlertSeverity.warning,
          isResolved: false,
          greenhouseName: greenhouseName,
          recommendedAction:
              'Improve air circulation and monitor leaf wetness conditions.',
        ),
      );
    }

    if (co2 != null && co2 > 1200) {
      alerts.add(
        AlertItem(
          title: 'High CO₂ Level',
          message:
              'CO₂ level is ${co2.toStringAsFixed(0)} ppm. Air quality should be checked.',
          time: 'Latest reading',
          category: 'CO₂',
          severity: AlertSeverity.warning,
          isResolved: false,
          greenhouseName: greenhouseName,
          recommendedAction:
              'Check ventilation and validate the CO₂ sensor reading.',
        ),
      );
    }

    if (battery != null && battery < 20) {
      alerts.add(
        AlertItem(
          title: 'Critical Battery Level',
          message:
              'Device battery is ${battery.toStringAsFixed(0)}%. The device may stop sending telemetry soon.',
          time: 'Latest reading',
          category: 'Battery',
          severity: AlertSeverity.critical,
          isResolved: false,
          greenhouseName: greenhouseName,
          recommendedAction:
              'Recharge or replace the battery as soon as possible.',
        ),
      );
    } else if (battery != null && battery < 40) {
      alerts.add(
        AlertItem(
          title: 'Low Battery',
          message:
              'Device battery is ${battery.toStringAsFixed(0)}%. Battery level should be monitored.',
          time: 'Latest reading',
          category: 'Battery',
          severity: AlertSeverity.warning,
          isResolved: false,
          greenhouseName: greenhouseName,
          recommendedAction:
              'Plan battery replacement or check the power source.',
        ),
      );
    }

    if (alerts.isEmpty) {
      alerts.add(
        AlertItem(
          title: 'System Stable',
          message:
              'No critical or warning conditions were detected in the latest telemetry reading.',
          time: 'Latest reading',
          category: 'System',
          severity: AlertSeverity.info,
          isResolved: false,
          greenhouseName: greenhouseName,
          recommendedAction:
              'Continue monitoring greenhouse conditions regularly.',
        ),
      );
    }

    return alerts;
  }
}

class _AlertsContent extends StatelessWidget {
  final String greenhouseName;
  final String? location;
  final List<AlertItem> alerts;
  final List<AlertItem> filteredAlerts;
  final int selectedFilter;
  final ValueChanged<int> onFilterChanged;
  final VoidCallback onSelectGreenhouse;

  const _AlertsContent({
    required this.greenhouseName,
    required this.location,
    required this.alerts,
    required this.filteredAlerts,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onSelectGreenhouse,
  });

  @override
  Widget build(BuildContext context) {
    final activeAlertsCount = alerts.where((alert) => !alert.isResolved).length;
    final criticalAlertsCount = alerts
        .where(
          (alert) =>
              alert.severity == AlertSeverity.critical && !alert.isResolved,
        )
        .length;
    final warningAlertsCount = alerts
        .where(
          (alert) =>
              alert.severity == AlertSeverity.warning && !alert.isResolved,
        )
        .length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _AlertsHeader(
          greenhouseName: greenhouseName,
          location: location,
          onSelectGreenhouse: onSelectGreenhouse,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Active Alerts',
                value: activeAlertsCount.toString(),
                subtitle: 'Need attention',
                icon: Icons.warning_amber_rounded,
                color: Colors.orangeAccent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _SummaryCard(
                title: 'Critical',
                value: criticalAlertsCount.toString(),
                subtitle: 'Immediate action',
                icon: Icons.error_outline,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SummaryWideCard(
          warningCount: warningAlertsCount,
          totalCount: alerts.length,
        ),
        const SizedBox(height: 24),
        _FilterTabs(
          selectedFilter: selectedFilter,
          onChanged: onFilterChanged,
        ),
        const SizedBox(height: 24),
        const Text(
          'RECENT ALERTS',
          style: TextStyle(
            color: AppColors.textGrey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 14),
        if (filteredAlerts.isEmpty)
          const _NoFilteredAlertsCard()
        else
          ...filteredAlerts.map(
            (alert) => _AlertCard(alert: alert),
          ),
      ],
    );
  }
}

class _AlertsHeader extends StatelessWidget {
  final String greenhouseName;
  final String? location;
  final VoidCallback onSelectGreenhouse;

  const _AlertsHeader({
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
                'Alert Center',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Alerts',
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
            Icons.notifications_active_outlined,
            color: AppColors.neonGreen,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryWideCard extends StatelessWidget {
  final int warningCount;
  final int totalCount;

  const _SummaryWideCard({
    required this.warningCount,
    required this.totalCount,
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
        children: [
          const Icon(
            Icons.monitor_heart_rounded,
            color: AppColors.neonGreen,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              warningCount == 0
                  ? 'No warning-level problems detected in the selected greenhouse.'
                  : '$warningCount warning-level condition detected. Review alert cards below.',
              style: const TextStyle(
                color: AppColors.textGrey,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$totalCount total',
            style: const TextStyle(
              color: AppColors.neonGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final int selectedFilter;
  final ValueChanged<int> onChanged;

  const _FilterTabs({
    required this.selectedFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _FilterItem(
            index: 0,
            label: 'All',
            selectedFilter: selectedFilter,
            onTap: onChanged,
          ),
          _FilterItem(
            index: 1,
            label: 'Critical',
            selectedFilter: selectedFilter,
            onTap: onChanged,
          ),
          _FilterItem(
            index: 2,
            label: 'Warning',
            selectedFilter: selectedFilter,
            onTap: onChanged,
          ),
          _FilterItem(
            index: 3,
            label: 'Resolved',
            selectedFilter: selectedFilter,
            onTap: onChanged,
          ),
        ],
      ),
    );
  }
}

class _FilterItem extends StatelessWidget {
  final int index;
  final String label;
  final int selectedFilter;
  final ValueChanged<int> onTap;

  const _FilterItem({
    required this.index,
    required this.label,
    required this.selectedFilter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedFilter == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.neonGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
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

class _AlertCard extends StatelessWidget {
  final AlertItem alert;

  const _AlertCard({
    required this.alert,
  });

  @override
  Widget build(BuildContext context) {
    final severityData = _getSeverityData(alert.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: alert.isResolved
              ? AppColors.textGrey.withOpacity(0.1)
              : severityData.color.withOpacity(0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: severityData.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  severityData.icon,
                  color: severityData.color,
                  size: 23,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: TextStyle(
                        color: alert.isResolved ? Colors.white70 : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${alert.greenhouseName} • ${alert.category}',
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _SeverityBadge(data: severityData),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            alert.message,
            style: TextStyle(
              color: alert.isResolved ? Colors.white54 : Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.tips_and_updates_rounded,
                  color: AppColors.neonGreen,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    alert.recommendedAction,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      height: 1.35,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                color: AppColors.textGrey,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                alert.time,
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _SeverityData _getSeverityData(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return const _SeverityData(
          label: 'Critical',
          color: Colors.redAccent,
          icon: Icons.error_outline,
        );
      case AlertSeverity.warning:
        return const _SeverityData(
          label: 'Warning',
          color: Colors.orangeAccent,
          icon: Icons.warning_amber_rounded,
        );
      case AlertSeverity.info:
        return const _SeverityData(
          label: 'Info',
          color: Colors.lightBlueAccent,
          icon: Icons.info_outline,
        );
    }
  }
}

class _SeverityBadge extends StatelessWidget {
  final _SeverityData data;

  const _SeverityBadge({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        data.label,
        style: TextStyle(
          color: data.color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _NoFilteredAlertsCard extends StatelessWidget {
  const _NoFilteredAlertsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 40,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.neonGreen.withOpacity(0.12),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.neonGreen,
            size: 34,
          ),
          SizedBox(height: 16),
          Text(
            'No alerts found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'There are no alerts matching the selected filter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _EmptyState({
    required this.title,
    required this.message,
    required this.icon,
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

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.redAccent,
        ),
      ),
    );
  }
}

class _SeverityData {
  final String label;
  final Color color;
  final IconData icon;

  const _SeverityData({
    required this.label,
    required this.color,
    required this.icon,
  });
}