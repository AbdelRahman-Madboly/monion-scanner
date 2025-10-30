// lib/services/database_service.dart
// Purpose: Handles all database operations with proper state management

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/session.dart';
import '../models/scan.dart';
import '../models/driver.dart';
import '../models/recording.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('monion.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        driver_name TEXT NOT NULL,
        bus_plate TEXT NOT NULL,
        direction TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        total_scans_in INTEGER NOT NULL DEFAULT 0,
        total_scans_out INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE scans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        national_id TEXT NOT NULL,
        scan_type TEXT NOT NULL,
        scan_in_time TEXT NOT NULL,
        scan_out_time TEXT,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE,
        UNIQUE(session_id, national_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE drivers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        bus_plate TEXT NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(name, bus_plate)
      )
    ''');

    await db.execute('''
      CREATE TABLE recordings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        camera_type TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_size INTEGER,
        duration INTEGER,
        start_time TEXT NOT NULL,
        end_time TEXT,
        status TEXT DEFAULT 'COMPLETED',
        FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add columns for version 2
      try {
        await db.execute('ALTER TABLE scans ADD COLUMN scan_in_time TEXT');
      } catch (e) {
        // Column might already exist
      }
      
      try {
        await db.execute('ALTER TABLE scans ADD COLUMN scan_out_time TEXT');
      } catch (e) {
        // Column might already exist
      }
      
      // Migrate existing data
      await db.execute('''
        UPDATE scans 
        SET scan_in_time = timestamp 
        WHERE scan_in_time IS NULL
      ''');
    }

    if (oldVersion < 3) {
      // Version 3: Fix UNIQUE constraint properly
      // Drop old index if it exists
      try {
        await db.execute('DROP INDEX IF EXISTS idx_session_national');
      } catch (e) {
        // Index doesn't exist, continue
      }

      // Remove duplicates before applying constraint
      await db.execute('''
        DELETE FROM scans WHERE id NOT IN (
          SELECT MIN(id) FROM scans GROUP BY session_id, national_id
        )
      ''');
    }
  }

  // ==================== SESSION OPERATIONS ====================

  Future<Session> createSession(Session session) async {
    final db = await database;
    final id = await db.insert('sessions', session.toMap());
    return session.copyWith(id: id);
  }

  Future<Session?> getActiveSession() async {
    final db = await database;
    final maps = await db.query(
      'sessions',
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Session.fromMap(maps.first);
  }

  Future<Session?> getSession(int id) async {
    final db = await database;
    final maps = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Session.fromMap(maps.first);
  }

  Future<List<Session>> getAllSessions() async {
    final db = await database;
    final maps = await db.query(
      'sessions',
      orderBy: 'start_time DESC',
    );

    return maps.map((map) => Session.fromMap(map)).toList();
  }

  Future<int> updateSession(Session session) async {
    final db = await database;
    return await db.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<void> endSession(int sessionId) async {
    final db = await database;
    await db.update(
      'sessions',
      {
        'is_active': 0,
        'end_time': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<int> deleteSession(int id) async {
    final db = await database;
    return await db.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== SCAN OPERATIONS ====================

  /// Create or update scan (handles IN -> OUT state change)
  Future<Scan> createOrUpdateScan(Scan scan) async {
    final db = await database;

    final existing = await getStudentScan(scan.sessionId, scan.nationalId);

    if (existing != null) {
      if (scan.scanType == 'OUT') {
        final updated = existing.copyWith(
          scanType: 'OUT',
          scanOutTime: DateTime.now(),
          timestamp: DateTime.now(),
        );

        await db.update(
          'scans',
          updated.toMap(),
          where: 'id = ?',
          whereArgs: [existing.id],
        );

        await _updateSessionCounts(scan.sessionId);
        return updated;
      } else {
        final updated = existing.copyWith(timestamp: DateTime.now());
        await db.update(
          'scans',
          updated.toMap(),
          where: 'id = ?',
          whereArgs: [existing.id],
        );
        return updated;
      }
    } else {
      final id = await db.insert(
        'scans',
        scan.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await _updateSessionCounts(scan.sessionId);
      return scan.copyWith(id: id);
    }
  }

  /// Get a specific student's scan in a session
  Future<Scan?> getStudentScan(int sessionId, String nationalId) async {
    final db = await database;
    final maps = await db.query(
      'scans',
      where: 'session_id = ? AND national_id = ?',
      whereArgs: [sessionId, nationalId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Scan.fromMap(maps.first);
  }

  /// Get all scans for a session
  Future<List<Scan>> getSessionScans(int sessionId) async {
    final db = await database;
    final maps = await db.query(
      'scans',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => Scan.fromMap(map)).toList();
  }

  /// Get only students currently scanned IN
  Future<List<Scan>> getScansIn(int sessionId) async {
    final db = await database;
    final maps = await db.query(
      'scans',
      where: 'session_id = ? AND scan_type = ?',
      whereArgs: [sessionId, 'IN'],
      orderBy: 'scan_in_time DESC',
    );

    return maps.map((map) => Scan.fromMap(map)).toList();
  }

  /// Get only students who scanned OUT
  Future<List<Scan>> getScansOut(int sessionId) async {
    final db = await database;
    final maps = await db.query(
      'scans',
      where: 'session_id = ? AND scan_type = ?',
      whereArgs: [sessionId, 'OUT'],
      orderBy: 'scan_out_time DESC',
    );

    return maps.map((map) => Scan.fromMap(map)).toList();
  }

  /// Check if student is currently scanned in
  Future<bool> isStudentScannedIn(int sessionId, String nationalId) async {
    final scan = await getStudentScan(sessionId, nationalId);
    return scan?.isScannedIn ?? false;
  }

  /// Manually mark student as OUT
  Future<void> markStudentAsOut(int sessionId, String nationalId) async {
    final db = await database;

    await db.update(
      'scans',
      {
        'scan_type': 'OUT',
        'scan_out_time': DateTime.now().toIso8601String(),
        'timestamp': DateTime.now().toIso8601String(),
      },
      where: 'session_id = ? AND national_id = ?',
      whereArgs: [sessionId, nationalId],
    );

    await _updateSessionCounts(sessionId);
  }

  /// Bulk mark students as OUT
  Future<void> markMultipleAsOut(int sessionId, List<String> nationalIds) async {
    final db = await database;
    final batch = db.batch();

    for (final nationalId in nationalIds) {
      batch.update(
        'scans',
        {
          'scan_type': 'OUT',
          'scan_out_time': DateTime.now().toIso8601String(),
          'timestamp': DateTime.now().toIso8601String(),
        },
        where: 'session_id = ? AND national_id = ?',
        whereArgs: [sessionId, nationalId],
      );
    }

    await batch.commit(noResult: true);
    await _updateSessionCounts(sessionId);
  }

  /// Delete scan
  Future<int> deleteScan(int id, int sessionId) async {
    final db = await database;
    final result = await db.delete(
      'scans',
      where: 'id = ?',
      whereArgs: [id],
    );

    await _updateSessionCounts(sessionId);
    return result;
  }

  /// Update session scan counts
  Future<void> _updateSessionCounts(int sessionId) async {
    final db = await database;

    final insResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM scans WHERE session_id = ? AND scan_type = ?',
      [sessionId, 'IN'],
    );
    final totalIn = insResult.first['count'] as int;

    final outsResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM scans WHERE session_id = ? AND scan_type = ?',
      [sessionId, 'OUT'],
    );
    final totalOut = outsResult.first['count'] as int;

    await db.update(
      'sessions',
      {
        'total_scans_in': totalIn,
        'total_scans_out': totalOut,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  // ==================== DRIVER OPERATIONS ====================

  Future<Driver> createDriver(Driver driver) async {
    final db = await database;

    try {
      final id = await db.insert('drivers', driver.toMap());
      return driver.copyWith(id: id);
    } catch (e) {
      final existing = await getDriver(driver.name, driver.busPlate);
      return existing!;
    }
  }

  Future<Driver?> getDriver(String name, String busPlate) async {
    final db = await database;
    final maps = await db.query(
      'drivers',
      where: 'name = ? AND bus_plate = ?',
      whereArgs: [name, busPlate],
    );

    if (maps.isEmpty) return null;
    return Driver.fromMap(maps.first);
  }

  Future<List<Driver>> getAllDrivers() async {
    final db = await database;
    final maps = await db.query('drivers', orderBy: 'name ASC');
    return maps.map((map) => Driver.fromMap(map)).toList();
  }

  // ==================== RECORDING OPERATIONS ====================

  /// Insert a new recording
  Future<int> insertRecording(Recording recording) async {
    final db = await database;
    return await db.insert('recordings', recording.toMap());
  }

  /// Get all recordings for a session
  Future<List<Recording>> getSessionRecordings(int sessionId) async {
    final db = await database;
    final maps = await db.query(
      'recordings',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'start_time ASC',
    );

    return maps.map((map) => Recording.fromMap(map)).toList();
  }

  /// Get all recordings
  Future<List<Recording>> getAllRecordings() async {
    final db = await database;
    final maps = await db.query(
      'recordings',
      orderBy: 'start_time DESC',
    );

    return maps.map((map) => Recording.fromMap(map)).toList();
  }

  /// Get a specific recording by ID
  Future<Recording?> getRecording(int id) async {
    final db = await database;
    final maps = await db.query(
      'recordings',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Recording.fromMap(maps.first);
  }

  /// Update recording status or metadata
  Future<int> updateRecording(Recording recording) async {
    final db = await database;
    return await db.update(
      'recordings',
      recording.toMap(),
      where: 'id = ?',
      whereArgs: [recording.id],
    );
  }

  /// Delete a recording
  Future<int> deleteRecording(int id) async {
    final db = await database;
    return await db.delete(
      'recordings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Check if session has recordings
  Future<bool> sessionHasRecordings(int sessionId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM recordings WHERE session_id = ?',
      [sessionId],
    );
    final count = result.first['count'] as int;
    return count > 0;
  }

  /// Get recording count for a session
  Future<int> getRecordingCount(int sessionId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM recordings WHERE session_id = ?',
      [sessionId],
    );
    return result.first['count'] as int;
  }

  // ==================== UTILITY OPERATIONS ====================

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('scans');
    await db.delete('sessions');
    await db.delete('drivers');
    await db.delete('recordings');
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}