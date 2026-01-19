import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/scheduled_group.dart';
import '../../models/scheduled_sms.dart';
import '../../models/master_sequence.dart';

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
      version: 9,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scheduled_groups(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        contact_ids TEXT,
        tag_ids TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE scheduled_messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        frequency TEXT NOT NULL,
        scheduled_day INTEGER,
        message TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        status TEXT DEFAULT 'pending',
        scheduled_time TEXT,
        contact_ids TEXT,
        tag_ids TEXT,
        FOREIGN KEY (group_id) REFERENCES scheduled_groups (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE master_sequences(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        tag_id TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE sequence_messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sequence_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        delay_days INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (sequence_id) REFERENCES master_sequences (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE sequence_subscriptions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contact_id TEXT NOT NULL,
        sequence_id INTEGER NOT NULL,
        subscribed_at TEXT NOT NULL,
        FOREIGN KEY (sequence_id) REFERENCES master_sequences (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE sequence_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subscription_id INTEGER NOT NULL,
        message_id INTEGER NOT NULL,
        sent_at TEXT NOT NULL,
        FOREIGN KEY (subscription_id) REFERENCES sequence_subscriptions (id) ON DELETE CASCADE,
        FOREIGN KEY (message_id) REFERENCES sequence_messages (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE sequence_logs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          subscription_id INTEGER NOT NULL,
          message_id INTEGER NOT NULL,
          sent_at TEXT NOT NULL,
          FOREIGN KEY (subscription_id) REFERENCES sequence_subscriptions (id) ON DELETE CASCADE,
          FOREIGN KEY (message_id) REFERENCES sequence_messages (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE master_sequences(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          tag_id TEXT NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1
        )
      ''');

      await db.execute('''
        CREATE TABLE sequence_messages(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sequence_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          delay_days INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (sequence_id) REFERENCES master_sequences (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE sequence_subscriptions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          contact_id TEXT NOT NULL,
          sequence_id INTEGER NOT NULL,
          subscribed_at TEXT NOT NULL,
          FOREIGN KEY (sequence_id) REFERENCES master_sequences (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 7) {
      // Add contact_ids and tag_ids to scheduled_groups
      try {
        await db.execute(
          'ALTER TABLE scheduled_groups ADD COLUMN contact_ids TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE scheduled_groups ADD COLUMN tag_ids TEXT',
        );
      } catch (_) {}
    }

    if (oldVersion < 6) {
      // Add contact_ids and tag_ids if they don't exist
      try {
        await db.execute(
          'ALTER TABLE scheduled_messages ADD COLUMN contact_ids TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE scheduled_messages ADD COLUMN tag_ids TEXT',
        );
      } catch (_) {}
    }

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
    if (oldVersion < 5) {
      try {
        // Check if column exists first
        var columns = await db.rawQuery(
          'PRAGMA table_info(scheduled_messages)',
        );
        bool hasColumn = columns.any((c) => c['name'] == 'scheduled_day');
        if (!hasColumn) {
          await db.execute(
            "ALTER TABLE scheduled_messages ADD COLUMN scheduled_day INTEGER",
          );
        }
      } catch (e) {
        debugPrint('Migration error: $e');
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

  Future<ScheduledGroup?> getGroupById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scheduled_groups',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return ScheduledGroup.fromMap(maps.first);
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

  Future<List<ScheduledSms>> getDueMessages(DateTime now) async {
    final db = await database;

    // Join with scheduled_groups to ensure the group is active (published)
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT m.* 
      FROM scheduled_messages m
      INNER JOIN scheduled_groups g ON m.group_id = g.id
      WHERE m.status = 'pending' 
        AND m.is_active = 1 
        AND g.is_active = 1
        AND m.scheduled_time <= ?
    ''',
      [now.toIso8601String()],
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

  Future<int> updateMessage(ScheduledSms message) async {
    final db = await database;
    return await db.update(
      'scheduled_messages',
      message.toMap(),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  Future<int> updateMessageStatusByGroup(int groupId, String status) async {
    final db = await database;
    return await db.update(
      'scheduled_messages',
      {'status': status},
      where: 'group_id = ? AND status != ?',
      whereArgs: [groupId, 'sent'], // Don't change status of sent messages
    );
  }

  Future<void> deleteMessages(List<int> ids) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final id in ids) {
        await txn.delete(
          'scheduled_messages',
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });
  }

  Future<void> updateMessagesStatus(List<int> ids, String status) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final id in ids) {
        await txn.update(
          'scheduled_messages',
          {'status': status},
          where: 'id = ? AND status != ?',
          whereArgs: [id, 'sent'],
        );
      }
    });
  }
  // --- Master Sequence Methods ---

  Future<int> insertMasterSequence(MasterSequence sequence) async {
    final db = await database;
    return await db.insert('master_sequences', sequence.toMap());
  }

  Future<List<MasterSequence>> getMasterSequences() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('master_sequences');
    return List.generate(maps.length, (i) => MasterSequence.fromMap(maps[i]));
  }

  Future<int> updateMasterSequence(MasterSequence sequence) async {
    final db = await database;
    return await db.update(
      'master_sequences',
      sequence.toMap(),
      where: 'id = ?',
      whereArgs: [sequence.id],
    );
  }

  Future<int> deleteMasterSequence(int id) async {
    final db = await database;
    return await db.delete(
      'master_sequences',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Sequence Message Methods ---

  Future<int> insertSequenceMessage(SequenceMessage message) async {
    final db = await database;
    return await db.insert('sequence_messages', message.toMap());
  }

  Future<List<SequenceMessage>> getSequenceMessages(int sequenceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sequence_messages',
      where: 'sequence_id = ?',
      whereArgs: [sequenceId],
      orderBy: 'delay_days ASC',
    );
    return List.generate(maps.length, (i) => SequenceMessage.fromMap(maps[i]));
  }

  Future<int> deleteSequenceMessage(int id) async {
    final db = await database;
    return await db.delete(
      'sequence_messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Sequence Subscription Methods ---

  Future<int> insertSubscription(SequenceSubscription subscription) async {
    final db = await database;
    return await db.insert('sequence_subscriptions', subscription.toMap());
  }

  Future<List<SequenceSubscription>> getSubscriptions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sequence_subscriptions',
    );
    return List.generate(
      maps.length,
      (i) => SequenceSubscription.fromMap(maps[i]),
    );
  }

  Future<List<SequenceSubscription>> getSubscriptionsForSequence(
    int sequenceId,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sequence_subscriptions',
      where: 'sequence_id = ?',
      whereArgs: [sequenceId],
    );
    return List.generate(
      maps.length,
      (i) => SequenceSubscription.fromMap(maps[i]),
    );
  }

  Future<int> deleteSubscription(String contactId, int sequenceId) async {
    final db = await database;
    return await db.delete(
      'sequence_subscriptions',
      where: 'contact_id = ? AND sequence_id = ?',
      whereArgs: [contactId, sequenceId],
    );
  }

  // --- Sequence Log Methods ---

  Future<int> insertSequenceLog(int subscriptionId, int messageId) async {
    final db = await database;
    return await db.insert('sequence_logs', {
      'subscription_id': subscriptionId,
      'message_id': messageId,
      'sent_at': DateTime.now().toIso8601String(),
    });
  }

  Future<bool> hasSentSequenceMessage(int subscriptionId, int messageId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sequence_logs',
      where: 'subscription_id = ? AND message_id = ?',
      whereArgs: [subscriptionId, messageId],
    );
    return maps.isNotEmpty;
  }
}
