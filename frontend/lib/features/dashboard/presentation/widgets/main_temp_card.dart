import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class MainTempCard extends StatelessWidget {
  final double? temperature;
  final String status;
  final String? targetRange;

  const MainTempCard({
    super.key,
    this.temperature,
    this.status = '--',
    this.targetRange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2D4021),
            const Color(0xFF13190E),
          ],
        ),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.thermostat, color: AppColors.neonGreen, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "TEMPERATURE",
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textGrey,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                temperature != null ? "${temperature!.toStringAsFixed(0)}°C" : "--°C",
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 80,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Target: ${targetRange ?? '--°C - --°C'}",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.neonGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Status: $status",
                style: const TextStyle(
                  color: AppColors.neonGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 6,
                ),
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(radius: 2, backgroundColor: AppColors.textGrey),
                    SizedBox(width: 4),
                    CircleAvatar(radius: 2, backgroundColor: AppColors.textGrey),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
