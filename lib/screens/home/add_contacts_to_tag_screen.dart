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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Area (iOS Style)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Color(0xFFFBB03B),
                              size: 20,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Back',
                              style: TextStyle(
                                color: Color(0xFFFBB03B),
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _selectedContactIds.isEmpty
                            ? null
                            : () async {
                                final total = _selectedContactIds.length;
                                for (final contactId in _selectedContactIds) {
                                  final contact = allContacts.firstWhere(
                                    (c) => c.contact_id == contactId,
                                  );
                                  final updatedTags = [
                                    ...contact.tags,
                                    widget.tag,
                                  ];
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
                                        'Added $total contacts to ${widget.tag.name}',
                                      ),
                                    ),
                                  );
                                }
                              },
                        child: Text(
                          'Add',
                          style: TextStyle(
                            color: _selectedContactIds.isEmpty
                                ? Colors.grey.shade400
                                : const Color(0xFFFBB03B),
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add Contacts',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.black.withOpacity(0.9),
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'to group "${widget.tag.name}"',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search',
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
            ),

            const SizedBox(height: 8),

            // Contact List
            Expanded(
              child: Container(
                color: const Color(0xFFF8F9FA),
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
                              'No contacts available',
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
                        itemCount: filteredContacts.length,
                        padding: const EdgeInsets.only(bottom: 32),
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          indent: 64,
                          color: Colors.grey.shade100,
                        ),
                        itemBuilder: (context, index) {
                          final contact = filteredContacts[index];
                          final isSelected = _selectedContactIds.contains(
                            contact.contact_id,
                          );
                          return _buildContactItem(contact, isSelected);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(Contact contact, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedContactIds.remove(contact.contact_id);
          } else {
            _selectedContactIds.add(contact.contact_id);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Selection Indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFBB03B)
                      : Colors.grey.shade300,
                  width: isSelected ? 8 : 1.5,
                ),
                color: isSelected ? const Color(0xFFFBB03B) : Colors.white,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check, size: 14, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFFBB03B).withOpacity(0.1),
              child: Text(
                contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Color(0xFFFBB03B),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name and Phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${contact.first_name} ${contact.last_name}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFFFBB03B)
                          : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact.phone,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected
                          ? const Color(0xFFFBB03B).withOpacity(0.7)
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
