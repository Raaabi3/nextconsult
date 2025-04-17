import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Services/EmailService.dart';

import '../Controllers/Auth_Controller.dart';

class Forgotpassword extends StatelessWidget {
  const Forgotpassword({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context, listen: false);
    final emailService = Provider.of<EmailService>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          color: Colors.blueAccent,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/gifs/Forgot password.gif", height: 200),
            Text(
              "Forgot Password?",
              style: TextStyle(fontSize: 30, color: Colors.blueAccent),
            ),
            SizedBox(height: 10),
            Text(
              "Please enter your email address to reset your password",
              style: TextStyle(color: Colors.grey, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: authController.emailController,
              decoration: InputDecoration(
                labelText: "Enter your email",
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                bool success = await emailService.sendEmail(
                  email: 'test@gmail.com',
                  time: '19:52',
                  passcode: 123456,
                );
                if (success) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Email sent!')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to send email')),
                  );
                }
                authController.sendResetLink(context);
              },
              child: Text(
                "Send Reset Link",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                fixedSize: Size(200, 50),
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
