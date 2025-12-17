import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tag.dart';
import '../../providers/tags_provider.dart';
import '../../providers/contacts_provider.dart';

class SelectTagsDialog extends ConsumerStatefulWidget {
  final List<Tag> initialSelectedTags;

  const SelectTagsDialog({super.key, required this.initialSelectedTags});

  @override
  ConsumerState<SelectTagsDialog> createState() => _SelectTagsDialogState();
}

class _SelectTagsDialogState extends ConsumerState<SelectTagsDialog> {
  late List<Tag> _selectedTags;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.initialSelectedTags);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    // Auto-focus search for better UX
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleTag(Tag tag) {
    setState(() {
      if (_selectedTags.any((t) => t.id == tag.id)) {
        _selectedTags.removeWhere((t) => t.id == tag.id);
      } else {
        _selectedTags.add(tag);
      }
    });
    // Clear search after selection? Maybe not if selecting multiple.
  }

  int _getTagCount(String tagId, List<dynamic> contacts) {
    int count = 0;
    for (final contact in contacts) {
      if (contact.tags.any((t) => t.id == tagId)) {
        count++;
      }
    }
    return count;
    // Note: This relies on contactsProvider having 'tags' as fully populated logic or checking ID match.
    // Contact model has 'List<Tag> tags'.
  }

  @override
  Widget build(BuildContext context) {
    final allTags = ref.watch(tagsProvider);
    final contacts = ref.watch(contactsProvider);

    final filteredTags = allTags.where((tag) {
      return tag.name.toLowerCase().contains(_searchQuery);
    }).toList();

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header? Screenshot just shows chips.
              // But let's add a small spacing or label if needed?
              // Reference image has chips directly at top inside the white box.

              // Selected Tags Area (Chips)
              if (_selectedTags.isNotEmpty) ...[
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
                          _selectedTags.removeWhere((t) => t.id == tag.id);
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
                const SizedBox(height: 12),
              ],

              // Search Bar
              TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search tags...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
              const SizedBox(height: 12),

              // Tag List
              // Constrain height if list is long
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredTags.length,
                  itemBuilder: (context, index) {
                    final tag = filteredTags[index];
                    final isSelected = _selectedTags.any((t) => t.id == tag.id);
                    final count = _getTagCount(tag.id, contacts);

                    return InkWell(
                      onTap: () => _toggleTag(tag),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 8.0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                tag.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Text(
                              count.toString(),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Add Tag Button (Confirm)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(_selectedTags);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFBB03B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Add Tag',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
