

class UserModel {
  final String id;
  final String name;
  final String email;
  final String passwordHash;
  bool isLoggedIn;
  int failedLoginAttempts; // Track failed attempts
  bool isLocked; // Track lock status
  DateTime? lockTime; // When account was locked

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.isLoggedIn = false,
    this.failedLoginAttempts = 0,
    this.isLocked = false,
    this.lockTime,
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
      failedLoginAttempts: json['failedLoginAttempts'] as int? ?? 0,
      isLocked: json['isLocked'] as bool? ?? false,
      lockTime: json['lockTime'] != null 
          ? DateTime.parse(json['lockTime'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'passwordHash': passwordHash,
    'isLoggedIn': isLoggedIn,
    'failedLoginAttempts': failedLoginAttempts,
    'isLocked': isLocked,
    'lockTime': lockTime?.toIso8601String(),
  };
}