import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  int selectedTab = 0; // 0: Temp, 1: Humid, 2: Light

  // --- DINAMIK VERI SETLERI ---
  
  // Dev Gösterge Değerleri
  String get _mainValue {
    if (selectedTab == 0) return "24.5°C";
    if (selectedTab == 1) return "64%";
    return "850lx";
  }

  // Grafik Verileri (Spots)
  List<FlSpot> get _chartSpots {
    switch (selectedTab) {
      case 0: // Temp
        return const [FlSpot(0, 2), FlSpot(1, 3.5), FlSpot(2, 3), FlSpot(3, 4), FlSpot(4, 3.2), FlSpot(5, 4.5), FlSpot(6, 3)];
      case 1: // Humid
        return const [FlSpot(0, 4), FlSpot(1, 3), FlSpot(2, 5), FlSpot(3, 4.5), FlSpot(4, 5.5), FlSpot(5, 4), FlSpot(6, 4.8)];
      case 2: // Light
        return const [FlSpot(0, 1), FlSpot(1, 2), FlSpot(2, 1.5), FlSpot(3, 3), FlSpot(4, 2.5), FlSpot(5, 4), FlSpot(6, 3.5)];
      default:
        return const [];
    }
  }

  // Tooltip Metni
  String get _tooltipText {
    if (selectedTab == 0) return "Wed: 25.1°";
    if (selectedTab == 1) return "Wed: 62%";
    return "Wed: 810lx";
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          
          // Üst Başlık
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Analytics", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text("Greenhouse 1 • Tomato Crop", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                child: const Icon(Icons.settings, color: Colors.white, size: 20),
              )
            ],
          ),
          const SizedBox(height: 25),

          // 1. TAB BAR (Artık Tıklanabilir)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                _buildTabItem(0, "Temp"),
                _buildTabItem(1, "Humid"),
                _buildTabItem(2, "Light"),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // 2. DINAMIK DEV GÖSTERGE
          Center(
            child: Column(
              children: [
                Text(_mainValue, style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, color: AppColors.neonGreen, size: 16),
                      SizedBox(width: 4),
                      Text("+1.2% THIS WEEK", style: TextStyle(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // 3. DINAMIK GRAFİK ALANI
          SizedBox(
            height: 200,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                LineChart(_mainChartData()),
                // Dinamik Tooltip
                Positioned(
                  left: MediaQuery.of(context).size.width * 0.35,
                  top: -20,
                  child: _buildTooltip(_tooltipText),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),

          // 4. AI YIELD FORECAST
          _buildForecastCard(),

          const SizedBox(height: 20),

          // 5. EN ALT İKİLİ KARTLAR
          Row(
            children: [
              Expanded(child: _buildBottomSmallCard("Watering", "On Track", Icons.opacity)),
              const SizedBox(width: 15),
              Expanded(child: _buildBottomSmallCard("Pest Risk", "Low", Icons.bug_report)),
            ],
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label) {
    bool isSelected = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index; // Tıklayınca state'i günceller ve UI'ı yeniler
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.neonGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white60, 
              fontWeight: FontWeight.bold
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTooltip(String text) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)]
          ),
          child: Text(text, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
      ],
    );
  }

  LineChartData _mainChartData() {
    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              if (value >= 0 && value < 7) {
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(days[value.toInt()], style: const TextStyle(color: Colors.white38, fontSize: 10)),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          // BURASI DINAMIK OLDU:
          spots: _chartSpots, 
          isCurved: true,
          color: AppColors.neonGreen,
          barWidth: 3,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => index == 2 
              ? FlDotCirclePainter(radius: 6, color: AppColors.neonGreen, strokeWidth: 3, strokeColor: const Color(0xFF0A0E0A))
              : FlDotCirclePainter(radius: 0),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [AppColors.neonGreen.withOpacity(0.2), AppColors.neonGreen.withOpacity(0.0)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForecastCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Projected Outcome", style: TextStyle(color: Colors.white60, fontSize: 12)),
                  Text("Excellent Yield", style: TextStyle(color: AppColors.neonGreen, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.neonGreen.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.eco, color: AppColors.neonGreen), 
              )
            ],
          ),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Confidence Score", style: TextStyle(color: Colors.white60, fontSize: 12)),
              Text("98%", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.98, 
              backgroundColor: Colors.white10, 
              valueColor: const AlwaysStoppedAnimation(AppColors.neonGreen),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 20),
          const Text("Based on current trends, conditions are optimal for the vegetative stage.",
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
            child: const Center(child: Text("View Detailed Report →", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          )
        ],
      ),
    );
  }

  Widget _buildBottomSmallCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white60, size: 16),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}