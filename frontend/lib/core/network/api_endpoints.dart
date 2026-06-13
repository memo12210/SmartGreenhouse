class ApiEndpoints {
  ApiEndpoints._();

  // Configured at build/run time, e.g.:
  //   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
  //   flutter build apk --dart-define=API_BASE_URL=https://api.example.com
  //
  // The default targets the host machine's localhost from the Android
  // emulator (10.0.2.2). Real devices, iOS, web, and production MUST override
  // this with a reachable host — and should use HTTPS.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
  static const String apiV1 = '/api/v1';

  // Auth
  static const String login = '$apiV1/auth/login';
  static const String register = '$apiV1/auth/register';
  static const String refresh = '$apiV1/auth/refresh';
  static const String me = '$apiV1/users/me';

  // Greenhouses
  static const String greenhouses = '$apiV1/greenhouses/';

  // Devices
  static const String devices = '$apiV1/devices/';
  static String greenhouseDevices(String greenhouseId) =>
      '$apiV1/devices/greenhouse/$greenhouseId';
  static String claimDevice(String mac) => '$apiV1/devices/claim/$mac';

  // Telemetry
  static String telemetry(String deviceId) => '$apiV1/telemetry/$deviceId';

  // Alerts
  static String greenhouseAlerts(String greenhouseId) =>
      '$apiV1/alerts/greenhouse/$greenhouseId';

  static String acknowledgeAlert(String alertId) =>
      '$apiV1/alerts/$alertId/acknowledge';

  static String dismissAlert(String alertId) =>
      '$apiV1/alerts/$alertId/dismiss';

  // Notifications
  static const String fcmToken = '$apiV1/notifications/fcm-token';

  // Alert Rules
  static String deviceAlertRules(String deviceId) =>
      '$apiV1/alerts/rules/device/$deviceId';

  static const String alertRules = '$apiV1/alerts/rules';
  static String alertRule(String ruleId) => '$apiV1/alerts/rules/$ruleId';

  // ML / Insights
  static String greenhousePredictions(String greenhouseId) =>
      '$apiV1/ml/predictions/greenhouse/$greenhouseId';

  // Health / status
  static const String health = '/health';
  static const String mlHealth = '$apiV1/ml/health';
}
