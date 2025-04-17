import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nextconsult/Services/EmailService.dart';
import 'package:nextconsult/Views/AuthScreen.dart';
import 'package:nextconsult/Views/DriveScreen.dart';
import 'package:nextconsult/Views/WelcomeScreen.dart';
import 'package:provider/provider.dart';
import 'Controllers/Auth_Controller.dart';
import 'Helpers/BiometricService.dart';
import 'Helpers/LocalStorageService.dart';
import 'Views/HomeScreen.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  bool isAuthenticated = false;

  ChangeNotifierProvider(create: (_) => AuthController());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => EmailService()),
      ],
      child: MyApp(isLoggedIn: isAuthenticated),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/upload': (context) => const UploadScreen(),
      },

      home: isLoggedIn ? const UploadScreen() : const Welcomescreen(),
    );
  }
}
