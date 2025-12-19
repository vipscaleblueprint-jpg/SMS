import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/user.dart';

class UserDbHelper {
  static final UserDbHelper _instance = UserDbHelper._internal();
  static Database? _database;

  factory UserDbHelper() => _instance;

  UserDbHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'user.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        name TEXT,
        email TEXT,
        created TEXT,
        access_token TEXT,
        numbers TEXT,
        settings TEXT,
        templates TEXT
      )
    ''');
  }

  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert(
      'users',
      user.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateUserToken(String email, String token) async {
    final db = await database;
    await db.update(
      'users',
      {'access_token': token},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  Future<User?> getUser() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users', limit: 1);
    if (maps.isNotEmpty) {
      return User.fromDbMap(maps.first);
    }
    return null;
  }

  Future<int> deleteUser() async {
    final db = await database;
    try {
      final count = await db.delete('users');
      print('DB: Deleted $count rows from users table');
      return count;
    } catch (e) {
      print('DB: Error deleting user: $e');
      return 0;
    }
  }
}
