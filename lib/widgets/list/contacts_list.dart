import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/contacts_provider.dart';
import '../../models/contact.dart';
import '../modals/edit_contact_dialog.dart';

class ContactsList extends ConsumerStatefulWidget {
  final String searchQuery;
  const ContactsList({super.key, this.searchQuery = ''});

  @override
  ConsumerState<ContactsList> createState() => _ContactsListState();
}

class _ContactsListState extends ConsumerState<ContactsList> {
  // Removed internal _searchController as it's now managed by parent

  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  // Dispose removed since _searchController is gone

  void _toggleSelectionMode(String? initialId) {
    setState(() {
      if (_isSelectionMode) {
        // Exit selection mode
        _isSelectionMode = false;
        _selectedIds.clear();
      } else {
        // Enter selection mode
        _isSelectionMode = true;
        if (initialId != null) {
          _selectedIds.add(initialId);
        }
      }
    });
  }

  void _toggleItemSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final idsToDelete = _selectedIds.toList();
    if (idsToDelete.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Delete ${idsToDelete.length} Contacts?'),
        content: const Text(
          'Are you sure you want to delete the selected contacts? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(contactsProvider.notifier).deleteContacts(idsToDelete);
      setState(() {
        _isSelectionMode = false;
        _selectedIds.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Contacts deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allContacts = ref.watch(contactsProvider);
    final query = widget.searchQuery.toLowerCase();

    // 1. Filter contacts based on search query
    final filteredContacts = allContacts.where((contact) {
      final queryStr = query;
      final nameMatch = contact.name.toLowerCase().contains(queryStr);
      final phoneMatch = contact.phone.contains(queryStr);
      final tagMatch = contact.tags.any(
        (t) => t.name.toLowerCase().contains(queryStr),
      );
      return nameMatch || phoneMatch || tagMatch;
    }).toList();

    return Column(
      children: [
        // Search Bar Area
        if (_isSelectionMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFBB03B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => _toggleSelectionMode(null),
                ),
                Expanded(
                  child: Text(
                    '${_selectedIds.length} Selected',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _deleteSelected,
                  child: const Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Removed internal TextField here, now managed by parent

        // Contact List
        Expanded(
          child: filteredContacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.contacts_rounded,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        allContacts.isEmpty
                            ? 'No contacts found'
                            : 'No matches found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: filteredContacts.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    indent: 64,
                    color: Colors.grey.shade100,
                  ),
                  itemBuilder: (context, index) {
                    final contact = filteredContacts[index];
                    final isSelected = _selectedIds.contains(
                      contact.contact_id,
                    );

                    return ContactRow(
                      contact: contact,
                      isSelectionMode: _isSelectionMode,
                      isSelected: isSelected,
                      onTap: () {
                        if (_isSelectionMode) {
                          _toggleItemSelection(contact.contact_id);
                        } else {
                          showDialog(
                            context: context,
                            builder: (context) =>
                                EditContactDialog(contact: contact),
                          );
                        }
                      },
                      onLongPress: () {
                        if (!_isSelectionMode) {
                          _toggleSelectionMode(contact.contact_id);
                        }
                      },
                      onSelectChange: (val) {
                        _toggleItemSelection(contact.contact_id);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class ContactRow extends StatelessWidget {
  final Contact contact;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool?>? onSelectChange;

  const ContactRow({
    super.key,
    required this.contact,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    this.onSelectChange,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            if (isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Checkbox(
                  value: isSelected,
                  activeColor: const Color(0xFFFBB03B),
                  shape: const CircleBorder(),
                  onChanged: onSelectChange,
                ),
              ),

            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFFBB03B).withOpacity(0.1),
              child: Text(
                contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Color(0xFFFBB03B),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Name and Phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact.phone,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Tags Indicator
            if (!isSelectionMode && contact.tags.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${contact.tags.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),

            if (!isSelectionMode)
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade300,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
