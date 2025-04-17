import 'package:flutter/material.dart';
import 'package:nextconsult/Helpers/FacebookSIgnIn.dart';
import 'package:nextconsult/Helpers/GoogleSIgnin.dart';
import 'package:nextconsult/Widgets/CustomButton.dart';
import 'package:nextconsult/Widgets/CustomTextField.dart';
import 'package:nextconsult/Widgets/SignInForm.dart';
import 'package:nextconsult/Widgets/SignUpForm.dart';
import '../Controllers/Auth_Controller.dart';
import '../Helpers/BiometricService.dart';
import '../Helpers/LocalStorageService.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  void initState() {
    super.initState();
    _checkSavedUser();
  }

  void _checkSavedUser() async {
  final savedUser = await LocalStorageService.getUser();
  if (savedUser != null && savedUser.isLoggedIn) {
    Navigator.of(context).pushReplacementNamed('/upload');
  }
}


  final AuthController _authController = AuthController();

  @override
  void dispose() {
    _authController.disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _authController,
          builder: (context, _) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Image.asset(
                        "assets/gifs/Login.gif",
                        height: 200,
                        key: ValueKey<bool>(_authController.isLogin),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _authController.isLogin
                          ? "Welcome to NextConsult"
                          : "Create an Account",
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _authController.isLogin
                          ? "Login to your account"
                          : "Fill in your details",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder:
                          (child, animation) => FadeTransition(
                            opacity: animation,
                            child: SizeTransition(
                              sizeFactor: animation,
                              axisAlignment: -1.0,
                              child: child,
                            ),
                          ),
                      child:
                          _authController.isLogin
                              ? Signinform(authController: _authController)
                              : Signupform(authController: _authController),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          
                          GestureDetector(
                            onTap: signInWithFacebook,
                            child: CircleAvatar(
                              foregroundImage:AssetImage("assets/logos/facebook.png")
                            ),
                          ),
                          SizedBox(width: 20),
                          GestureDetector(
                            onTap: () async {
                             await signInWithGoogle(context);
                              
                            },
                            child: CircleAvatar(
                              foregroundImage:AssetImage("assets/logos/google.png")
                            ),
                          ),
                          
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _authController.isLogin
                              ? "Don't have an account?"
                              : "Already have an account?",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: _authController.toggleAuthMode,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              _authController.isLogin ? "Sign Up" : "Login",
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
