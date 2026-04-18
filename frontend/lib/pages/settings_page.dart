import 'package:flutter/material.dart';
import '../core/constants.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double maxTemp = 30.0;
  double minHumid = 45.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D120D), // Görseldeki koyu zemin
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.white),
        title: const Text("System Settings", style: TextStyle(color: Colors.white, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            
            // --- MY GREENHOUSES ---
            _buildSectionHeader("MY GREENHOUSES"),
            _buildGreenhouseCard("Tomato Greenhouse", "Zone A • 4 Sensors Active", Icons.eco),
            _buildGreenhouseCard("Orchid Nursery", "Zone B • 2 Sensors Active", Icons.local_florist),
            
            // Add Greenhouse Button
            _buildOutlineButton(Icons.add_circle_outline, "Add Greenhouse"),

            const SizedBox(height: 30),

            // --- HARDWARE ---
            _buildSectionHeader("HARDWARE"),
            _buildDeviceCard("ESP32-Control-01", "Assigned to: Tomato Greenhouse", true),
            _buildDeviceCard("Arduino-Sensor-B", "Unassigned Device", false),
            
            // Scan New Device Button
            _buildScanButton(),

            const SizedBox(height: 30),

            // --- GLOBAL THRESHOLDS ---
            _buildSectionHeader("GLOBAL THRESHOLDS"),
            _buildThresholdSlider(
              "Max Temperature", 
              maxTemp, 
              "°C", 
              Colors.orange, 
              (val) => setState(() => maxTemp = val)
            ),
            const SizedBox(height: 15),
            _buildThresholdSlider(
              "Min Humidity", 
              minHumid, 
              "%", 
              Colors.blueAccent, 
              (val) => setState(() => minHumid = val)
            ),

            const SizedBox(height: 40),

            // Log Out Button
            _buildLogOutButton(),

            const SizedBox(height: 20),
            const Center(child: Text("Version 1.0.4", style: TextStyle(color: Colors.white24, fontSize: 12))),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BİLEŞENLERİ ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 10),
      child: Text(title, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  Widget _buildGreenhouseCard(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F1A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.neonGreen, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(String name, String status, bool isOnline) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F1A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.developer_board, color: Colors.white54, size: 24),
              ),
              Positioned(
                right: 0, bottom: 0,
                child: CircleAvatar(radius: 4, backgroundColor: isOnline ? Colors.green : Colors.red),
              )
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(status, style: TextStyle(color: isOnline ? Colors.white38 : Colors.orangeAccent.withOpacity(0.7), fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isOnline ? Colors.green.withOpacity(0.1) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(isOnline ? "ONLINE" : "OFFLINE", 
              style: TextStyle(color: isOnline ? Colors.green : Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildOutlineButton(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05), style: BorderStyle.solid),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.neonGreen, size: 20),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: AppColors.neonGreen, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.neonGreen,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: AppColors.neonGreen.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_scanner, color: Colors.black, size: 20),
          const SizedBox(width: 10),
          Text("Scan New Device", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildThresholdSlider(String title, double value, String unit, Color color, Function(double) onChanged) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1A1F1A), borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(title.contains("Temp") ? Icons.thermostat : Icons.water_drop, color: color, size: 20),
                  const SizedBox(width: 10),
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              Text("${value.toInt()}$unit", style: TextStyle(color: AppColors.neonGreen, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: value,
            min: 0, max: title.contains("Temp") ? 50 : 100,
            activeColor: color,
            inactiveColor: Colors.white10,
            onChanged: onChanged,
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("0", style: TextStyle(color: Colors.white24, fontSize: 10)),
              Text("MAX", style: TextStyle(color: Colors.white24, fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLogOutButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout, color: Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}