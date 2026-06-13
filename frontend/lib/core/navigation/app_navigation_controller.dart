import 'package:flutter/foundation.dart';

/// Bottom-navigation tabs, in display order. The enum order is the source of
/// truth for tab indices, so reordering tabs here updates both the navigation
/// bar and any deep-link targets without magic numbers.
enum AppTab { dashboard, devices, insights, alerts, settings }

/// Global navigation entry point.
///
/// This is intentionally a process-global (not a Riverpod provider) because it
/// is driven from Firebase messaging callbacks that run outside the widget
/// tree and have no access to a [WidgetRef]/[ProviderContainer].
class AppNavigationController {
  AppNavigationController._();

  static final ValueNotifier<AppTab?> target = ValueNotifier<AppTab?>(null);

  static void goTo(AppTab tab) {
    target.value = tab;
  }

  static void goToAlerts() => goTo(AppTab.alerts);

  static void clearTarget() {
    target.value = null;
  }
}
