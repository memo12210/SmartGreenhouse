import 'package:flutter/material.dart';
import 'package:greenhouse_app/core/models.dart';
import 'package:greenhouse_app/core/services/device_service.dart';

class DeviceProvider extends ChangeNotifier {
  final DeviceService _service = DeviceService();
  String? _token;
  
  List<Device> _devices = [];
  bool _isLoading = false;
  String? _error;

  List<Device> get devices => _devices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateToken(String? token) {
    _token = token;
    if (_token != null) {
      fetchDevices();
    } else {
      _devices = [];
      notifyListeners();
    }
  }

  Future<void> fetchDevices() async {
    if (_token == null) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _devices = await _service.getDevices(_token!);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> claimDevice({
    required String macAddress,
    required String secret,
    required String greenhouseId,
    String? name,
  }) async {
    if (_token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final newDevice = await _service.claimDevice(
        token: _token!,
        macAddress: macAddress,
        secret: secret,
        greenhouseId: greenhouseId,
        name: name,
      );
      _devices.add(newDevice);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDevice({
    required String id,
    String? name,
    String? macAddress,
  }) async {
    if (_token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updated = await _service.updateDevice(
        token: _token!,
        id: id,
        name: name,
        macAddress: macAddress,
      );
      final index = _devices.indexWhere((d) => d.id == id);
      if (index != -1) {
        _devices[index] = updated;
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteDevice(String id) async {
    if (_token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _service.deleteDevice(_token!, id);
      _devices.removeWhere((d) => d.id == id);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Device> getDevicesByGreenhouse(String greenhouseId) {
    return _devices.where((d) => d.greenhouseId == greenhouseId).toList();
  }

  Map<String, List<String>> getGreenhouseDeviceMap() {
    final Map<String, List<String>> map = {};
    for (final device in _devices) {
      map.putIfAbsent(device.greenhouseId, () => []).add(device.macAddress);
    }
    return map;
  }
}
