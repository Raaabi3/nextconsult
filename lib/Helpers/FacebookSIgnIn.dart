
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

Future<void> signInWithFacebook() async {
  try {
    final LoginResult result = await FacebookAuth.instance.login(); // permissions: ['email']
    if (result.status == LoginStatus.success) {
      final userData = await FacebookAuth.instance.getUserData();
      print("✅ Facebook Sign-In: ${userData['email']}");
    } else {
      print("❌ Facebook Sign-In Failed: ${result.status}");
    }
  } catch (e) {
    print("❌ Facebook Error: $e");
  }
}