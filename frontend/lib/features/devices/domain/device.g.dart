// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Device _$DeviceFromJson(Map<String, dynamic> json) => Device(
  id: json['id'] as String,
  name: json['name'] as String,
  serialNumber: json['serial_number'] as String,
  deviceType: json['device_type'] as String,
  status: json['status'] as String,
  firmwareVersion: json['firmware_version'] as String?,
  greenhouseId: json['greenhouse_id'] as String,
);

Map<String, dynamic> _$DeviceToJson(Device instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'serial_number': instance.serialNumber,
  'device_type': instance.deviceType,
  'status': instance.status,
  'firmware_version': instance.firmwareVersion,
  'greenhouse_id': instance.greenhouseId,
};
