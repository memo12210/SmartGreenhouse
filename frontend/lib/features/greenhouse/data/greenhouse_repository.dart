import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/greenhouse.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';

final greenhouseRepositoryProvider = Provider<GreenhouseRepository>((ref) {
  return GreenhouseRepository(ref.read(dioProvider));
});

class GreenhouseRepository {
  final Dio _dio;

  GreenhouseRepository(this._dio);

  Future<List<Greenhouse>> getGreenhouses() async {
    final response = await _dio.get(ApiEndpoints.greenhouses);
    return (response.data as List).map((e) => Greenhouse.fromJson(e)).toList();
  }

  Future<Greenhouse> createGreenhouse({
    required String name,
    String? location,
    Map<String, dynamic>? extraMetadata,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.greenhouses,
      data: {
        'name': name,
        'location': location,
        'extra_metadata': extraMetadata ?? {},
      },
    );
    return Greenhouse.fromJson(response.data);
  }

  Future<void> deleteGreenhouse(String id) async {
    await _dio.delete('${ApiEndpoints.greenhouses}$id');
  }
}
