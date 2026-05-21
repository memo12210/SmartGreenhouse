import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import 'device_controller.dart';
import 'qr_scanner_page.dart';

class AddDevicePage extends ConsumerStatefulWidget {
  final String greenhouseId;
  final String greenhouseName;

  const AddDevicePage({
    super.key,
    required this.greenhouseId,
    required this.greenhouseName,
  });

  @override
  ConsumerState<AddDevicePage> createState() => _AddDevicePageState();
}

class _AddDevicePageState extends ConsumerState<AddDevicePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _serialController = TextEditingController();

  bool _isSaving = false;

  static const String _defaultDeviceType = 'ESP32';
  static const String _defaultStatus = 'online';
  static const String _defaultFirmwareVersion = '1.0.0';

  @override
  void dispose() {
    _nameController.dispose();
    _serialController.dispose();
    super.dispose();
  }

  Future<void> _scanSerialNumber() async {
    final scannedValue = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const QrScannerPage(),
      ),
    );

    if (scannedValue == null || scannedValue.trim().isEmpty) return;

    setState(() {
      _serialController.text = scannedValue.trim();
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Serial number scanned successfully.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(devicesProvider(widget.greenhouseId).notifier).registerDevice(
            name: _nameController.text.trim(),
            serialNumber: _serialController.text.trim(),
            deviceType: _defaultDeviceType,
            status: _defaultStatus,
            firmwareVersion: _defaultFirmwareVersion,
            greenhouseId: widget.greenhouseId,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device added successfully.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.neonGreen,
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add device: $error'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _Header(greenhouseName: widget.greenhouseName),
            const SizedBox(height: 24),

            const _IntroCard(),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.neonGreen.withOpacity(0.18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonGreen.withOpacity(0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FormSectionTitle(
                      title: 'Device Registration',
                      subtitle:
                          'Add a sensor device by entering its label and serial number. You can also scan the QR code on the device.',
                    ),

                    const SizedBox(height: 22),

                    _InputField(
                      controller: _nameController,
                      label: 'Device Name',
                      hint: 'Tomato Sensor Node',
                      icon: Icons.sensors_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Device name is required';
                        }

                        if (value.trim().length < 3) {
                          return 'Device name is too short';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _SerialNumberField(
                      controller: _serialController,
                      onScanTap: _scanSerialNumber,
                    ),

                    const SizedBox(height: 22),

                    const _AutoConfigCard(),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _submit,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.add_rounded),
                        label: Text(
                          _isSaving ? 'Adding Device...' : 'Add Device',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const _InfoCard(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String greenhouseName;

  const _Header({
    required this.greenhouseName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.pop(context),
            child: const SizedBox(
              width: 46,
              height: 46,
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.neonGreen,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Device Setup',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                greenhouseName,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.neonGreen.withOpacity(0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonGreen.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withOpacity(0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: AppColors.neonGreen,
              size: 34,
            ),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Register Sensor Device',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Connect an ESP32 sensor node to this greenhouse using its serial number or QR code.',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _FormSectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textGrey,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?) validator;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: AppColors.neonGreen,
        ),
        filled: true,
        fillColor: Colors.black.withOpacity(0.16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.neonGreen.withOpacity(0.14),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.neonGreen.withOpacity(0.14),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppColors.neonGreen,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Colors.redAccent,
          ),
        ),
      ),
    );
  }
}

class _SerialNumberField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onScanTap;

  const _SerialNumberField({
    required this.controller,
    required this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Serial number is required';
        }

        if (value.trim().length < 3) {
          return 'Serial number is too short';
        }

        return null;
      },
      style: const TextStyle(color: Colors.white),
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: 'Serial Number',
        hintText: 'ESP32-001 or scan QR',
        prefixIcon: const Icon(
          Icons.qr_code_rounded,
          color: AppColors.neonGreen,
        ),
        suffixIcon: IconButton(
          onPressed: onScanTap,
          icon: const Icon(
            Icons.qr_code_scanner_rounded,
            color: AppColors.neonGreen,
          ),
          tooltip: 'Scan QR Code',
        ),
        filled: true,
        fillColor: Colors.black.withOpacity(0.16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.neonGreen.withOpacity(0.14),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.neonGreen.withOpacity(0.14),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppColors.neonGreen,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Colors.redAccent,
          ),
        ),
      ),
    );
  }
}

class _AutoConfigCard extends StatelessWidget {
  const _AutoConfigCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.neonGreen.withOpacity(0.12),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.neonGreen,
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Device type, status and firmware version are configured automatically. The device will appear online when it starts sending telemetry.',
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.neonGreen.withOpacity(0.12),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.neonGreen,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'The serial number should match the identifier used by the ESP32 firmware. This allows telemetry records to be associated with the correct device.',
              style: TextStyle(
                color: AppColors.textGrey,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}