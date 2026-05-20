import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ControlTile extends StatelessWidget {
  final String title;
  final bool isActive;
  final IconData icon;
  final ValueChanged<bool> onChanged;

  const ControlTile({
    super.key,
    required this.title,
    required this.isActive,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardGrey,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isActive 
            ? AppColors.neonGreen.withValues(alpha: 0.3) 
            : Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon, 
                color: isActive ? AppColors.neonGreen : AppColors.textGrey, 
                size: 28
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: isActive,
                  onChanged: onChanged,
                  activeThumbColor: AppColors.neonGreen,
                  activeTrackColor: AppColors.neonGreen.withValues(alpha: 0.2),
                  inactiveThumbColor: AppColors.textGrey,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isActive ? "ON" : "OFF",
                style: TextStyle(
                  color: isActive ? AppColors.neonGreen : AppColors.textGrey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
