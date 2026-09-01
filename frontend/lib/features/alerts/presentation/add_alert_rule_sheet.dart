import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import 'alert_rule_controller.dart';

class AddAlertRuleSheet extends ConsumerStatefulWidget {
  final String deviceId;

  const AddAlertRuleSheet({
    super.key,
    required this.deviceId,
  });

  @override
  ConsumerState<AddAlertRuleSheet> createState() => _AddAlertRuleSheetState();
}

class _AddAlertRuleSheetState extends ConsumerState<AddAlertRuleSheet> {
  final thresholdController = TextEditingController();
  final messageController = TextEditingController();

  String selectedField = 'temperature';
  String selectedOperator = '>=';
  String selectedSeverity = 'warning';
  bool isEnabled = true;
  bool isSaving = false;

  final fields = const [
    'temperature',
    'humidity',
    'soil_moisture',
    'light_intensity',
    'co2',
    'battery_level',
  ];

  final operators = const [
    '>=',
    '<=',
    '>',
    '<',
    '==',
    '!=',
  ];

  final severities = const [
    'info',
    'warning',
    'critical',
  ];

  @override
  void dispose() {
    thresholdController.dispose();
    messageController.dispose();
    super.dispose();
  }

  Future<void> _saveRule() async {
    final threshold = double.tryParse(thresholdController.text.trim());

    if (threshold == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid threshold value.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final customMessage = messageController.text.trim();

      await ref.read(alertRulesProvider(widget.deviceId).notifier).createRule(
            field: selectedField,
            operator: selectedOperator,
            threshold: threshold,
            severity: selectedSeverity,
            isEnabled: isEnabled,
            messageTemplate: customMessage.isEmpty ? null : customMessage,
          );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert rule created successfully.'),
          backgroundColor: AppColors.neonGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create rule: $error'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textGrey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Create Alert Rule',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Define when this device should generate an alert.',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 22),

                _DropdownField(
                  label: 'Sensor Field',
                  value: selectedField,
                  items: fields,
                  onChanged: (value) {
                    setState(() {
                      selectedField = value;
                    });
                  },
                ),

                const SizedBox(height: 14),

                _DropdownField(
                  label: 'Operator',
                  value: selectedOperator,
                  items: operators,
                  onChanged: (value) {
                    setState(() {
                      selectedOperator = value;
                    });
                  },
                ),

                const SizedBox(height: 14),

                _InputField(
                  label: 'Threshold',
                  controller: thresholdController,
                  hintText: 'Example: 30',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),

                const SizedBox(height: 14),

                _DropdownField(
                  label: 'Severity',
                  value: selectedSeverity,
                  items: severities,
                  onChanged: (value) {
                    setState(() {
                      selectedSeverity = value;
                    });
                  },
                ),

                const SizedBox(height: 14),

                _InputField(
                  label: 'Custom Message',
                  controller: messageController,
                  hintText: 'Optional alert message',
                  maxLines: 2,
                ),

                const SizedBox(height: 14),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.neonGreen,
                  title: const Text(
                    'Rule Enabled',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Disabled rules will not generate alerts.',
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 12,
                    ),
                  ),
                  value: isEnabled,
                  onChanged: (value) {
                    setState(() {
                      isEnabled = value;
                    });
                  },
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _saveRule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Save Rule',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  String _formatLabel(String value) {
    switch (value) {
      case 'temperature':
        return 'Temperature';
      case 'humidity':
        return 'Humidity';
      case 'soil_moisture':
        return 'Soil Moisture';
      case 'light_intensity':
        return 'Light Intensity';
      case 'co2':
        return 'CO₂';
      case 'battery_level':
        return 'Battery Level';
      case 'info':
        return 'Info';
      case 'warning':
        return 'Warning';
      case 'critical':
        return 'Critical';
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.neonGreen.withValues(alpha: 0.12),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: AppColors.surfaceDark,
              isExpanded: true,
              iconEnabledColor: AppColors.neonGreen,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              items: items
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(_formatLabel(item)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final int maxLines;

  const _InputField({
    required this.label,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: AppColors.textGrey),
            filled: true,
            fillColor: AppColors.surfaceDark,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.neonGreen.withValues(alpha: 0.12),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.neonGreen,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textGrey,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}