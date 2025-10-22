// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../services/auth_service.dart';
import '../../utils/helpers.dart';
import 'register_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;

    // Check internet connection first
    final hasInternet = await Helpers.checkInternetConnection();
    if (!hasInternet && mounted) {
      Helpers.showErrorSnackBar(
        context,
        'No internet connection. Please check your network and try again.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final email = _emailController.text.trim();

      print('🔐 Attempting login for: $email');

      // Sign in with timeout
      final userCredential = await authService
          .signInWithEmail(email: email, password: _passwordController.text)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException(
                'Login timeout. Please check your internet connection.',
              );
            },
          );

      if (userCredential != null && mounted) {
        print('✅ Login successful: ${userCredential.user?.uid}');

        // Show success message
        Helpers.showSuccessSnackBar(
          context,
          'Welcome back, ${userCredential.user?.displayName ?? 'User'}!',
        );

        // Wait for auth state to propagate
        await Future.delayed(const Duration(milliseconds: 500));

        // Navigate to home screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } on TimeoutException catch (e) {
      print('⏱️ Timeout error: $e');
      if (mounted) {
        Helpers.showErrorSnackBar(
          context,
          'Login timeout. Please check your internet connection and try again.',
        );
      }
    } catch (e) {
      print('❌ Login error: $e');
      if (mounted) {
        Helpers.showErrorSnackBar(context, _getErrorMessage(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String error) {
    // Handle specific error messages
    if (error.contains('network-request-failed') || error.contains('network')) {
      return 'Network error. Please check your internet connection.';
    } else if (error.contains('user-not-found')) {
      return 'No account found with this email.';
    } else if (error.contains('wrong-password') ||
        error.contains('invalid-credential')) {
      return 'Incorrect email or password.';
    } else if (error.contains('invalid-email')) {
      return 'Invalid email address.';
    } else if (error.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later.';
    } else if (error.contains('timeout')) {
      return 'Request timeout. Please check your connection and try again.';
    } else if (error.contains('user-disabled')) {
      return 'This account has been disabled.';
    }

    // Return a generic message if no specific match
    return 'Login failed. Please check your credentials and try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.call,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Greeting & Title
                  Text(
                    Helpers.getGreeting(),
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to continue',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 40),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white10,
                    ),
                    validator: (value) {
                      if (Helpers.isNullOrEmpty(value)) {
                        return 'Please enter your email';
                      }
                      if (!Helpers.isValidEmail(value!)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white10,
                    ),
                    validator: (value) {
                      if (Helpers.isNullOrEmpty(value)) {
                        return 'Please enter your password';
                      }
                      if (value!.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Sign in button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        disabledBackgroundColor: Colors.blue.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
