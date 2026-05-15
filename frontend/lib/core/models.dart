class Greenhouse {
  final String id;
  final String name;

  Greenhouse({required this.id, required this.name});

  factory Greenhouse.fromJson(Map<String, dynamic> json) =>
      Greenhouse(id: json['id'] as String, name: json['name'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class Device {
  final String id;
  final String macAddress;
  final String? name;
  final bool isActive;
  final String greenhouseId;

  Device({
    required this.id,
    required this.macAddress,
    this.name,
    required this.isActive,
    required this.greenhouseId,
  });

  factory Device.fromJson(Map<String, dynamic> json) => Device(
        id: json['id'] as String,
        macAddress: json['mac_address'] as String,
        name: json['name'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        greenhouseId: json['greenhouse_id'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'mac_address': macAddress,
        'name': name,
        'is_active': isActive,
        'greenhouse_id': greenhouseId,
      };
}

class Telemetry {
  final String id;
  final String deviceId;
  final double? temperature;
  final double? humidity;
  final double? light;
  final double? soilMoisture;
  final DateTime timestamp;

  Telemetry({
    required this.id,
    required this.deviceId,
    this.temperature,
    this.humidity,
    this.light,
    this.soilMoisture,
    required this.timestamp,
  });

  factory Telemetry.fromJson(Map<String, dynamic> json) => Telemetry(
        id: json['id'] as String,
        deviceId: json['device_id'] as String,
        temperature: (json['temperature'] as num?)?.toDouble(),
        humidity: (json['humidity'] as num?)?.toDouble(),
        light: (json['light'] as num?)?.toDouble(),
        soilMoisture: (json['soil_moisture'] as num?)?.toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'device_id': deviceId,
        'temperature': temperature,
        'humidity': humidity,
        'light': light,
        'soil_moisture': soilMoisture,
        'timestamp': timestamp.toIso8601String(),
      };
}
