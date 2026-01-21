import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/scheduling_service.dart';

import '../utils/db/user_db_helper.dart';
import 'login_screen.dart';
import 'home/contact_screen.dart';

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
    // Request permissions first
    await _requestPermissions();
    // Initialize Scheduling
    await SchedulingService.initialize();
    // Check Session
    await _checkSession();
  }

  Future<void> _requestPermissions() async {
    // Defines the list of permissions to request
    Map<Permission, PermissionStatus> statuses = await [
      Permission.sms,
      Permission.phone,
      Permission.contacts,
      Permission.scheduleExactAlarm,
      Permission.notification,
      Permission.storage,
    ].request();

    // Log the results (optional: handle denied permissions if needed)
    statuses.forEach((permission, status) {
      debugPrint('Permission $permission: $status');
    });
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
