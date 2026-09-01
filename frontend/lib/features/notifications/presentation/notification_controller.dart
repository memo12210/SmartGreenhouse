import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_repository.dart';

String _currentPlatform() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'android';
    case TargetPlatform.iOS:
      return 'ios';
    default:
      return kIsWeb ? 'web' : defaultTargetPlatform.name;
  }
}

final notificationControllerProvider =
    Provider<NotificationController>((ref) {
  return NotificationController(ref);
});

class NotificationController {
  final Ref _ref;

  NotificationController(this._ref);

  Future<void> registerCurrentDeviceToken() async {
    try {
      final messaging = FirebaseMessaging.instance;

      final token = await messaging.getToken();

      if (token == null || token.isEmpty) {
        debugPrint('FCM token is null or empty.');
        return;
      }

      debugPrint('Registering FCM token to backend: $token');

      final platform = _currentPlatform();

      await _ref.read(notificationRepositoryProvider).registerFcmToken(
            token: token,
            platform: platform,
            deviceName: '${platform[0].toUpperCase()}${platform.substring(1)} Device',
          );

      debugPrint('FCM token registered successfully.');
    } catch (error) {
      debugPrint('Failed to register FCM token: $error');
    }
  }
}