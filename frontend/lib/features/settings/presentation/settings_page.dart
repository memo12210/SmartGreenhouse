import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../greenhouse/presentation/greenhouse_controller.dart';
import '../../devices/presentation/device_controller.dart';
import '../../greenhouse/domain/greenhouse.dart';
import '../../devices/domain/device.dart';

import '../../greenhouse/presentation/add_greenhouse_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  double maxTemp = 30.0;
  double minHumid = 45.0;

  @override
  Widget build(BuildContext context) {
    final greenhousesAsync = ref.watch(greenhousesProvider);

    return GradientScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text("System Settings", style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 25),

              _buildSectionHeader("MY GREENHOUSES"),
              greenhousesAsync.when(
                data: (greenhouses) {
                  if (greenhouses.isEmpty) {
                    return const Text("No greenhouses added yet.", style: TextStyle(color: Colors.white24));
                  }
                  return Column(
                    children: greenhouses.map((g) => _buildGreenhouseCard(g)).toList(),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text("Error loading greenhouses: $e"),
              ),
              
              const SizedBox(height: 20),
              _buildOutlineButton(Icons.add_circle_outline, "Add Greenhouse", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddGreenhousePage()),
                );
              }),

              const SizedBox(height: 30),
              _buildSectionHeader("GLOBAL THRESHOLDS"),
              _buildThresholdSlider("Max Temperature", maxTemp, "°C", Colors.orange, (val) => setState(() => maxTemp = val)),
              const SizedBox(height: 15),
              _buildThresholdSlider("Min Humidity", minHumid, "%", Colors.blueAccent, (val) => setState(() => minHumid = val)),

              const SizedBox(height: 40),
              _buildLogOutButton(),
              const SizedBox(height: 20),
              const Center(child: Text("Version 2.0.0", style: TextStyle(color: Colors.white24, fontSize: 12))),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 10),
      child: Text(title, style: Theme.of(context).textTheme.labelSmall),
    );
  }

  Widget _buildGreenhouseCard(Greenhouse greenhouse) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.cardGrey,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.eco, color: AppColors.neonGreen, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(greenhouse.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
            onPressed: () {
              ref.read(greenhousesProvider.notifier).deleteGreenhouse(greenhouse.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOutlineButton(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.neonGreen, size: 20),
            const SizedBox(width: 10),
            Text(text, style: const TextStyle(color: AppColors.neonGreen, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdSlider(String title, double value, String unit, Color color, Function(double) onChanged) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.cardGrey, borderRadius: BorderRadius.circular(20)),
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
              Text("${value.toInt()}$unit", style: const TextStyle(color: AppColors.neonGreen, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: value,
            min: 0, max: title.contains("Temp") ? 50 : 100,
            activeColor: color,
            inactiveColor: Colors.white10,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildLogOutButton() {
    return InkWell(
      onTap: () => ref.read(authControllerProvider.notifier).logout(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.redAccent, size: 20),
            SizedBox(width: 10),
            Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
