import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/loading_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home/contact_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home/settings_screen.dart';
import 'screens/home/add_contact_screen.dart';
// import 'services/scheduling_service.dart'; // Removed as it moved to LoadingScreen

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar to transparent with dark icons (light mode style)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          Brightness.dark, // Dark icons for light background
      statusBarBrightness: Brightness.light, // iOS light status bar
    ),
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
        ), // Updated to match design
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoadingScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/signup': (context) => const SignupScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/add_contact': (context) => const AddContactScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
