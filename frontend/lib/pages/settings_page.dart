import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/models.dart';
import '../core/storage.dart';
import '../core/mqtt_service.dart';
import 'package:greenhouse_app/core/providers/auth_provider.dart';
import 'package:greenhouse_app/core/providers/greenhouse_provider.dart';
import 'add_greenhouse_page.dart';
import 'scan_device_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double maxTemp = 30.0;
  double minHumid = 45.0;

  Map<String, List<String>> _deviceMap = {};
  Map<String, bool> _deviceStatus = {};
  final Map<String, StreamSubscription> _subscriptions = {};
  bool _isInitLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceData();
  }

  @override
  void dispose() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }

  Future<void> _loadDeviceData() async {
    final map = await Storage.getGreenhousesDevicesMap();
    
    if (mounted) {
      setState(() {
        _deviceMap = map;
        _isInitLoading = false;
      });
      _initializeStatusMonitoring();
    }
  }

  void _initializeStatusMonitoring() {
    final mqtt = MqttService();
    _deviceMap.forEach((ghId, deviceIds) {
      for (final devId in deviceIds) {
        if (!_subscriptions.containsKey(devId)) {
          final sub = mqtt.subscribeToStatus(ghId, devId).listen((isOnline) {
            if (mounted) {
              setState(() {
                _deviceStatus[devId] = isOnline;
              });
            }
          });
          _subscriptions[devId] = sub;
        }
      }
    });
  }

  Future<void> _assignDeviceToGreenhouse(String deviceId) async {
    final greenhouses = context.read<GreenhouseProvider>().greenhouses;
    if (greenhouses.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No greenhouse found. Add one first."),
            backgroundColor: Colors.orangeAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final selected = await showDialog<Greenhouse>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111611),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Select Greenhouse', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: greenhouses.length,
              itemBuilder: (context, index) {
                final g = greenhouses[index];
                return ListTile(
                  title: Text(g.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(g.id, style: const TextStyle(color: Colors.white54)),
                  onTap: () => Navigator.pop(dialogCtx, g),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
          ],
        );
      },
    );

    if (selected == null || !mounted) return;

    await Storage.addDeviceToGreenhouse(selected.id, deviceId);
    await _loadDeviceData();
    final mapping = await Storage.getGreenhousesDevicesMap();
    await MqttService.publishGreenhouses(mapping);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Device added to ${selected.name} and synced to MQTT"),
          backgroundColor: AppColors.neonGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDeletion(Greenhouse greenhouse) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text("Delete Greenhouse", style: TextStyle(color: Colors.white)),
        content: Text("Are you sure you want to delete '${greenhouse.name}'? This action cannot be undone.",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<GreenhouseProvider>().deleteGreenhouse(greenhouse.id);
        
        // Cleanup local device map too for now
        await Storage.removeGreenhouse(greenhouse.id);
        await _loadDeviceData();
        
        final mapping = await Storage.getGreenhousesDevicesMap();
        await MqttService.publishGreenhouses(mapping);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Greenhouse '${greenhouse.name}' deleted"),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: ${e.toString()}"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  List<Widget> _buildDeviceList(List<Greenhouse> greenhouses) {
    final List<Widget> devices = [];
    _deviceMap.forEach((ghId, deviceIds) {
      final gh = greenhouses.firstWhere((g) => g.id == ghId, orElse: () => Greenhouse(id: ghId, name: "Unknown Greenhouse"));
      for (final devId in deviceIds) {
        final isOnline = _deviceStatus[devId] ?? false;
        devices.add(_buildDeviceCard(devId, "Assigned to: ${gh.name}", isOnline));
      }
    });
    return devices;
  }

  @override
  Widget build(BuildContext context) {
    final greenhouseProvider = context.watch<GreenhouseProvider>();
    final greenhouses = greenhouseProvider.greenhouses;
    final isLoading = greenhouseProvider.isLoading || _isInitLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF0D120D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.white),
        title: const Text("System Settings", style: TextStyle(color: Colors.white, fontSize: 18)),
        centerTitle: true,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.neonGreen))
        : RefreshIndicator(
            onRefresh: () => greenhouseProvider.fetchGreenhouses(),
            color: AppColors.neonGreen,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  
                  if (greenhouseProvider.error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              greenhouseProvider.error!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.redAccent),
                            onPressed: () => greenhouseProvider.fetchGreenhouses(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // --- MY GREENHOUSES ---
                  _buildSectionHeader("MY GREENHOUSES"),
                  if (greenhouses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text("No greenhouses added yet.", style: TextStyle(color: Colors.white24, fontSize: 13)),
                    )
                  else
                    ...greenhouses.map((g) => _buildGreenhouseCard(
                      g, 
                      "${(_deviceMap[g.id] ?? []).length} Devices Active", 
                      Icons.eco,
                    )),
                  
                  // Add Greenhouse Button
                  _buildOutlineButton(
                    Icons.add_circle_outline,
                    "Add Greenhouse",
                    () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddGreenhousePage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // --- HARDWARE ---
                  _buildSectionHeader("HARDWARE"),
                  if (_deviceMap.values.every((list) => list.isEmpty))
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text("No devices connected yet.", style: TextStyle(color: Colors.white24, fontSize: 13)),
                    )
                  else
                    ..._buildDeviceList(greenhouses),
                  
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

  Widget _buildGreenhouseCard(Greenhouse greenhouse, String subtitle, IconData icon) {
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
                Text(greenhouse.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
            onPressed: () => _confirmDeletion(greenhouse),
          ),
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

Widget _buildOutlineButton(IconData icon, String text, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.neonGreen, size: 20),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.neonGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildScanButton() {
  return GestureDetector(
    onTap: () async {
      final scannedCode = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => const ScanDevicePage(),
        ),
      );

      if (scannedCode != null && mounted) {
        await _assignDeviceToGreenhouse(scannedCode);
      }
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.neonGreen,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonGreen.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_scanner, color: Colors.black, size: 20),
          SizedBox(width: 10),
          Text(
            "Scan New Device",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
    return GestureDetector(
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1F1A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: const Text("Log Out", style: TextStyle(color: Colors.white)),
            content: const Text("Are you sure you want to log out?",
                style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Log Out"),
              ),
            ],
          ),
        );

        if (confirmed == true && mounted) {
          context.read<AuthProvider>().logout();
        }
      },
      child: Container(
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
      ),
    );
  }
}
