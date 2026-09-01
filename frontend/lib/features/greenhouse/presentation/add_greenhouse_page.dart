import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/turkey_locations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import 'greenhouse_controller.dart';

class AddGreenhousePage extends ConsumerStatefulWidget {
  const AddGreenhousePage({super.key});

  @override
  ConsumerState<AddGreenhousePage> createState() => _AddGreenhousePageState();
}

class _AddGreenhousePageState extends ConsumerState<AddGreenhousePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _areaSizeController = TextEditingController();
  final _fertilizerNController = TextEditingController();
  final _fertilizerPController = TextEditingController();
  final _fertilizerKController = TextEditingController();

  final List<_KVItem> _kvItems = [];

  String _selectedCrop = 'Tomato';
  String _selectedVariety = 'Beefsteak';
  DateTime? _selectedPlantingDate;
  DateTime? _selectedHarvestDate;
  String? _selectedCity;
  String? _selectedDistrict;
  bool _isLoading = false;

  final List<String> _cropTypes = const [
    'Tomato',
    'Cucumber',
    'Pepper',
    'Lettuce',
    'Other',
  ];

  static const Map<String, List<String>> _cropVarieties = {
    'Tomato': ['Beefsteak', 'Cherry', 'Heirloom', 'Roma'],
    'Cucumber': ['English', 'Pickling', 'Slicing'],
    'Pepper': ['Bell', 'Habanero', 'Jalapeno'],
    'Lettuce': ['Butterhead', 'Iceberg', 'Leaf', 'Romaine'],
    'Other': ['Generic'],
  };

  static const List<String> _numericKeys = [
    'days_to_maturity',
    'photoperiod_hours',
    'irrigation_mm',
    'fertilizer_N_kg_ha',
    'fertilizer_P_kg_ha',
    'fertilizer_K_kg_ha',
    'pest_severity',
    'soil_pH',
    'area_size',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _areaSizeController.dispose();
    _fertilizerNController.dispose();
    _fertilizerPController.dispose();
    _fertilizerKController.dispose();

    for (final item in _kvItems) {
      item.keyController.dispose();
      item.valueController.dispose();
    }

    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final city = _selectedCity;
    final district = _selectedDistrict;
    final areaSizeText = _areaSizeController.text.trim();

    final locationParts = [
      if (city != null) city,
      if (district != null) district,
    ];

    final location = locationParts.join(' / ');

    final Map<String, dynamic> metadata = {
      'crop_type': _selectedCrop,
      'variety': _selectedVariety,
      'planting_date': _selectedPlantingDate!.toIsoformatString(),
      'harvest_date': _selectedHarvestDate!.toIsoformatString(),
      'fertilizer_N_kg_ha':
          double.tryParse(_fertilizerNController.text.replaceAll(',', '.')) ??
              0.0,
      'fertilizer_P_kg_ha':
          double.tryParse(_fertilizerPController.text.replaceAll(',', '.')) ??
              0.0,
      'fertilizer_K_kg_ha':
          double.tryParse(_fertilizerKController.text.replaceAll(',', '.')) ??
              0.0,
      if (city != null) 'city': city,
      if (district != null) 'district': district,
      if (areaSizeText.isNotEmpty)
        'area_size':
            double.tryParse(areaSizeText.replaceAll(',', '.')) ?? areaSizeText,
    };

    for (final item in _kvItems) {
      final key = item.keyController.text.trim();
      final value = item.valueController.text.trim();

      if (key.isEmpty || value.isEmpty) continue;

      if (_numericKeys.contains(key)) {
        metadata[key] = double.tryParse(value.replaceAll(',', '.')) ?? value;
      } else {
        metadata[key] = value;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(greenhousesProvider.notifier).addGreenhouse(
            name: name,
            location: location.isNotEmpty ? location : null,
            extraMetadata: metadata,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Greenhouse "$name" added successfully.'),
          backgroundColor: AppColors.neonGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add greenhouse: $error'),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addOptionalAttribute() {
    setState(() {
      _kvItems.add(_KVItem());
    });
  }

  void _removeOptionalAttribute(_KVItem item) {
    setState(() {
      _kvItems.remove(item);
    });

    item.keyController.dispose();
    item.valueController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<String>>>(
      future: TurkeyLocations.load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const GradientScaffold(
            body: SafeArea(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return GradientScaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Location data could not be loaded. Please check assets/data/turkey_locations.json and pubspec.yaml.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
            ),
          );
        }

        final locations = snapshot.data!;
        final cities = locations.keys.toList();
        final districts =
            _selectedCity == null ? <String>[] : locations[_selectedCity] ?? [];

        return GradientScaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                const _Header(),
                const SizedBox(height: 24),
                _IntroCard(crop: _selectedCrop),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.neonGreen.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FormSectionTitle(
                          title: 'Greenhouse Profile',
                          subtitle:
                              'Create a greenhouse profile for monitoring devices, alerts and insights.',
                        ),
                        const SizedBox(height: 20),
                        _InputField(
                          controller: _nameController,
                          label: 'Greenhouse Name',
                          hint: 'Tomato Greenhouse',
                          icon: Icons.eco_rounded,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Greenhouse name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _CropDropdown(
                          value: _selectedCrop,
                          items: _cropTypes,
                          onChanged: (value) {
                            if (value == null) return;

                            setState(() {
                              _selectedCrop = value;
                              _selectedVariety =
                                  _cropVarieties[value]?.first ?? 'Generic';
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _VarietyDropdown(
                          value: _selectedVariety,
                          items: _cropVarieties[_selectedCrop] ?? ['Generic'],
                          onChanged: (value) {
                            if (value == null) return;

                            setState(() {
                              _selectedVariety = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _DatePickerField(
                          label: 'Planting Date',
                          selectedDate: _selectedPlantingDate,
                          icon: Icons.calendar_today_rounded,
                          onDateSelected: (date) {
                            setState(() {
                              _selectedPlantingDate = date;
                            });
                          },
                          validator: (value) {
                            if (_selectedPlantingDate == null) {
                              return 'Planting date is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _DatePickerField(
                          label: 'Expected Harvest Date',
                          selectedDate: _selectedHarvestDate,
                          icon: Icons.event_available_rounded,
                          onDateSelected: (date) {
                            setState(() {
                              _selectedHarvestDate = date;
                            });
                          },
                          validator: (value) {
                            if (_selectedHarvestDate == null) {
                              return 'Harvest date is required';
                            }
                            if (_selectedPlantingDate != null &&
                                _selectedHarvestDate!
                                    .isBefore(_selectedPlantingDate!)) {
                              return 'Harvest must be after planting';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        const _FormSectionTitle(
                          title: 'Agricultural Inputs',
                          subtitle:
                              'Enter fertilizer concentrations for accurate yield predictions.',
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _InputField(
                                controller: _fertilizerNController,
                                label: 'Nitrogen Fertilizer',
                                hint: '100',
                                icon: Icons.science_rounded,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                suffixText: 'kg/ha',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _InputField(
                                controller: _fertilizerPController,
                                label: 'Phosphorus Fertilizer',
                                hint: '50',
                                icon: Icons.science_rounded,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                suffixText: 'kg/ha',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _InputField(
                          controller: _fertilizerKController,
                          label: 'Potasium Fertilizer',
                          hint: '150',
                          icon: Icons.science_rounded,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          suffixText: 'kg/ha',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Fertilizer K is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        const _FormSectionTitle(
                          title: 'Location',
                          subtitle:
                              'Select a real city and district. Free text input is disabled to keep location data clean.',
                        ),
                        const SizedBox(height: 20),
                        _LocationDropdowns(
                          cities: cities,
                          districts: districts,
                          selectedCity: _selectedCity,
                          selectedDistrict: _selectedDistrict,
                          onCityChanged: (value) {
                            setState(() {
                              _selectedCity = value;
                              _selectedDistrict = null;
                            });
                          },
                          onDistrictChanged: (value) {
                            setState(() {
                              _selectedDistrict = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _InputField(
                          controller: _areaSizeController,
                          label: 'Area Size',
                          hint: '120',
                          icon: Icons.square_foot_rounded,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          suffixText: 'm²',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }

                            final parsed = double.tryParse(
                              value.trim().replaceAll(',', '.'),
                            );

                            if (parsed == null || parsed <= 0) {
                              return 'Enter a valid area size';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        const _FormSectionTitle(
                          title: 'Optional Attributes',
                          subtitle:
                              'Add custom metadata such as soil type or irrigation method.',
                        ),
                        const SizedBox(height: 16),
                        if (_kvItems.isEmpty)
                          const _OptionalEmptyCard()
                        else
                          ..._kvItems.map(
                            (item) => _OptionalAttributeRow(
                              item: item,
                              onRemove: () => _removeOptionalAttribute(item),
                            ),
                          ),
                        const SizedBox(height: 12),
                        _OutlineActionButton(
                          icon: Icons.add_rounded,
                          text: 'Add Attribute',
                          onTap: _addOptionalAttribute,
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _submit,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Icon(Icons.check_rounded),
                            label: Text(
                              _isLoading
                                  ? 'Saving Greenhouse...'
                                  : 'Save Greenhouse',
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
      },
    );
  }
}

class _LocationDropdowns extends StatelessWidget {
  final List<String> cities;
  final List<String> districts;
  final String? selectedCity;
  final String? selectedDistrict;
  final ValueChanged<String?> onCityChanged;
  final ValueChanged<String?> onDistrictChanged;

  const _LocationDropdowns({
    required this.cities,
    required this.districts,
    required this.selectedCity,
    required this.selectedDistrict,
    required this.onCityChanged,
    required this.onDistrictChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 390;

    if (!isWide) {
      return Column(
        children: [
          _CityDropdown(
            value: selectedCity,
            cities: cities,
            onChanged: onCityChanged,
          ),
          const SizedBox(height: 14),
          _DistrictDropdown(
            value: selectedDistrict,
            districts: districts,
            enabled: selectedCity != null,
            onChanged: onDistrictChanged,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _CityDropdown(
            value: selectedCity,
            cities: cities,
            onChanged: onCityChanged,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _DistrictDropdown(
            value: selectedDistrict,
            districts: districts,
            enabled: selectedCity != null,
            onChanged: onDistrictChanged,
          ),
        ),
      ],
    );
  }
}

class _CityDropdown extends StatelessWidget {
  final String? value;
  final List<String> cities;
  final ValueChanged<String?> onChanged;

  const _CityDropdown({
    required this.value,
    required this.cities,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      items: cities
          .map(
            (city) => DropdownMenuItem<String>(
              value: city,
              child: Text(
                city,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'City is required';
        }
        return null;
      },
      dropdownColor: AppColors.surfaceDark,
      style: const TextStyle(color: Colors.white),
      decoration: _dropdownDecoration(
        label: 'City',
        icon: Icons.location_city_rounded,
      ),
    );
  }
}

class _DistrictDropdown extends StatelessWidget {
  final String? value;
  final List<String> districts;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  const _DistrictDropdown({
    required this.value,
    required this.districts,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      items: districts
          .map(
            (district) => DropdownMenuItem<String>(
              value: district,
              child: Text(
                district,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
      validator: (value) {
        if (!enabled) {
          return 'Select city';
        }

        if (value == null || value.isEmpty) {
          return 'District required';
        }

        return null;
      },
      dropdownColor: AppColors.surfaceDark,
      style: const TextStyle(color: Colors.white),
      decoration: _dropdownDecoration(
        label: 'District',
        icon: Icons.map_rounded,
      ),
    );
  }
}

InputDecoration _dropdownDecoration({
  required String label,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(
      icon,
      color: AppColors.neonGreen,
    ),
    filled: true,
    fillColor: Colors.black.withValues(alpha: 0.16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: AppColors.neonGreen.withValues(alpha: 0.14),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: AppColors.neonGreen.withValues(alpha: 0.14),
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
  );
}

class _Header extends StatelessWidget {
  const _Header();

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
                'Greenhouse Setup',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add Greenhouse',
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
  final String crop;

  const _IntroCard({
    required this.crop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.neonGreen.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonGreen.withValues(alpha: 0.08),
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
              color: AppColors.neonGreen.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.energy_savings_leaf_rounded,
              color: AppColors.neonGreen,
              size: 34,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Smart Greenhouse Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Current crop type: $crop. This data can improve future recommendations and alert rules.',
                  style: const TextStyle(
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
  final String? suffixText;
  final TextInputType? keyboardType;
  final String? Function(String?) validator;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.validator,
    this.suffixText,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffixText,
        prefixIcon: Icon(
          icon,
          color: AppColors.neonGreen,
        ),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.neonGreen.withValues(alpha: 0.14),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.neonGreen.withValues(alpha: 0.14),
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

class _CropDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _CropDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items
          .map(
            (crop) => DropdownMenuItem<String>(
              value: crop,
              child: Text(crop),
            ),
          )
          .toList(),
      onChanged: onChanged,
      dropdownColor: AppColors.surfaceDark,
      style: const TextStyle(color: Colors.white),
      decoration: _dropdownDecoration(
        label: 'Crop Type',
        icon: Icons.spa_rounded,
      ),
    );
  }
}

class _VarietyDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _VarietyDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items
          .map(
            (variety) => DropdownMenuItem<String>(
              value: variety,
              child: Text(variety),
            ),
          )
          .toList(),
      onChanged: onChanged,
      dropdownColor: AppColors.surfaceDark,
      style: const TextStyle(color: Colors.white),
      decoration: _dropdownDecoration(
        label: 'Variety',
        icon: Icons.category_rounded,
      ),
    );
  }
}

class _DatePickerField extends StatefulWidget {
  final String label;
  final DateTime? selectedDate;
  final IconData icon;
  final ValueChanged<DateTime> onDateSelected;
  final String? Function(String?) validator;

  const _DatePickerField({
    required this.label,
    required this.selectedDate,
    required this.icon,
    required this.onDateSelected,
    required this.validator,
  });

  @override
  State<_DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<_DatePickerField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.selectedDate));
  }

  @override
  void didUpdateWidget(_DatePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _controller.text = _format(widget.selectedDate);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(DateTime? date) {
    if (date == null) return '';
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      controller: _controller,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: widget.selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.neonGreen,
                  onPrimary: Colors.black,
                  surface: AppColors.surfaceDark,
                  onSurface: Colors.white,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.neonGreen,
                  ),
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          widget.onDateSelected(date);
        }
      },
      decoration: _dropdownDecoration(
        label: widget.label,
        icon: widget.icon,
      ).copyWith(
        hintText: 'Select Date',
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      validator: widget.validator,
    );
  }
}

extension _DateTimeIso on DateTime {
  String toIsoformatString() {
    return "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
  }
}

class _OptionalAttributeRow extends StatelessWidget {
  final _KVItem item;
  final VoidCallback onRemove;

  const _OptionalAttributeRow({
    required this.item,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: item.keyController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Key',
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: item.valueController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Value',
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionalEmptyCard extends StatelessWidget {
  const _OptionalEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.neonGreen.withValues(alpha: 0.1),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.textGrey,
            size: 21,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No optional attributes added. You can add custom metadata if needed.',
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _OutlineActionButton({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.neonGreen.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: AppColors.neonGreen,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                text,
                style: const TextStyle(
                  color: AppColors.neonGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
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
          color: AppColors.neonGreen.withValues(alpha: 0.12),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.tips_and_updates_rounded,
            color: AppColors.neonGreen,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Greenhouse metadata such as crop type, location and area size can be used later for AI-supported recommendations.',
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

class _KVItem {
  final TextEditingController keyController;
  final TextEditingController valueController;

  _KVItem()
      : keyController = TextEditingController(),
        valueController = TextEditingController();
}