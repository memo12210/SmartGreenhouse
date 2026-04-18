import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../widgets/info_card.dart';
import '../widgets/main_temp_card.dart';
import '../widgets/control_tile.dart';
import '../widgets/alert_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Kontrol durumları
  bool isFanActive = true;
  bool isIrrigationActive = false;
  bool isLightsActive = true;
  bool isHeaterActive = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),

          // 1. Üst Yazılar
          const Text("Greenhouse #1", style: TextStyle(color: AppColors.textGrey, fontSize: 14)),
          const Text("Healthy Growth", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          
          const SizedBox(height: 25),

          // 2. Ana Sıcaklık Kartı
          const MainTempCard(),
          
          const SizedBox(height: 25),

          // 3. Bilgi Kartları (Nem, Işık vb.)
          const Row(
            children: [
              Expanded(child: InfoCard(title: "HUMIDITY", value: "65%", icon: Icons.water_drop_outlined, trend: "↗ 2%", iconColor: Colors.blueAccent)),
              SizedBox(width: 15),
              Expanded(child: InfoCard(title: "LIGHT", value: "82%", icon: Icons.wb_sunny_outlined, trend: "↘ 5%", iconColor: Colors.orangeAccent)),
            ],
          ),
          const SizedBox(height: 15),
          const Row(
            children: [
              Expanded(child: InfoCard(title: "CO2 LEVELS", value: "450 ppm", icon: Icons.cloud_outlined, trend: "Stable", iconColor: Colors.purpleAccent)),
              SizedBox(width: 15),
              Expanded(child: InfoCard(title: "SOIL MOISTURE", value: "38%", icon: Icons.grass, trend: "↘ 12%", iconColor: Colors.brown)),
            ],
          ),
          
          const SizedBox(height: 35),

          // 4. QUICK CONTROLS Başlığı
          const Text(
            "QUICK CONTROLS",
            style: TextStyle(color: AppColors.textGrey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 15),

          // 5. YATAY KAYAN KONTROL LİSTESİ (İstediğin Değişiklik)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal, // Sağa doğru kaydırmayı sağlar
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildHorizontalControl(
                  "Ventilation", isFanActive, Icons.air, 
                  (val) => setState(() => isFanActive = val)
                ),
                _buildHorizontalControl(
                  "Irrigation", isIrrigationActive, Icons.opacity, 
                  (val) => setState(() => isIrrigationActive = val)
                ),
                _buildHorizontalControl(
                  "LED Lights", isLightsActive, Icons.lightbulb_outline, 
                  (val) => setState(() => isLightsActive = val)
                ),
                _buildHorizontalControl(
                  "Heater", isHeaterActive, Icons.wb_sunny_outlined, 
                  (val) => setState(() => isHeaterActive = val)
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // 6. ALERT CARD
          const AlertCard(),

          const SizedBox(height: 130), 
        ],
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