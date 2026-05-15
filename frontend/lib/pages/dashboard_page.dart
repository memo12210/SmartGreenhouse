import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:greenhouse_app/core/constants.dart';
import 'package:greenhouse_app/core/models.dart';
import 'package:greenhouse_app/core/providers/greenhouse_provider.dart';
import 'package:greenhouse_app/core/providers/device_provider.dart';
import 'package:greenhouse_app/widgets/info_card.dart';
import 'package:greenhouse_app/widgets/main_temp_card.dart';
import 'package:greenhouse_app/widgets/control_tile.dart';
import 'package:greenhouse_app/widgets/alert_card.dart';
import 'package:greenhouse_app/widgets/gradient_background.dart';
import 'add_greenhouse_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Kontrol durumları
  bool isFanActive = false;
  bool isIrrigationActive = false;
  bool isLightsActive = false;
  bool isHeaterActive = false;

  Timer? _telemetryTimer;

  @override
  void initState() {
    super.initState();
    _startTelemetryUpdates();
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    super.dispose();
  }

  void _startTelemetryUpdates() {
    _telemetryTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final greenhouseProvider = context.read<GreenhouseProvider>();
    final deviceProvider = context.read<DeviceProvider>();

    await greenhouseProvider.fetchGreenhouses();
    await deviceProvider.fetchDevices();

    if (greenhouseProvider.greenhouses.isNotEmpty) {
      final activeGh = greenhouseProvider.greenhouses.first;
      final devices = deviceProvider.getDevicesByGreenhouse(activeGh.id);
      for (final device in devices) {
        await deviceProvider.fetchLatestTelemetry(device.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final greenhouseProvider = context.watch<GreenhouseProvider>();
    final deviceProvider = context.watch<DeviceProvider>();
    
    final greenhouses = greenhouseProvider.greenhouses;
    final devices = deviceProvider.devices;
    
    final isLoading = greenhouseProvider.isLoading || deviceProvider.isLoading;
    final error = greenhouseProvider.error ?? deviceProvider.error;

    if (isLoading && greenhouses.isEmpty) {
      return const GradientBackground(
        child: Center(child: CircularProgressIndicator(color: AppColors.neonGreen)),
      );
    }

    if (greenhouses.isEmpty) {
      return GradientBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.eco_outlined, color: AppColors.textGrey, size: 64),
              const SizedBox(height: 20),
              const Text(
                "No Greenhouses Added",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Add your first greenhouse to start monitoring.",
                style: TextStyle(color: AppColors.textGrey),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddGreenhousePage()),
                  );
                },
                child: const Text("Add Greenhouse", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              if (error != null) ...[
                const SizedBox(height: 20),
                Text(error, style: const TextStyle(color: Colors.redAccent)),
                TextButton(
                  onPressed: () {
                    greenhouseProvider.fetchGreenhouses();
                    deviceProvider.fetchDevices();
                  },
                  child: const Text("Retry", style: TextStyle(color: AppColors.neonGreen)),
                )
              ]
            ],
          ),
        ),
      );
    }

    final activeGreenhouse = greenhouses.first;
    final activeDevices = deviceProvider.getDevicesByGreenhouse(activeGreenhouse.id);
    final primaryDevice = activeDevices.isNotEmpty ? activeDevices.first : null;
    final telemetry = primaryDevice != null ? deviceProvider.latestTelemetry[primaryDevice.id] : null;

    return GradientBackground(
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: AppColors.neonGreen,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  activeGreenhouse.name,
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                ),
                const Text(
                  "System Status",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 25),
                MainTempCard(deviceId: primaryDevice?.id),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: InfoCard(
                        title: "HUMIDITY",
                        value: telemetry?.humidity != null ? "${telemetry!.humidity!.toStringAsFixed(1)}%" : "--",
                        icon: Icons.water_drop_outlined,
                        trend: telemetry != null ? "Real-time" : "Waiting for data",
                        iconColor: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: InfoCard(
                        title: "LIGHT",
                        value: telemetry?.light != null ? "${telemetry!.light!.toStringAsFixed(0)} lux" : "--",
                        icon: Icons.wb_sunny_outlined,
                        trend: telemetry != null ? "Real-time" : "Waiting for data",
                        iconColor: Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: InfoCard(
                        title: "CO2 LEVELS",
                        value: "--", // Not implemented in backend Telemetry model yet
                        icon: Icons.cloud_outlined,
                        trend: "Not available",
                        iconColor: Colors.purpleAccent,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: InfoCard(
                        title: "SOIL MOISTURE",
                        value: telemetry?.soilMoisture != null ? "${telemetry!.soilMoisture!.toStringAsFixed(1)}%" : "--",
                        icon: Icons.grass,
                        trend: telemetry != null ? "Real-time" : "Waiting for data",
                        iconColor: Colors.brown,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 35),
                const Text(
                  "QUICK CONTROLS",
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 15),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildHorizontalControl(
                        "Ventilation",
                        isFanActive,
                        Icons.air,
                        (val) => setState(() => isFanActive = val),
                      ),
                      _buildHorizontalControl(
                        "Irrigation",
                        isIrrigationActive,
                        Icons.opacity,
                        (val) => setState(() => isIrrigationActive = val),
                      ),
                      _buildHorizontalControl(
                        "LED Lights",
                        isLightsActive,
                        Icons.lightbulb_outline,
                        (val) => setState(() => isLightsActive = val),
                      ),
                      _buildHorizontalControl(
                        "Heater",
                        isHeaterActive,
                        Icons.wb_sunny_outlined,
                        (val) => setState(() => isHeaterActive = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const SizedBox(height: 130),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Yatay liste için kart boyutlarını sabitleyen yardımcı fonksiyon
  Widget _buildHorizontalControl(String title, bool active, IconData icon, Function(bool) onChanged) {
    return Container(
      width: 150, // Kartların genişliğini sabitledik
      height: 140, // Kartların yüksekliğini sabitledik
      margin: const EdgeInsets.only(right: 15), // Aralarındaki boşluk
      child: ControlTile(
        title: title,
        isActive: active,
        icon: icon,
        onChanged: onChanged,
      ),
    );
  }
}
