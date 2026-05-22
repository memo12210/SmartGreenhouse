import 'package:flutter/foundation.dart';

class AppNavigationController {
  static final ValueNotifier<int?> targetTabIndex = ValueNotifier<int?>(null);

  static void goToAlerts() {
    targetTabIndex.value = 3;
  }

  static void clearTarget() {
    targetTabIndex.value = null;
  }
}