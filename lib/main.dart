import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'screens/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home/settings_screen.dart';
import 'screens/home/add_contact_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
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
        '/': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/signup': (context) => const SignupScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/add_contact': (context) => const AddContactScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
