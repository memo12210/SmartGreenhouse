import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_navigation_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../devices/presentation/device_controller.dart';
import '../../greenhouse/presentation/add_greenhouse_page.dart';
import '../../greenhouse/presentation/greenhouse_controller.dart';
import '../../greenhouse/presentation/greenhouse_selector_sheet.dart';
import '../../greenhouse/presentation/selected_greenhouse_provider.dart';
import '../../telemetry/presentation/telemetry_controller.dart';

class DashboardPage extends ConsumerWidget {
  final VoidCallback? onNavigateToDevices;

  const DashboardPage({
    super.key,
    this.onNavigateToDevices,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greenhousesAsync = ref.watch(greenhousesProvider);

    return GradientScaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.neonGreen,
          onRefresh: () async {
            ref.invalidate(greenhousesProvider);
          },
          child: greenhousesAsync.when(
            data: (greenhouses) {
              if (greenhouses.isEmpty) {
                return const _EmptyGreenhouseState();
              }

              final activeGreenhouse =
                  ref.watch(selectedGreenhouseProvider) ?? greenhouses.first;

              final devicesAsync = ref.watch(
                devicesProvider(activeGreenhouse.id),
              );

              return devicesAsync.when(
                data: (devices) {
                  final primaryDevice =
                      devices.isNotEmpty ? devices.first : null;

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                    children: [
                      _DashboardHeader(
                        greenhouseName: activeGreenhouse.name,
                        location: activeGreenhouse.location,
                        onSelectGreenhouse: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (_) => const GreenhouseSelectorSheet(),
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      _GreenhouseHealthCard(
                        greenhouseName: activeGreenhouse.name,
                        deviceCount: devices.length,
                        onlineDeviceCount: devices
                            .where((device) => device.status == 'online')
                            .length,
                        hasDevice: primaryDevice != null,
                      ),
                      const SizedBox(height: 22),
                      if (primaryDevice == null)
                        const _NoDeviceCard()
                      else
                        _TelemetryOverviewSection(
                          deviceId: primaryDevice.id,
                          deviceName: primaryDevice.name,
                          deviceStatus: primaryDevice.status,
                        ),
                      const SizedBox(height: 22),
                      _TodayRecommendationCard(
                        hasDevice: primaryDevice != null,
                      ),
                      const SizedBox(height: 22),
                      _QuickActionsSection(
                        onAddGreenhouse: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddGreenhousePage(),
                            ),
                          );
                        },
                        onViewDevices: onNavigateToDevices,
                      ),
                    ],
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
}

class _DashboardHeader extends StatelessWidget {
  final String greenhouseName;
  final String? location;
  final VoidCallback onSelectGreenhouse;

  const _DashboardHeader({
    required this.greenhouseName,
    required this.location,
    required this.onSelectGreenhouse,
  });

  @override
  Widget build(BuildContext context) {
    final greenhouseLabel = location == null || location!.isEmpty
        ? greenhouseName
        : '$greenhouseName • $location';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Greenhouse Overview',
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
                    Flexible(
                      child: Text(
                        greenhouseLabel,
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
        Material(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: AppNavigationController.goToAlerts,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.neonGreen.withValues(alpha: 0.18),
                ),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.neonGreen,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GreenhouseHealthCard extends StatelessWidget {
  final String greenhouseName;
  final int deviceCount;
  final int onlineDeviceCount;
  final bool hasDevice;

  const _GreenhouseHealthCard({
    required this.greenhouseName,
    required this.deviceCount,
    required this.onlineDeviceCount,
    required this.hasDevice,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = hasDevice ? 'Stable' : 'Setup Required';
    final statusDescription = hasDevice
        ? 'Your greenhouse is operating within a normal range.'
        : 'Add a device to start monitoring this greenhouse.';
    final statusColor = hasDevice ? AppColors.neonGreen : Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.08),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(
                icon: Icons.health_and_safety_rounded,
                color: statusColor,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Greenhouse Health',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      greenhouseName,
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            statusDescription,
            style: const TextStyle(
              color: AppColors.textGrey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Devices',
                  value: deviceCount.toString(),
                  icon: Icons.sensors_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  label: 'Online',
                  value: onlineDeviceCount.toString(),
                  icon: Icons.wifi_tethering_rounded,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: _MiniStat(
                  label: 'Sync',
                  value: 'Live',
                  icon: Icons.sync_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TelemetryOverviewSection extends ConsumerWidget {
  final String deviceId;
  final String deviceName;
  final String deviceStatus;

  const _TelemetryOverviewSection({
    required this.deviceId,
    required this.deviceName,
    required this.deviceStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetryAsync = ref.watch(latestTelemetryProvider(deviceId));

    return telemetryAsync.when(
      data: (telemetry) {
        final hasData = telemetry != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              title: 'Live Sensor Overview',
              subtitle: hasData
                  ? '$deviceName • ${deviceStatus.toUpperCase()}'
                  : '$deviceName • Waiting for telemetry',
            ),
            const SizedBox(height: 14),
            _MainTemperatureCard(
              temperature: telemetry?.temperature,
              hasData: hasData,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SensorMetricCard(
                    title: 'Humidity',
                    value: telemetry?.humidity,
                    unit: '%',
                    icon: Icons.water_drop_rounded,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _SensorMetricCard(
                    title: 'Soil',
                    value: telemetry?.soilMoisture,
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
                  child: _SensorMetricCard(
                    title: 'Light',
                    value: telemetry?.lightIntensity,
                    unit: 'lx',
                    icon: Icons.wb_sunny_rounded,
                    color: Colors.orangeAccent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _SensorMetricCard(
                    title: 'CO₂',
                    value: telemetry?.co2,
                    unit: 'ppm',
                    icon: Icons.cloud_rounded,
                    color: Colors.purpleAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _BatteryStatusCard(
              batteryLevel: telemetry?.batteryLevel,
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => _ErrorState(
        message: 'Telemetry error: $error',
      ),
    );
  }
}

class _MainTemperatureCard extends StatelessWidget {
  final double? temperature;
  final bool hasData;

  const _MainTemperatureCard({
    required this.temperature,
    required this.hasData,
  });

  @override
  Widget build(BuildContext context) {
    final tempText = temperature == null ? '--' : temperature!.toStringAsFixed(1);

    final status = !hasData
        ? 'Waiting for data'
        : temperature! >= 18 && temperature! <= 30
            ? 'Optimal'
            : 'Attention needed';

    final statusColor =
        status == 'Optimal' ? AppColors.neonGreen : Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.neonGreen.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          _IconBadge(
            icon: Icons.thermostat_rounded,
            color: statusColor,
            size: 64,
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
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: tempText,
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      const TextSpan(
                        text: ' °C',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
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

class _SensorMetricCard extends StatelessWidget {
  final String title;
  final double? value;
  final String unit;
  final IconData icon;
  final Color color;

  const _SensorMetricCard({
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
          color: color.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
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

class _BatteryStatusCard extends StatelessWidget {
  final double? batteryLevel;

  const _BatteryStatusCard({
    required this.batteryLevel,
  });

  @override
  Widget build(BuildContext context) {
    final batteryText =
        batteryLevel == null ? '--' : batteryLevel!.toStringAsFixed(0);
    final isHealthy = batteryLevel == null || batteryLevel! >= 40;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isHealthy
              ? AppColors.neonGreen.withValues(alpha: 0.18)
              : Colors.redAccent.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isHealthy
                ? Icons.battery_charging_full_rounded
                : Icons.battery_alert_rounded,
            color: isHealthy ? AppColors.neonGreen : Colors.redAccent,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Device Battery',
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
              color: isHealthy ? AppColors.neonGreen : Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayRecommendationCard extends StatelessWidget {
  final bool hasDevice;

  const _TodayRecommendationCard({
    required this.hasDevice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.orangeAccent.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBadge(
            icon: Icons.tips_and_updates_rounded,
            color: Colors.orangeAccent,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasDevice ? 'Today’s Recommendation' : 'Setup Recommendation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasDevice
                      ? 'Monitor soil moisture and ventilation during warmer hours. Conditions are currently stable.'
                      : 'Add your first ESP32 sensor device to activate live monitoring and smart recommendations.',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    height: 1.4,
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

class _QuickActionsSection extends StatelessWidget {
  final VoidCallback onAddGreenhouse;
  final VoidCallback? onViewDevices;

  const _QuickActionsSection({
    required this.onAddGreenhouse,
    required this.onViewDevices,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Quick Actions',
          subtitle: 'Manage your greenhouse system faster.',
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.add_rounded,
                label: 'Add Greenhouse',
                onTap: onAddGreenhouse,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _ActionButton(
                icon: Icons.sensors_rounded,
                label: 'View Devices',
                onTap: onViewDevices ?? () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Icon(icon, color: AppColors.neonGreen),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoDeviceCard extends StatelessWidget {
  const _NoDeviceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.orangeAccent.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          _IconBadge(
            icon: Icons.sensors_off_rounded,
            color: Colors.orangeAccent,
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'No device is linked to this greenhouse yet. Add a device to start receiving live telemetry.',
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

class _EmptyGreenhouseState extends StatelessWidget {
  const _EmptyGreenhouseState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 120),
      children: [
        const Icon(
          Icons.eco_outlined,
          color: AppColors.neonGreen,
          size: 76,
        ),
        const SizedBox(height: 24),
        Text(
          'No Greenhouses Added',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Add your first greenhouse to start monitoring sensor data, device status, and smart recommendations.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textGrey,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddGreenhousePage(),
              ),
            );
          },
          child: const Text('Add Greenhouse'),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.neonGreen, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
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

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _IconBadge({
    required this.icon,
    required this.color,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.48,
      ),
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