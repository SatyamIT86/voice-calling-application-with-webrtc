// lib/screens/call/incoming_call_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/webrtc_service.dart';
import '../../services/signaling_service.dart';
import '../../models/contact_model.dart';
import 'call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final ContactModel contact;
  final String callerId;
  final String offer;

  const IncomingCallScreen({
    Key? key,
    required this.contact,
    required this.callerId,
    required this.offer,
  }) : super(key: key);

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _isAnswering = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _answerCall() async {
    if (_isAnswering) return;

    setState(() {
      _isAnswering = true;
    });

    try {
      final webrtcService = context.read<WebRTCService>();

      // Answer the call
      await webrtcService.answerCall(widget.callerId);

      if (mounted) {
        // Navigate to call screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CallScreen(contact: widget.contact, isIncoming: true),
          ),
        );
      }
    } catch (e) {
      print('Error answering call: $e');
      if (mounted) {
        setState(() {
          _isAnswering = false;
        });
        _showError('Failed to answer call: $e');
      }
    }
  }

  void _rejectCall() {
    try {
      final signalingService = context.read<SignalingService>();

      // Send rejection signal
      signalingService.endCall();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error rejecting call: $e');
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          // Prevent back button from dismissing the call
          _rejectCall();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F1E),
        body: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0xFF1A1A2E), const Color(0xFF0F0F1E)],
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // Incoming call text
                  const Text(
                    'Incoming Call',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const Spacer(),

                  // Animated contact avatar
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer ring
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                        ),
                        // Avatar
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              widget.contact.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 64,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Contact name
                  Text(
                    widget.contact.name,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Contact info
                  if (widget.contact.phone != null)
                    Text(
                      widget.contact.phone!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white60,
                      ),
                    ),

                  const Spacer(),

                  // Call action buttons
                  if (_isAnswering)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 60),
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: Colors.blue),
                          SizedBox(height: 16),
                          Text(
                            'Connecting...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 60),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Reject button
                          _buildCallButton(
                            icon: Icons.call_end,
                            label: 'Decline',
                            color: Colors.red,
                            onPressed: _rejectCall,
                          ),

                          // Answer button
                          _buildCallButton(
                            icon: Icons.call,
                            label: 'Accept',
                            color: Colors.green,
                            onPressed: _answerCall,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
