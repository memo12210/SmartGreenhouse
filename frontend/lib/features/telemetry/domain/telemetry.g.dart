// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'telemetry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Telemetry _$TelemetryFromJson(Map<String, dynamic> json) => Telemetry(
  deviceId: json['device_id'] as String,
  temperature: (json['temperature'] as num?)?.toDouble(),
  humidity: (json['humidity'] as num?)?.toDouble(),
  soilMoisture: (json['soil_moisture'] as num?)?.toDouble(),
  lightIntensity: (json['light_intensity'] as num?)?.toDouble(),
  co2: (json['co2'] as num?)?.toDouble(),
  batteryLevel: (json['battery_level'] as num?)?.toDouble(),
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$TelemetryToJson(Telemetry instance) => <String, dynamic>{
  'device_id': instance.deviceId,
  'temperature': instance.temperature,
  'humidity': instance.humidity,
  'soil_moisture': instance.soilMoisture,
  'light_intensity': instance.lightIntensity,
  'co2': instance.co2,
  'battery_level': instance.batteryLevel,
  'timestamp': instance.timestamp.toIso8601String(),
};
