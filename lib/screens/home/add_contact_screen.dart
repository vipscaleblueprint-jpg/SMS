import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import '../../models/contact.dart';
import '../../models/tag.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/tags_provider.dart';
import '../../widgets/modals/select_tags_dialog.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AddContactScreen extends ConsumerStatefulWidget {
  const AddContactScreen({super.key});

  @override
  ConsumerState<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends ConsumerState<AddContactScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _tagSearchController = TextEditingController();
  final FocusNode _tagFocusNode = FocusNode();
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'PH');

  List<Tag> _selectedTags = [];
  bool _isEditing = false;
  String? _photoPath;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _photoPath = image.path;
      });
    }
  }

  void _removeTag(Tag tag) {
    setState(() {
      _selectedTags.removeWhere((t) => t.id == tag.id);
    });
  }

  Future<void> _saveContact() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneNumber.phoneNumber ?? '';

    if (firstName.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and phone are required')),
      );
      return;
    }

    // Removed phone validation - accept any format

    final contact = Contact(
      contact_id: const Uuid().v4(),
      first_name: firstName,
      last_name: lastName,
      phone: phone,
      email: null,
      created: DateTime.now(),
      tags: _selectedTags,
      photoPath: _photoPath,
    );

    try {
      // Add contact via provider (ref provided by ConsumerState)
      await ref.read(contactsProvider.notifier).addContact(contact);

      if (!mounted) return;

      // Log success
      debugPrint('✅ Contact added: ${contact.name}, ${contact.phone}');

      // Show success UI
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact added successfully')),
      );

      Navigator.of(context).pop(); // Go back to contacts list
    } catch (e) {
      debugPrint('❌ Failed to add contact: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to add contact')));
      }
    }
  }

  void _deleteContact() {
    // TODO: Delete contact logic
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _saveContact,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFBB03B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
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

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Profile Photo Placeholder
                    GestureDetector(
                      onTap: _pickImage,
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              height: 100,
                              width: 100,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBB03B).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: _photoPath != null
                                  ? Image.file(
                                      File(_photoPath!),
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(
                                      Icons.person_rounded,
                                      size: 50,
                                      color: Color(0xFFFBB03B),
                                    ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _photoPath != null ? 'Change Photo' : 'Add Photo',
                              style: const TextStyle(
                                color: Color(0xFFFBB03B),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Name Section
                    _buildSectionHeader('NAME'),
                    const SizedBox(height: 10),
                    _buildCardWrapper(
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _firstNameController,
                            hint: 'First Name',
                          ),
                          const Divider(height: 1, indent: 16),
                          _buildTextField(
                            controller: _lastNameController,
                            hint: 'Last Name',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Phone Section
                    _buildSectionHeader('PHONE'),
                    const SizedBox(height: 10),
                    _buildCardWrapper(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: InternationalPhoneNumberInput(
                        onInputChanged: (PhoneNumber number) {
                          _phoneNumber = number;
                        },
                        selectorConfig: const SelectorConfig(
                          selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                          useBottomSheetSafeArea: true,
                        ),
                        ignoreBlank: false,
                        autoValidateMode: AutovalidateMode.disabled,
                        selectorTextStyle: const TextStyle(color: Colors.black),
                        initialValue: _phoneNumber,
                        textFieldController: _phoneController,
                        formatInput: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: true,
                          decimal: true,
                        ),
                        inputDecoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Number',
                          isDense: true,
                        ),
                        searchBoxDecoration: InputDecoration(
                          labelText: 'Search by Country Name or Dial Code',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tags Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader('TAGS'),
                        GestureDetector(
                          onTap: () async {
                            final List<Tag>? result =
                                await showDialog<List<Tag>>(
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
                          child: const Text(
                            'Select More',
                            style: TextStyle(
                              color: Color(0xFFFBB03B),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildCardWrapper(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RawAutocomplete<Tag>(
                            focusNode: _tagFocusNode,
                            textEditingController: _tagSearchController,
                            optionsBuilder:
                                (TextEditingValue textEditingValue) {
                                  if (textEditingValue.text.isEmpty) {
                                    return const Iterable<Tag>.empty();
                                  }
                                  final availableTags = ref.read(tagsProvider);
                                  return availableTags.where((tag) {
                                    return tag.name.toLowerCase().contains(
                                          textEditingValue.text.toLowerCase(),
                                        ) &&
                                        !_selectedTags.any(
                                          (t) => t.id == tag.id,
                                        );
                                  });
                                },
                            displayStringForOption: (Tag option) => option.name,
                            onSelected: (Tag selection) {
                              setState(() {
                                _selectedTags.add(selection);
                              });
                              _tagSearchController.clear();
                              _tagFocusNode.requestFocus();
                            },
                            fieldViewBuilder:
                                (
                                  context,
                                  textController,
                                  focusNode,
                                  onSubmitted,
                                ) {
                                  return TextField(
                                    controller: textController,
                                    focusNode: focusNode,
                                    decoration: const InputDecoration(
                                      hintText: 'Search or type to add...',
                                      border: InputBorder.none,
                                      isDense: true,
                                      hintStyle: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 8,
                                  borderRadius: BorderRadius.circular(15),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxHeight: 200,
                                      maxWidth: 280,
                                    ),
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder: (context, index) {
                                        final Tag option = options.elementAt(
                                          index,
                                        );
                                        return ListTile(
                                          title: Text(
                                            option.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                          onTap: () => onSelected(option),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (_selectedTags.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Divider(height: 1),
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedTags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFBB03B,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFFBB03B,
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        tag.name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFFBB03B),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => _removeTag(tag),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 14,
                                          color: Color(0xFFFBB03B),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    if (_isEditing)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: TextButton(
                          onPressed: _deleteContact,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(
                                color: Colors.redAccent.withOpacity(0.2),
                              ),
                            ),
                            backgroundColor: Colors.redAccent.withOpacity(0.05),
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
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCardWrapper({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
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
}
