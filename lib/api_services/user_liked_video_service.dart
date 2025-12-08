import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserLikedVideoService{
  static final FlutterSecureStorage storage = FlutterSecureStorage();

  static String key = "likedVideosList";

 static Future<void> saveLikedVideoList(List values) async {
    String encodedList = jsonEncode(values);
    await storage.write(key: key, value: encodedList);
  }

  static Future<List> getLikedVideoList() async {
    String? encodedList = await storage.read(key: key);
    if (encodedList == null) return [];
    return List.from(jsonDecode(encodedList));
  }

}