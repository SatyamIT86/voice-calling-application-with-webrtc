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
      endCall();
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
          _recordingService.startRecording(_localStream!, _remoteStream!);
        }
      };

      // Handle ICE candidates
      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        _signalingService.sendIceCandidate(candidate);
      };

      // Handle connection state changes
      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        print('Connection state: $state');
        if (state ==
                RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          endCall();
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
    if (_localStream != null) {
      _localStream!.getAudioTracks().forEach((track) {
        track.enabled = enabled;
      });
    }
  }

  // Get local stream for UI
  MediaStream? get localStream => _localStream;

  // Get remote stream for UI
  MediaStream? get remoteStream => _remoteStream;

  // End call
  Future<void> endCall() async {
    try {
      // Stop recording
      await _recordingService.stopRecording();

      // Close peer connection
      await _peerConnection?.close();
      _peerConnection = null;

      // Stop local stream
      _localStream?.getTracks().forEach((track) {
        track.stop();
      });
      _localStream?.dispose();
      _localStream = null;

      // Stop remote stream
      _remoteStream?.getTracks().forEach((track) {
        track.stop();
      });
      _remoteStream?.dispose();
      _remoteStream = null;

      // Notify signaling
      _signalingService.endCall();

      // Notify UI
      onCallEnded?.call();

      print('Call ended');
    } catch (e) {
      print('Error ending call: $e');
    }
  }

  // Cleanup
  void dispose() {
    endCall();
  }
}
