import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceUtils {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<bool> saveString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    return _prefs.getString(key);
  }

  static Future<bool> saveInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  static Future<int?> getInt(String key) async {
    await init();
    return _prefs.getInt(key) ?? 0;
  }

  static Future<bool> getFirstTime(String key) async {
    await init();
    return _prefs.getBool(key) ?? true;
  }

  static Future<bool> getBoolean(String key) async {
    await init();
    return _prefs.getBool(key) ?? false;
  }

  static Future<bool> getNotification(String key) async {
    await init();
    return _prefs.getBool(key) ?? true;
  }

  static Future<bool?> getIsFacebookInstaller() async {
    return _prefs.getBool('isFacebookInstaller');
  }

  static Future<bool?> getIsUnityInstaller() async {
    return _prefs.getBool('isUnityInstaller');
  }

  static Future<bool?> getIsGoogleAdInstaller() async {
    return _prefs.getBool('isGoogleAdsInstaller');
  }

  static Future<bool?> getIsGoogleAdInstallChecked() async {
    return _prefs.getBool('isGoogleAdsInstallerCheck');
  }

  static Future<void> setIsGoogleAdInstallChecked(bool val) async {
    await _prefs.setBool('isGoogleAdsInstallerCheck',val);
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

  static Future<bool> saveCoin(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  static Future<int?> getCoin(String key) async {
    return _prefs.getInt(key);
  }

  static Future<bool> saveUsage(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  static Future<bool> saveBoolean(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  static Future<int?> getUsage(String key) async {
    return _prefs.getInt(key) ?? 0;
  }

  static Future<bool> saveStringList(String key, List<String> list) async {
    final jsonString = json.encode(list);
    return await _prefs.setString(key, jsonString);
  }

  static Future<List<String>> getStringList(String key) async {
    final jsonString = _prefs.getString(key);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((item) => item.toString()).toList();
    } else {
      return [];
    }
  }
}
