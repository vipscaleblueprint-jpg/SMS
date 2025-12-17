import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert'; // Added for safer decoding
import 'dart:io';
import 'package:flutter_contacts/flutter_contacts.dart' as flutter_contacts;
import 'package:permission_handler/permission_handler.dart';
import '../../widgets/modals/add_tag_dialog.dart';
import '../../widgets/list/contacts_list.dart';
import '../../widgets/list/tags_list.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/tags_provider.dart';
import '../../services/csv_service.dart';
import '../../models/contact.dart';
import '../../models/tag.dart';
import 'settings_screen.dart';
import 'add_contact_screen.dart';
import '../send/send_screen.dart';

import '../campaigns/campaigns_screen.dart';

import 'tag_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const CampaignsScreen(),
    const ContactsPage(),
    const SendScreen(),
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
            icon: Icon(Icons.campaign),
            label: 'Campaigns',
          ),
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
  bool _isImporting = false; // Flag to prevent concurrent imports

  Future<void> _importCsvContacts() async {
    // Prevent concurrent imports
    if (_isImporting) {
      debugPrint('⚠️ Import already in progress, ignoring request');
      return;
    }

    setState(() => _isImporting = true);

    try {
      debugPrint('🔵 Starting CSV import...');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData:
            true, // Request file data in memory for Android 10+ support where path might fail
      );

      if (result != null) {
        String csvString = '';
        final fileParams = result.files.first;

        // Try bytes first if available (reliable for Android URI schemes)
        if (fileParams.bytes != null) {
          debugPrint(
            '🔵 Reading valid bytes from memory (Size: ${fileParams.bytes!.length})',
          );
          try {
            csvString = utf8.decode(fileParams.bytes!);
          } catch (e) {
            debugPrint(
              '⚠️ UTF-8 decode failed, falling back to simple char codes',
            );
            csvString = String.fromCharCodes(fileParams.bytes!);
          }
        } else if (fileParams.path != null) {
          // Fallback to path
          final file = File(fileParams.path!);
          debugPrint('🔵 Reading from file path: ${file.path}');
          csvString = await file.readAsString();
        } else {
          throw Exception(
            'Could not retrieve file content (No path or bytes).',
          );
        }

        final csvService = CsvService();
        final contacts = csvService.parseCsvContent(csvString);

        debugPrint('🔵 Service parsed ${contacts.length} potential contacts');

        if (contacts.isEmpty) {
          debugPrint('🔴 No contacts found by CsvService');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No valid contacts found. Please check CSV headers (First Name, Phone).',
                ),
              ),
            );
          }
          return;
        }

        int importedCount = 0;
        int skippedCount = 0;

        for (final contact in contacts) {
          // Basic validation
          if (contact.phone.isNotEmpty &&
              (contact.first_name.isNotEmpty || contact.last_name.isNotEmpty)) {
            // Ensure tags exist in DB
            List<Tag> finalTags = [];
            for (var t in contact.tags) {
              try {
                final tag = await ref
                    .read(tagsProvider.notifier)
                    .getOrCreateTag(t.name);
                finalTags.add(tag);
              } catch (e) {
                debugPrint('⚠️ Error processing tag ${t.name}: $e');
              }
            }

            final newContact = contact.copyWith(tags: finalTags);

            await ref.read(contactsProvider.notifier).addContact(newContact);
            importedCount++;
          } else {
            skippedCount++;
            debugPrint(
              '⚠️ Skipped contact: Missing Name or Phone. Name: "${contact.first_name} ${contact.last_name}", Phone: "${contact.phone}"',
            );
          }
        }

        debugPrint(
          '🎉 CSV Import Complete! Imported: $importedCount, Skipped: $skippedCount',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully imported $importedCount contacts${skippedCount > 0 ? ' ($skippedCount skipped)' : ''}',
              ),
            ),
          );
        }
      } else {
        debugPrint('🔴 No file selected or file path is null');
      }
    } catch (e) {
      debugPrint('🔴 CSV Import Error: $e');
      debugPrint('🔴 Stack trace: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error importing CSV: $e')));
      }
    } finally {
      // Always reset the flag when done
      if (mounted) {
        setState(() => _isImporting = false);
      }
      debugPrint('🔵 Import process completed, flag reset');
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
        PopupMenuItem<String>(
          value: 'import_csv',
          enabled: !_isImporting,
          child: Row(
            children: [
              Text('Import CSV'),
              if (_isImporting) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),

        PopupMenuItem<String>(
          value: 'single',
          enabled: !_isImporting,
          child: const Text('Add Single Contact'),
        ),
      ],
    ).then((value) {
      if (value == 'import_csv') {
        _importCsvContacts();
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
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Color(0xFFFBB03B),
                        radius: 16,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Antony John',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 12),
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
