import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class Storage {
  static const String _greenhousesKey = 'greenhouses_v1';
  static const String _devicesKey = 'greenhouse_devices_v1';

  static Future<SharedPreferences> _prefs() async =>
      await SharedPreferences.getInstance();

  static Future<List<Greenhouse>> loadGreenhouses() async {
    final p = await _prefs();
    final raw = p.getStringList(_greenhousesKey) ?? <String>[];
    return raw
        .map((s) => Greenhouse.fromJson(json.decode(s) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> addGreenhouse(Greenhouse g) async {
    final p = await _prefs();
    final list = p.getStringList(_greenhousesKey) ?? <String>[];
    list.add(json.encode(g.toJson()));
    await p.setStringList(_greenhousesKey, list);
  }

  static Future<void> removeGreenhouse(String id) async {
    final p = await _prefs();
    
    // Remove from greenhouses list
    final list = p.getStringList(_greenhousesKey) ?? <String>[];
    list.removeWhere((s) {
      final decoded = json.decode(s) as Map<String, dynamic>;
      return decoded['id'] == id;
    });
    await p.setStringList(_greenhousesKey, list);

    // Remove from devices map
    final map = await loadDevicesMap();
    if (map.containsKey(id)) {
      map.remove(id);
      await p.setString(_devicesKey, json.encode(map));
    }
  }

  static Future<Map<String, List<String>>> loadDevicesMap() async {
    final p = await _prefs();
    final raw = p.getString(_devicesKey);
    if (raw == null || raw.isEmpty) return {};
    final Map<String, dynamic> map = json.decode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, List<String>.from(v as List)));
  }

  /// Returns a combined map of all greenhouse IDs to their device lists.
  /// Ensures every greenhouse has an entry (empty list if no devices).
  static Future<Map<String, List<String>>> getGreenhousesDevicesMap() async {
    final ghs = await loadGreenhouses();
    final devMap = await loadDevicesMap();
    final Map<String, List<String>> result = {};
    for (final gh in ghs) {
      result[gh.id] = devMap[gh.id] ?? <String>[];
    }
    // include any devices map entries for unknown greenhouses as well
    for (final entry in devMap.entries) {
      result.putIfAbsent(entry.key, () => entry.value);
    }
    return result;
  }

  static Future<void> addDeviceToGreenhouse(String greenhouseId, String deviceId) async {
    final p = await _prefs();
    final map = await loadDevicesMap();
    final devices = map[greenhouseId] ?? <String>[];
    if (!devices.contains(deviceId)) {
      devices.add(deviceId);
      map[greenhouseId] = devices;
      await p.setString(_devicesKey, json.encode(map));
    }
  }

  static Future<String> getGreenhousesMqttPayload() async {
    final map = await loadDevicesMap();
    return json.encode(map);
  }
}
