import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
      return UserModel.fromJsonSafe(jsonDecode(userJson)); // Use the safe method
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

class UserModel {
  final String id;
  final String name;
  final String email;
  final String passwordHash;
  bool isLoggedIn;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.isLoggedIn = false,
  });

  // Safe parsing method
  static UserModel? fromJsonSafe(Map<String, dynamic>? json) {
    if (json == null) return null;
    try {
      return UserModel.fromJson(json);
    } catch (e) {
      print('Error creating UserModel: $e');
      return null;
    }
  }

  // Main parsing method
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      passwordHash: json['passwordHash'] as String,
      isLoggedIn: json['isLoggedIn'] as bool? ?? false,
    );
  }

  // Add this complete toJson() method
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'passwordHash': passwordHash,
    'isLoggedIn': isLoggedIn,
  };
}