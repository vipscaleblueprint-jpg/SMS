import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/contact.dart';
import '../../models/tag.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/tags_provider.dart';
import 'delete_contact_dialog.dart';
import '../../widgets/modals/select_tags_dialog.dart';

class EditContactDialog extends ConsumerStatefulWidget {
  final Contact contact;

  const EditContactDialog({super.key, required this.contact});

  @override
  ConsumerState<EditContactDialog> createState() => _EditContactDialogState();
}

class _EditContactDialogState extends ConsumerState<EditContactDialog> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  final TextEditingController _tagSearchController = TextEditingController();
  final FocusNode _tagFocusNode = FocusNode();
  List<Tag> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.contact.first_name,
    );
    _lastNameController = TextEditingController(text: widget.contact.last_name);

    // Use phone number as-is without stripping country code
    _phoneController = TextEditingController(text: widget.contact.phone);

    _selectedTags = List.from(widget.contact.tags);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _tagSearchController.dispose();
    _tagFocusNode.dispose();
    super.dispose();
  }

  void _saveContact() {
    // Use phone number as entered (no forced +63 prefix)
    String phoneInput = _phoneController.text.trim();

    final updatedContact = widget.contact.copyWith(
      first_name: _firstNameController.text.trim(),
      last_name: _lastNameController.text.trim(),
      phone: phoneInput,
      tags: _selectedTags,
    );

    ref.read(contactsProvider.notifier).updateContact(updatedContact);
    Navigator.of(context).pop();
  }

  Future<void> _deleteContact() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) =>
          DeleteContactDialog(contactName: widget.contact.name),
    );

    if (confirm == true) {
      if (mounted) {
        // Refactor Delete to take ID
        ref
            .read(contactsProvider.notifier)
            .deleteContact(widget.contact.contact_id);
        Navigator.of(
          context,
        ).pop(); // Close edit dialog (delete success implies close)
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: const Color(0xFFF2F2F2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _saveContact,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFBB03B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Name (First Name)
                const Text('Name', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      hintText: 'First name',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Last Name
                const Text('Last Name', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      hintText: 'Last name',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Phone
                const Text('Phone', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _phoneController,
                    style: const TextStyle(
                      color: Color(0xFFFBB03B), // Yellow text
                      fontWeight: FontWeight.normal,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText:
                          'Phone number with country code (e.g., +15551234567)',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),

                const SizedBox(height: 20),

                // Tags Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tags', style: TextStyle(fontSize: 16)),
                    ElevatedButton(
                      onPressed: () async {
                        final List<Tag>? result = await showDialog<List<Tag>>(
                          context: context,
                          builder: (context) => SelectTagsDialog(
                            initialSelectedTags: _selectedTags,
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            _selectedTags = result;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFBB03B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text(
                        'Search or add tags',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 100),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RawAutocomplete<Tag>(
                        focusNode: _tagFocusNode,
                        textEditingController: _tagSearchController,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<Tag>.empty();
                          }
                          final availableTags = ref.read(tagsProvider);
                          return availableTags.where((tag) {
                            return tag.name.toLowerCase().contains(
                                  textEditingValue.text.toLowerCase(),
                                ) &&
                                !_selectedTags.any((t) => t.id == tag.id);
                          });
                        },
                        displayStringForOption: (Tag option) => option.name,
                        onSelected: (Tag selection) {
                          setState(() {
                            _selectedTags.add(selection);
                          });
                          _tagSearchController.clear();
                          // Dismiss keyboard after selection as per user request
                          FocusScope.of(context).unfocus();
                        },
                        fieldViewBuilder:
                            (
                              context,
                              textEditingController,
                              focusNode,
                              onFieldSubmitted,
                            ) {
                              return TextField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  hintText: 'Add Tag',
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              );
                            },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0,
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 200,
                                  maxWidth: 300,
                                ),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                        final Tag option = options.elementAt(
                                          index,
                                        );
                                        return InkWell(
                                          onTap: () {
                                            onSelected(option);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Text(option.name),
                                          ),
                                        );
                                      },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      if (_selectedTags.isNotEmpty) const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedTags.map((tag) {
                          return Chip(
                            label: Text(
                              tag.name,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _selectedTags.remove(tag);
                              });
                            },
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Delete Button
                SizedBox(
                  width: 160,
                  child: ElevatedButton(
                    onPressed: _deleteContact,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF0000), // Red
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Delete Contact',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
