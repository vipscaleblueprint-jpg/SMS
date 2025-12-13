import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/tag.dart';

class TagsDbHelper {
  TagsDbHelper._internal();
  static final TagsDbHelper instance = TagsDbHelper._internal();

  static Database? _db;

  // Use the same database as ContactDbHelper
  // Ideally, these would share a common core DB helper
  // For now, we open the same file
  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sms_app.db');

    // We rely on ContactDbHelper having created the tables
    // or we can ensure they exist here too.
    // Better safely open it.
    return openDatabase(
      path,
      version: 1,
      // onCreate is handled by ContactDbHelper usually, so we might not need it here
      // if we assume the app starts with ContactDbHelper being called or main.
      // But for robustness:
      onCreate: (db, version) async {
        // Duplicate table creation logic strictly if needed, usually better to centralize
        // Assuming ContactDbHelper handles creation for now or this is run after.
        debugPrint('⚠️ TagsDbHelper: db created (fallback)');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS tags (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            color TEXT,
            created TEXT
          )
        ''');
      },
      onOpen: (db) {
        debugPrint('📂 TagsDbHelper: DB open');
      },
    );
  }

  // =========================
  // CRUD
  // =========================

  Future<List<Tag>> getAllTags() async {
    final db = await database;
    try {
      final rows = await db.query('tags', orderBy: 'name ASC');
      return rows.map((row) {
        return Tag(
          id: row['id'] as String,
          name: row['name'] as String,
          color: row['color'] as String?,
          created: row['created'] != null
              ? DateTime.parse(row['created'] as String)
              : null,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting all tags: $e');
      return [];
    }
  }

  Future<void> insertTag(Tag tag) async {
    final db = await database;
    await db.insert('tags', {
      'id': tag.id,
      'name': tag.name,
      'color': tag.color,
      'created': tag.created?.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    debugPrint('✅ DB: Tag added → ${tag.name}');
  }

  Future<void> updateTag(Tag tag) async {
    final db = await database;
    await db.update(
      'tags',
      {'name': tag.name, 'color': tag.color},
      where: 'id = ?',
      whereArgs: [tag.id],
    );
    debugPrint('✅ DB: Tag updated → ${tag.name}');
  }

  Future<void> deleteTag(String id) async {
    final db = await database;
    await db.delete('tags', where: 'id = ?', whereArgs: [id]);
    debugPrint('🗑 DB: Tag deleted → $id');
  }
}
