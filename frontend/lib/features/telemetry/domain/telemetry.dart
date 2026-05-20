import 'package:json_annotation/json_annotation.dart';

part 'telemetry.g.dart';

@JsonSerializable()
class Telemetry {
  @JsonKey(name: 'device_id')
  final String deviceId;
  final double? temperature;
  final double? humidity;
  @JsonKey(name: 'soil_moisture')
  final double? soilMoisture;
  @JsonKey(name: 'light_intensity')
  final double? lightIntensity;
  final double? co2;
  @JsonKey(name: 'battery_level')
  final double? batteryLevel;
  final DateTime timestamp;

  Telemetry({
    required this.deviceId,
    this.temperature,
    this.humidity,
    this.soilMoisture,
    this.lightIntensity,
    this.co2,
    this.batteryLevel,
    required this.timestamp,
  });

  factory Telemetry.fromJson(Map<String, dynamic> json) => _$TelemetryFromJson(json);
  Map<String, dynamic> toJson() => _$TelemetryToJson(this);
}
