// lib/models/recording.dart
// Purpose: Model for video recordings

class Recording {
  final int? id;
  final int sessionId;
  final String cameraType;  // 'FRONT' or 'WIFI'
  final String filePath;
  final int? fileSize;      // in bytes
  final int? duration;      // in seconds
  final DateTime startTime;
  final DateTime? endTime;
  final String status;      // 'ACTIVE', 'COMPLETED', 'FAILED'

  Recording({
    this.id,
    required this.sessionId,
    required this.cameraType,
    required this.filePath,
    this.fileSize,
    this.duration,
    required this.startTime,
    this.endTime,
    this.status = 'ACTIVE',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'camera_type': cameraType,
      'file_path': filePath,
      'file_size': fileSize,
      'duration': duration,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'status': status,
    };
  }

  factory Recording.fromMap(Map<String, dynamic> map) {
    return Recording(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int,
      cameraType: map['camera_type'] as String,
      filePath: map['file_path'] as String,
      fileSize: map['file_size'] as int?,
      duration: map['duration'] as int?,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null 
          ? DateTime.parse(map['end_time'] as String)
          : null,
      status: map['status'] as String? ?? 'ACTIVE',
    );
  }

  String get fileSizeMB {
    if (fileSize == null) return 'Unknown';
    return (fileSize! / 1024 / 1024).toStringAsFixed(2);
  }

  String get formattedDuration {
    if (duration == null) return 'Unknown';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Recording copyWith({
    int? id,
    int? sessionId,
    String? cameraType,
    String? filePath,
    int? fileSize,
    int? duration,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
  }) {
    return Recording(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      cameraType: cameraType ?? this.cameraType,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
    );
  }
}