import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:greenhouse_app/core/constants.dart';
import 'package:greenhouse_app/pages/dashboard_page.dart';
import 'package:greenhouse_app/widgets/bottom_nav_bar.dart';
import 'package:greenhouse_app/pages/analytics_page.dart';
import 'package:greenhouse_app/pages/settings_page.dart';
import 'package:greenhouse_app/pages/alerts_page.dart';
import 'package:greenhouse_app/pages/add_greenhouse_page.dart';
import 'package:greenhouse_app/pages/scan_device_page.dart';
import 'package:greenhouse_app/pages/auth/login_page.dart';
import 'package:greenhouse_app/core/models.dart';
import 'package:greenhouse_app/core/mqtt_service.dart';
import 'package:greenhouse_app/core/providers/auth_provider.dart';
import 'package:greenhouse_app/core/providers/greenhouse_provider.dart';
import 'package:greenhouse_app/core/providers/device_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, GreenhouseProvider>(
          create: (_) => GreenhouseProvider(),
          update: (_, auth, greenhouse) =>
              greenhouse!..updateToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, DeviceProvider>(
          create: (_) => DeviceProvider(),
          update: (_, auth, device) =>
              device!..updateToken(auth.token),
        ),
      ],
      child: const GreenhouseApp(),
    ),
  );
}

class GreenhouseApp extends StatelessWidget {
  const GreenhouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isAuthenticated) {
            return const LoginPage();
          }
          return const MainNavigationWrapper();
        },
      ),
    );
  }
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  void _showQuickActionsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          decoration: const BoxDecoration(
            color: Color(0xFF111611),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  "Quick Actions",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Choose a quick action for your greenhouse system",
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 22),

                _buildQuickActionTile(
                  icon: Icons.qr_code_scanner,
                  title: "Scan New Device",
                  subtitle: "Connect a new ESP32 using QR code",
                  onTap: () async {
                    Navigator.pop(context);
                    // Small delay to prevent mouse tracker assertion on some platforms (like Linux)
                    await Future.delayed(Duration.zero);
                    if (!context.mounted) return;

                    final scannedCode = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(builder: (_) => const ScanDevicePage()),
                    );

                    if (scannedCode == null || !context.mounted) return;

                    // Support "MAC:SECRET" or just "MAC"
                    final parts = scannedCode.split(':');
                    final mac = parts[0];
                    final secret = parts.length > 1 ? parts[1] : '';

                    if (secret.isEmpty) {
                      _showManualDeviceDialog(mac: mac);
                    } else {
                      await _assignDeviceToGreenhouse(macAddress: mac, secret: secret);
                    }
                  },
                ),

                _buildQuickActionTile(
                  icon: Icons.eco_outlined,
                  title: "Add Greenhouse",
                  subtitle: "Create a new greenhouse profile",
                  onTap: () async {
                    Navigator.pop(context);
                    // Small delay to prevent mouse tracker assertion on some platforms (like Linux)
                    await Future.delayed(Duration.zero);
                    if (!context.mounted) return;

                    final result = await Navigator.push<Greenhouse>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddGreenhousePage(),
                      ),
                    );

                    if (result != null && context.mounted) {
                      final userId = context.read<AuthProvider>().user?.id;
                      final mapping = context.read<DeviceProvider>().getGreenhouseDeviceMap();
                      if (userId != null) {
                        await MqttService.publishGreenhouses(userId, mapping);
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Greenhouse added: ${result.name}"),
                            backgroundColor: AppColors.neonGreen,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                ),

                _buildQuickActionTile(
                  icon: Icons.developer_board,
                  title: "Add Device Manually",
                  subtitle: "Register device ID without scanning",
                  onTap: () {
                    Navigator.pop(context);
                    _showManualDeviceDialog();
                  },
                ),

                _buildQuickActionTile(
                  icon: Icons.tune,
                  title: "Set Thresholds",
                  subtitle: "Configure temperature and humidity limits",
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _currentIndex = 3;
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.neonGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.neonGreen, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white38,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignDeviceToGreenhouse({
    required String macAddress,
    required String secret,
    String? name,
  }) async {
    if (!mounted) return;
    
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

    try {
      await context.read<DeviceProvider>().claimDevice(
        macAddress: macAddress,
        secret: secret,
        greenhouseId: selected.id,
        name: name,
      );

      final userId = context.read<AuthProvider>().user?.id;
      final mapping = context.read<DeviceProvider>().getGreenhouseDeviceMap();
      if (userId != null) {
        await MqttService.publishGreenhouses(userId, mapping);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Device added to ${selected.name} and registered securely"),
            backgroundColor: AppColors.neonGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Registration failed: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showManualDeviceDialog({String? mac}) {
    final TextEditingController macController = TextEditingController(text: mac);
    final TextEditingController secretController = TextEditingController();
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1F1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            "Add Device Manually",
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: macController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Device MAC Address",
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Device Name (Optional)",
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: secretController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Device Secret",
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonGreen,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                final macVal = macController.text.trim();
                final secretVal = secretController.text.trim();
                final nameVal = nameController.text.trim();
                
                if (macVal.isEmpty || secretVal.isEmpty) return;
                
                Navigator.pop(dialogContext);
                _assignDeviceToGreenhouse(
                  macAddress: macVal,
                  secret: secretVal,
                  name: nameVal.isNotEmpty ? nameVal : null,
                );
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const AnalyticsPage(),
    const AlertsPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonGreen,
        shape: const CircleBorder(),
        onPressed: _showQuickActionsSheet,
        child: const Icon(Icons.add, color: Colors.black, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
