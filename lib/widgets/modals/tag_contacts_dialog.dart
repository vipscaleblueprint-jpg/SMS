import 'package:flutter/material.dart';
import '../../models/contact.dart';
import '../../models/tag.dart';
import '../list/contacts_list.dart';
import 'edit_contact_dialog.dart';

class TagContactsDialog extends StatelessWidget {
  final Tag tag;
  final List<Contact> contacts;

  const TagContactsDialog({
    super.key,
    required this.tag,
    required this.contacts,
  });

  @override
  Widget build(BuildContext context) {
    // Filter contacts that have this tag
    final tagContacts = contacts
        .where((c) => c.tags.any((t) => t.id == tag.id))
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contacts with tag',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      Text(
                        tag.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFBB03B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Expanded(
              child: tagContacts.isEmpty
                  ? const Center(
                      child: Text(
                        'No contacts associated with this tag',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: tagContacts.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final contact = tagContacts[index];
                        return ContactRow(
                          contact: contact,
                          isSelectionMode: false,
                          isSelected: false,
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  EditContactDialog(contact: contact),
                            );
                          },
                          onLongPress: () {},
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
