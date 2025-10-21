// lib/services/recording_service.dart
import 'dart:io';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import '../models/recording_model.dart';
import 'database_service.dart';

class RecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final DatabaseService _databaseService;
  final Uuid _uuid = const Uuid();

  bool _isRecording = false;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  String? _currentCallLogId;

  RecordingService({required DatabaseService databaseService})
    : _databaseService = databaseService;

  // Start recording both local and remote streams
  Future<String?> startRecording(
    MediaStream localStream,
    MediaStream remoteStream, {
    String? callLogId,
  }) async {
    if (_isRecording) {
      print('Already recording');
      return null;
    }

    try {
      // Check and request permissions
      if (await _audioRecorder.hasPermission()) {
        // Get directory for recordings
        final directory = await getApplicationDocumentsDirectory();
        final recordingsDir = Directory('${directory.path}/recordings');

        // Create directory if it doesn't exist
        if (!await recordingsDir.exists()) {
          await recordingsDir.create(recursive: true);
        }

        // Generate unique filename
        final recordingId = _uuid.v4();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        _currentRecordingPath =
            '${recordingsDir.path}/recording_$timestamp.m4a';
        _recordingStartTime = DateTime.now();
        _currentCallLogId = callLogId;

        // Start recording
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _currentRecordingPath!,
        );

        _isRecording = true;
        print('Recording started: $_currentRecordingPath');

        return _currentRecordingPath;
      } else {
        print('Recording permission not granted');
        return null;
      }
    } catch (e) {
      print('Error starting recording: $e');
      return null;
    }
  }

  // Stop recording and save
  Future<RecordingModel?> stopRecording({String? transcript}) async {
    if (!_isRecording || _currentRecordingPath == null) {
      print('Not currently recording');
      return null;
    }

    try {
      // Stop recording
      final path = await _audioRecorder.stop();
      _isRecording = false;

      if (path != null && _recordingStartTime != null) {
        final duration = DateTime.now().difference(_recordingStartTime!);
        final recordingId = _uuid.v4();

        // Create recording model
        final recording = RecordingModel(
          id: recordingId,
          callLogId: _currentCallLogId,
          filePath: _currentRecordingPath!,
          duration: duration.inSeconds,
          timestamp: DateTime.now(),
          transcript: transcript,
        );

        // Save to database
        await _databaseService.insertRecording(recording);

        print('Recording stopped and saved: ${recording.filePath}');
        print('Duration: ${recording.duration} seconds');

        // Reset state
        _currentRecordingPath = null;
        _recordingStartTime = null;
        _currentCallLogId = null;

        return recording;
      }

      return null;
    } catch (e) {
      print('Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  // Check if currently recording
  bool get isRecording => _isRecording;

  // Get current recording duration
  int? getCurrentDuration() {
    if (_recordingStartTime != null) {
      return DateTime.now().difference(_recordingStartTime!).inSeconds;
    }
    return null;
  }

  // Delete a recording file
  Future<bool> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('Recording deleted: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting recording: $e');
      return false;
    }
  }

  // Get all recordings
  Future<List<RecordingModel>> getAllRecordings() async {
    return await _databaseService.getAllRecordings();
  }

  // Get recording by ID
  Future<RecordingModel?> getRecordingById(String id) async {
    return await _databaseService.getRecordingById(id);
  }

  // Get recordings by call log ID
  Future<List<RecordingModel>> getRecordingsByCallLogId(
    String callLogId,
  ) async {
    return await _databaseService.getRecordingsByCallLogId(callLogId);
  }

  // Get total recordings size
  Future<int> getTotalRecordingsSize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${directory.path}/recordings');

      if (!await recordingsDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (var entity in recordingsDir.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      print('Error calculating total size: $e');
      return 0;
    }
  }

  // Clean up old recordings (optional - older than X days)
  Future<void> cleanOldRecordings(int daysToKeep) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${directory.path}/recordings');

      if (!await recordingsDir.exists()) {
        return;
      }

      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      await for (var entity in recordingsDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await entity.delete();
            print('Deleted old recording: ${entity.path}');
          }
        }
      }
    } catch (e) {
      print('Error cleaning old recordings: $e');
    }
  }

  // Dispose
  void dispose() {
    _audioRecorder.dispose();
  }
}
