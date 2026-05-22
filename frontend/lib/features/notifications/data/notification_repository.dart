import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.read(dioProvider));
});

class NotificationRepository {
  final Dio _dio;

  NotificationRepository(this._dio);

  Future<void> registerFcmToken({
    required String token,
    String platform = 'android',
    String? deviceName,
  }) async {
    await _dio.post(
      ApiEndpoints.fcmToken,
      data: {
        'token': token,
        'platform': platform,
        'device_name': deviceName,
      },
    );
  }
}