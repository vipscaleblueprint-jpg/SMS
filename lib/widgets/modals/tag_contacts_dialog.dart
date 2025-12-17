import 'package:flutter/material.dart';
import '../../models/contact.dart';
import '../../models/tag.dart';

class TagContactsDialog extends StatefulWidget {
  final Tag tag;
  final List<Contact> allContacts;

  const TagContactsDialog({
    super.key,
    required this.tag,
    required this.allContacts,
  });

  @override
  State<TagContactsDialog> createState() => _TagContactsDialogState();
}

class _TagContactsDialogState extends State<TagContactsDialog> {
  late List<Contact> _tagContacts;
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    // Filter contacts that have this tag
    _tagContacts = widget.allContacts.where((c) {
      return c.tags.any((t) => t.id == widget.tag.id);
    }).toList();

    // Initially select all
    _selectedIds = _tagContacts.map((c) => c.contact_id).toSet();
  }

  void _toggleAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedIds = _tagContacts.map((c) => c.contact_id).toSet();
      } else {
        _selectedIds.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if all are selected
    final areAllSelected =
        _tagContacts.isNotEmpty && _selectedIds.length == _tagContacts.length;
    final isNoneSelected = _selectedIds.isEmpty;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Contacts in "${widget.tag.name}"',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(), // Cancel/Close
                  child: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Select All Checkbox
            Row(
              children: [
                Checkbox(
                  value: isNoneSelected
                      ? false
                      : (areAllSelected ? true : null),
                  tristate: true,
                  onChanged: _toggleAll,
                  activeColor: const Color(0xFFFBB03B),
                ),
                const Text(
                  'Select All',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${_selectedIds.length}/${_tagContacts.length}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const Divider(),

            // Contacts List
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: _tagContacts.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'No contacts in this tag',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _tagContacts.length,
                      itemBuilder: (context, index) {
                        final contact = _tagContacts[index];
                        final isSelected = _selectedIds.contains(
                          contact.contact_id,
                        );

                        return CheckboxListTile(
                          value: isSelected,
                          activeColor: const Color(0xFFFBB03B),
                          title: Text(contact.name),
                          subtitle: Text(contact.phone),
                          secondary: CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            child: Text(
                              contact.first_name.isNotEmpty
                                  ? contact.first_name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedIds.add(contact.contact_id);
                              } else {
                                _selectedIds.remove(contact.contact_id);
                              }
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    // Return the list of selected IDs
                    Navigator.of(context).pop(_selectedIds.toList());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFBB03B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
