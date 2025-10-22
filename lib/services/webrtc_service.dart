// lib/services/webrtc_service.dart
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'signaling_service.dart';
import 'recording_service.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final SignalingService _signalingService;
  final RecordingService _recordingService;
  bool _isEnding = false;

  Function(MediaStream)? onRemoteStream;
  Function()? onCallEnded;

  WebRTCService({
    required SignalingService signalingService,
    required RecordingService recordingService,
  }) : _signalingService = signalingService,
       _recordingService = recordingService {
    _setupSignalingListeners();
  }

  // STUN servers configuration (free Google STUN servers)
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
  };

  final Map<String, dynamic> _mediaConstraints = {
    'audio': true,
    'video': false,
  };

  void _setupSignalingListeners() {
    _signalingService.onIncomingCall = (offer, from, callerName) async {
      await _handleIncomingCall(offer, from);
    };

    _signalingService.onCallAnswered = (answer) async {
      await _handleAnswer(answer);
    };

    _signalingService.onIceCandidate = (candidate) async {
      await _addIceCandidate(candidate);
    };

    _signalingService.onCallEnded = () {
      print('Call ended by remote peer');
      // Don't call endCall() here - just cleanup and notify UI
      _cleanupWithoutSignaling();
    };
  }

  // Initialize local media stream
  Future<void> initializeLocalStream() async {
    try {
      _localStream = await navigator.mediaDevices.getUserMedia(
        _mediaConstraints,
      );
      print('Local stream initialized');
    } catch (e) {
      print('Error initializing local stream: $e');
      rethrow;
    }
  }

  // Create peer connection
  Future<void> _createPeerConnection() async {
    try {
      _peerConnection = await createPeerConnection(_configuration);

      // Add local stream tracks
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          _peerConnection!.addTrack(track, _localStream!);
        });
      }

      // Handle remote stream
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          onRemoteStream?.call(_remoteStream!);

          // Start recording when remote stream is available
          try {
            _recordingService.startRecording(_localStream!, _remoteStream!);
          } catch (e) {
            print('Error starting recording: $e');
          }
        }
      };

      // Handle ICE candidates
      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        try {
          _signalingService.sendIceCandidate(candidate);
        } catch (e) {
          print('Error sending ICE candidate: $e');
        }
      };

      // Handle connection state changes
      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        print('Connection state: $state');
        if (state ==
                RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          if (!_isEnding) {
            endCall();
          }
        }
      };

      print('Peer connection created');
    } catch (e) {
      print('Error creating peer connection: $e');
      rethrow;
    }
  }

  // Make a call
  Future<void> makeCall(String targetUserId, String callerName) async {
    try {
      await initializeLocalStream();
      await _createPeerConnection();

      // Create offer
      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      // Send offer through signaling
      await _signalingService.sendCallOffer(
        targetUserId,
        offer.sdp!,
        callerName,
      );

      print('Call offer sent to $targetUserId');
    } catch (e) {
      print('Error making call: $e');
      rethrow;
    }
  }

  // Handle incoming call
  Future<void> _handleIncomingCall(String offer, String from) async {
    try {
      await initializeLocalStream();
      await _createPeerConnection();

      // Set remote description
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(offer, 'offer'),
      );

      print('Incoming call handled from $from');
    } catch (e) {
      print('Error handling incoming call: $e');
      rethrow;
    }
  }

  // Answer call
  Future<void> answerCall(String callerId) async {
    try {
      // Create answer
      RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      // Send answer through signaling
      await _signalingService.sendCallAnswer(callerId, answer.sdp!);

      print('Call answered');
    } catch (e) {
      print('Error answering call: $e');
      rethrow;
    }
  }

  // Handle call answer
  Future<void> _handleAnswer(String answer) async {
    try {
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(answer, 'answer'),
      );
      print('Answer received and set');
    } catch (e) {
      print('Error handling answer: $e');
    }
  }

  // Add ICE candidate
  Future<void> _addIceCandidate(Map<String, dynamic> candidateMap) async {
    try {
      if (_peerConnection == null) {
        print('Cannot add ICE candidate: peer connection is null');
        return;
      }

      RTCIceCandidate candidate = RTCIceCandidate(
        candidateMap['candidate'],
        candidateMap['sdpMid'],
        candidateMap['sdpMLineIndex'],
      );
      await _peerConnection?.addCandidate(candidate);
      print('ICE candidate added');
    } catch (e) {
      print('Error adding ICE candidate: $e');
    }
  }

  // Toggle microphone
  void toggleMicrophone(bool enabled) {
    try {
      if (_localStream != null) {
        _localStream!.getAudioTracks().forEach((track) {
          track.enabled = enabled;
        });
      }
    } catch (e) {
      print('Error toggling microphone: $e');
    }
  }

  // Get local stream for UI
  MediaStream? get localStream => _localStream;

  // Get remote stream for UI
  MediaStream? get remoteStream => _remoteStream;

  // End call
  Future<void> endCall() async {
    // Prevent multiple simultaneous end call attempts
    if (_isEnding) {
      print('Already ending call, ignoring duplicate request');
      return;
    }

    _isEnding = true;
    print('WebRTC: Starting end call cleanup');

    try {
      // Stop recording first
      try {
        await _recordingService.stopRecording();
        print('Recording stopped');
      } catch (e) {
        print('Error stopping recording: $e');
      }

      // Close peer connection
      try {
        if (_peerConnection != null) {
          await _peerConnection!.close();
          _peerConnection = null;
          print('Peer connection closed');
        }
      } catch (e) {
        print('Error closing peer connection: $e');
      }

      // Stop and dispose local stream
      try {
        if (_localStream != null) {
          _localStream!.getTracks().forEach((track) {
            try {
              track.stop();
            } catch (e) {
              print('Error stopping local track: $e');
            }
          });
          await _localStream!.dispose();
          _localStream = null;
          print('Local stream disposed');
        }
      } catch (e) {
        print('Error disposing local stream: $e');
      }

      // Stop and dispose remote stream
      try {
        if (_remoteStream != null) {
          _remoteStream!.getTracks().forEach((track) {
            try {
              track.stop();
            } catch (e) {
              print('Error stopping remote track: $e');
            }
          });
          await _remoteStream!.dispose();
          _remoteStream = null;
          print('Remote stream disposed');
        }
      } catch (e) {
        print('Error disposing remote stream: $e');
      }

      // Notify signaling
      try {
        _signalingService.endCall();
        print('Signaling notified of call end');
      } catch (e) {
        print('Error notifying signaling: $e');
      }

      // Notify UI
      try {
        onCallEnded?.call();
        print('UI notified of call end');
      } catch (e) {
        print('Error notifying UI: $e');
      }

      print('Call cleanup completed');
    } catch (e) {
      print('Error in endCall: $e');
    } finally {
      _isEnding = false;
    }
  }

  // Cleanup without sending signaling messages (for remote-initiated end)
  Future<void> _cleanupWithoutSignaling() async {
    if (_isEnding) {
      print('Already ending call, ignoring duplicate request');
      return;
    }

    _isEnding = true;
    print('WebRTC: Starting cleanup without signaling');

    try {
      // Stop recording first
      try {
        await _recordingService.stopRecording();
        print('Recording stopped');
      } catch (e) {
        print('Error stopping recording: $e');
      }

      // Close peer connection
      try {
        if (_peerConnection != null) {
          await _peerConnection!.close();
          _peerConnection = null;
          print('Peer connection closed');
        }
      } catch (e) {
        print('Error closing peer connection: $e');
      }

      // Stop and dispose local stream
      try {
        if (_localStream != null) {
          _localStream!.getTracks().forEach((track) {
            try {
              track.stop();
            } catch (e) {
              print('Error stopping local track: $e');
            }
          });
          await _localStream!.dispose();
          _localStream = null;
          print('Local stream disposed');
        }
      } catch (e) {
        print('Error disposing local stream: $e');
      }

      // Stop and dispose remote stream
      try {
        if (_remoteStream != null) {
          _remoteStream!.getTracks().forEach((track) {
            try {
              track.stop();
            } catch (e) {
              print('Error stopping remote track: $e');
            }
          });
          await _remoteStream!.dispose();
          _remoteStream = null;
          print('Remote stream disposed');
        }
      } catch (e) {
        print('Error disposing remote stream: $e');
      }

      // Notify UI (but NOT signaling service)
      try {
        onCallEnded?.call();
        print('UI notified of call end');
      } catch (e) {
        print('Error notifying UI: $e');
      }

      print('Cleanup without signaling completed');
    } catch (e) {
      print('Error in _cleanupWithoutSignaling: $e');
    } finally {
      _isEnding = false;
    }
  }

  // Cleanup
  void dispose() {
    endCall();
  }
}
