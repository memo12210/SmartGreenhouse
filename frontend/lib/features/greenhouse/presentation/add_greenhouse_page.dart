import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import 'greenhouse_controller.dart';

class AddGreenhousePage extends ConsumerStatefulWidget {
  const AddGreenhousePage({super.key});

  @override
  ConsumerState<AddGreenhousePage> createState() => _AddGreenhousePageState();
}

class _AddGreenhousePageState extends ConsumerState<AddGreenhousePage> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final List<_KVItem> _kvItems = [];
  bool _isLoading = false;

  static const List<String> _numericKeys = [
    'days_to_maturity',
    'photoperiod_hours',
    'irrigation_mm',
    'fertilizer_N_kg_ha',
    'fertilizer_P_kg_ha',
    'fertilizer_K_kg_ha',
    'pest_severity',
    'soil_pH',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    for (final item in _kvItems) {
      item.keyController.dispose();
      item.valueController.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final location = _locationController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a greenhouse name')),
      );
      return;
    }

    final Map<String, dynamic> metadata = {};

    // include dynamic optional key/value pairs
    for (final item in _kvItems) {
      final key = item.keyController.text.trim();
      final val = item.valueController.text.trim();
      if (key.isEmpty || val.isEmpty) continue;
      if (_numericKeys.contains(key)) {
        metadata[key] = double.tryParse(val) ?? val;
      } else {
        metadata[key] = val;
      }
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(greenhousesProvider.notifier).addGreenhouse(
            name: name,
            location: location.isNotEmpty ? location : null,
            extraMetadata: metadata,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greenhouse "$name" added successfully'),
            backgroundColor: AppColors.neonGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Add Greenhouse",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Create New Profile",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter the details of your new greenhouse system",
                style: TextStyle(color: AppColors.textGrey),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: "Greenhouse Name (e.g. Tomato Greenhouse)",
                  prefixIcon: Icon(
                    Icons.eco_outlined,
                    color: AppColors.textGrey,
                  ),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: "Location (e.g. North Sector)",
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    color: AppColors.textGrey,
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 40),

              // Dynamic optional attributes editor
              _buildSectionHeader("Add Optional Attributes"),
              const SizedBox(height: 8),
              if (_kvItems.isNotEmpty) ...[
                const SizedBox(height: 4),
                ..._kvItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: item.keyController,
                            decoration: const InputDecoration(
                              hintText: 'Key',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: item.valueController,
                            decoration: const InputDecoration(
                              hintText: 'Value',
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              setState(() => _kvItems.remove(item)),
                          icon: const Icon(
                            Icons.delete,
                            color: AppColors.errorRed,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              TextButton.icon(
                onPressed: () => setState(() => _kvItems.add(_KVItem())),
                icon: const Icon(Icons.add),
                label: const Text('Add attribute'),
              ),

              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text("Add Greenhouse"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textGrey,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _KVItem {
  final TextEditingController keyController;
  final TextEditingController valueController;

  _KVItem()
      : keyController = TextEditingController(),
        valueController = TextEditingController();
}
