import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/contacts_provider.dart';
import '../../models/contact.dart';
import '../../models/tag.dart';

class AddContactsToTagScreen extends ConsumerStatefulWidget {
  final Tag tag;

  const AddContactsToTagScreen({super.key, required this.tag});

  @override
  ConsumerState<AddContactsToTagScreen> createState() =>
      _AddContactsToTagScreenState();
}

class _AddContactsToTagScreenState
    extends ConsumerState<AddContactsToTagScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _selectedContactIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final allContacts = ref.watch(contactsProvider);

    // Filter out contacts already in this tag or filter by search query
    final filteredContacts = allContacts.where((contact) {
      final fullName = "${contact.first_name} ${contact.last_name}"
          .toLowerCase();
      final phone = contact.phone;
      final matchesSearch =
          fullName.contains(_searchQuery) || phone.contains(_searchQuery);

      // We might want to show all contacts but visually indicate which are already tagged,
      // or just filter them out. Let's filter out for simplicity.
      final isAlreadyTagged = contact.tags.any((t) => t.id == widget.tag.id);

      return matchesSearch && !isAlreadyTagged;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.tag.name,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
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
          ),

          // Contact List
          Expanded(
            child: filteredContacts.isEmpty
                ? const Center(child: Text('No contacts available to add'))
                : ListView.separated(
                    itemCount: filteredContacts.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 0),
                    itemBuilder: (context, index) {
                      final contact = filteredContacts[index];
                      final isSelected = _selectedContactIds.contains(
                        contact.contact_id,
                      );
                      return ListTile(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedContactIds.remove(contact.contact_id);
                            } else {
                              _selectedContactIds.add(contact.contact_id);
                            }
                          });
                        },
                        leading: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            color: isSelected
                                ? const Color(0xFFFBB03B)
                                : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        title: Text(
                          "${contact.first_name} ${contact.last_name}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFFFBB03B)
                                : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          contact.phone,
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected
                                ? const Color(0xFFFBB03B)
                                : Colors.grey[600],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const Divider(height: 1),

          // Bottom Action
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _selectedContactIds.isEmpty
                    ? null
                    : () async {
                        // Add tag to all selected contacts
                        for (final contactId in _selectedContactIds) {
                          final contact = allContacts.firstWhere(
                            (c) => c.contact_id == contactId,
                          );
                          final updatedTags = [...contact.tags, widget.tag];
                          final updatedContact = contact.copyWith(
                            tags: updatedTags,
                          );

                          await ref
                              .read(contactsProvider.notifier)
                              .updateContact(updatedContact);
                        }

                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Added ${_selectedContactIds.length} contacts to ${widget.tag.name}',
                              ),
                            ),
                          );
                        }
                      },
                child: Text(
                  'Add Contacts',
                  style: TextStyle(
                    color: _selectedContactIds.isEmpty
                        ? Colors.grey
                        : const Color(0xFFFBB03B),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
