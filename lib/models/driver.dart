// lib/models/driver.dart
// Purpose: Represents a bus driver (for login and session tracking)

class Driver {
  final int? id; // Database ID (auto-generated)
  final String name; // Driver's full name
  final String busPlate; // Bus license plate assigned to this driver
  final DateTime createdAt; // When this driver was added to system
  
  Driver({
    this.id,
    required this.name,
    required this.busPlate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  // Convert Driver object to Map (for database storage)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'bus_plate': busPlate,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  // Create Driver object from Map (from database)
  factory Driver.fromMap(Map<String, dynamic> map) {
    return Driver(
      id: map['id'] as int?,
      name: map['name'] as String,
      busPlate: map['bus_plate'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
  
  // Create a copy of this Driver with some fields changed
  Driver copyWith({
    int? id,
    String? name,
    String? busPlate,
    DateTime? createdAt,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      busPlate: busPlate ?? this.busPlate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  @override
  String toString() {
    return 'Driver{id: $id, name: $name, busPlate: $busPlate}';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Driver &&
        other.name == name &&
        other.busPlate == busPlate;
  }
  
  @override
  int get hashCode => name.hashCode ^ busPlate.hashCode;
}