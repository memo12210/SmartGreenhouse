import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/greenhouse.dart';
import 'add_greenhouse_page.dart';
import 'greenhouse_controller.dart';
import 'selected_greenhouse_provider.dart';

class GreenhouseSelectorSheet extends ConsumerWidget {
  const GreenhouseSelectorSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greenhousesAsync = ref.watch(greenhousesProvider);
    final selectedGreenhouse = ref.watch(selectedGreenhouseProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: greenhousesAsync.when(
          data: (greenhouses) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textGrey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 22),

                Row(
                  children: [
                    const Icon(
                      Icons.eco_rounded,
                      color: AppColors.neonGreen,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'My Greenhouses',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                if (greenhouses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No greenhouses added yet.',
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                  )
                else
                  ...greenhouses.map(
                    (greenhouse) {
                      final isSelected = selectedGreenhouse?.id == greenhouse.id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _GreenhouseOption(
                          greenhouse: greenhouse,
                          isSelected: isSelected,
                          onTap: () {
                            ref.read(selectedGreenhouseIdProvider.notifier).state =
                                greenhouse.id;
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddGreenhousePage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add New Greenhouse'),
                  ),
                ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(28),
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Greenhouse error: $error',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      ),
    );
  }
}

class _GreenhouseOption extends StatelessWidget {
  final Greenhouse greenhouse;
  final bool isSelected;
  final VoidCallback onTap;

  const _GreenhouseOption({
    required this.greenhouse,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final location = greenhouse.location;

    return Material(
      color: isSelected
          ? AppColors.neonGreen.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.energy_savings_leaf_rounded,
                  color: AppColors.neonGreen,
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greenhouse.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location == null || location.isEmpty
                          ? 'No location specified'
                          : location,
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.neonGreen,
                ),
            ],
          ),
        ),
      ),
    );
  }
}