class AppAlert {
  final String id;
  final String deviceId;
  final String greenhouseId;
  final String alertType;
  final String severity;
  final String message;
  final double? value;
  final bool isAcknowledged;
  final String? acknowledgedBy;
  final Map<String, dynamic> extraMetadata;

  const AppAlert({
    required this.id,
    required this.deviceId,
    required this.greenhouseId,
    required this.alertType,
    required this.severity,
    required this.message,
    required this.value,
    required this.isAcknowledged,
    required this.acknowledgedBy,
    required this.extraMetadata,
  });

  factory AppAlert.fromJson(Map<String, dynamic> json) {
    return AppAlert(
      id: json['id']?.toString() ?? '',
      deviceId: json['device_id']?.toString() ?? '',
      greenhouseId: json['greenhouse_id']?.toString() ?? '',
      alertType: json['alert_type']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'warning',
      message: json['message']?.toString() ?? '',
      value: _toDouble(json['value']),
      isAcknowledged: json['is_acknowledged'] == true,
      acknowledgedBy: json['acknowledged_by']?.toString(),
      extraMetadata: json['extra_metadata'] is Map<String, dynamic>
          ? json['extra_metadata'] as Map<String, dynamic>
          : {},
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  bool get isCritical => severity.toLowerCase() == 'critical';
  bool get isWarning => severity.toLowerCase() == 'warning';
  bool get isInfo => severity.toLowerCase() == 'info';

  String get readableType {
    return alertType
        .replaceAll('_', ' ')
        .replaceAll('>=', 'above or equal')
        .replaceAll('<=', 'below or equal')
        .trim();
  }
}