import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceUtils {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- STRING ---
  static Future<bool> saveString(String key, String value) async {
    return _prefs.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs.getString(key);
  }

  // --- INT ---
  static Future<bool> saveInt(String key, int value) async {
    return _prefs.setInt(key, value);
  }

  static int getInt(String key) {
    return _prefs.getInt(key) ?? 0;
  }

  // --- BOOL (generic) ---
  static Future<bool> saveBoolean(String key, bool value) async {
    return _prefs.setBool(key, value);
  }

  static Future<bool> getFirstTime(String key) async {
    await init();
    return _prefs.getBool(key) ?? true;
  }

  static bool getBoolean(String key) {
    return _prefs.getBool(key) ?? false;
  }

  static bool getNotification(String key) {
    return _prefs.getBool(key) ?? true;
  }

  // --- Specific flags ---
  static bool? getIsFacebookInstaller() {
    return _prefs.getBool('isFacebookInstaller');
  }

  static bool? getIsUnityInstaller() {
    return _prefs.getBool('isUnityInstaller');
  }

  static bool? getIsGoogleAdInstaller() {
    return _prefs.getBool('isGoogleAdsInstaller');
  }

  static bool? getIsGoogleAdInstallChecked() {
    return _prefs.getBool('isGoogleAdsInstallerCheck');
  }

  static Future<void> setIsGoogleAdInstallChecked(bool val) async {
    await _prefs.setBool('isGoogleAdsInstallerCheck', val);
  }

  static Future<void> setIsFacebookInstaller(bool val) async {
    await _prefs.setBool('isFacebookInstaller', val);
  }

  static Future<void> setIsUnityInstaller(bool val) async {
    await _prefs.setBool('isUnityInstaller', val);
  }

  static Future<void> setIsGoogleAdInstaller(bool val) async {
    await _prefs.setBool('isGoogleAdsInstaller', val);
  }

  // --- Coin / Usage ---
  static Future<bool> saveCoin(String key, int value) async {
    return _prefs.setInt(key, value);
  }

  static int getCoin(String key) {
    return _prefs.getInt(key) ?? 0;
  }

  static Future<bool> saveUsage(String key, int value) async {
    return _prefs.setInt(key, value);
  }

  static int getUsage(String key) {
    return _prefs.getInt(key) ?? 0;
  }

  // --- LIST ---
  static Future<bool> saveStringList(String key, List<String> list) async {
    return _prefs.setString(key, json.encode(list));
  }

  static List<String> getStringList(String key) {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => e.toString()).toList();
  }
}
