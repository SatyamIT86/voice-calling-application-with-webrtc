// lib/main.dart
import 'package:firebase_auth/firebase_auth.dart';
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
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('Initializing Firebase...');

    // Initialize Firebase with timeout
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        print('Firebase initialization timed out');
        throw Exception('Firebase initialization timeout');
      },
    );

    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
    // Show error dialog or retry logic here
  }

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
        Provider<AuthService>(
          create: (_) {
            final authService = AuthService();
            // Set persistence for auth state
            authService.setPersistence();
            return authService;
          },
        ),

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

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }

        // Show error if there's an error
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Retry logic
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthWrapper()),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // Navigate based on auth state
        if (snapshot.hasData && snapshot.data != null) {
          print('User authenticated: ${snapshot.data!.uid}');
          return const HomeScreen();
        }

        print('User not authenticated');
        return const LoginScreen();
      },
    );
  }
}
