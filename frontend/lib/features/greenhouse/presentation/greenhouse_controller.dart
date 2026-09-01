import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/greenhouse.dart';
import '../data/greenhouse_repository.dart';

final greenhousesProvider = AsyncNotifierProvider<GreenhousesController, List<Greenhouse>>(() {
  return GreenhousesController();
});

class GreenhousesController extends AsyncNotifier<List<Greenhouse>> {
  @override
  Future<List<Greenhouse>> build() async {
    return _fetch();
  }

  Future<List<Greenhouse>> _fetch() async {
    return ref.read(greenhouseRepositoryProvider).getGreenhouses();
  }

  Future<void> addGreenhouse({
    required String name,
    String? location,
    Map<String, dynamic>? extraMetadata,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(greenhouseRepositoryProvider).createGreenhouse(
        name: name,
        location: location,
        extraMetadata: extraMetadata,
      );
      return _fetch();
    });
  }

  Future<void> deleteGreenhouse(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(greenhouseRepositoryProvider).deleteGreenhouse(id);
      return _fetch();
    });
  }
}
