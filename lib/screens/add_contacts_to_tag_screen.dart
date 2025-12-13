import 'package:flutter/material.dart';

class AddContactsToTagScreen extends StatefulWidget {
  final String tagName;

  const AddContactsToTagScreen({super.key, required this.tagName});

  @override
  State<AddContactsToTagScreen> createState() => _AddContactsToTagScreenState();
}

class _AddContactsToTagScreenState extends State<AddContactsToTagScreen> {
  final TextEditingController _searchController = TextEditingController();
  // Mock contacts to add
  final List<Map<String, String>> _allContacts = [
    {'name': 'Antony', 'number': '09123456789'},
    {'name': 'Berna', 'number': '09345612368'},
    {'name': 'Cathy', 'number': '09345612368'},
    {'name': 'Doglas', 'number': '09345612368'},
  ];

  List<Map<String, String>> _filteredContacts = [];

  // Track selected contacts by object reference to support filtering
  final Set<Map<String, String>> _selectedContacts = {};

  @override
  void initState() {
    super.initState();
    _filteredContacts = List.from(_allContacts);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = _allContacts.where((contact) {
        final name = contact['name']!.toLowerCase();
        final number = contact['number']!.toLowerCase();
        return name.contains(query) || number.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
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
          widget.tagName,
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
            child: ListView.separated(
              itemCount: _filteredContacts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 0),
              itemBuilder: (context, index) {
                final contact = _filteredContacts[index];
                final isSelected = _selectedContacts.contains(contact);
                return ListTile(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedContacts.remove(contact);
                      } else {
                        _selectedContacts.add(contact);
                      }
                    });
                  },
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      color: isSelected
                          ? const Color(0xFFFBB03B)
                          : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                  title: Text(
                    contact['name']!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFFFBB03B)
                          : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    contact['number']!,
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
            child: TextButton(
              onPressed: () {
                // TODO: Implement logic to actually add selected contacts
                Navigator.of(context).pop();
              },
              child: const Text(
                'Add Contacts',
                style: TextStyle(
                  color: Color(0xFFFBB03B),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
