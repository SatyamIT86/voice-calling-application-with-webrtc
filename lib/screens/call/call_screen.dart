// lib/screens/call/call_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../services/webrtc_service.dart';
import '../../services/speech_to_text_service.dart';
import '../../models/contact_model.dart';

class CallScreen extends StatefulWidget {
  final ContactModel contact;
  final bool isIncoming;

  const CallScreen({Key? key, required this.contact, this.isIncoming = false})
    : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late WebRTCService _webrtcService;
  late SpeechToTextService _speechToTextService;

  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isTranscriptionEnabled = true;
  String _liveTranscript = '';
  int _callDuration = 0;
  Timer? _callTimer;
  bool _isConnected = false;
  bool _isEnding = false; // Add flag to prevent multiple end call attempts

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      _webrtcService = context.read<WebRTCService>();
      _speechToTextService = context.read<SpeechToTextService>();

      // Setup callbacks
      _webrtcService.onRemoteStream = (stream) {
        if (mounted) {
          setState(() {
            _isConnected = true;
          });
          _startCallTimer();
          _startTranscription();
        }
      };

      _webrtcService.onCallEnded = () {
        if (mounted && !_isEnding) {
          _endCall();
        }
      };

      _speechToTextService.onTranscriptUpdate = (transcript) {
        if (mounted) {
          setState(() {
            _liveTranscript = transcript;
          });
        }
      };

      // If outgoing call, initiate
      if (!widget.isIncoming) {
        await _makeCall();
      }
    } catch (e) {
      print('Error initializing services: $e');
      if (mounted) {
        _showError('Failed to initialize call: $e');
        Navigator.pop(context);
      }
    }
  }

  Future<void> _makeCall() async {
    try {
      await _webrtcService.makeCall(
        widget.contact.userId,
        'Current User', // Replace with actual user name
      );
    } catch (e) {
      print('Error making call: $e');
      if (mounted) {
        _showError('Failed to make call: $e');
        Navigator.pop(context);
      }
    }
  }

  void _startCallTimer() {
    _callTimer?.cancel(); // Cancel any existing timer
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _startTranscription() async {
    if (_isTranscriptionEnabled) {
      try {
        final initialized = await _speechToTextService.initialize();
        if (initialized && mounted) {
          await _speechToTextService.startListening();
        }
      } catch (e) {
        print('Error starting transcription: $e');
      }
    }
  }

  void _toggleMute() {
    if (!_isEnding) {
      setState(() {
        _isMuted = !_isMuted;
      });
      try {
        _webrtcService.toggleMicrophone(!_isMuted);
      } catch (e) {
        print('Error toggling microphone: $e');
      }
    }
  }

  void _toggleSpeaker() {
    if (!_isEnding) {
      setState(() {
        _isSpeakerOn = !_isSpeakerOn;
        // Implement speaker toggle logic
      });
    }
  }

  void _toggleTranscription() {
    if (!_isEnding) {
      setState(() {
        _isTranscriptionEnabled = !_isTranscriptionEnabled;
      });

      if (_isTranscriptionEnabled) {
        _startTranscription();
      } else {
        try {
          _speechToTextService.stopListening();
        } catch (e) {
          print('Error stopping transcription: $e');
        }
      }
    }
  }

  Future<void> _endCall() async {
    // Prevent multiple simultaneous end call attempts
    if (_isEnding) {
      print('Already ending call, ignoring duplicate request');
      return;
    }

    setState(() {
      _isEnding = true;
    });

    print('Ending call...');

    try {
      // Cancel timer first
      _callTimer?.cancel();
      _callTimer = null;

      // Stop speech to text service
      try {
        await _speechToTextService.stopListening().timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            print('Speech to text stop timed out');
          },
        );
      } catch (e) {
        print('Error stopping speech service: $e');
      }

      // End WebRTC call
      try {
        await _webrtcService.endCall().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            print('WebRTC end call timed out');
          },
        );
      } catch (e) {
        print('Error ending WebRTC call: $e');
      }

      // Navigate back with results
      if (mounted) {
        Navigator.pop(context, {
          'duration': _callDuration,
          'transcript': _liveTranscript,
        });
      }
    } catch (e) {
      print('Error in _endCall: $e');
      // Try to navigate back anyway
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _callTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (!didPop && !_isEnding) {
          await _endCall();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _isEnding ? null : () => _endCall(),
                    ),
                    Text(
                      _isEnding
                          ? 'Ending...'
                          : (_isConnected ? 'Connected' : 'Connecting...'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              const Spacer(),

              // Contact Info
              Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blue,
                    child: Text(
                      widget.contact.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 48,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.contact.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(_callDuration),
                    style: const TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                ],
              ),

              const Spacer(),

              // Live Transcription
              if (_isTranscriptionEnabled && _liveTranscript.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.mic, size: 16, color: Colors.red[400]),
                            const SizedBox(width: 8),
                            const Text(
                              'Live Transcript',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _liveTranscript,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Call Controls
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Top row controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildControlButton(
                          icon: _isMuted ? Icons.mic_off : Icons.mic,
                          label: 'Mute',
                          onPressed: _isEnding ? () {} : _toggleMute,
                          isActive: _isMuted,
                        ),
                        _buildControlButton(
                          icon: _isSpeakerOn
                              ? Icons.volume_up
                              : Icons.volume_down,
                          label: 'Speaker',
                          onPressed: _isEnding ? () {} : _toggleSpeaker,
                          isActive: _isSpeakerOn,
                        ),
                        _buildControlButton(
                          icon: _isTranscriptionEnabled
                              ? Icons.subtitles
                              : Icons.subtitles_off,
                          label: 'Transcript',
                          onPressed: _isEnding ? () {} : _toggleTranscription,
                          isActive: _isTranscriptionEnabled,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    // End call button
                    GestureDetector(
                      onTap: _isEnding ? null : _endCall,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: _isEnding
                              ? Colors.red.withOpacity(0.5)
                              : Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: _isEnding
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.call_end,
                                color: Colors.white,
                                size: 36,
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isActive ? Colors.blue : Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
