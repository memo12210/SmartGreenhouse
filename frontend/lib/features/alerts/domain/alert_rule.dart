class AlertRule {
  final String id;
  final String deviceId;
  final String field;
  final String operator;
  final double threshold;
  final String severity;
  final bool isEnabled;
  final String? messageTemplate;

  const AlertRule({
    required this.id,
    required this.deviceId,
    required this.field,
    required this.operator,
    required this.threshold,
    required this.severity,
    required this.isEnabled,
    this.messageTemplate,
  });

  factory AlertRule.fromJson(Map<String, dynamic> json) {
    return AlertRule(
      id: json['id']?.toString() ?? '',
      deviceId: json['device_id']?.toString() ?? '',
      field: json['field']?.toString() ?? '',
      operator: json['operator']?.toString() ?? '',
      threshold: (json['threshold'] as num?)?.toDouble() ?? 0,
      severity: json['severity']?.toString() ?? 'warning',
      isEnabled: json['is_enabled'] as bool? ?? true,
      messageTemplate: json['message_template']?.toString(),
    );
  }
}