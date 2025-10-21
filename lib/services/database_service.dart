// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/contact_model.dart';
import '../models/call_log_model.dart';
import '../models/recording_model.dart';

class DatabaseService {
  static Database? _database;
  static const String dbName = 'filament_voice_app.db';
  static const int dbVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Contacts table
    await db.execute('''
      CREATE TABLE contacts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        user_id TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Call logs table
    await db.execute('''
      CREATE TABLE call_logs (
        id TEXT PRIMARY KEY,
        contact_id TEXT,
        contact_name TEXT NOT NULL,
        contact_phone TEXT,
        duration INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        call_type TEXT NOT NULL,
        recording_path TEXT,
        transcript TEXT
      )
    ''');

    // Recordings table
    await db.execute('''
      CREATE TABLE recordings (
        id TEXT PRIMARY KEY,
        call_log_id TEXT,
        file_path TEXT NOT NULL,
        duration INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        transcript TEXT,
        FOREIGN KEY (call_log_id) REFERENCES call_logs (id)
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_contacts_user_id ON contacts(user_id)');
    await db.execute(
      'CREATE INDEX idx_call_logs_timestamp ON call_logs(timestamp)',
    );
    await db.execute(
      'CREATE INDEX idx_recordings_call_log_id ON recordings(call_log_id)',
    );
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Handle database upgrades
  }

  // ========== CONTACTS ==========

  Future<int> insertContact(ContactModel contact) async {
    final db = await database;
    await db.insert(
      'contacts',
      contact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return 1;
  }

  Future<List<ContactModel>> getAllContacts(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contacts',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => ContactModel.fromMap(maps[i]));
  }

  Future<ContactModel?> getContactById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ContactModel.fromMap(maps.first);
  }

  Future<List<ContactModel>> searchContacts(String userId, String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contacts',
      where: 'user_id = ? AND (name LIKE ? OR email LIKE ? OR phone LIKE ?)',
      whereArgs: [userId, '%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => ContactModel.fromMap(maps[i]));
  }

  Future<int> updateContact(ContactModel contact) async {
    final db = await database;
    return await db.update(
      'contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<int> deleteContact(String id) async {
    final db = await database;
    return await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }

  // ========== CALL LOGS ==========

  Future<int> insertCallLog(CallLogModel callLog) async {
    final db = await database;
    await db.insert(
      'call_logs',
      callLog.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return 1;
  }

  Future<List<CallLogModel>> getAllCallLogs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'call_logs',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => CallLogModel.fromMap(maps[i]));
  }

  Future<List<CallLogModel>> getCallLogsByContact(String contactId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'call_logs',
      where: 'contact_id = ?',
      whereArgs: [contactId],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => CallLogModel.fromMap(maps[i]));
  }

  Future<CallLogModel?> getCallLogById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'call_logs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CallLogModel.fromMap(maps.first);
  }

  Future<int> updateCallLog(CallLogModel callLog) async {
    final db = await database;
    return await db.update(
      'call_logs',
      callLog.toMap(),
      where: 'id = ?',
      whereArgs: [callLog.id],
    );
  }

  Future<int> deleteCallLog(String id) async {
    final db = await database;
    return await db.delete('call_logs', where: 'id = ?', whereArgs: [id]);
  }

  // ========== RECORDINGS ==========

  Future<int> insertRecording(RecordingModel recording) async {
    final db = await database;
    await db.insert(
      'recordings',
      recording.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return 1;
  }

  Future<List<RecordingModel>> getAllRecordings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recordings',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => RecordingModel.fromMap(maps[i]));
  }

  Future<RecordingModel?> getRecordingById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recordings',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return RecordingModel.fromMap(maps.first);
  }

  Future<List<RecordingModel>> getRecordingsByCallLogId(
    String callLogId,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recordings',
      where: 'call_log_id = ?',
      whereArgs: [callLogId],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => RecordingModel.fromMap(maps[i]));
  }

  Future<int> updateRecording(RecordingModel recording) async {
    final db = await database;
    return await db.update(
      'recordings',
      recording.toMap(),
      where: 'id = ?',
      whereArgs: [recording.id],
    );
  }

  Future<int> deleteRecording(String id) async {
    final db = await database;
    return await db.delete('recordings', where: 'id = ?', whereArgs: [id]);
  }

  // ========== UTILITY ==========

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('contacts');
    await db.delete('call_logs');
    await db.delete('recordings');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
