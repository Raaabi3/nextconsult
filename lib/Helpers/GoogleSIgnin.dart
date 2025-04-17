import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/io_client.dart' as auth;

import '../Models/UserModel.dart';
import 'LocalStorageService.dart';

Future<drive.DriveApi> getDriveApi() async {
  final client = await authenticate();
  return drive.DriveApi(client);
}

final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: <String>[
    'email',
    drive.DriveApi.driveFileScope,
    drive.DriveApi.driveAppdataScope,
    drive.DriveApi.driveScope,
  ],
);

Future<void> signInWithGoogle(BuildContext context) async {
  try {
    final account = await _googleSignIn.signIn();
    if (account != null) {
      final user = UserModel(
        id: account.id,
        name: account.displayName ?? 'Google User',
        email: account.email,
        passwordHash: '12345678',
      );
      await LocalStorageService.saveUser(user);
      Navigator.of(context).pushReplacementNamed('/upload');
    }
    print("logi nsuccessful !!!!!!" + account.toString());
  } catch (error) {
    print("❌ Google Sign-In Failed: $error");
  }
}

Future<auth.AuthClient> authenticate() async {
  final account = await _googleSignIn.signIn();
  if (account == null) {
    throw Exception("Google sign-in failed.");
  }

  final authHeaders = await account.authHeaders;
  final baseClient = auth.IOClient();

  return auth.authenticatedClient(
    baseClient,
    auth.AccessCredentials(
      auth.AccessToken(
        'Bearer',
        authHeaders['Authorization']!.replaceFirst('Bearer ', ''),
        DateTime.now().add(Duration(hours: 1)).toUtc(),
      ),
      null,
      [drive.DriveApi.driveFileScope],
    ),
  );
}
