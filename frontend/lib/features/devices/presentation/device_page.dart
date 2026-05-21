import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../greenhouse/presentation/greenhouse_controller.dart';
import '../../greenhouse/presentation/greenhouse_selector_sheet.dart';
import '../../greenhouse/presentation/selected_greenhouse_provider.dart';
import 'add_device_page.dart';
import 'device_controller.dart';
import 'device_detail_page.dart';
import '../domain/device.dart';

class DevicesPage extends ConsumerWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greenhousesAsync = ref.watch(greenhousesProvider);

    return GradientScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 105),
          child: greenhousesAsync.when(
            data: (greenhouses) {
              if (greenhouses.isEmpty) {
                return const _EmptyDevicesState(
                  title: 'No Greenhouse Found',
                  message: 'Please add a greenhouse before managing devices.',
                  icon: Icons.eco_outlined,
                );
              }

              final activeGreenhouse =
                  ref.watch(selectedGreenhouseProvider) ?? greenhouses.first;

              final devicesAsync = ref.watch(
                devicesProvider(activeGreenhouse.id),
              );

              return devicesAsync.when(
                data: (devices) {
                  final totalDevices = devices.length;
                  final onlineDevices = devices
                      .where((device) => device.status == 'online')
                      .length;
                  final offlineDevices = devices
                      .where((device) => device.status != 'online')
                      .length;

                  return RefreshIndicator(
                    color: AppColors.neonGreen,
                    onRefresh: () async {
                      ref.invalidate(greenhousesProvider);
                      await ref
                          .read(devicesProvider(activeGreenhouse.id).notifier)
                          .refresh();
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        _DevicesHeader(
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

                        _DeviceSummaryCard(
                          totalDevices: totalDevices,
                          onlineDevices: onlineDevices,
                          offlineDevices: offlineDevices,
                        ),

                        const SizedBox(height: 22),

                        _SectionHeader(
                          title: 'Connected Devices',
                          subtitle:
                              'Monitor sensor nodes linked to your selected greenhouse.',
                          actionLabel: 'Add Device',
                          onActionTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddDevicePage(
                                  greenhouseId: activeGreenhouse.id,
                                  greenhouseName: activeGreenhouse.name,
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 14),

                        if (devices.isEmpty)
                          const _EmptyDevicesState(
                            title: 'No Devices Added',
                            message:
                                'There are no devices linked to this greenhouse yet.',
                            icon: Icons.memory_outlined,
                          )
                        else
                          ...devices.map(
                            (device) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _DeviceCard(
                                device: device,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DeviceDetailPage(device: device),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                        const SizedBox(height: 18),

                        const _DeviceInfoPanel(),
                      ],
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

class _DevicesHeader extends StatelessWidget {
  final String greenhouseName;
  final String? location;
  final VoidCallback onSelectGreenhouse;

  const _DevicesHeader({
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
                'Device Management',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Devices',
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
            Icons.sensors_rounded,
            color: AppColors.neonGreen,
          ),
        ),
      ],
    );
  }
}

class _DeviceSummaryCard extends StatelessWidget {
  final int totalDevices;
  final int onlineDevices;
  final int offlineDevices;

  const _DeviceSummaryCard({
    required this.totalDevices,
    required this.onlineDevices,
    required this.offlineDevices,
  });

  @override
  Widget build(BuildContext context) {
    final systemStatus = totalDevices == 0
        ? 'No Devices'
        : offlineDevices == 0
            ? 'All Systems Online'
            : 'Attention Needed';

    final statusColor = totalDevices == 0
        ? Colors.orangeAccent
        : offlineDevices == 0
            ? AppColors.neonGreen
            : Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: statusColor.withOpacity(0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 24,
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
                icon: Icons.hub_rounded,
                color: statusColor,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      systemStatus,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Device connectivity overview',
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Total',
                  value: totalDevices.toString(),
                  icon: Icons.sensors_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  label: 'Online',
                  value: onlineDevices.toString(),
                  icon: Icons.wifi_tethering_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  label: 'Offline',
                  value: offlineDevices.toString(),
                  icon: Icons.wifi_off_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onTap;

  const _DeviceCard({
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = device.status == 'online';
    final statusColor = isOnline ? AppColors.neonGreen : Colors.orangeAccent;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: statusColor.withOpacity(0.24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _DeviceIcon(isOnline: isOnline),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Serial: ${device.serialNumber}',
                          style: const TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusBadge(
                    status: device.status,
                    color: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _DeviceMetaTile(
                      label: 'Type',
                      value: device.deviceType,
                      icon: Icons.memory_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DeviceMetaTile(
                      label: 'Firmware',
                      value: device.firmwareVersion ?? 'N/A',
                      icon: Icons.system_update_alt_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    isOnline
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    color: statusColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isOnline
                          ? 'Device is connected and ready to send telemetry.'
                          : 'Device is not currently online.',
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textGrey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceIcon extends StatelessWidget {
  final bool isOnline;

  const _DeviceIcon({
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? AppColors.neonGreen : AppColors.textGrey;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        Icons.sensors_rounded,
        color: color,
        size: 30,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DeviceMetaTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DeviceMetaTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.neonGreen,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
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

class _DeviceInfoPanel extends StatelessWidget {
  const _DeviceInfoPanel();

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
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.neonGreen,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Devices collect sensor data such as temperature, humidity, soil moisture, light intensity, CO₂ and battery level. Use Add Device to register an ESP32 sensor node manually or by scanning its QR code.',
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onActionTap;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
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
          ),
        ),
        TextButton.icon(
          onPressed: onActionTap,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(actionLabel),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.neonGreen,
          ),
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
        horizontal: 10,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.neonGreen,
            size: 22,
          ),
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

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        icon,
        color: color,
        size: 28,
      ),
    );
  }
}

class _EmptyDevicesState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _EmptyDevicesState({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppColors.textGrey,
              size: 68,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textGrey,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}