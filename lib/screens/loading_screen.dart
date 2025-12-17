import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_number/mobile_number.dart';
import '../utils/db/user_db_helper.dart';
import 'login_screen.dart';
import 'home/home_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // 1. Request Permissions
    await _checkPermissions();

    // 2. Check Session
    await _checkSession();
  }

  Future<void> _checkPermissions() async {
    // Request all necessary permissions
    await [
      Permission.sms,
      Permission.contacts,
      Permission.phone,
      Permission.notification,
    ].request();

    // Specific check for MobileNumber plugin
    try {
      if (!await MobileNumber.hasPhonePermission) {
        await MobileNumber.requestPhonePermission;
      }
    } catch (e) {
      debugPrint('Error checking mobile number permission: $e');
    }
  }

  Future<void> _checkSession() async {
    // Add a small delay to show the logo/loading state
    await Future.delayed(const Duration(seconds: 2));

    try {
      final user = await UserDbHelper().getUser();
      if (user != null &&
          user.access_token != null &&
          user.access_token!.isNotEmpty) {
        debugPrint('Loading: Valid session found. Navigate to Home.');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
        return;
      }
    } catch (e) {
      debugPrint('Loading: Error checking session: $e');
    }

    debugPrint('Loading: No valid session. Navigate to Login.');
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png', // Ensure this asset exists as used in LoginScreen
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Colors.amber),
          ],
        ),
      ),
    );
  }
}
