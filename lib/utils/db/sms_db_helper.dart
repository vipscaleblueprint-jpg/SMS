import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/sms.dart';

class SmsDbHelper {
  static final SmsDbHelper _instance = SmsDbHelper._internal();
  static Database? _database;

  factory SmsDbHelper() => _instance;

  SmsDbHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sms.db');

    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sms(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        message TEXT NOT NULL,
        contact_id TEXT,
        phone_number TEXT,
        sender_number TEXT,
        status TEXT NOT NULL, 
        sentTimeStamps TEXT,
        schedule_time TEXT,
        event_id INTEGER,
        batchId TEXT,
        batchTotal INTEGER
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Re-create table for version 3 (status column change)
      await db.execute('DROP TABLE IF EXISTS sms');
      await _onCreate(db, newVersion);
    } else if (oldVersion < 4) {
      // Version 3 to 4: Add title column
      await db.execute('ALTER TABLE sms ADD COLUMN title TEXT');
    }
    if (oldVersion < 5) {
      // Version 4 to 5: Add batchId and batchTotal columns
      try {
        await db.execute('ALTER TABLE sms ADD COLUMN batchId TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE sms ADD COLUMN batchTotal INTEGER');
      } catch (_) {}
    }
  }

  Future<int> insertSms(Sms sms) async {
    final db = await database;
    return await db.insert(
      'sms',
      sms.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Sms>> getSmsList() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sms');

    return List.generate(maps.length, (i) {
      return Sms.fromMap(maps[i]);
    });
  }

  Future<List<Sms>> getDueOneTimeMessages(DateTime now) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sms',
      where:
          "status = 'pending' AND schedule_time IS NOT NULL AND schedule_time <= ?",
      whereArgs: [now.toIso8601String()],
    );

    return List.generate(maps.length, (i) {
      return Sms.fromMap(maps[i]);
    });
  }

  Future<List<Sms>> getSmsByEventId(int eventId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sms',
      where: 'event_id = ?',
      whereArgs: [eventId],
    );

    return List.generate(maps.length, (i) {
      return Sms.fromMap(maps[i]);
    });
  }

  Future<int> updateSms(Sms sms) async {
    final db = await database;
    return await db.update(
      'sms',
      sms.toMap(),
      where: 'id = ?',
      whereArgs: [sms.id],
    );
  }

  Future<int> deleteSms(int id) async {
    final db = await database;
    return await db.delete('sms', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllSms() async {
    final db = await database;
    await db.delete('sms');
  }

  Future<List<Sms>> getGroupedSmsHistory() async {
    final db = await database;
    // We want the most recent messages, but if they have a batchId, we only want one per batchId
    // If batchId is null, we treat it as an individual message.

    // This is a bit complex in SQL to do perfectly, so we'll do some post-processing or a subquery.
    // Let's get them all and then unique them by batchId in Dart for now, or use a GROUP BY if simple enough.

    final List<Map<String, dynamic>> maps = await db.query(
      'sms',
      orderBy: 'id DESC',
    );

    final List<Sms> allHistory = maps.map((m) => Sms.fromMap(m)).toList();
    final List<Sms> groupedHistory = [];
    final Set<String> seenBatchIds = {};

    for (final sms in allHistory) {
      if (sms.batchId == null) {
        groupedHistory.add(sms);
      } else {
        if (!seenBatchIds.contains(sms.batchId)) {
          groupedHistory.add(sms);
          seenBatchIds.add(sms.batchId!);
        }
      }
    }

    return groupedHistory;
  }
}
