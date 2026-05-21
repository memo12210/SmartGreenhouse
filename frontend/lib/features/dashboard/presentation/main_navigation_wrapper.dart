import 'package:flutter/material.dart';

import '../../../shared/widgets/custom_bottom_nav_bar.dart';
import 'dashboard_page.dart';
import 'package:greenhouse_app/features/devices/presentation/device_page.dart';
import 'package:greenhouse_app/features/insights/presentation/insights_page.dart';
import 'package:greenhouse_app/features/alerts/presentation/alerts_page.dart';
import '../../settings/presentation/settings_page.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        onNavigateToDevices: () => _changeTab(1),
      ),
      const DevicesPage(),
      const InsightsPage(),
      const AlertsPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      extendBody: true,
      body: pages[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _changeTab,
      ),
    );
  }
}