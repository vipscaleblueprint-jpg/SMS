import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../providers/contacts_provider.dart';
import '../screens/home/settings_screen.dart';
import '../screens/home/edit_profile_screen.dart';
import '../utils/db/user_db_helper.dart';
import '../utils/db/contact_db_helper.dart';
import '../utils/db/sms_db_helper.dart';

class HeaderUser extends ConsumerStatefulWidget {
  const HeaderUser({super.key});

  @override
  ConsumerState<HeaderUser> createState() => _HeaderUserState();
}

class _HeaderUserState extends ConsumerState<HeaderUser> {
  final GlobalKey _profileKey = GlobalKey();

  void _showProfileMenu() async {
    final RenderBox button =
        _profileKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset(0, button.size.height), ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset(0, button.size.height)),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final value = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 8,
      items: [
        const PopupMenuItem<String>(value: 'settings', child: Text('Settings')),
        const PopupMenuItem<String>(
          value: 'edit_profile',
          child: Text('Edit Profile'),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Text('Logout', style: TextStyle(color: Colors.red)),
        ),
      ],
    );

    if (value != null && mounted) {
      if (value == 'logout') {
        debugPrint('Logout: Starting logout process...');

        try {
          // 1. Delete User from DB
          await UserDbHelper().deleteUser();

          // 2. Wipe app data
          await ContactDbHelper.instance.clearContacts();
          await SmsDbHelper().deleteAllSms();

          // 3. Clear providers
          ref.read(userProvider.notifier).clearUser();
          ref.read(contactsProvider.notifier).clear();

          if (mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        } catch (e) {
          debugPrint('Logout Error: $e');
        }
      } else if (value == 'settings') {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
      } else if (value == 'edit_profile') {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const EditProfileScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          key: _profileKey,
          onTap: _showProfileMenu,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFFBB03B),
                  radius: 16,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? const Icon(Icons.person, color: Colors.white, size: 20)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  user.name.isEmpty ? 'Loading...' : user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
