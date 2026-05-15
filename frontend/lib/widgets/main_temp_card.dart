import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:greenhouse_app/core/providers/device_provider.dart';
import '../core/constants.dart';

class MainTempCard extends StatelessWidget {
  final String? deviceId;
  const MainTempCard({super.key, this.deviceId});

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final telemetry = deviceId != null ? deviceProvider.latestTelemetry[deviceId] : null;
    final tempStr = telemetry?.temperature != null ? "${telemetry!.temperature!.toStringAsFixed(1)}°C" : "--°C";

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
              Text(tempStr, style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  const Text("Target: 22°C - 26°C", style: TextStyle(color: AppColors.textGrey, fontSize: 14)),
                  const SizedBox(width: 8),
                  if (telemetry != null)
                    const Icon(Icons.sync, color: AppColors.neonGreen, size: 12),
                ],
              ),
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
                child: Column(
                  children: [
                    Text("Status: ${telemetry != null ? 'Online' : '--'}", 
                      style: const TextStyle(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (telemetry?.timestamp != null)
                Text(
                  "Last: ${telemetry!.timestamp!.hour.toString().padLeft(2, '0')}:${telemetry!.timestamp!.minute.toString().padLeft(2, '0')}:${telemetry!.timestamp!.second.toString().padLeft(2, '0')}",
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 10),
                ),
              const SizedBox(height: 10),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 70, height: 70,
                    child: CircularProgressIndicator(
                      value: telemetry?.temperature != null ? (telemetry!.temperature! / 50.0).clamp(0.0, 1.0) : 0, strokeWidth: 8, color: AppColors.neonGreen, backgroundColor: Colors.white10,
                    ),
                  ),
                  Text(telemetry != null ? "Optimal" : "--", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}