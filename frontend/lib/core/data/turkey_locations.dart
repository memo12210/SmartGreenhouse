import 'dart:convert';

import 'package:flutter/services.dart';

class TurkeyLocations {
  TurkeyLocations._();

  static Map<String, List<String>>? _cache;

  static Future<Map<String, List<String>>> load() async {
    if (_cache != null) return _cache!;

    final jsonString = await rootBundle.loadString(
      'assets/data/turkey_locations.json',
    );

    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

    final locations = decoded.map(
      (city, districts) {
        final districtList = (districts as List)
            .map((district) => district.toString())
            .toList()
          ..sort((a, b) => a.compareTo(b));

        return MapEntry(city, districtList);
      },
    );

    final sortedEntries = locations.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    _cache = {
      for (final entry in sortedEntries) entry.key: entry.value,
    };

    return _cache!;
  }
}
