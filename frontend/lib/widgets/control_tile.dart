import 'package:flutter/material.dart';
import '../core/constants.dart';

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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardGrey,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive ? AppColors.neonGreen.withOpacity(0.5) : AppColors.borderWhite,
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
              // Tasarımdaki küçük yuvarlak anahtar (Switch yerine daha minimal)
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: isActive,
                  onChanged: onChanged,
                  activeColor: AppColors.neonGreen,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 13,
                  letterSpacing: 0.5
                ),
              ),
              const SizedBox(height: 2),
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