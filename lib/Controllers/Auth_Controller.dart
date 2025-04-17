import 'package:flutter/material.dart';
import 'package:nextconsult/Helpers/Hash.dart';
import 'package:nextconsult/Services/BlockedService.dart';

import '../Helpers/BiometricService.dart';
import '../Helpers/LocalStorageService.dart';
import '../Models/UserModel.dart';

class AuthController with ChangeNotifier {
  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();
  final signupNameController = TextEditingController();
  final signupEmailController = TextEditingController();
  final signupPasswordController = TextEditingController();
  final signupConfirmPasswordController = TextEditingController();
  static const unlockCode = '123456'; // The unlock code
  static const maxFailedAttempts = 3;
  final loginFormKey = GlobalKey<FormState>();
  final signupFormKey = GlobalKey<FormState>();

  bool _isLogin = true;
  bool _isLoading = false;

  bool get isLogin => _isLogin;
  bool get isLoading => _isLoading;

  void setisloading(value) => _isLoading = value;

  final emailController = TextEditingController();

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Send reset link logic
  void sendResetLink(BuildContext context) {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Email field cannot be empty")));
      return;
    }

    if (!isValidEmail(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please enter a valid email")));
      return;
    }

    // Simulate sending email
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Reset link sent to $email")));

    Future.delayed(Duration(seconds: 1), () {
      Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void toggleAuthMode() {
    clearControllers();
    _isLogin = !_isLogin;
    notifyListeners();
  }

  void clearControllers() {
    loginEmailController.clear();
    loginPasswordController.clear();
    signupNameController.clear();
    signupEmailController.clear();
    signupPasswordController.clear();
    signupConfirmPasswordController.clear();
  }

  void disposeControllers() {
    loginEmailController.dispose();
    loginPasswordController.dispose();
    signupNameController.dispose();
    signupEmailController.dispose();
    signupPasswordController.dispose();
    signupConfirmPasswordController.dispose();
  }

  Future<bool> isAccountLocked() async {
    final user = await LocalStorageService.getUser();
    return user?.isLocked == true;
  }

  Future<void> submitLogin(BuildContext context) async {
    if (!loginFormKey.currentState!.validate()) return;
    setisloading(true);
    notifyListeners();

    try {
      final savedUser = await LocalStorageService.getUser();
      final enteredPassword = loginPasswordController.text;

      // Check if account is locked
      if (savedUser?.isLocked == true) {
        // Check if unlock code is entered
        if (enteredPassword == unlockCode) {
          // Unlock the account
          savedUser!.isLocked = false;
          savedUser.failedLoginAttempts = 0;
          savedUser.lockTime = null;
          await LocalStorageService.saveUser(savedUser);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Account unlocked successfully! Please login with your credentials.',
              ),
            ),
          );
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account locked. Enter unlock code to unlock.'),
            ),
          );
          return;
        }
      }

      // Normal login validation
      if (savedUser == null ||
          savedUser.email != loginEmailController.text ||
          savedUser.passwordHash != hashPassword(enteredPassword)) {
        // Only increment attempts if the email matches an existing user
        if (savedUser != null && savedUser.email == loginEmailController.text) {
          savedUser.failedLoginAttempts++;

          // Lock account if max attempts reached
          if (savedUser.failedLoginAttempts >= maxFailedAttempts) {
            savedUser.isLocked = true;
            savedUser.lockTime = DateTime.now();
            Blockedservice().sendEmail(
              email: 'test@gmail.com',
              time: DateTime.now().toString(),
              passcode: 123456,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Account locked due to too many failed attempts. Enter unlock code to unlock.',
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Invalid credentials. ${maxFailedAttempts - savedUser.failedLoginAttempts} attempts remaining.',
                ),
              ),
            );
          }

          await LocalStorageService.saveUser(savedUser);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Invalid credentials')));
        }
        return;
      }

      // Successful login - reset attempts
      savedUser.isLoggedIn = true;
      savedUser.failedLoginAttempts = 0;
      savedUser.isLocked = false;
      savedUser.lockTime = null;
      await LocalStorageService.saveUser(savedUser);
      Navigator.of(context).pushReplacementNamed('/upload');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: ${e.toString()}')));
    } finally {
      setisloading(false);
      notifyListeners();
    }
  }

  Future<void> submitSignup(BuildContext context) async {
    if (!signupFormKey.currentState!.validate()) return;

    // Verify passwords match
    if (signupPasswordController.text != signupConfirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setisloading(true);
    notifyListeners();

    try {
      final user = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: signupNameController.text,
        email: signupEmailController.text,
        passwordHash: hashPassword(
          signupPasswordController.text,
        ), // Store hashed
      );

      await LocalStorageService.saveUser(user);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signup successful! Please login'),
          duration: Duration(seconds: 3),
        ),
      );

      _isLogin = true;
      notifyListeners();

      signupNameController.clear();
      signupEmailController.clear();
      signupPasswordController.clear();
      signupConfirmPasswordController.clear();
    } catch (e) {
      print("Signup error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Signup failed: $e')));
    } finally {
      setisloading(false);
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String? validateLoginEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value))
      return 'Enter a valid email';
    return null;
  }

  String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 6) return 'Min 6 characters required';
    return null;
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) return 'Enter your name';
    return null;
  }

  String? validateSignupEmail(String? value) => validateLoginEmail(value);

  String? validateSignupPassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter a password';
    if (value.length < 8) return 'Min 8 characters';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Include an uppercase letter';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Include a number';
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != signupPasswordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> logout(BuildContext context) async {
    final user = await LocalStorageService.getUser();
    if (user != null) {
      user.isLoggedIn = false;
      user.failedLoginAttempts = 0; // Reset failed attempts on logout
      await LocalStorageService.saveUser(user);
    }
    // Clear all controllers
    clearControllers();
    // Navigate back to auth screen
    Navigator.of(context).pushReplacementNamed('/auth');
  }
}
