import 'package:json_annotation/json_annotation.dart';

part 'device.g.dart';

@JsonSerializable()
class Device {
  final String id;
  final String name;
  @JsonKey(name: 'serial_number')
  final String serialNumber;
  @JsonKey(name: 'device_type')
  final String deviceType;
  final String status;
  @JsonKey(name: 'firmware_version')
  final String? firmwareVersion;
  @JsonKey(name: 'greenhouse_id')
  final String greenhouseId;

  Device({
    required this.id,
    required this.name,
    required this.serialNumber,
    required this.deviceType,
    required this.status,
    this.firmwareVersion,
    required this.greenhouseId,
  });

  bool get isOnline => status == 'online';

  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceToJson(this);
}
