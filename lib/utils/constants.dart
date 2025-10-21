// lib/utils/constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'Filament Voice Call';
  static const String appVersion = '1.0.0';

  // Signaling Server URL
  // IMPORTANT: Update this with your deployed signaling server URL
  // For local testing: 'http://10.0.2.2:3000' (Android Emulator)
  // For physical device: 'http://YOUR_LOCAL_IP:3000'
  // For production: 'https://your-server.render.com'
  static const String signalingServerUrl = 'YOUR_SIGNALING_SERVER_URL';

  // STUN Servers (Google's free STUN servers)
  static const List<Map<String, String>> stunServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:stun2.l.google.com:19302'},
    {'urls': 'stun:stun3.l.google.com:19302'},
    {'urls': 'stun:stun4.l.google.com:19302'},
  ];

  // Timeouts
  static const Duration authTimeout = Duration(seconds: 30);
  static const Duration callTimeout = Duration(seconds: 60);
  static const Duration signalingTimeout = Duration(seconds: 10);

  // Recording Settings
  static const int recordingBitRate = 128000;
  static const int recordingSampleRate = 44100;
  static const int maxRecordingDuration = 7200; // 2 hours in seconds

  // UI Settings
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;

  // Database
  static const String dbName = 'filament_voice_app.db';
  static const int dbVersion = 1;
}

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color accent = Color(0xFF03A9F4);

  // Background Colors
  static const Color background = Color(0xFF0F0F1E);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceVariant = Color(0xFF252541);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textHint = Color(0xFF808080);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Call Colors
  static const Color callIncoming = Color(0xFF4CAF50);
  static const Color callOutgoing = Color(0xFF2196F3);
  static const Color callMissed = Color(0xFFF44336);
  static const Color callActive = Color(0xFF00BCD4);
}

class AppStyles {
  // Text Styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: AppColors.textHint,
  );

  // Input Decoration
  static InputDecoration inputDecoration({
    required String label,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      filled: true,
      fillColor: Colors.white10,
    );
  }

  // Button Style
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
    ),
  );

  // Card Decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}
