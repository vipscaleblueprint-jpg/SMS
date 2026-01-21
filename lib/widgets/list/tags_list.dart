import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/tags_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../models/tag.dart';
import '../modals/edit_tag_dialog.dart';
import '../modals/delete_tag_dialog.dart';
import '../../screens/home/tag_detail_screen.dart';

class TagsList extends ConsumerStatefulWidget {
  final String searchQuery;
  const TagsList({super.key, this.searchQuery = ''});

  @override
  ConsumerState<TagsList> createState() => _TagsListState();
}

class _TagsListState extends ConsumerState<TagsList> {
  // Removed internal _searchController as it's now managed by parent

  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  // Dispose removed since _searchController is gone

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
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: Colors.white,
        child: SizedBox(
          width: 270,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      'Delete ${idsToDelete.length} Tags?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Are you sure you want to delete the selected tags? This will remove them from all contacts and cannot be undone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        height: 1.3,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0.5, thickness: 0.5, color: Colors.grey),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx, false),
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
                      onTap: () => Navigator.pop(ctx, true),
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
      return tag.name.toLowerCase().contains(widget.searchQuery.toLowerCase());
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        return ref.refresh(tagsProvider);
      },
      child: Column(
        children: [
          // Search Bar Area
          if (_isSelectionMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFBB03B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => _toggleSelectionMode(null),
                  ),
                  Expanded(
                    child: Text(
                      '${_selectedIds.length} Selected',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _deleteSelected,
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Removed internal TextField here, now managed by parent

          // Tags List
          Expanded(
            child: filteredTags.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.label_rounded,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No tags found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredTags.length,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      indent: 48,
                      color: Colors.grey.shade100,
                    ),

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
                                builder: (context) => TagDetailScreen(tag: tag),
                              ),
                            );
                          }
                        },
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            _toggleSelectionMode(tag.id);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              if (_isSelectionMode)
                                Padding(
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: Checkbox(
                                    value: isSelected,
                                    activeColor: const Color(0xFFFBB03B),
                                    shape: const CircleBorder(),
                                    onChanged: (val) =>
                                        _toggleItemSelection(tag.id),
                                  ),
                                ),

                              // Icon
                              Icon(
                                Icons.label_rounded,
                                color: const Color(0xFFFBB03B).withOpacity(0.5),
                                size: 24,
                              ),
                              const SizedBox(width: 16),

                              // Tag Name
                              Expanded(
                                child: Text(
                                  tag.name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ),

                              // Count & Actions
                              if (!_isSelectionMode) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFBB03B,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFFBB03B),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_note_rounded,
                                    color: Colors.blue.shade300,
                                    size: 22,
                                  ),
                                  onPressed: () => _showEditTagDialog(tag),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  icon: Icon(
                                    Icons.remove_circle_outline_rounded,
                                    color: Colors.red.shade300,
                                    size: 22,
                                  ),
                                  onPressed: () => _showDeleteTagDialog(tag),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.grey.shade300,
                                  size: 20,
                                ),
                              ],
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
