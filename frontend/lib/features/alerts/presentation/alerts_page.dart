import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../greenhouse/presentation/greenhouse_controller.dart';
import '../../greenhouse/presentation/selected_greenhouse_provider.dart';
import '../domain/app_alert.dart';
import 'alert_controller.dart';

enum AlertFilter {
  all,
  critical,
  warning,
  info,
  resolved,
}

class AlertsPage extends ConsumerStatefulWidget {
  const AlertsPage({super.key});

  @override
  ConsumerState<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends ConsumerState<AlertsPage> {
  AlertFilter selectedFilter = AlertFilter.all;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.invalidate(greenhousesProvider);
    });
  }

  List<AppAlert> _sortedAlerts(List<AppAlert> alerts) {
    final sorted = [...alerts];

    sorted.sort((a, b) {
      if (a.isAcknowledged != b.isAcknowledged) {
        return a.isAcknowledged ? 1 : -1;
      }

      // Newest first by creation time. Fall back to id when timestamps are
      // missing or equal so ordering stays stable.
      final aTime = a.createdAt;
      final bTime = b.createdAt;
      if (aTime != null && bTime != null && aTime != bTime) {
        return bTime.compareTo(aTime);
      }
      return b.id.compareTo(a.id);
    });

    return sorted;
  }

  List<AppAlert> _filteredAlerts(List<AppAlert> alerts) {
    switch (selectedFilter) {
      case AlertFilter.critical:
        return alerts
            .where(
              (alert) =>
                  alert.severity.toLowerCase() == 'critical' &&
                  !alert.isAcknowledged,
            )
            .toList();

      case AlertFilter.warning:
        return alerts
            .where(
              (alert) =>
                  alert.severity.toLowerCase() == 'warning' &&
                  !alert.isAcknowledged,
            )
            .toList();

      case AlertFilter.info:
        return alerts
            .where(
              (alert) =>
                  alert.severity.toLowerCase() == 'info' &&
                  !alert.isAcknowledged,
            )
            .toList();

      case AlertFilter.resolved:
        return alerts.where((alert) => alert.isAcknowledged).toList();

      case AlertFilter.all:
        return alerts;
    }
  }

  @override
  Widget build(BuildContext context) {
    final greenhousesAsync = ref.watch(greenhousesProvider);

    return GradientScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          child: greenhousesAsync.when(
            data: (greenhouses) {
              if (greenhouses.isEmpty) {
                return const _EmptyState(
                  title: 'No Greenhouse Found',
                  message: 'Add a greenhouse first to start monitoring alerts.',
                  icon: Icons.eco_outlined,
                );
              }

              final activeGreenhouse =
                  ref.watch(selectedGreenhouseProvider) ?? greenhouses.first;
              final alertsAsync = ref.watch(alertsProvider(activeGreenhouse.id));

              return alertsAsync.when(
                data: (alerts) {
                  final sortedAlerts = _sortedAlerts(alerts);
                  final filteredAlerts = _filteredAlerts(sortedAlerts);

                  return RefreshIndicator(
                    color: AppColors.neonGreen,
                    onRefresh: () async {
                      await ref
                          .read(alertsProvider(activeGreenhouse.id).notifier)
                          .refresh();
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        _Header(greenhouseName: activeGreenhouse.name),
                        const SizedBox(height: 24),
                        _SummaryCards(alerts: alerts),
                        const SizedBox(height: 24),
                        _FilterTabs(
                          selectedFilter: selectedFilter,
                          onChanged: (filter) {
                            setState(() {
                              selectedFilter = filter;
                            });
                          },
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
                          _EmptyState(
                            title: 'No alerts found',
                            message: _emptyMessageForFilter(selectedFilter),
                            icon: Icons.check_circle_outline_rounded,
                          )
                        else
                          ...filteredAlerts.map(
                            (alert) => _AlertCard(
                              alert: alert,
                              greenhouseId: activeGreenhouse.id,
                            ),
                          ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => _ErrorState(
                  message: 'Failed to load alerts: $error',
                  onRetry: () {
                    ref.invalidate(alertsProvider(activeGreenhouse.id));
                  },
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, _) => _ErrorState(
              message: 'Failed to load greenhouses: $error',
              onRetry: () {
                ref.invalidate(greenhousesProvider);
              },
            ),
          ),
        ),
      ),
    );
  }

  String _emptyMessageForFilter(AlertFilter filter) {
    switch (filter) {
      case AlertFilter.critical:
        return 'There are no active critical alerts.';
      case AlertFilter.warning:
        return 'There are no active warning alerts.';
      case AlertFilter.info:
        return 'There are no active informational alerts.';
      case AlertFilter.resolved:
        return 'There are no resolved alerts yet.';
      case AlertFilter.all:
        return 'There are no alerts for this greenhouse yet.';
    }
  }
}

class _Header extends StatelessWidget {
  final String greenhouseName;

  const _Header({
    required this.greenhouseName,
  });

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
                'Alert Center',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                greenhouseName,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Backend-driven greenhouse warnings and system events.',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.neonGreen.withValues(alpha: 0.18),
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

class _SummaryCards extends StatelessWidget {
  final List<AppAlert> alerts;

  const _SummaryCards({
    required this.alerts,
  });

  @override
  Widget build(BuildContext context) {
    final activeAlerts = alerts.where((alert) => !alert.isAcknowledged).length;

    final criticalAlerts = alerts
        .where(
          (alert) =>
              alert.severity.toLowerCase() == 'critical' &&
              !alert.isAcknowledged,
        )
        .length;

    final warningAlerts = alerts
        .where(
          (alert) =>
              alert.severity.toLowerCase() == 'warning' &&
              !alert.isAcknowledged,
        )
        .length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Active Alerts',
                value: activeAlerts.toString(),
                subtitle: 'Need attention',
                icon: Icons.warning_amber_rounded,
                iconColor: Colors.orangeAccent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _SummaryCard(
                title: 'Critical',
                value: criticalAlerts.toString(),
                subtitle: 'Immediate action',
                icon: Icons.error_outline_rounded,
                iconColor: Colors.redAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _WideSummaryCard(
          warningAlerts: warningAlerts,
          totalAlerts: alerts.length,
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
  final Color iconColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
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
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 28,
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

class _WideSummaryCard extends StatelessWidget {
  final int warningAlerts;
  final int totalAlerts;

  const _WideSummaryCard({
    required this.warningAlerts,
    required this.totalAlerts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.neonGreen.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.health_and_safety_outlined,
              color: AppColors.neonGreen,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Greenhouse Alert Health',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  totalAlerts == 0
                      ? 'No alert records have been created yet.'
                      : '$warningAlerts active warning alert(s), $totalAlerts total alert record(s).',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                    height: 1.35,
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

class _FilterTabs extends StatelessWidget {
  final AlertFilter selectedFilter;
  final ValueChanged<AlertFilter> onChanged;

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
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _FilterItem(
            label: 'All',
            filter: AlertFilter.all,
            selectedFilter: selectedFilter,
            onTap: onChanged,
          ),
          _FilterItem(
            label: 'Critical',
            filter: AlertFilter.critical,
            selectedFilter: selectedFilter,
            onTap: onChanged,
          ),
          _FilterItem(
            label: 'Warning',
            filter: AlertFilter.warning,
            selectedFilter: selectedFilter,
            onTap: onChanged,
          ),
          _FilterItem(
            label: 'Resolved',
            filter: AlertFilter.resolved,
            selectedFilter: selectedFilter,
            onTap: onChanged,
          ),
        ],
      ),
    );
  }
}

class _FilterItem extends StatelessWidget {
  final String label;
  final AlertFilter filter;
  final AlertFilter selectedFilter;
  final ValueChanged<AlertFilter> onTap;

  const _FilterItem({
    required this.label,
    required this.filter,
    required this.selectedFilter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedFilter == filter;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.neonGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : AppColors.textGrey,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends ConsumerWidget {
  final AppAlert alert;
  final String greenhouseId;

  const _AlertCard({
    required this.alert,
    required this.greenhouseId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final severity = _severityData(alert.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: alert.isAcknowledged
              ? AppColors.textGrey.withValues(alpha: 0.12)
              : severity.color.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: severity.color.withValues(
              alpha: alert.isAcknowledged ? 0 : 0.05,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
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
                  color: severity.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  severity.icon,
                  color: severity.color,
                  size: 23,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleForAlert(alert),
                      style: TextStyle(
                        color: alert.isAcknowledged
                            ? Colors.white70
                            : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.alertType,
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _SeverityBadge(
                label: alert.isAcknowledged ? 'RESOLVED' : severity.label,
                color: alert.isAcknowledged
                    ? AppColors.textGrey
                    : severity.color,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            alert.message,
            style: TextStyle(
              color: alert.isAcknowledged ? Colors.white54 : Colors.white70,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          _AlertMetadata(alert: alert),
          const SizedBox(height: 16),
          if (alert.isAcknowledged)
            _ResolvedInfo(alert: alert)
          else
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    text: 'Mark as Resolved',
                    isPrimary: true,
                    onTap: () => _acknowledge(context, ref),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    text: 'Dismiss',
                    isPrimary: false,
                    danger: true,
                    onTap: () => _dismiss(context, ref),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _titleForAlert(AppAlert alert) {
    final type = alert.alertType.toLowerCase();

    if (type.contains('temperature')) {
      return 'Temperature Warning';
    }
    if (type.contains('humidity')) {
      return 'Humidity Warning';
    }
    if (type.contains('soil')) {
      return 'Soil Moisture Warning';
    }
    if (type.contains('battery')) {
      return 'Battery Warning';
    }
    if (type.contains('light')) {
      return 'Light Intensity Warning';
    }
    if (type.contains('co2')) {
      return 'CO₂ Level Warning';
    }

    return 'Greenhouse Alert';
  }

  Future<void> _acknowledge(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(alertsProvider(greenhouseId).notifier).acknowledgeAlert(
            alertId: alert.id,
            greenhouseId: greenhouseId,
          );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert marked as resolved.'),
          backgroundColor: AppColors.neonGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resolve alert: $error'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _dismiss(BuildContext context, WidgetRef ref) async {
    final shouldDismiss = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text(
            'Dismiss Alert',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'This alert will be removed from the alert center. Are you sure?',
            style: TextStyle(
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
                'Dismiss',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDismiss != true) return;

    try {
      await ref.read(alertsProvider(greenhouseId).notifier).dismissAlert(
            alertId: alert.id,
            greenhouseId: greenhouseId,
          );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert dismissed.'),
          backgroundColor: AppColors.neonGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to dismiss alert: $error'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  _SeverityData _severityData(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const _SeverityData(
          label: 'CRITICAL',
          color: Colors.redAccent,
          icon: Icons.error_outline_rounded,
        );

      case 'info':
        return const _SeverityData(
          label: 'INFO',
          color: Colors.lightBlueAccent,
          icon: Icons.info_outline_rounded,
        );

      case 'warning':
      default:
        return const _SeverityData(
          label: 'WARNING',
          color: Colors.orangeAccent,
          icon: Icons.warning_amber_rounded,
        );
    }
  }
}

class _AlertMetadata extends StatelessWidget {
  final AppAlert alert;

  const _AlertMetadata({
    required this.alert,
  });

  @override
  Widget build(BuildContext context) {
    final valueText =
        alert.value == null ? '--' : alert.value!.toStringAsFixed(1);

    final shortDeviceId = alert.deviceId.length > 8
        ? '${alert.deviceId.substring(0, 8)}...'
        : alert.deviceId;

    final field = alert.extraMetadata['field']?.toString();
    final operatorText = alert.extraMetadata['operator']?.toString();
    final threshold = alert.extraMetadata['threshold']?.toString();
    final time = alert.createdAt;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.neonGreen.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          if (time != null) _MetadataRow(label: 'Time', value: _formatTime(time)),
          _MetadataRow(label: 'Current Value', value: valueText),
          if (field != null) _MetadataRow(label: 'Measured Field', value: field),
          if (operatorText != null && threshold != null)
            _MetadataRow(
              label: 'Threshold',
              value: '$operatorText $threshold',
            ),
          _MetadataRow(label: 'Device ID', value: shortDeviceId),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}';
  }
}

class _MetadataRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetadataRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textGrey,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResolvedInfo extends StatelessWidget {
  final AppAlert alert;

  const _ResolvedInfo({
    required this.alert,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.neonGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.neonGreen,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This alert has been resolved.',
              style: TextStyle(
                color: AppColors.neonGreen,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _SeverityBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final bool isPrimary;
  final bool danger;
  final VoidCallback onTap;

  const _ActionButton({
    required this.text,
    required this.isPrimary,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.redAccent : AppColors.neonGreen;

    return Material(
      color:
          isPrimary ? AppColors.neonGreen : Colors.black.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: isPrimary
                ? null
                : Border.all(
                    color: color.withValues(alpha: 0.18),
                  ),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isPrimary ? Colors.black : color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
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
    return Center(
      child: ListView(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppColors.neonGreen.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: AppColors.neonGreen,
                  size: 44,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    height: 1.45,
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.redAccent.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 42,
            ),
            const SizedBox(height: 14),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textGrey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
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