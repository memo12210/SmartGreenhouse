import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../greenhouse/presentation/greenhouse_controller.dart';
import '../../devices/presentation/device_controller.dart';
import '../../telemetry/presentation/telemetry_controller.dart';
import '../../../shared/widgets/gradient_scaffold.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  int selectedTab = 0; // 0: Temp, 1: Humid, 2: Light

  @override
  Widget build(BuildContext context) {
    final greenhousesAsync = ref.watch(greenhousesProvider);

    return GradientScaffold(
      body: SafeArea(
        child: greenhousesAsync.when(
          data: (greenhouses) {
            if (greenhouses.isEmpty) {
              return _buildEmptyState();
            }
            final activeGreenhouse = greenhouses.first;
            final devicesAsync = ref.watch(devicesProvider(activeGreenhouse.id));

            return devicesAsync.when(
              data: (devices) {
                if (devices.isEmpty) {
                  return _buildNoDevicesState(activeGreenhouse.name);
                }
                final primaryDevice = devices.first;
                final telemetryAsync = ref.watch(latestTelemetryProvider(primaryDevice.id));

                return telemetryAsync.when(
                  data: (telemetry) {
                    return _buildContent(activeGreenhouse.name, telemetry);
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.analytics_outlined, color: AppColors.textGrey, size: 64),
          const SizedBox(height: 20),
          Text("No Analytics Data", style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          const Text("Add a greenhouse to see analytics.", style: TextStyle(color: AppColors.textGrey)),
        ],
      ),
    );
  }

  Widget _buildNoDevicesState(String greenhouseName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.developer_board_off, color: AppColors.textGrey, size: 64),
          const SizedBox(height: 20),
          Text("No Devices in $greenhouseName", style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          const Text("Connect a device to start tracking data.", style: TextStyle(color: AppColors.textGrey)),
        ],
      ),
    );
  }

  Widget _buildContent(String greenhouseName, dynamic telemetry) {
    String mainValue = "--";
    if (telemetry != null) {
      if (selectedTab == 0) {
        mainValue = "${telemetry.temperature?.toStringAsFixed(1) ?? '--'}°C";
      } else if (selectedTab == 1) {
        mainValue = "${telemetry.humidity?.toStringAsFixed(1) ?? '--'}%";
      } else {
        mainValue = "${telemetry.lightIntensity?.toStringAsFixed(0) ?? '--'} lx";
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Analytics", style: Theme.of(context).textTheme.headlineMedium),
                  Text(greenhouseName, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
                child: const Icon(Icons.settings, color: Colors.white, size: 20),
              )
            ],
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
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
          Center(
            child: Column(
              children: [
                Text(mainValue, style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 64)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_flat, color: AppColors.neonGreen, size: 16),
                      SizedBox(width: 4),
                      Text("REAL-TIME DATA", style: TextStyle(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 200,
            child: Center(child: Text("Historical Chart Coming Soon", style: TextStyle(color: Colors.white.withValues(alpha: 0.3)))),
          ),
          const SizedBox(height: 50),
          _buildForecastCard(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildBottomSmallCard("Watering", "Optimal", Icons.opacity)),
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
        onTap: () => setState(() => selectedTab = index),
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

  Widget _buildForecastCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                decoration: BoxDecoration(color: AppColors.neonGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
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
        ],
      ),
    );
  }

  Widget _buildBottomSmallCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
