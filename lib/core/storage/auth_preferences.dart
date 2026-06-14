import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';

abstract final class AuthPreferences {
  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  static Future<bool> getRememberMe() async {
    final prefs = await _prefs;
    return prefs.getBool(StorageKeys.rememberMe) ?? false;
  }

  static Future<void> setRememberMe(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(StorageKeys.rememberMe, value);
  }
}
