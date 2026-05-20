import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../../core/theme/app_colors.dart';
import '../../greenhouse/presentation/greenhouse_controller.dart';
import '../../devices/presentation/device_controller.dart';
import '../../telemetry/presentation/telemetry_controller.dart';
import 'widgets/main_temp_card.dart';
import 'widgets/info_card.dart';
import 'widgets/control_tile.dart';

import '../../greenhouse/presentation/add_greenhouse_page.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  // Mock control states
  bool isFanActive = false;
  bool isIrrigationActive = false;
  bool isLightsActive = false;

  @override
  Widget build(BuildContext context) {
    final greenhousesAsync = ref.watch(greenhousesProvider);

    return GradientScaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(greenhousesProvider);
          },
          color: AppColors.neonGreen,
          child: greenhousesAsync.when(
            data: (greenhouses) {
              if (greenhouses.isEmpty) {
                return _buildEmptyState(context);
              }
              final activeGh = greenhouses.first;
              final devicesAsync = ref.watch(devicesProvider(activeGh.id));
              
              return devicesAsync.when(
                data: (devices) {
                  return _buildDashboardContent(context, ref, activeGh, devices);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.eco_outlined, color: AppColors.textGrey, size: 64),
          const SizedBox(height: 20),
          Text(
            "No Greenhouses Added",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          const Text(
            "Add your first greenhouse to start monitoring.",
            style: TextStyle(color: AppColors.textGrey),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddGreenhousePage()),
                );
              },
              child: const Text("Add Greenhouse"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, WidgetRef ref, dynamic greenhouse, List<dynamic> devices) {
    final primaryDevice = devices.isNotEmpty ? devices.first : null;
    
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            greenhouse.name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            "System Status",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25),
          if (primaryDevice != null) ...[
             _TelemetrySection(deviceId: primaryDevice.id),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text("No devices linked to this greenhouse"),
              ),
            ),
          ],
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
                ControlTile(
                  title: "Ventilation",
                  isActive: isFanActive,
                  icon: Icons.air,
                  onChanged: (val) => setState(() => isFanActive = val),
                ),
                const SizedBox(width: 15),
                ControlTile(
                  title: "Irrigation",
                  isActive: isIrrigationActive,
                  icon: Icons.opacity,
                  onChanged: (val) => setState(() => isIrrigationActive = val),
                ),
                const SizedBox(width: 15),
                ControlTile(
                  title: "LED Lights",
                  isActive: isLightsActive,
                  icon: Icons.lightbulb_outline,
                  onChanged: (val) => setState(() => isLightsActive = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 130),
        ],
      ),
    );
  }
}

class _TelemetrySection extends ConsumerWidget {
  final String deviceId;
  const _TelemetrySection({required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetryAsync = ref.watch(latestTelemetryProvider(deviceId));

    return telemetryAsync.when(
      data: (telemetry) {
        final hasData = telemetry != null;
        
        return Column(
          children: [
            MainTempCard(
              temperature: telemetry?.temperature,
              status: hasData ? "Optimal" : "--",
              targetRange: "22°C - 26°C",
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: InfoCard(
                    title: "HUMIDITY",
                    value: telemetry?.humidity != null ? telemetry!.humidity!.toStringAsFixed(0) : "--",
                    icon: Icons.water_drop_outlined,
                    status: "Waiting for data",
                    iconColor: Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: InfoCard(
                    title: "LIGHT",
                    value: telemetry?.lightIntensity != null ? telemetry!.lightIntensity!.toStringAsFixed(0) : "--",
                    icon: Icons.wb_sunny_outlined,
                    status: "Waiting for data",
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
                    value: telemetry?.co2 != null ? telemetry!.co2!.toStringAsFixed(0) : "--",
                    icon: Icons.cloud_outlined,
                    status: "Waiting for data",
                    iconColor: Colors.purpleAccent,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: InfoCard(
                    title: "SOIL MOISTURE",
                    value: telemetry?.soilMoisture != null ? telemetry!.soilMoisture!.toStringAsFixed(0) : "--",
                    icon: Icons.grass_outlined,
                    status: "Waiting for data",
                    iconColor: Colors.brown,
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Telemetry error: $e'),
    );
  }
}
