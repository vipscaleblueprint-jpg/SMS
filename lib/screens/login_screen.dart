import 'package:flutter/material.dart';
import 'package:mobile_number/mobile_number.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../utils/db/user_db_helper.dart';

import 'signup_screen.dart';
import 'otp_screen.dart';
import 'home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  bool _rememberMe = false;
  bool _isCheckingSession = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Add a small delay to prevent flickering if checking is too fast
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final user = await UserDbHelper().getUser();
      if (user != null) {
        debugPrint('Session Check: User found: ${user.email}');
        if (user.access_token != null && user.access_token!.isNotEmpty) {
          debugPrint('Session Check: Valid token found. Redirecting to Home.');
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
          return;
        } else {
          debugPrint('Session Check: User found but no token.');
        }
      } else {
        debugPrint('Session Check: No user found in DB.');
      }
    } catch (e) {
      debugPrint('Session Check: Error checking session: $e');
    }

    if (mounted) {
      setState(() {
        _isCheckingSession = false;
      });
    }
  }

  Future<void> _checkPermissions() async {
    // Request Phone permission via MobileNumber plugin logic
    // Note: On newer Android versions, getting the phone number is restricted.
    // This adds the permission request flow.
    try {
      if (!await MobileNumber.hasPhonePermission) {
        await MobileNumber.requestPhonePermission;
      }
    } catch (e) {
      // Handle or ignore platform errors (e.g. simulator)
      debugPrint('Error checking mobile number permission: $e');
    }

    // Request SMS permission
    await Permission.sms.request();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your email')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse(
        'https://n8n.srv1151765.hstgr.cloud/webhook/sms/auth',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['success'] == true) {
          if (mounted) {
            // Navigate to OTP Screen
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => OtpScreen(email: email)),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Failed to send OTP')));
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToSignUp() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SignupScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isCheckingSession
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),
                    // Logo Area
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 48),

                    const Text(
                      'Sign in',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Email Field
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Remember Me Checkbox
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          activeColor: Colors.amber,
                        ),
                        const Text('Remember Me'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),

                    const Center(
                      child: Text(
                        'Or',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sign Up Button (Replacing Google Sign In)
                    OutlinedButton(
                      onPressed: _navigateToSignUp,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        side: const BorderSide(color: Colors.amber),
                        foregroundColor: Colors.amber,
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
