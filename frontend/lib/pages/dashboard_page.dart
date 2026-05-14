import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/models.dart';
import '../core/storage.dart';
import '../core/mqtt_service.dart';
import 'package:greenhouse_app/core/providers/greenhouse_provider.dart';
import '../widgets/info_card.dart';
import '../widgets/main_temp_card.dart';
import '../widgets/control_tile.dart';
import '../widgets/alert_card.dart';
import '../widgets/gradient_background.dart';
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

  @override
  Widget build(BuildContext context) {
    final greenhouseProvider = context.watch<GreenhouseProvider>();
    final greenhouses = greenhouseProvider.greenhouses;
    final isLoading = greenhouseProvider.isLoading;

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
              if (greenhouseProvider.error != null) ...[
                const SizedBox(height: 20),
                Text(greenhouseProvider.error!, style: const TextStyle(color: Colors.redAccent)),
                TextButton(
                  onPressed: () => greenhouseProvider.fetchGreenhouses(),
                  child: const Text("Retry", style: TextStyle(color: AppColors.neonGreen)),
                )
              ]
            ],
          ),
        ),
      );
    }

    final activeGreenhouse = greenhouses.first;

    return GradientBackground(
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => greenhouseProvider.fetchGreenhouses(),
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
                const MainTempCard(),
                const SizedBox(height: 25),
                const Row(
                  children: [
                    Expanded(
                      child: InfoCard(
                        title: "HUMIDITY",
                        value: "--",
                        icon: Icons.water_drop_outlined,
                        trend: "Waiting for data",
                        iconColor: Colors.blueAccent,
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: InfoCard(
                        title: "LIGHT",
                        value: "--",
                        icon: Icons.wb_sunny_outlined,
                        trend: "Waiting for data",
                        iconColor: Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Row(
                  children: [
                    Expanded(
                      child: InfoCard(
                        title: "CO2 LEVELS",
                        value: "--",
                        icon: Icons.cloud_outlined,
                        trend: "Waiting for data",
                        iconColor: Colors.purpleAccent,
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: InfoCard(
                        title: "SOIL MOISTURE",
                        value: "--",
                        icon: Icons.grass,
                        trend: "Waiting for data",
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
