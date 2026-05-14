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
