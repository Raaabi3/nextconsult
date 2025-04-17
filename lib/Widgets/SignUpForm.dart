import 'package:flutter/material.dart';
import 'package:nextconsult/Widgets/CustomButton.dart';
import 'package:nextconsult/Widgets/CustomTextField.dart';

class Signupform extends StatelessWidget {
  final dynamic authController;
  const Signupform({super.key, required this.authController});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: authController.signupFormKey,
      child: Column(
        children: [
          CustomTextField(
            controller: authController.signupNameController,
            hintText: "Full Name",
            obscureText: false,
            icon: Icons.person,
            validator: authController.validateName,
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: authController.signupEmailController,
            hintText: "Email",
            obscureText: false,
            icon: Icons.email,
            validator: authController.validateSignupEmail,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: authController.signupPasswordController,
            hintText: "Password",
            obscureText: true,
            icon: Icons.lock,
            validator: authController.validateSignupPassword,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: authController.signupConfirmPasswordController,
            hintText: "Confirm Password",
            obscureText: true,
            icon: Icons.lock_outline,
            validator: authController.validateConfirmPassword,
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: "Sign Up",
            onPressed: 
                authController.isLoading
                    ? null
                    : () => authController.submitSignup(
                      context,
                    ), 
            isLoading: authController.isLoading,
          ),
        ],
      ),
    );
  }
}
