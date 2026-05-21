import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../devices/presentation/device_controller.dart';
import '../../greenhouse/domain/greenhouse.dart';
import '../../greenhouse/presentation/add_greenhouse_page.dart';
import '../../greenhouse/presentation/greenhouse_controller.dart';
import '../../greenhouse/presentation/greenhouse_selector_sheet.dart';
import '../../greenhouse/presentation/selected_greenhouse_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  double maxTemp = 30.0;
  double minHumid = 45.0;
  bool pushNotifications = true;
  bool criticalAlerts = true;
  bool dailySummary = false;
  String temperatureUnit = 'Celsius';

  @override
  Widget build(BuildContext context) {
    final greenhousesAsync = ref.watch(greenhousesProvider);

    return GradientScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          child: greenhousesAsync.when(
            data: (greenhouses) {
              final selectedGreenhouse = ref.watch(selectedGreenhouseProvider);
              final activeGreenhouse = selectedGreenhouse ??
                  (greenhouses.isNotEmpty ? greenhouses.first : null);

              final devicesAsync = activeGreenhouse == null
                  ? null
                  : ref.watch(devicesProvider(activeGreenhouse.id));

              final deviceCount = devicesAsync?.maybeWhen(
                    data: (devices) => devices.length,
                    orElse: () => 0,
                  ) ??
                  0;

              final onlineDeviceCount = devicesAsync?.maybeWhen(
                    data: (devices) =>
                        devices.where((device) => device.status == 'online').length,
                    orElse: () => 0,
                  ) ??
                  0;

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _SettingsHeader(
                    greenhouseName: activeGreenhouse?.name,
                    location: activeGreenhouse?.location,
                    onSelectGreenhouse: greenhouses.isEmpty
                        ? null
                        : () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (_) => const GreenhouseSelectorSheet(),
                            );
                          },
                  ),

                  const SizedBox(height: 24),

                  _ProfileCard(
                    greenhouseCount: greenhouses.length,
                    deviceCount: deviceCount,
                    onlineDeviceCount: onlineDeviceCount,
                  ),

                  const SizedBox(height: 24),

                  _SectionTitle(
                    title: 'System Status',
                    subtitle: 'Live service and connectivity overview.',
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _StatusCard(
                          title: 'Backend',
                          value: 'Online',
                          icon: Icons.cloud_done_rounded,
                          color: AppColors.neonGreen,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _StatusCard(
                          title: 'Database',
                          value: 'Synced',
                          icon: Icons.storage_rounded,
                          color: AppColors.neonGreen,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _StatusCard(
                          title: 'MQTT',
                          value: 'Ready',
                          icon: Icons.hub_rounded,
                          color: AppColors.neonGreen,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _StatusCard(
                          title: 'Telemetry',
                          value: deviceCount > 0 ? 'Active' : 'Waiting',
                          icon: Icons.monitor_heart_rounded,
                          color: deviceCount > 0
                              ? AppColors.neonGreen
                              : Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _SectionTitle(
                    title: 'My Greenhouses',
                    subtitle: 'Manage greenhouse profiles linked to your account.',
                  ),
                  const SizedBox(height: 14),

                  if (greenhouses.isEmpty)
                    const _EmptyGreenhouseCard()
                  else
                    ...greenhouses.map(
                      (greenhouse) => _GreenhouseCard(
                        greenhouse: greenhouse,
                        isSelected: activeGreenhouse?.id == greenhouse.id,
                        onSelect: () {
                          ref.read(selectedGreenhouseIdProvider.notifier).state =
                              greenhouse.id;
                        },
                        onDelete: () {
                          _confirmDeleteGreenhouse(context, greenhouse);
                        },
                      ),
                    ),

                  const SizedBox(height: 12),

                  _OutlineActionButton(
                    icon: Icons.add_circle_outline_rounded,
                    text: 'Add Greenhouse',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddGreenhousePage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  _SectionTitle(
                    title: 'Alert Preferences',
                    subtitle: 'Control how the system notifies you.',
                  ),
                  const SizedBox(height: 14),

                  _SwitchTile(
                    title: 'Push Notifications',
                    subtitle: 'Receive alerts when critical conditions occur.',
                    icon: Icons.notifications_active_outlined,
                    value: pushNotifications,
                    onChanged: (value) {
                      setState(() {
                        pushNotifications = value;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  _SwitchTile(
                    title: 'Critical Alerts',
                    subtitle: 'Always notify for frost, heat, battery and device risks.',
                    icon: Icons.warning_amber_rounded,
                    value: criticalAlerts,
                    onChanged: (value) {
                      setState(() {
                        criticalAlerts = value;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  _SwitchTile(
                    title: 'Daily Summary',
                    subtitle: 'Receive a daily greenhouse condition summary.',
                    icon: Icons.summarize_rounded,
                    value: dailySummary,
                    onChanged: (value) {
                      setState(() {
                        dailySummary = value;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  _SectionTitle(
                    title: 'Global Thresholds',
                    subtitle: 'Default alert thresholds used across greenhouses.',
                  ),
                  const SizedBox(height: 14),

                  _ThresholdSlider(
                    title: 'Max Temperature',
                    value: maxTemp,
                    unit: '°C',
                    color: Colors.orangeAccent,
                    icon: Icons.thermostat_rounded,
                    min: 0,
                    max: 50,
                    onChanged: (value) {
                      setState(() {
                        maxTemp = value;
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  _ThresholdSlider(
                    title: 'Min Humidity',
                    value: minHumid,
                    unit: '%',
                    color: Colors.blueAccent,
                    icon: Icons.water_drop_rounded,
                    min: 0,
                    max: 100,
                    onChanged: (value) {
                      setState(() {
                        minHumid = value;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  _SectionTitle(
                    title: 'Preferences',
                    subtitle: 'Customize application display options.',
                  ),
                  const SizedBox(height: 14),

                  _PreferenceSelector(
                    title: 'Temperature Unit',
                    subtitle: 'Current unit used in sensor readings.',
                    icon: Icons.device_thermostat_rounded,
                    value: temperatureUnit,
                    options: const ['Celsius', 'Fahrenheit'],
                    onChanged: (value) {
                      setState(() {
                        temperatureUnit = value;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  _SectionTitle(
                    title: 'Security',
                    subtitle: 'Account access and session control.',
                  ),
                  const SizedBox(height: 14),

                  _LogoutButton(
                    onTap: () {
                      ref.read(authControllerProvider.notifier).logout();
                    },
                  ),

                  const SizedBox(height: 24),

                  const Center(
                    child: Text(
                      'Smart Greenhouse v2.0.0',
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, _) => Center(
              child: Text(
                'Settings error: $error',
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteGreenhouse(BuildContext context, Greenhouse greenhouse) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('Delete Greenhouse'),
          content: Text(
            'Are you sure you want to delete "${greenhouse.name}"? This action cannot be undone.',
            style: const TextStyle(color: AppColors.textGrey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await ref
                    .read(greenhousesProvider.notifier)
                    .deleteGreenhouse(greenhouse.id);

                final selectedId = ref.read(selectedGreenhouseIdProvider);
                if (selectedId == greenhouse.id) {
                  ref.read(selectedGreenhouseIdProvider.notifier).state = null;
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  final String? greenhouseName;
  final String? location;
  final VoidCallback? onSelectGreenhouse;

  const _SettingsHeader({
    required this.greenhouseName,
    required this.location,
    required this.onSelectGreenhouse,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = greenhouseName == null
        ? 'No greenhouse selected'
        : location == null || location!.isEmpty
            ? greenhouseName!
            : '$greenhouseName • $location';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Account & System',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Profile',
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
                    if (onSelectGreenhouse != null) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textGrey,
                        size: 20,
                      ),
                    ],
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
            Icons.person_rounded,
            color: AppColors.neonGreen,
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final int greenhouseCount;
  final int deviceCount;
  final int onlineDeviceCount;

  const _ProfileCard({
    required this.greenhouseCount,
    required this.deviceCount,
    required this.onlineDeviceCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.neonGreen.withOpacity(0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonGreen.withOpacity(0.08),
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
              color: AppColors.neonGreen.withOpacity(0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.agriculture_rounded,
              color: AppColors.neonGreen,
              size: 32,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Greenhouse Operator',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Smart monitoring account',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _MiniInfo(label: 'Greenhouses', value: '$greenhouseCount'),
                    const SizedBox(width: 14),
                    _MiniInfo(label: 'Devices', value: '$deviceCount'),
                    const SizedBox(width: 14),
                    _MiniInfo(label: 'Online', value: '$onlineDeviceCount'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;

  const _MiniInfo({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.neonGreen,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textGrey,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatusCard({
    required this.title,
    required this.value,
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
          const SizedBox(height: 14),
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
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _GreenhouseCard extends StatelessWidget {
  final Greenhouse greenhouse;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  const _GreenhouseCard({
    required this.greenhouse,
    required this.isSelected,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isSelected
            ? AppColors.neonGreen.withOpacity(0.12)
            : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.energy_savings_leaf_rounded,
                    color: AppColors.neonGreen,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greenhouse.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        greenhouse.location == null ||
                                greenhouse.location!.isEmpty
                            ? 'No location specified'
                            : greenhouse.location!,
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.neonGreen,
                  ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyGreenhouseCard extends StatelessWidget {
  const _EmptyGreenhouseCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.orangeAccent.withOpacity(0.18),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.eco_outlined,
            color: Colors.orangeAccent,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'No greenhouse profile has been added yet.',
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

class _OutlineActionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _OutlineActionButton({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.neonGreen.withOpacity(0.15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: AppColors.neonGreen,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                text,
                style: const TextStyle(
                  color: AppColors.neonGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.neonGreen,
            size: 26,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.neonGreen,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ThresholdSlider extends StatelessWidget {
  final String title;
  final double value;
  final String unit;
  final Color color;
  final IconData icon;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _ThresholdSlider({
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withOpacity(0.14),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${value.toInt()}$unit',
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: color,
            inactiveColor: Colors.white10,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _PreferenceSelector extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _PreferenceSelector({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.neonGreen,
            size: 26,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: value,
            dropdownColor: AppColors.surfaceDark,
            underline: const SizedBox(),
            iconEnabledColor: AppColors.neonGreen,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            items: options
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  ),
                )
                .toList(),
            onChanged: (newValue) {
              if (newValue == null) return;
              onChanged(newValue);
            },
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.redAccent.withOpacity(0.25),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                'Log Out',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
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