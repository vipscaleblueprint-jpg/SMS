import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/contact.dart';
import '../../models/tag.dart';

class ContactDbHelper {
  ContactDbHelper._internal();
  static final ContactDbHelper instance = ContactDbHelper._internal();

  static Database? _db;

  // =========================
  // DATABASE INIT
  // =========================

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sms_app.db');

    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE contacts (
        contact_id TEXT PRIMARY KEY,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT,
        phone TEXT NOT NULL,
        created TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tags (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        color TEXT,
        created TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE contact_tags (
        contact_id TEXT NOT NULL,
        tag_id TEXT NOT NULL,
        PRIMARY KEY (contact_id, tag_id),
        FOREIGN KEY (contact_id) REFERENCES contacts(contact_id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      )
    ''');
  }

  // =========================
  // INSERT
  // =========================

  Future<void> insertContact(Contact contact) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.insert('contacts', {
        'contact_id': contact.contact_id,
        'first_name': contact.first_name,
        'last_name': contact.last_name,
        'email': contact.email,
        'phone': contact.phone,
        'created': contact.created.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      for (final tag in contact.tags) {
        // Ensure tag exists
        await txn.insert('tags', {
          'id': tag.id,
          'name': tag.name,
          'color': tag.color,
          'created': tag.created?.toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        // Link contact <-> tag
        await txn.insert('contact_tags', {
          'contact_id': contact.contact_id,
          'tag_id': tag.id,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  Future<void> updateContact(Contact contact) async {
    final db = await database;

    await db.transaction((txn) async {
      // 1. Update contact details
      await txn.update(
        'contacts',
        {
          'first_name': contact.first_name,
          'last_name': contact.last_name,
          'email': contact.email,
          'phone': contact.phone,
        },
        where: 'contact_id = ?',
        whereArgs: [contact.contact_id],
      );

      // 2. Sync tags: Remove all old associations first
      await txn.delete(
        'contact_tags',
        where: 'contact_id = ?',
        whereArgs: [contact.contact_id],
      );

      // 3. Re-add current tags
      for (final tag in contact.tags) {
        // Ensure tag exists in tags table
        await txn.insert('tags', {
          'id': tag.id,
          'name': tag.name,
          'color': tag.color,
          'created': tag.created?.toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        // Link contact <-> tag
        await txn.insert('contact_tags', {
          'contact_id': contact.contact_id,
          'tag_id': tag.id,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  // =========================
  // READ
  // =========================

  Future<List<Contact>> getAllContacts() async {
    final db = await database;

    final contactRows = await db.query('contacts', orderBy: 'created DESC');

    final List<Contact> contacts = [];

    for (final row in contactRows) {
      final tags = await _getTagsForContact(row['contact_id'] as String);

      contacts.add(
        Contact(
          contact_id: row['contact_id'] as String,
          first_name: row['first_name'] as String,
          last_name: row['last_name'] as String,
          email: row['email'] as String?,
          phone: row['phone'] as String,
          created: DateTime.parse(row['created'] as String),
          tags: tags,
        ),
      );
    }

    return contacts;
  }

  Future<List<Tag>> getAllTags() async {
    final db = await database;
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
  }

  // =========================
  // DELETE
  // =========================

  Future<void> deleteContact(String contactId) async {
    final db = await database;

    await db.delete(
      'contacts',
      where: 'contact_id = ?',
      whereArgs: [contactId],
    );
  }

  // =========================
  // INTERNAL
  // =========================

  Future<List<Tag>> _getTagsForContact(String contactId) async {
    final db = await database;

    final rows = await db.rawQuery(
      '''
      SELECT t.*
      FROM tags t
      INNER JOIN contact_tags ct ON ct.tag_id = t.id
      WHERE ct.contact_id = ?
    ''',
      [contactId],
    );

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
  }

  // =========================
  // CLEAR CONTACTS
  // =========================

  Future<void> clearContacts() async {
    final db = await database;
    await db.delete('contact_tags');
    await db.delete('contacts');
  }
}
