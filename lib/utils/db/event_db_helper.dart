import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/events.dart';

class EventDbHelper {
  static final EventDbHelper _instance = EventDbHelper._internal();
  static Database? _database;

  factory EventDbHelper() => _instance;

  EventDbHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'events.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        recipients TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE events ADD COLUMN recipients TEXT');
    }
    if (oldVersion == 2) {
      // For simplicity in this dev environment, we'll try to rename.
      // SQLite supports RENAME COLUMN in newer versions.
      try {
        await db.execute(
          'ALTER TABLE events RENAME COLUMN receipts TO recipients',
        );
      } catch (e) {
        // Fallback: Add new column, copy data (optional), drop old (requires table recreate in sqlite usually, simplify to just add)
        await db.execute('ALTER TABLE events ADD COLUMN recipients TEXT');
      }
    }
  }

  Future<int> insertEvent(Event event) async {
    final db = await database;
    return await db.insert(
      'events',
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Event>> getEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('events');

    return List.generate(maps.length, (i) {
      return Event.fromMap(maps[i]);
    });
  }

  Future<Event?> getEventById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Event.fromMap(maps.first);
  }

  Future<int> updateEvent(Event event) async {
    final db = await database;
    return await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(int id) async {
    final db = await database;
    return await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }
}
