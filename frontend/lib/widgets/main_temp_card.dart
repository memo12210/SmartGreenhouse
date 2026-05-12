import 'package:flutter/material.dart';
import '../core/constants.dart';

class MainTempCard extends StatelessWidget {
  const MainTempCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.neonGreen.withOpacity(0.15),
            AppColors.cardGrey,
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.borderWhite),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.thermostat, color: AppColors.neonGreen, size: 20),
                  SizedBox(width: 8),
                  Text("TEMPERATURE", 
                    style: TextStyle(color: AppColors.textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              const Text("--°C", style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold)),
              const Text("Target: --°C - --°C", style: TextStyle(color: AppColors.textGrey, fontSize: 14)),
            ],
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text("Status: --", style: TextStyle(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(
                    width: 70, height: 70,
                    child: CircularProgressIndicator(
                      value: 0, strokeWidth: 8, color: AppColors.neonGreen, backgroundColor: Colors.white10,
                    ),
                  ),
                  const Text("--", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}