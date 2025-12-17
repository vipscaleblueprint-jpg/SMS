import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/tags_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../models/tag.dart';
import '../modals/edit_tag_dialog.dart';
import '../modals/delete_tag_dialog.dart';
import '../../screens/home/tag_detail_screen.dart';

class TagsList extends ConsumerStatefulWidget {
  const TagsList({super.key});

  @override
  ConsumerState<TagsList> createState() => _TagsListState();
}

class _TagsListState extends ConsumerState<TagsList> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showEditTagDialog(Tag tag) {
    showDialog(
      context: context,
      builder: (context) => EditTagDialog(tag: tag),
    );
  }

  void _showDeleteTagDialog(Tag tag) {
    showDialog(
      context: context,
      builder: (context) => DeleteTagDialog(tag: tag),
    );
  }

  void _toggleSelectionMode(String? initialId) {
    setState(() {
      if (_isSelectionMode) {
        _isSelectionMode = false;
        _selectedIds.clear();
      } else {
        _isSelectionMode = true;
        if (initialId != null) {
          _selectedIds.add(initialId);
        }
      }
    });
  }

  void _toggleItemSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final idsToDelete = _selectedIds.toList();
    if (idsToDelete.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Delete ${idsToDelete.length} Tags?'),
        content: const Text(
          'Are you sure you want to delete the selected tags? This will remove them from all contacts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(tagsProvider.notifier).deleteTags(idsToDelete);
      setState(() {
        _isSelectionMode = false;
        _selectedIds.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tags deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(tagsProvider);
    final contacts = ref.watch(contactsProvider);

    // Filter tags
    final filteredTags = tags.where((tag) {
      return tag.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        return ref.refresh(tagsProvider);
      },
      child: Column(
        children: [
          // ===========================
          // TOOLBAR (Search or Actions)
          // ===========================
          if (_isSelectionMode)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: const Color(0xFFFBB03B).withOpacity(0.1),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => _toggleSelectionMode(null),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedIds.length} Selected',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _deleteSelected,
                  ),
                ],
              ),
            )
          else
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search tags...',
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

          if (!_isSelectionMode)
            const SizedBox(height: 24)
          else
            const SizedBox(height: 8),

          // ===========================
          // TABLE HEADERS
          // ===========================
          Row(
            children: [
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Checkbox(
                    value:
                        _selectedIds.isNotEmpty &&
                        _selectedIds.length == filteredTags.length,
                    onChanged: (val) {
                      if (val == true) {
                        setState(() {
                          _selectedIds.addAll(filteredTags.map((t) => t.id));
                        });
                      } else {
                        setState(() {
                          _selectedIds.clear();
                        });
                      }
                    },
                  ),
                ),

              const Expanded(
                flex: 3,
                child: Text(
                  'Tags',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const Expanded(
                flex: 2,
                child: Text(
                  'Contacts',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              if (!_isSelectionMode)
                const Expanded(
                  // Actions column (fixed width or flex)
                  flex: 2,
                  child: SizedBox(), // Empty header for actions
                ),
            ],
          ),
          const Divider(height: 1),

          // ===========================
          // LIST
          // ===========================
          Expanded(
            child: filteredTags.isEmpty
                ? const Center(
                    child: Text(
                      'No tags found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredTags.length,
                    padding: const EdgeInsets.only(top: 16, bottom: 80),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final tag = filteredTags[index];
                      // Calculate usage count
                      final count = contacts
                          .where((c) => c.tags.any((t) => t.id == tag.id))
                          .length;

                      final isSelected = _selectedIds.contains(tag.id);

                      return InkWell(
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleItemSelection(tag.id);
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => TagDetailScreen(
                                  tagName: tag.name,
                                  peopleCount: count,
                                ),
                              ),
                            );
                          }
                        },
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            _toggleSelectionMode(tag.id);
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFBB03B).withOpacity(0.05)
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(
                                    color: const Color(
                                      0xFFFBB03B,
                                    ).withOpacity(0.3),
                                  )
                                : null,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              if (_isSelectionMode)
                                Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: Checkbox(
                                    value: isSelected,
                                    activeColor: const Color(0xFFFBB03B),
                                    onChanged: (val) =>
                                        _toggleItemSelection(tag.id),
                                  ),
                                ),

                              // Tag Name
                              Expanded(
                                flex: 3,
                                child: Text(
                                  tag.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              // Count
                              Expanded(
                                flex: 2,
                                child: Text(
                                  count.toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: count > 0
                                        ? const Color(0xFFFBB03B)
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                              // Actions
                              if (!_isSelectionMode)
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () =>
                                            _showEditTagDialog(tag),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () =>
                                            _showDeleteTagDialog(tag),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
