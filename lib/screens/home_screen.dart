import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/modals/add_tag_dialog.dart';
import '../widgets/contacts_list.dart';
import '../widgets/tags_list.dart';
import 'settings_screen.dart';
import 'add_contact_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const ContactsPage(),
    const Center(child: Text('Send Page')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFFFBB03B),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.contact_page_outlined),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.send_outlined),
            label: 'Send',
          ),
        ],
      ),
    );
  }
}

class ContactsPage extends ConsumerStatefulWidget {
  const ContactsPage({super.key});

  @override
  ConsumerState<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends ConsumerState<ContactsPage> {
  bool _showAllContacts = true;
  final GlobalKey _addContactBtnKey = GlobalKey();
  final GlobalKey _profileKey = GlobalKey();

  Future<void> _pickCsvFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        // PlatformFile file = result.files.first;
        // String? filePath = file.path;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected file: ${result.files.first.name}')),
        );

        // TODO: Process CSV file content here
      } else {
        // User canceled the picker
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  void _showAddContactMenu() async {
    final RenderBox button =
        _addContactBtnKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    // Calculate the position to display the menu below the button
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

    await showMenu(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 8,
      items: [
        const PopupMenuItem<String>(value: 'import', child: Text('Import csv')),
        const PopupMenuItem<String>(
          value: 'single',
          child: Text('Add Single Contact'),
        ),
      ],
    ).then((value) {
      if (value == 'import') {
        _pickCsvFile();
      } else if (value == 'single') {
        // Navigate to Add Contact Screen
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const AddContactScreen()),
        );
      }
    });
  }

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

    await showMenu(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 8,
      items: [
        const PopupMenuItem<String>(value: 'settings', child: Text('Settings')),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Text('Logout', style: TextStyle(color: Colors.red)),
        ),
      ],
    ).then((value) {
      if (value == 'logout') {
        // Navigate back to login screen
        Navigator.of(context).pushReplacementNamed('/');
      } else if (value == 'settings') {
        // Navigate to settings screen
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
      }
    });
  }

  void _showAddTagDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddTagDialog();
      },
    );
  }

  // NOTE: Edit and Delete might need adjustment since we don't have IDs directly in this view context
  // but for now I'll keep the placeholders or basic logic.
  // The TagsList widget doesn't expose the edit/delete buttons yet, so these dialogs
  // are only reachable if we add the buttons back to TagsList or keep the old list.
  // Since we are replacing the old list with TagsList, we won't be able to trigger these
  // from the list items immediately unless we update TagsList.
  // However, I will leave the methods here in case we pass them to TagsList later.

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Bar: User Profile
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                key: _profileKey,
                onTap: _showProfileMenu,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFBB03B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Antony John',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tabs: All Contacts / Manage Tags AND Add Contact Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showAllContacts = true),
                    child: Column(
                      children: [
                        Text(
                          'All Contacts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _showAllContacts
                                ? Colors.black
                                : Colors.grey,
                            decoration: _showAllContacts
                                ? TextDecoration.underline
                                : null,
                            decorationColor: Colors.black,
                            decorationThickness: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () => setState(() => _showAllContacts = false),
                    child: Column(
                      children: [
                        Text(
                          'Manage Tags',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: !_showAllContacts
                                ? Colors.black
                                : Colors.black,
                            decoration: !_showAllContacts
                                ? TextDecoration.underline
                                : null,
                            decorationColor: Colors.black,
                            decorationThickness: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                key: _addContactBtnKey,
                onPressed: _showAllContacts
                    ? _showAddContactMenu
                    : _showAddTagDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBB03B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  _showAllContacts ? 'Add Contact' : 'Add Tag',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Conditional content based on tab selection
          Expanded(
            child: _showAllContacts ? const ContactsList() : const TagsList(),
          ),
        ],
      ),
    );
  }
}
