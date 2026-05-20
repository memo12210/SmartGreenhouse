class ApiEndpoints {
  ApiEndpoints._();

  // Use 10.0.2.2 for Android Emulator to connect to host's localhost
  // Use localhost or your computer's IP for other platforms
  static const String baseUrl = 'http://10.0.2.2:8000';
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
  static String greenhouseDevices(String greenhouseId) => '$apiV1/devices/greenhouse/$greenhouseId';
  static String claimDevice(String mac) => '$apiV1/devices/claim/$mac';
  
  // Telemetry
  static String telemetry(String deviceId) => '$apiV1/telemetry/$deviceId';
}
