import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_number/mobile_number.dart';
import '../../widgets/modals/add_tag_dialog.dart';
import '../../widgets/list/contacts_list.dart';
import '../../widgets/list/tags_list.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/tags_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/tag.dart';
import '../../services/csv_service.dart';
import 'add_contact_screen.dart';
import '../campaigns/campaigns_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../send/send_screen.dart';
import '../../widgets/header_user.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final String? userName;
  final String? userPhotoUrl;
  final int initialIndex;

  const HomeScreen({
    super.key,
    this.userName,
    this.userPhotoUrl,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    if (widget.initialIndex != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(navigationProvider.notifier).setTab(widget.initialIndex);
      });
    }
    _checkPermissions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.userName != null) {
        ref
            .read(userProvider.notifier)
            .setUser(widget.userName!, widget.userPhotoUrl);
      } else {
        // Load from DB if no params passed (e.g. from cold start)
        ref.read(userProvider.notifier).loadUserFromDb();
      }
    });

    _pages = [
      const DashboardScreen(),
      const CampaignsScreen(),
      const SendScreen(),
      const ContactsPage(),
    ];
  }

  Future<void> _checkPermissions() async {
    // Basic permissions are already handled in LoadingScreen
    // Specific check for MobileNumber plugin
    try {
      if (await Permission.phone.isGranted) {
        if (!await MobileNumber.hasPhonePermission) {
          await MobileNumber.requestPhonePermission;
        }
      }
    } catch (e) {
      debugPrint('Error checking mobile number permission: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: IndexedStack(index: currentIndex, children: _pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        currentIndex: currentIndex,
        onTap: (index) => ref.read(navigationProvider.notifier).setTab(index),
        selectedItemColor: const Color(0xFFFBB03B),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_outlined),
            activeIcon: Icon(Icons.campaign),
            label: 'Campaigns',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.send_outlined),
            activeIcon: Icon(Icons.send),
            label: 'Send',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contact_page_outlined),
            activeIcon: Icon(Icons.contact_page),
            label: 'Contacts',
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
  bool _isImporting = false; // Flag to prevent concurrent imports
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _importCsvContacts() async {
    // Prevent concurrent imports
    if (_isImporting) {
      debugPrint('⚠️ Import already in progress, ignoring request');
      return;
    }

    setState(() => _isImporting = true);

    try {
      debugPrint('🔵 Starting CSV import...');
      debugPrint('🔵 Launching file picker...');
      FilePickerResult? result;
      try {
        // We use FileType.custom as it's often more reliable for specific file types on Drive
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['csv', 'txt'],
          withData: true,
        );
      } on PlatformException catch (pe) {
        debugPrint(
          '🔴 PlatformException during pickFiles: ${pe.code} - ${pe.message}',
        );
        if (pe.code == 'unknown_path') {
          debugPrint('🔵 Falling back to FileType.any due to unknown_path...');
          result = await FilePicker.platform.pickFiles(
            type: FileType.any,
            withData: true,
          );
        } else {
          rethrow;
        }
      }

      if (result != null) {
        final fileParams = result.files.first;
        debugPrint(
          '🔵 Picked file properties -> Name: ${fileParams.name}, Path: ${fileParams.path}, Bytes: ${fileParams.bytes?.length}',
        );

        final extension = fileParams.extension?.toLowerCase() ?? '';

        // Validation including filename check as FileType.any was used
        bool isValidExtension =
            extension == 'csv' ||
            extension == 'txt' ||
            fileParams.name.toLowerCase().endsWith('.csv') ||
            fileParams.name.toLowerCase().endsWith('.txt');

        if (!isValidExtension) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a .csv or .txt file'),
              ),
            );
          }
          setState(() => _isImporting = false);
          return;
        }

        String csvString = '';

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

            // 1. Add "new" tag automatically for all imported contacts
            try {
              final newTag = await ref
                  .read(tagsProvider.notifier)
                  .getOrCreateTag('new');
              finalTags.add(newTag);
            } catch (e) {
              debugPrint('⚠️ Error processing "new" tag: $e');
            }

            for (var t in contact.tags) {
              // Avoid adding 'new' twice if it was already in the CSV
              if (t.name.toLowerCase() == 'new') continue;

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
      surfaceTintColor: Colors.white,
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Area (iOS Style)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section
                const HeaderUser(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Contacts',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.black.withOpacity(0.9),
                        letterSpacing: -1,
                      ),
                    ),
                    IconButton(
                      key: _addContactBtnKey,
                      onPressed: _showAllContacts
                          ? _showAddContactMenu
                          : _showAddTagDialog,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBB03B).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Color(0xFFFBB03B),
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Segmented Control (Refactored to fix flicker)
                Container(
                  height: 44,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    children: [
                      // Animated Background Slider
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        alignment: _showAllContacts
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: FractionallySizedBox(
                          widthFactor: 0.5,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _SegmentToggle(
                              label: 'All Contacts',
                              isSelected: _showAllContacts,
                              onTap: () =>
                                  setState(() => _showAllContacts = true),
                            ),
                          ),
                          Expanded(
                            child: _SegmentToggle(
                              label: 'Manage Tags',
                              isSelected: !_showAllContacts,
                              onTap: () =>
                                  setState(() => _showAllContacts = false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Persistent Search Bar (Moved from lists to parent to fix flicker)
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: _showAllContacts
                        ? 'Search Contacts'
                        : 'Search Tags',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.grey.shade400,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FA),
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: IndexedStack(
                index: _showAllContacts ? 0 : 1,
                children: [
                  ContactsList(searchQuery: _searchQuery),
                  TagsList(searchQuery: _searchQuery),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentToggle({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent, // Ensure the whole area is tappable
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.black : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
