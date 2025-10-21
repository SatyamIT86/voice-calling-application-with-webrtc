// lib/models/recording_model.dart
class RecordingModel {
  final String id;
  final String? callLogId;
  final String filePath;
  final int duration; // in seconds
  final DateTime timestamp;
  final String? transcript;

  RecordingModel({
    required this.id,
    this.callLogId,
    required this.filePath,
    required this.duration,
    required this.timestamp,
    this.transcript,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'call_log_id': callLogId,
      'file_path': filePath,
      'duration': duration,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'transcript': transcript,
    };
  }

  factory RecordingModel.fromMap(Map<String, dynamic> map) {
    return RecordingModel(
      id: map['id'],
      callLogId: map['call_log_id'],
      filePath: map['file_path'],
      duration: map['duration'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      transcript: map['transcript'],
    );
  }

  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String get fileName {
    return filePath.split('/').last;
  }

  RecordingModel copyWith({
    String? id,
    String? callLogId,
    String? filePath,
    int? duration,
    DateTime? timestamp,
    String? transcript,
  }) {
    return RecordingModel(
      id: id ?? this.id,
      callLogId: callLogId ?? this.callLogId,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      timestamp: timestamp ?? this.timestamp,
      transcript: transcript ?? this.transcript,
    );
  }
}
