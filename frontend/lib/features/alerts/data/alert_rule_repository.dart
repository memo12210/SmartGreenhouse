import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/alert_rule.dart';

final alertRuleRepositoryProvider = Provider<AlertRuleRepository>((ref) {
  return AlertRuleRepository(ref.read(dioProvider));
});

class AlertRuleRepository {
  final Dio _dio;

  AlertRuleRepository(this._dio);

  Future<List<AlertRule>> getRulesByDevice(String deviceId) async {
    final response = await _dio.get(ApiEndpoints.deviceAlertRules(deviceId));

    final data = response.data as List<dynamic>;

    return data
        .map((item) => AlertRule.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AlertRule> createRule({
    required String deviceId,
    required String field,
    required String operator,
    required double threshold,
    required String severity,
    required bool isEnabled,
    String? messageTemplate,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.alertRules,
      data: {
        'device_id': deviceId,
        'field': field,
        'operator': operator,
        'threshold': threshold,
        'severity': severity,
        'is_enabled': isEnabled,
        'message_template': messageTemplate,
      },
    );

    return AlertRule.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AlertRule> updateRule({
    required String ruleId,
    String? field,
    String? operator,
    double? threshold,
    String? severity,
    bool? isEnabled,
    String? messageTemplate,
  }) async {
    final data = <String, dynamic>{};

    if (field != null) data['field'] = field;
    if (operator != null) data['operator'] = operator;
    if (threshold != null) data['threshold'] = threshold;
    if (severity != null) data['severity'] = severity;
    if (isEnabled != null) data['is_enabled'] = isEnabled;
    if (messageTemplate != null) data['message_template'] = messageTemplate;

    final response = await _dio.patch(
      ApiEndpoints.alertRule(ruleId),
      data: data,
    );

    return AlertRule.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteRule(String ruleId) async {
    await _dio.delete(ApiEndpoints.alertRule(ruleId));
  }
}