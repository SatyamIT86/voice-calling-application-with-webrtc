// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../services/auth_service.dart';
import '../../utils/helpers.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;

    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      Helpers.showErrorSnackBar(context, 'Passwords do not match');
      return;
    }

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
      final name = _nameController.text.trim();

      print('📝 Attempting registration for: $email');

      // Sign up with timeout
      final userCredential = await authService
          .signUpWithEmail(
            email: email,
            password: _passwordController.text,
            name: name,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException(
                'Registration timeout. Please check your internet connection.',
              );
            },
          );

      if (userCredential != null && mounted) {
        print('✅ Registration successful: ${userCredential.user?.uid}');

        // Show success message
        Helpers.showSuccessSnackBar(
          context,
          'Welcome, $name! Your account has been created successfully.',
        );

        // Wait for auth state to propagate
        await Future.delayed(const Duration(milliseconds: 500));

        // Navigate to home screen and remove all previous routes
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      }
    } on TimeoutException catch (e) {
      print('⏱️ Timeout error: $e');
      if (mounted) {
        Helpers.showErrorSnackBar(
          context,
          'Registration timeout. Please check your internet connection and try again.',
        );
      }
    } catch (e) {
      print('❌ Registration error: $e');
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
    } else if (error.contains('email-already-in-use')) {
      return 'This email is already registered. Please sign in instead.';
    } else if (error.contains('weak-password')) {
      return 'Password is too weak. Please use at least 6 characters.';
    } else if (error.contains('invalid-email')) {
      return 'Invalid email address format.';
    } else if (error.contains('timeout')) {
      return 'Request timeout. Please check your connection and try again.';
    } else if (error.contains('operation-not-allowed')) {
      return 'Email/password registration is not enabled.';
    }

    // Return a generic message if no specific match
    return 'Registration failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        title: const Text('Create Account'),
      ),
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
                      Icons.person_add,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Title
                  const Text(
                    'Join Us Today',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your account to get started',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 40),

                  // Name field
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter your full name',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white10,
                    ),
                    validator: (value) {
                      if (Helpers.isNullOrEmpty(value)) {
                        return 'Please enter your name';
                      }
                      if (value!.length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      if (value.length > 50) {
                        return 'Name is too long';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

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
                        return 'Please enter a valid email address';
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
                      hintText: 'Create a password',
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
                        return 'Please enter a password';
                      }
                      if (value!.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      if (value.length > 50) {
                        return 'Password is too long';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      // Optional: Add password strength indicator
                      setState(() {});
                    },
                  ),

                  // Password strength indicator
                  if (_passwordController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildPasswordStrengthIndicator(),
                  ],

                  const SizedBox(height: 16),

                  // Confirm Password field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Re-enter your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          );
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
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Register button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
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
                              'Create Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Terms and conditions
                  const Text(
                    'By signing up, you agree to our Terms & Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                  const SizedBox(height: 16),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text(
                          'Sign In',
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

  Widget _buildPasswordStrengthIndicator() {
    final password = _passwordController.text;
    final strength = _calculatePasswordStrength(password);

    Color strengthColor;
    String strengthText;

    if (strength < 0.3) {
      strengthColor = Colors.red;
      strengthText = 'Weak';
    } else if (strength < 0.7) {
      strengthColor = Colors.orange;
      strengthText = 'Medium';
    } else {
      strengthColor = Colors.green;
      strengthText = 'Strong';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: strength,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                minHeight: 4,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              strengthText,
              style: TextStyle(
                color: strengthColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;

    double strength = 0;

    // Length check
    if (password.length >= 6) strength += 0.2;
    if (password.length >= 8) strength += 0.2;
    if (password.length >= 12) strength += 0.1;

    // Character variety
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.15;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.15;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.1;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.1;

    return strength > 1.0 ? 1.0 : strength;
  }
}
