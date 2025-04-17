import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/UserModel.dart';
import 'package:open_file/open_file.dart';

class LocalStorageService {
  static const String userKey = 'user'; // Consistent key name

  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, jsonEncode(user.toJson()));
  }

  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(userKey); // Use consistent key
    if (userJson == null) return null;

    try {
      return UserModel.fromJsonSafe(
        jsonDecode(userJson),
      ); // Use the safe method
    } catch (e) {
      print('Error parsing user: $e');
      return null;
    }
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userKey);
  }
}

Future<void> saveFilePath(String path) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> files = prefs.getStringList('savedFiles') ?? [];
  if (!files.contains(path)) {
    files.add(path);
    await prefs.setStringList('savedFiles', files);
  }
}

void openFileExternally(File file) {
  OpenFile.open(file.path);
}
