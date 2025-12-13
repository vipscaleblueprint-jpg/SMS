import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/contacts_provider.dart';
import '../../models/contact.dart';

class ContactsList extends ConsumerStatefulWidget {
  const ContactsList({super.key});

  @override
  ConsumerState<ContactsList> createState() => _ContactsListState();
}

class _ContactsListState extends ConsumerState<ContactsList> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        // SEARCH BAR
        // ===========================
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
        const SizedBox(height: 24),

        // ===========================
        // TABLE HEADERS
        // ===========================
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0, left: 4, right: 4),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Name',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Number',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
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
                  itemCount: filteredContacts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  padding: const EdgeInsets.only(top: 16, bottom: 80),
                  itemBuilder: (context, index) {
                    final contact = filteredContacts[index];
                    return _ContactRow(contact: contact);
                  },
                ),
        ),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  final Contact contact;

  const _ContactRow({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        children: [
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
          // Tag Count
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
    );
  }
}
