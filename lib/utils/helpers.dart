// lib/utils/helpers.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:async';
import 'package:voice_call_application/utils/constants.dart';

class Helpers {
  // Format duration to HH:MM:SS or MM:SS
  static String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  // Format date time
  static String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE HH:mm').format(dateTime);
    } else {
      return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
    }
  }

  // Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  // Get initials from name
  static String getInitials(String name) {
    if (name.isEmpty) return '?';

    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    } else {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
  }

  // Generate random color
  static Color getRandomColor(String seed) {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.orange,
      Colors.deepOrange,
    ];

    final index = seed.hashCode % colors.length;
    return colors[index.abs()];
  }

  // Validate email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate phone number
  static bool isValidPhone(String phone) {
    return RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(phone) && phone.length >= 10;
  }

  // Show snackbar
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: action,
      ),
    );
  }

  // Show error snackbar
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    showSnackBar(
      context,
      message,
      backgroundColor: AppColors.error,
      duration: duration,
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    );
  }

  // Show success snackbar
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.green,
      duration: duration,
    );
  }

  // Show loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  // Show confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              cancelText,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmText,
              style: TextStyle(
                color: isDangerous ? AppColors.error : AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // Check internet connectivity with multiple methods
  static Future<bool> checkInternetConnection() async {
    try {
      print('Checking internet connection...');

      // Method 1: Try to lookup Google DNS
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('Internet connection: Available (Google DNS)');
        return true;
      }
    } on SocketException catch (e) {
      print('Internet connection: Failed (SocketException: $e)');
    } on TimeoutException catch (e) {
      print('Internet connection: Timeout ($e)');
    } catch (e) {
      print('Internet connection: Error ($e)');
    }

    // Method 2: Try Firebase as backup
    try {
      final result = await InternetAddress.lookup(
        'firebase.google.com',
      ).timeout(const Duration(seconds: 5));

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('Internet connection: Available (Firebase)');
        return true;
      }
    } catch (e) {
      print('Internet connection: Firebase lookup also failed');
    }

    print('Internet connection: Not available');
    return false;
  }

  // Check internet and show error if not available
  static Future<bool> checkInternetWithDialog(BuildContext context) async {
    final hasInternet = await checkInternetConnection();

    if (!hasInternet && context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Row(
            children: [
              Icon(Icons.wifi_off, color: AppColors.error),
              SizedBox(width: 8),
              Text(
                'No Internet',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
          content: const Text(
            'Please check your internet connection and try again.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // Retry check
                await Future.delayed(const Duration(seconds: 1));
                await checkInternetWithDialog(context);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return hasInternet;
  }

  // Debounce function
  static Timer? _debounceTimer;

  static void debounce(
    Function() function, {
    Duration delay = const Duration(milliseconds: 500),
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, function);
  }

  // Throttle function
  static DateTime? _lastThrottleTime;

  static void throttle(
    Function() function, {
    Duration delay = const Duration(milliseconds: 500),
  }) {
    final now = DateTime.now();

    if (_lastThrottleTime == null ||
        now.difference(_lastThrottleTime!) > delay) {
      _lastThrottleTime = now;
      function();
    }
  }

  // Copy to clipboard
  static Future<void> copyToClipboard(
    BuildContext context,
    String text, {
    String? successMessage,
  }) async {
    try {
      // You would need to add clipboard package for this
      // import 'package:flutter/services.dart';
      // await Clipboard.setData(ClipboardData(text: text));

      if (context.mounted) {
        showSuccessSnackBar(context, successMessage ?? 'Copied to clipboard');
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, 'Failed to copy');
      }
    }
  }

  // Format phone number
  static String formatPhoneNumber(String phone) {
    // Remove all non-digit characters
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 10) {
      // Format as (XXX) XXX-XXXX
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    } else if (digits.length == 11 && digits.startsWith('1')) {
      // Format as +1 (XXX) XXX-XXXX
      return '+1 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    }

    // Return original if can't format
    return phone;
  }

  // Truncate text with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Check if string is null or empty
  static bool isNullOrEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }

  // Safe parse int
  static int? parseInt(String? value) {
    if (value == null) return null;
    return int.tryParse(value);
  }

  // Safe parse double
  static double? parseDouble(String? value) {
    if (value == null) return null;
    return double.tryParse(value);
  }

  // Show bottom sheet
  static Future<T?> showCustomBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: child,
      ),
    );
  }

  // Get greeting based on time
  static String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  // Check if email domain is valid
  static bool isValidEmailDomain(String email) {
    if (!isValidEmail(email)) return false;

    final domain = email.split('@').last.toLowerCase();
    final invalidDomains = ['test.com', 'example.com', 'temp.com'];

    return !invalidDomains.contains(domain);
  }

  // Generate random string
  static String generateRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;

    return List.generate(
      length,
      (index) => chars[(random + index) % chars.length],
    ).join();
  }

  // Format call type
  static String formatCallType(String type) {
    switch (type.toLowerCase()) {
      case 'incoming':
        return 'Incoming';
      case 'outgoing':
        return 'Outgoing';
      case 'missed':
        return 'Missed';
      default:
        return type;
    }
  }

  // Get call type icon
  static IconData getCallTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'incoming':
        return Icons.call_received;
      case 'outgoing':
        return Icons.call_made;
      case 'missed':
        return Icons.call_missed;
      default:
        return Icons.call;
    }
  }

  // Get call type color
  static Color getCallTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'incoming':
        return Colors.green;
      case 'outgoing':
        return Colors.blue;
      case 'missed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Calculate time ago
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return formatDateTime(dateTime);
    }
  }
}
