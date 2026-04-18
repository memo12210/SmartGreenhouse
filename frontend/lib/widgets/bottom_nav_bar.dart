import 'package:flutter/material.dart';
import '../core/constants.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.cardGrey,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_filled, "Home", 0),
          _navItem(Icons.analytics_outlined, "Analytics", 1),
          const SizedBox(width: 40),
          _navItem(Icons.notifications_none, "Alerts", 2),
          _navItem(Icons.person_outline, "Profile", 3),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? AppColors.neonGreen : AppColors.textGrey, size: 24),
          Text(label, style: TextStyle(color: isSelected ? AppColors.neonGreen : AppColors.textGrey, fontSize: 10)),
        ],
      ),
    );
  }
}