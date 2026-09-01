import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/alert_rule_repository.dart';
import '../domain/alert_rule.dart';

final alertRulesProvider = StateNotifierProvider.family<
    AlertRuleController,
    AsyncValue<List<AlertRule>>,
    String>((ref, deviceId) {
  return AlertRuleController(
    repository: ref.read(alertRuleRepositoryProvider),
    deviceId: deviceId,
  )..loadRules();
});

class AlertRuleController extends StateNotifier<AsyncValue<List<AlertRule>>> {
  final AlertRuleRepository repository;
  final String deviceId;

  AlertRuleController({
    required this.repository,
    required this.deviceId,
  }) : super(const AsyncValue.loading());

  Future<void> loadRules() async {
    try {
      state = const AsyncValue.loading();
      final rules = await repository.getRulesByDevice(deviceId);
      state = AsyncValue.data(rules);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    try {
      final rules = await repository.getRulesByDevice(deviceId);
      state = AsyncValue.data(rules);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createRule({
    required String field,
    required String operator,
    required double threshold,
    required String severity,
    required bool isEnabled,
    String? messageTemplate,
  }) async {
    await repository.createRule(
      deviceId: deviceId,
      field: field,
      operator: operator,
      threshold: threshold,
      severity: severity,
      isEnabled: isEnabled,
      messageTemplate: messageTemplate,
    );

    await refresh();
  }

  Future<void> toggleRule(AlertRule rule) async {
    await repository.updateRule(
      ruleId: rule.id,
      isEnabled: !rule.isEnabled,
    );

    await refresh();
  }

  Future<void> deleteRule(String ruleId) async {
    await repository.deleteRule(ruleId);
    await refresh();
  }
}