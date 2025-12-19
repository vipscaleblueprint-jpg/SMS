import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/db/user_db_helper.dart';

class UserProfile {
  final String name;
  final String email;
  final String? photoUrl;
  final String businessName;
  final String location;

  const UserProfile({
    this.name = 'User',
    this.email = '',
    this.photoUrl,
    this.businessName = '',
    this.location = '',
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? photoUrl,
    String? businessName,
    String? location,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      businessName: businessName ?? this.businessName,
      location: location ?? this.location,
    );
  }
}

class UserNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    return const UserProfile();
  }

  Future<void> loadUserFromDb() async {
    final dbUser = await UserDbHelper().getUser();
    if (dbUser != null) {
      state = state.copyWith(
        name: dbUser.name,
        email: dbUser.email,
        // photoUrl: dbUser.photoUrl, // User model might not have this yet
      );
    }
  }

  void setUser(String name, String? photoUrl, {String? email}) {
    state = state.copyWith(name: name, photoUrl: photoUrl, email: email);
  }

  void updateProfile({
    String? name,
    String? email,
    String? businessName,
    String? location,
    String? photoUrl,
  }) {
    state = state.copyWith(
      name: name,
      email: email,
      businessName: businessName,
      location: location,
      photoUrl: photoUrl,
    );
  }

  void clearUser() {
    state = const UserProfile();
  }
}

final userProvider = NotifierProvider<UserNotifier, UserProfile>(
  UserNotifier.new,
);
