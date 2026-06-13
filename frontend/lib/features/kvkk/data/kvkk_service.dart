import 'package:shared_preferences/shared_preferences.dart';

class KvkkService {
  static const String _kvkkAcceptedKey = 'kvkk_accepted';

  Future<bool> isAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kvkkAcceptedKey) ?? false;
  }

  Future<void> accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kvkkAcceptedKey, true);
  }

  Future<void> clearAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kvkkAcceptedKey);
  }
}