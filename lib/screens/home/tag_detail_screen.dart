import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/contacts_provider.dart';
import '../../models/contact.dart';
import '../../models/tag.dart';
import 'add_contacts_to_tag_screen.dart';

class TagDetailScreen extends ConsumerStatefulWidget {
  final Tag tag;

  const TagDetailScreen({super.key, required this.tag});

  @override
  ConsumerState<TagDetailScreen> createState() => _TagDetailScreenState();
}

class _TagDetailScreenState extends ConsumerState<TagDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    final contacts = ref.watch(contactsProvider);

    // Filter contacts that have this tag
    final tagContacts = contacts.where((contact) {
      return contact.tags.any((t) => t.id == widget.tag.id);
    }).toList();

    // Secondary filter for search
    final filteredContacts = tagContacts.where((contact) {
      final fullName = "${contact.first_name} ${contact.last_name}"
          .toLowerCase();
      final phone = contact.phone;
      return fullName.contains(_searchQuery) || phone.contains(_searchQuery);
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
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddContactsToTagScreen(tag: widget.tag),
                            ),
                          );
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBB03B).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_add_rounded,
                            color: Color(0xFFFBB03B),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.tag.name,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.black.withOpacity(0.9),
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tagContacts.length} contacts matching this tag',
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
                              Icons.people_alt_rounded,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              tagContacts.isEmpty
                                  ? 'No contacts in this tag'
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
                          return _buildContactItem(contact);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(Contact contact) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
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
                  "${contact.first_name} ${contact.last_name}",
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

          IconButton(
            icon: Icon(
              Icons.remove_circle_outline_rounded,
              color: Colors.red.shade300,
              size: 22,
            ),
            onPressed: () => _showDeleteConfirmation(contact),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Contact contact) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: Colors.white,
        child: SizedBox(
          width: 270, // Approximate standard iOS dialog width
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 20.0,
                  bottom: 20.0,
                  left: 16.0,
                  right: 16.0,
                ),
                child: Text(
                  'Are you sure you want to\nremove this contact from\n${widget.tag.name}?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    height: 1.3,
                    color: Colors.black,
                  ),
                ),
              ),
              const Divider(height: 0.5, thickness: 0.5, color: Colors.grey),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Colors.grey, width: 0.5),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        // Remove tag from contact
                        final updatedTags = contact.tags
                            .where((t) => t.id != widget.tag.id)
                            .toList();
                        final updatedContact = contact.copyWith(
                          tags: updatedTags,
                        );

                        await ref
                            .read(contactsProvider.notifier)
                            .updateContact(updatedContact);

                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Contact removed from ${widget.tag.name}',
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            color: Color(0xFFFF3B30), // iOS Red
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
