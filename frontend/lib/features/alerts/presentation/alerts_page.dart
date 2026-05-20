import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_scaffold.dart';

enum AlertSeverity { critical, warning, info }

class AlertItem {
  final String title;
  final String message;
  final String time;
  final String category;
  final AlertSeverity severity;
  final bool isResolved;
  final String greenhouseName;

  const AlertItem({
    required this.title,
    required this.message,
    required this.time,
    required this.category,
    required this.severity,
    required this.isResolved,
    required this.greenhouseName,
  });
}

class AlertsPage extends ConsumerStatefulWidget {
  const AlertsPage({super.key});

  @override
  ConsumerState<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends ConsumerState<AlertsPage> {
  int selectedFilter = 0; // 0: All, 1: Critical, 2: Warning, 3: Resolved

  final List<AlertItem> alerts = []; // This should eventually come from a provider

  List<AlertItem> get filteredAlerts {
    switch (selectedFilter) {
      case 1:
        return alerts
            .where((alert) =>
                alert.severity == AlertSeverity.critical && !alert.isResolved)
            .toList();
      case 2:
        return alerts
            .where((alert) =>
                alert.severity == AlertSeverity.warning && !alert.isResolved)
            .toList();
      case 3:
        return alerts.where((alert) => alert.isResolved).toList();
      default:
        return alerts;
    }
  }

  int get activeAlertsCount =>
      alerts.where((alert) => !alert.isResolved).length;

  int get criticalAlertsCount => alerts
      .where((alert) =>
          alert.severity == AlertSeverity.critical && !alert.isResolved)
      .length;

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSummaryCards(),
              const SizedBox(height: 24),
              _buildFilterTabs(),
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
                _buildEmptyState()
              else
                ...filteredAlerts.map(_buildAlertCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alerts', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            const Text(
              'Monitor greenhouse warnings and system events',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: const Icon(
            Icons.notifications_active_outlined,
            color: AppColors.neonGreen,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Active Alerts',
            value: activeAlertsCount.toString(),
            subtitle: 'Need attention',
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orangeAccent,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildSummaryCard(
            title: 'Critical',
            value: criticalAlertsCount.toString(),
            subtitle: 'Immediate action',
            icon: Icons.error_outline,
            iconColor: Colors.redAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
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
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildFilterItem(0, 'All'),
          _buildFilterItem(1, 'Critical'),
          _buildFilterItem(2, 'Warning'),
          _buildFilterItem(3, 'Resolved'),
        ],
      ),
    );
  }

  Widget _buildFilterItem(int index, String label) {
    final bool isSelected = selectedFilter == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedFilter = index),
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
              color: isSelected ? Colors.black : Colors.white60,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(AlertItem alert) {
    final severityData = _getSeverityData(alert.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: alert.isResolved
              ? Colors.white.withValues(alpha: 0.06)
              : severityData.color.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: severityData.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(severityData.icon, color: severityData.color, size: 22),
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
                    Text(alert.greenhouseName, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  text: alert.isResolved ? 'View Details' : 'Mark as Resolved',
                  isPrimary: !alert.isResolved,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(text: 'Dismiss', isPrimary: false, onTap: () {}),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.neonGreen : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: isPrimary ? null : Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isPrimary ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline, color: AppColors.neonGreen, size: 30),
          ),
          const SizedBox(height: 16),
          const Text(
            'No alerts found',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'There are no alerts matching the selected filter.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  _SeverityData _getSeverityData(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return const _SeverityData(label: 'Critical', color: Colors.redAccent, icon: Icons.error_outline);
      case AlertSeverity.warning:
        return const _SeverityData(label: 'Warning', color: Colors.orangeAccent, icon: Icons.warning_amber_rounded);
      case AlertSeverity.info:
        return const _SeverityData(label: 'Info', color: Colors.lightBlueAccent, icon: Icons.info_outline);
    }
  }
}

class _SeverityData {
  final String label;
  final Color color;
  final IconData icon;

  const _SeverityData({required this.label, required this.color, required this.icon});
}
