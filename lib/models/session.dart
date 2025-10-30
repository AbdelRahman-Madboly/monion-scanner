// lib/models/session.dart
// Purpose: Represents a bus trip session (one journey)

class Session {
  final int? id; // Database ID (auto-generated)
  final String driverName; // Name of the driver
  final String busPlate; // Bus license plate number
  final String direction; // 'To University' or 'From University'
  final DateTime startTime; // When session started
  final DateTime? endTime; // When session ended (null if still active)
  final bool isActive; // Is this session currently running?
  final int totalScansIn; // Total number of scan-ins
  final int totalScansOut; // Total number of scan-outs
  
  Session({
    this.id,
    required this.driverName,
    required this.busPlate,
    required this.direction,
    required this.startTime,
    this.endTime,
    this.isActive = true,
    this.totalScansIn = 0,
    this.totalScansOut = 0,
  });
  
  // Convert Session object to Map (for database storage)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driver_name': driverName,
      'bus_plate': busPlate,
      'direction': direction,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'is_active': isActive ? 1 : 0, // SQLite stores booleans as 0/1
      'total_scans_in': totalScansIn,
      'total_scans_out': totalScansOut,
    };
  }
  
  // Create Session object from Map (from database)
  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'] as int?,
      driverName: map['driver_name'] as String,
      busPlate: map['bus_plate'] as String,
      direction: map['direction'] as String,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null 
          ? DateTime.parse(map['end_time'] as String) 
          : null,
      isActive: (map['is_active'] as int) == 1,
      totalScansIn: map['total_scans_in'] as int? ?? 0,
      totalScansOut: map['total_scans_out'] as int? ?? 0,
    );
  }
  
  // Create a copy of this Session with some fields changed
  Session copyWith({
    int? id,
    String? driverName,
    String? busPlate,
    String? direction,
    DateTime? startTime,
    DateTime? endTime,
    bool? isActive,
    int? totalScansIn,
    int? totalScansOut,
  }) {
    return Session(
      id: id ?? this.id,
      driverName: driverName ?? this.driverName,
      busPlate: busPlate ?? this.busPlate,
      direction: direction ?? this.direction,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      totalScansIn: totalScansIn ?? this.totalScansIn,
      totalScansOut: totalScansOut ?? this.totalScansOut,
    );
  }
  
  // Get duration of session
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }
  
  // Get formatted duration (e.g., "1h 23m")
  String get formattedDuration {
    final d = duration;
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
    return 'Session{id: $id, driver: $driverName, bus: $busPlate, direction: $direction, active: $isActive}';
  }
}