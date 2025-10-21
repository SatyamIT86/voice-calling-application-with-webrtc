// lib/services/speech_to_text_service.dart
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechToTextService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String _currentTranscript = '';

  // Callbacks
  Function(String transcript)? onTranscriptUpdate;
  Function(String finalTranscript)? onFinalTranscript;
  Function(String error)? onError;

  // Initialize speech recognition
  Future<bool> initialize() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        onError?.call('Microphone permission not granted');
        return false;
      }

      // Initialize speech to text
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          print('Speech recognition error: ${error.errorMsg}');
          onError?.call(error.errorMsg);
        },
        onStatus: (status) {
          print('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );

      if (_isInitialized) {
        print('Speech to text initialized successfully');
      } else {
        print('Speech to text initialization failed');
      }

      return _isInitialized;
    } catch (e) {
      print('Error initializing speech to text: $e');
      onError?.call('Initialization error: $e');
      return false;
    }
  }

  // Start listening
  Future<bool> startListening({String? localeId}) async {
    if (!_isInitialized) {
      print('Speech to text not initialized');
      return false;
    }

    if (_isListening) {
      print('Already listening');
      return true;
    }

    try {
      _currentTranscript = '';

      await _speechToText.listen(
        onResult: (result) {
          _currentTranscript = result.recognizedWords;

          // Update transcript in real-time
          onTranscriptUpdate?.call(_currentTranscript);

          // If final result, trigger callback
          if (result.finalResult) {
            onFinalTranscript?.call(_currentTranscript);
          }
        },
        listenFor: const Duration(minutes: 30), // Max duration
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        onSoundLevelChange: (level) {
          // Can be used for visual feedback
        },
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
        localeId: localeId,
      );

      _isListening = true;
      print('Started listening for speech');
      return true;
    } catch (e) {
      print('Error starting speech recognition: $e');
      onError?.call('Error starting recognition: $e');
      return false;
    }
  }

  // Stop listening
  Future<void> stopListening() async {
    if (!_isListening) {
      return;
    }

    try {
      await _speechToText.stop();
      _isListening = false;
      print('Stopped listening for speech');

      // Trigger final transcript
      if (_currentTranscript.isNotEmpty) {
        onFinalTranscript?.call(_currentTranscript);
      }
    } catch (e) {
      print('Error stopping speech recognition: $e');
    }
  }

  // Cancel listening
  Future<void> cancelListening() async {
    try {
      await _speechToText.cancel();
      _isListening = false;
      _currentTranscript = '';
      print('Cancelled speech recognition');
    } catch (e) {
      print('Error cancelling speech recognition: $e');
    }
  }

  // Get available locales
  Future<List<LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      return [];
    }

    try {
      return await _speechToText.locales();
    } catch (e) {
      print('Error getting locales: $e');
      return [];
    }
  }

  // Get system locale - FIXED: Added parentheses to call the function
  Future<LocaleName?> getSystemLocale() async {
    return await _speechToText.systemLocale();
  }

  // Check if speech recognition is available
  bool get isAvailable => _speechToText.isAvailable;

  // Check if currently listening
  bool get isListening => _isListening;

  // Get current transcript
  String get currentTranscript => _currentTranscript;

  // Dispose
  void dispose() {
    if (_isListening) {
      _speechToText.stop();
    }
  }
}
