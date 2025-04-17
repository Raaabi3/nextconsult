import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis_auth/auth_io.dart';

class SecureStorage {
  final storage = FlutterSecureStorage();

  // Save credentials
  Future<void> saveCredentials(AccessToken token, String refreshToken) async {
    await storage.write(key: 'type', value: token.type);
    await storage.write(key: 'data', value: token.data);
    await storage.write(key: 'expiry', value: token.expiry.toIso8601String());
    await storage.write(key: 'refreshToken', value: refreshToken);
  }

  // Retrieve saved credentials
  Future<Map<String, dynamic>?> getCredentials() async {
    final result = await storage.readAll();
    if (result.isEmpty) return null;
    return result;
  }

  // Clear credentials
  Future<void> clear() async {
    await storage.deleteAll();
  }
}
