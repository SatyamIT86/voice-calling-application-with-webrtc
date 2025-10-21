// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/webrtc_service.dart';
import 'services/signaling_service.dart';
import 'services/recording_service.dart';
import 'services/speech_to_text_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Database Service
        Provider<DatabaseService>(create: (_) => DatabaseService()),

        // Auth Service
        Provider<AuthService>(create: (_) => AuthService()),

        // Signaling Service
        Provider<SignalingService>(create: (_) => SignalingService()),

        // Recording Service
        ProxyProvider<DatabaseService, RecordingService>(
          update: (_, dbService, __) =>
              RecordingService(databaseService: dbService),
        ),

        // WebRTC Service
        ProxyProvider2<SignalingService, RecordingService, WebRTCService>(
          update: (_, signalingService, recordingService, __) => WebRTCService(
            signalingService: signalingService,
            recordingService: recordingService,
          ),
        ),

        // Speech to Text Service
        Provider<SpeechToTextService>(create: (_) => SpeechToTextService()),
      ],
      child: MaterialApp(
        title: 'Filament Voice Call',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F0F1E),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1A1A2E),
            elevation: 0,
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
