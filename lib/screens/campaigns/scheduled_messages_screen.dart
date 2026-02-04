import 'package:flutter/material.dart';
import '../../widgets/header_user.dart';
import 'scheduled_detail_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/scheduled_provider.dart';
import '../../models/scheduled_group.dart';
import '../../widgets/list/dropdown-contacts.dart';
import '../../widgets/scheduling_debug_panel.dart';
import '../../widgets/modals/delete_confirmation_dialog.dart';

class ScheduledMessagesScreen extends ConsumerStatefulWidget {
  const ScheduledMessagesScreen({super.key});

  @override
  ConsumerState<ScheduledMessagesScreen> createState() =>
      _ScheduledMessagesScreenState();
}

class _ScheduledMessagesScreenState
    extends ConsumerState<ScheduledMessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddScheduledDialog() {
    final titleController = TextEditingController();
    final recipientController = TextEditingController();
    final recipientFocusNode = FocusNode();
    final Set<String> selectedContactIds = {};
    final Set<String> selectedTagIds = {};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create a Scheduled SMS',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Title',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'Title',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Recipients',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownContacts(
                    controller: recipientController,
                    focusNode: recipientFocusNode,
                    selectedContactIds: selectedContactIds,
                    selectedTagIds: selectedTagIds,
                    onContactSelected: (contact) {
                      debugPrint('Contact selected: ${contact.name}');
                      setState(() {
                        if (selectedContactIds.contains(contact.contact_id)) {
                          selectedContactIds.remove(contact.contact_id);
                        } else {
                          selectedContactIds.add(contact.contact_id);
                        }
                      });
                    },
                    onTagSelected: (tag) {
                      debugPrint('Tag selected: ${tag.name}');
                      setState(() {
                        if (selectedTagIds.contains(tag.id)) {
                          selectedTagIds.remove(tag.id);
                        } else {
                          selectedTagIds.add(tag.id);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          debugPrint('Cancel pressed');
                          recipientFocusNode.dispose();
                          recipientController.dispose();
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (titleController.text.isNotEmpty) {
                            ref
                                .read(scheduledGroupsProvider.notifier)
                                .addGroup(
                                  titleController.text,
                                  contactIds: selectedContactIds,
                                  tagIds: selectedTagIds,
                                );
                            recipientFocusNode.dispose();
                            recipientController.dispose();
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFBB03B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduledGroups = ref.watch(scheduledGroupsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const HeaderUser(),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Add Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Scheduled',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _showAddScheduledDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFBB03B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Add Scheduled',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // "All" Tab indicator
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        SizedBox(
                          width: 24,
                          child: Divider(
                            color: Color(0xFFFBB03B),
                            thickness: 2,
                            height: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search Scheduled SMS',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.grey[400],
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // List Header
                    Column(
                      children: [
                        const Row(
                          children: [
                            Text(
                              'Title',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Divider(color: Colors.grey[300]),
                      ],
                    ),

                    // List Items
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final filteredGroups = scheduledGroups
                              .where(
                                (group) => group.title.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ),
                              )
                              .toList();

                          if (filteredGroups.isEmpty) {
                            return const Center(child: Text("No items found"));
                          }

                          return ListView.builder(
                            itemCount: filteredGroups.length,
                            itemBuilder: (context, index) {
                              return _buildScheduledItem(filteredGroups[index]);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SchedulingDebugPanel(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduledItem(ScheduledGroup group) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ScheduledDetailScreen(group: group),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  group.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (group.id == null) return;
                    showDialog(
                      context: context,
                      builder: (context) => DeleteConfirmationDialog(
                        title: 'Delete this Schedule?',
                        message:
                            'Are you sure you want to delete the ${group.title} Schedule?\n\nDeleting this schedule will result in the following actions that you may want to consider before moving forward.',
                        deleteButtonText: 'Delete schedule',
                      ),
                    ).then((confirm) {
                      if (confirm == true && group.id != null) {
                        ref
                            .read(scheduledGroupsProvider.notifier)
                            .deleteGroup(group.id!);
                      }
                    });
                  },
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(color: Colors.grey[100], height: 1),
      ],
    );
  }
}
