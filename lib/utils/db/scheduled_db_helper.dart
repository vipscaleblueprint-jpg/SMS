import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/scheduled_group.dart';
import '../../models/scheduled_sms.dart';

class ScheduledDbHelper {
  static final ScheduledDbHelper _instance = ScheduledDbHelper._internal();
  static Database? _database;

  factory ScheduledDbHelper() => _instance;

  ScheduledDbHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'scheduled_groups.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scheduled_groups(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE scheduled_messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        frequency TEXT NOT NULL,
        message TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        status TEXT DEFAULT 'pending',
        scheduled_time TEXT,
        FOREIGN KEY (group_id) REFERENCES scheduled_groups (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE scheduled_messages(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          group_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          frequency TEXT NOT NULL,
          message TEXT NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          status TEXT DEFAULT 'pending',
          scheduled_time TEXT,
          FOREIGN KEY (group_id) REFERENCES scheduled_groups (id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 3) {
      // Check if table exists (if skipped version 2 migration somehow or if version 2 was flawed)
      // Since user had "no such table" error, it's safer to try creating it if not exists,
      // OR add columns if it does exist.
      // Easiest is to add columns if table exists.

      var tableExists = false;
      try {
        await db.rawQuery('SELECT * FROM scheduled_messages LIMIT 1');
        tableExists = true;
      } catch (_) {}

      if (!tableExists) {
        await db.execute('''
          CREATE TABLE scheduled_messages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            group_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            frequency TEXT NOT NULL,
            message TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1,
            status TEXT DEFAULT 'pending',
            scheduled_time TEXT,
            FOREIGN KEY (group_id) REFERENCES scheduled_groups (id) ON DELETE CASCADE
          )
        ''');
      } else {
        // Table exists, add columns if missing
        try {
          await db.execute(
            "ALTER TABLE scheduled_messages ADD COLUMN status TEXT DEFAULT 'pending'",
          );
        } catch (_) {}
        try {
          await db.execute(
            "ALTER TABLE scheduled_messages ADD COLUMN scheduled_time TEXT",
          );
        } catch (_) {}
      }
    }
  }

  // Group Methods
  Future<int> insertGroup(ScheduledGroup group) async {
    final db = await database;
    return await db.insert(
      'scheduled_groups',
      group.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ScheduledGroup>> getGroups() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('scheduled_groups');

    return List.generate(maps.length, (i) {
      return ScheduledGroup.fromMap(maps[i]);
    });
  }

  Future<int> updateGroup(ScheduledGroup group) async {
    final db = await database;
    return await db.update(
      'scheduled_groups',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<int> deleteGroup(int id) async {
    final db = await database;
    // Cascade delete manual if FK not reliable
    await db.delete(
      'scheduled_messages',
      where: 'group_id = ?',
      whereArgs: [id],
    );
    return await db.delete(
      'scheduled_groups',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Message Methods
  Future<int> insertMessage(ScheduledSms message) async {
    final db = await database;
    return await db.insert(
      'scheduled_messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ScheduledSms>> getMessagesByGroupId(int groupId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scheduled_messages',
      where: 'group_id = ?',
      whereArgs: [groupId],
    );

    return List.generate(maps.length, (i) {
      return ScheduledSms.fromMap(maps[i]);
    });
  }

  Future<int> deleteMessage(int id) async {
    final db = await database;
    return await db.delete(
      'scheduled_messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
