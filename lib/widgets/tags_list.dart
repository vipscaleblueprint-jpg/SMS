import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tags_provider.dart';
import '../providers/contacts_provider.dart';
import '../models/tag.dart';
import 'modals/edit_tag_dialog.dart';
import 'modals/delete_tag_dialog.dart';

class TagsList extends ConsumerStatefulWidget {
  const TagsList({super.key});

  @override
  ConsumerState<TagsList> createState() => _TagsListState();
}

class _TagsListState extends ConsumerState<TagsList> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
          // SEARCH BAR
          // ===========================
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
          const SizedBox(height: 24),

          // ===========================
          // TABLE HEADERS
          // ===========================
          // ===========================
          // TABLE HEADERS
          // ===========================
          const Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Tags',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Contacts',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
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

                      return Row(
                        children: [
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
                                  onPressed: () => _showEditTagDialog(tag),
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
                                  onPressed: () => _showDeleteTagDialog(tag),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
