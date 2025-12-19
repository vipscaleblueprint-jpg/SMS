import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/contacts_provider.dart';
import '../../models/contact.dart';
import '../modals/edit_contact_dialog.dart';

class ContactsList extends ConsumerStatefulWidget {
  const ContactsList({super.key});

  @override
  ConsumerState<ContactsList> createState() => _ContactsListState();
}

class _ContactsListState extends ConsumerState<ContactsList> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

    // 1. Filter contacts based on search query
    final filteredContacts = allContacts.where((contact) {
      final query = _searchQuery.toLowerCase();
      final nameMatch = contact.name.toLowerCase().contains(query);
      final phoneMatch = contact.phone.contains(query);
      final tagMatch = contact.tags.any(
        (t) => t.name.toLowerCase().contains(query),
      );
      return nameMatch || phoneMatch || tagMatch;
    }).toList();

    return Column(
      children: [
        // ===========================
        // TOOLBAR (Search or Actions)
        // ===========================
        if (_isSelectionMode)
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: const Color(0xFFFBB03B).withOpacity(0.1),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _toggleSelectionMode(null),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_selectedIds.length} Selected',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _deleteSelected,
                ),
              ],
            ),
          )
        else
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search contacts tags...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
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
            ),
          ),

        if (!_isSelectionMode)
          const SizedBox(height: 24)
        else
          const SizedBox(height: 8),

        // ===========================
        // TABLE HEADERS
        // ===========================
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 4, right: 4),
          child: Row(
            children: [
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Checkbox(
                    value:
                        _selectedIds.isNotEmpty &&
                        _selectedIds.length == filteredContacts.length,
                    onChanged: (val) {
                      if (val == true) {
                        setState(() {
                          _selectedIds.addAll(
                            filteredContacts.map((c) => c.contact_id),
                          );
                        });
                      } else {
                        setState(() {
                          _selectedIds.clear();
                        });
                      }
                    },
                  ),
                ),

              const Expanded(
                flex: 2,
                child: Text(
                  'Name',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const Expanded(
                flex: 2,
                child: Text(
                  'Number',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              if (!_isSelectionMode)
                const Expanded(
                  flex: 1,
                  child: Text(
                    'Tags',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ===========================
        // LIST (TABLE ROWS)
        // ===========================
        Expanded(
          child: filteredContacts.isEmpty
              ? Center(
                  child: Text(
                    allContacts.isEmpty
                        ? 'No contacts found'
                        : 'No matches found',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: filteredContacts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  padding: const EdgeInsets.only(top: 16, bottom: 80),
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFBB03B).withOpacity(0.05) : null,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: const Color(0xFFFBB03B).withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            if (isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Checkbox(
                  value: isSelected,
                  activeColor: const Color(0xFFFBB03B),
                  onChanged: onSelectChange,
                ),
              ),

            // Name
            Expanded(
              flex: 2,
              child: Text(
                contact.name,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Number
            Expanded(
              flex: 2,
              child: Text(
                contact.phone,
                style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Tag Count - Hide in selection mode on small screens if cluttered, but fitting it is better
            if (!isSelectionMode)
              Expanded(
                flex: 1,
                child: Text(
                  contact.tags.isEmpty ? '-' : '${contact.tags.length} Tags',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    color: contact.tags.isEmpty
                        ? Colors.grey[400]
                        : const Color(0xFFFBB03B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
