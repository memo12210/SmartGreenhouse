import 'package:flutter/material.dart';
import 'package:greenhouse_app/core/models.dart';
import 'package:greenhouse_app/core/services/greenhouse_service.dart';

class GreenhouseProvider extends ChangeNotifier {
  final GreenhouseService _service = GreenhouseService();
  String? _token;
  
  List<Greenhouse> _greenhouses = [];
  bool _isLoading = false;
  String? _error;

  List<Greenhouse> get greenhouses => _greenhouses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Method to update token when AuthProvider changes
  void updateToken(String? token) {
    _token = token;
    if (_token != null) {
      fetchGreenhouses();
    } else {
      _greenhouses = [];
      notifyListeners();
    }
  }

  Future<void> fetchGreenhouses() async {
    if (_token == null) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _greenhouses = await _service.getGreenhouses(_token!);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addGreenhouse(String name) async {
    if (_token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final newGh = await _service.createGreenhouse(_token!, name);
      _greenhouses.add(newGh);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteGreenhouse(String id) async {
    if (_token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _service.deleteGreenhouse(_token!, id);
      _greenhouses.removeWhere((gh) => gh.id == id);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
