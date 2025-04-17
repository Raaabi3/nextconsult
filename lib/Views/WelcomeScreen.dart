import 'package:flutter/material.dart';
import 'package:nextconsult/Views/AuthScreen.dart';

class Welcomescreen extends StatelessWidget {
  const Welcomescreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () {

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AuthScreen(),
            ),
          );
        },
        child: Icon(Icons.arrow_forward_ios),
        mini: true,
        foregroundColor: Colors.blueAccent,
      ),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset("assets/gifs/Authentication.gif"),
          Text("Welcome to NextConsult", style: TextStyle(fontSize: 20)),
          Text("Please Proceed by entering your credentials"),
        ],
      ),
    );
  }
}
