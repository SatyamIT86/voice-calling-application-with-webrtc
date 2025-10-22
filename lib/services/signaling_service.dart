// lib/services/signaling_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SignalingService {
  IO.Socket? _socket;
  String? _currentUserId;

  // Callbacks
  Function(String offer, String from, String callerName)? onIncomingCall;
  Function(String answer)? onCallAnswered;
  Function(Map<String, dynamic> candidate)? onIceCandidate;
  Function()? onCallEnded;

  // Update this with your signaling server URL
  // For development: http://localhost:3000
  // For production: https://your-server.render.com
  static const String signalingServerUrl =
      'https://voice-calling-application-with-webrtc.onrender.com';

  // Initialize signaling connection
  Future<void> initialize(String userId) async {
    _currentUserId = userId;

    try {
      _socket = IO.io(
        signalingServerUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionAttempts(5)
            .build(),
      );

      _setupSocketListeners();

      _socket!.connect();

      _socket!.onConnect((_) {
        print('Connected to signaling server');
        _socket!.emit('register', userId);
      });

      _socket!.onConnectError((data) {
        print('Connection error: $data');
      });

      _socket!.onError((data) {
        print('Socket error: $data');
      });

      print('Signaling service initialized for user: $userId');
    } catch (e) {
      print('Error initializing signaling: $e');
      rethrow;
    }
  }

  void _setupSocketListeners() {
    // Handle incoming call
    _socket!.on('incoming-call', (data) {
      print('Incoming call from: ${data['from']}');
      onIncomingCall?.call(
        data['offer'],
        data['from'],
        data['callerName'] ?? 'Unknown',
      );
    });

    // Handle call answered
    _socket!.on('call-answered', (data) {
      print('Call answered');
      onCallAnswered?.call(data['answer']);
    });

    // Handle ICE candidate
    _socket!.on('ice-candidate', (data) {
      print('ICE candidate received');
      onIceCandidate?.call(data['candidate']);
    });

    // Handle call ended
    _socket!.on('call-ended', (_) {
      print('Call ended by remote peer');
      onCallEnded?.call();
    });

    // Handle reconnection
    _socket!.onReconnect((_) {
      print('Reconnected to signaling server');
      if (_currentUserId != null) {
        _socket!.emit('register', _currentUserId);
      }
    });
  }

  // Send call offer
  Future<void> sendCallOffer(
    String targetUserId,
    String offer,
    String callerName,
  ) async {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Not connected to signaling server');
    }

    _socket!.emit('call', {
      'to': targetUserId,
      'offer': offer,
      'callerName': callerName,
    });

    print('Call offer sent to: $targetUserId');
  }

  // Send call answer
  Future<void> sendCallAnswer(String targetUserId, String answer) async {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Not connected to signaling server');
    }

    _socket!.emit('answer', {'to': targetUserId, 'answer': answer});

    print('Call answer sent to: $targetUserId');
  }

  // Send ICE candidate
  void sendIceCandidate(dynamic candidate) {
    if (_socket == null || !_socket!.connected) {
      print('Cannot send ICE candidate - not connected');
      return;
    }

    _socket!.emit('ice-candidate', {
      'to': _currentUserId,
      'candidate': {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      },
    });
  }

  // End call
  void endCall() {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('end-call', {'to': _currentUserId});
    }
  }

  // Check connection status
  bool get isConnected => _socket?.connected ?? false;

  // Disconnect
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    print('Signaling service disconnected');
  }

  // Dispose
  void dispose() {
    disconnect();
  }
}
