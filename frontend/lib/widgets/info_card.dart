import 'package:flutter/material.dart';
import '../core/constants.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String trend;
  final Color iconColor;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.trend,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderWhite),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 20),
              Text(trend, style: const TextStyle(color: AppColors.neonGreen, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: AppColors.textGrey, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}