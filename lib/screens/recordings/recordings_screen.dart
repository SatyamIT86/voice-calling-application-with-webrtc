// lib/screens/recordings/recordings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../services/recording_service.dart';
import '../../models/recording_model.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({Key? key}) : super(key: key);

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  List<RecordingModel> _recordings = [];
  bool _isLoading = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingRecordingId;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() => _position = position);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _playingRecordingId = null;
        _position = Duration.zero;
      });
    });
  }

  Future<void> _loadRecordings() async {
    setState(() => _isLoading = true);

    try {
      final dbService = context.read<DatabaseService>();
      final recordings = await dbService.getAllRecordings();

      setState(() {
        _recordings = recordings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading recordings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _playRecording(RecordingModel recording) async {
    if (_playingRecordingId == recording.id) {
      // Pause if currently playing
      await _audioPlayer.pause();
      setState(() => _playingRecordingId = null);
    } else {
      // Play new recording
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(recording.filePath));
      setState(() => _playingRecordingId = recording.id);
    }
  }

  Future<void> _deleteRecording(RecordingModel recording) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Delete Recording',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this recording?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final recordingService = context.read<RecordingService>();
      await recordingService.deleteRecording(recording.filePath);
      await context.read<DatabaseService>().deleteRecording(recording.id);
      _loadRecordings();
    }
  }

  void _showTranscript(RecordingModel recording) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Transcript', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Text(
            recording.transcript ?? 'No transcript available',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recordings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.mic_none, size: 80, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'No recordings yet',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            SizedBox(height: 8),
            Text(
              'Recordings from calls will appear here',
              style: TextStyle(fontSize: 14, color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recordings.length,
      itemBuilder: (context, index) {
        final recording = _recordings[index];
        final isPlaying = _playingRecordingId == recording.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: const Color(0xFF1A1A2E),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  DateFormat(
                    'MMM dd, yyyy - HH:mm',
                  ).format(recording.timestamp),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  recording.formattedDuration,
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  itemBuilder: (context) => [
                    if (recording.transcript != null)
                      const PopupMenuItem(
                        value: 'transcript',
                        child: Text('View Transcript'),
                      ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                  onSelected: (value) {
                    if (value == 'transcript') {
                      _showTranscript(recording);
                    } else if (value == 'delete') {
                      _deleteRecording(recording);
                    }
                  },
                ),
                onTap: () => _playRecording(recording),
              ),

              // Progress bar when playing
              if (isPlaying)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          trackHeight: 2,
                        ),
                        child: Slider(
                          value: _position.inSeconds.toDouble(),
                          max: _duration.inSeconds.toDouble(),
                          onChanged: (value) async {
                            await _audioPlayer.seek(
                              Duration(seconds: value.toInt()),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_position),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatDuration(_duration),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
