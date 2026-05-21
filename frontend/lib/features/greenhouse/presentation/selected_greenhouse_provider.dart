import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/greenhouse.dart';
import 'greenhouse_controller.dart';

final selectedGreenhouseIdProvider = StateProvider<String?>((ref) {
  return null;
});

final selectedGreenhouseProvider = Provider<Greenhouse?>((ref) {
  final greenhousesAsync = ref.watch(greenhousesProvider);
  final selectedId = ref.watch(selectedGreenhouseIdProvider);

  return greenhousesAsync.maybeWhen(
    data: (greenhouses) {
      if (greenhouses.isEmpty) return null;

      if (selectedId == null) {
        return greenhouses.first;
      }

      return greenhouses.firstWhere(
        (greenhouse) => greenhouse.id == selectedId,
        orElse: () => greenhouses.first,
      );
    },
    orElse: () => null,
  );
});