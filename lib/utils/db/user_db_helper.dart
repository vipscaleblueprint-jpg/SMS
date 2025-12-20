import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/user.dart';

class UserDbHelper {
  static final UserDbHelper _instance = UserDbHelper._internal();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _userKey = 'user_data';

  factory UserDbHelper() => _instance;

  UserDbHelper._internal();

  Future<void> insertUser(User user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<void> updateUserToken(String email, String token) async {
    final user = await getUser();
    if (user != null && user.email == email) {
      final updatedUser = user.copyWith(access_token: token);
      await insertUser(updatedUser);
    }
  }

  Future<User?> getUser() async {
    final String? userJson = await _storage.read(key: _userKey);
    if (userJson != null) {
      try {
        return User.fromJson(jsonDecode(userJson));
      } catch (e) {
        // print('Error parsing user json: $e');
        return null;
      }
    }
    return null;
  }

  Future<void> deleteUser() async {
    await _storage.delete(key: _userKey);
  }
}
