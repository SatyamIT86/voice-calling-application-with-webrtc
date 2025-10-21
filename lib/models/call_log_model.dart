enum CallType { incoming, outgoing, missed }

class CallLogModel {
  final String id;
  final String? contactId;
  final String contactName;
  final String? contactPhone;
  final int duration; // in seconds
  final DateTime timestamp;
  final CallType callType;
  final String? recordingPath;
  final String? transcript;

  CallLogModel({
    required this.id,
    this.contactId,
    required this.contactName,
    this.contactPhone,
    required this.duration,
    required this.timestamp,
    required this.callType,
    this.recordingPath,
    this.transcript,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contact_id': contactId,
      'contact_name': contactName,
      'contact_phone': contactPhone,
      'duration': duration,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'call_type': callType.toString().split('.').last,
      'recording_path': recordingPath,
      'transcript': transcript,
    };
  }

  factory CallLogModel.fromMap(Map<String, dynamic> map) {
    return CallLogModel(
      id: map['id'],
      contactId: map['contact_id'],
      contactName: map['contact_name'],
      contactPhone: map['contact_phone'],
      duration: map['duration'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      callType: CallType.values.firstWhere(
        (e) => e.toString().split('.').last == map['call_type'],
      ),
      recordingPath: map['recording_path'],
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

  CallLogModel copyWith({
    String? id,
    String? contactId,
    String? contactName,
    String? contactPhone,
    int? duration,
    DateTime? timestamp,
    CallType? callType,
    String? recordingPath,
    String? transcript,
  }) {
    return CallLogModel(
      id: id ?? this.id,
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      duration: duration ?? this.duration,
      timestamp: timestamp ?? this.timestamp,
      callType: callType ?? this.callType,
      recordingPath: recordingPath ?? this.recordingPath,
      transcript: transcript ?? this.transcript,
    );
  }
}
