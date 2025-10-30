// lib/models/scan.dart
// Purpose: Represents a single student scan with IN/OUT tracking
// UPDATED: Now tracks both IN and OUT times in one record

class Scan {
  final int? id;
  final int sessionId;
  final String nationalId;
  final String scanType; // 'IN' or 'OUT'
  final DateTime scanInTime;
  final DateTime? scanOutTime;
  final DateTime timestamp;
  
  Scan({
    this.id,
    required this.sessionId,
    required this.nationalId,
    required this.scanType,
    required this.scanInTime,
    this.scanOutTime,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'national_id': nationalId,
      'scan_type': scanType,
      'scan_in_time': scanInTime.toIso8601String(),
      'scan_out_time': scanOutTime?.toIso8601String(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  factory Scan.fromMap(Map<String, dynamic> map) {
    return Scan(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int,
      nationalId: map['national_id'] as String,
      scanType: map['scan_type'] as String,
      scanInTime: DateTime.parse(map['scan_in_time'] as String),
      scanOutTime: map['scan_out_time'] != null 
          ? DateTime.parse(map['scan_out_time'] as String)
          : null,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
  
  Scan copyWith({
    int? id,
    int? sessionId,
    String? nationalId,
    String? scanType,
    DateTime? scanInTime,
    DateTime? scanOutTime,
    DateTime? timestamp,
  }) {
    return Scan(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      nationalId: nationalId ?? this.nationalId,
      scanType: scanType ?? this.scanType,
      scanInTime: scanInTime ?? this.scanInTime,
      scanOutTime: scanOutTime ?? this.scanOutTime,
      timestamp: timestamp ?? this.timestamp,
    );
  }
  
  bool get isScannedIn => scanType == 'IN';
  bool get isScannedOut => scanType == 'OUT';
  
  Duration? get duration {
    if (scanOutTime == null) return null;
    return scanOutTime!.difference(scanInTime);
  }
  
  String get formattedDuration {
    final d = duration;
    if (d == null) return 'Still IN';
    
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
  
  @override
  String toString() {
    return 'Scan{id: $id, sessionId: $sessionId, nationalId: $nationalId, '
        'scanType: $scanType, in: $scanInTime, out: $scanOutTime}';
  }
}