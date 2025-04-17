import 'package:flutter/material.dart';
import 'package:nextconsult/Views/ForgotPAssword.dart';
import 'package:nextconsult/Widgets/CustomButton.dart';
import 'package:nextconsult/Widgets/CustomTextField.dart';

import '../Helpers/BiometricService.dart';
import '../Helpers/LocalStorageService.dart';
import '../Models/UserModel.dart';

class Signinform extends StatelessWidget {
  final dynamic authController;
  const Signinform({super.key, required this.authController});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: authController.loginFormKey,
      child: Column(
        children: [
          CustomTextField(
            controller: authController.loginEmailController,
            hintText: "Email",
            obscureText: false,
            icon: Icons.email,
            validator: authController.validateLoginEmail,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: authController.loginPasswordController,
            hintText: "Password",
            obscureText: true,
            icon: Icons.lock,
            validator: authController.validateLoginPassword,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Forgotpassword(),
                  ),
                );
              },
              child: Text(
                "Forgot Password?",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: "Login",
            onPressed:
                authController.isLoading
                    ? null
                    : () => authController.submitLogin(context),
            isLoading: authController.isLoading,
          ),
          IconButton(
            icon: const Icon(Icons.fingerprint, size: 36),
            onPressed: () async {
              final savedUser = await LocalStorageService.getUser();
              if (savedUser == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No user account found')),
                );
                return;
              }

              final success = await BiometricService.authenticate();
              if (success) {
                savedUser.isLoggedIn = true;
                await LocalStorageService.saveUser(savedUser);
                Navigator.of(context).pushReplacementNamed('/upload');
              }
            },
          ),
           FutureBuilder<UserModel?>(
            future: LocalStorageService.getUser(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data?.isLocked == true) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Account locked. Enter unlock code in password field.',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
