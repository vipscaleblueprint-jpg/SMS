import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tag.dart';
import '../utils/db/tags_db_helper.dart';

/// Public provider
final tagsProvider = NotifierProvider<TagsNotifier, List<Tag>>(
  TagsNotifier.new,
);

class TagsNotifier extends Notifier<List<Tag>> {
  final _db = TagsDbHelper.instance;

  @override
  List<Tag> build() {
    _loadTags();
    return [];
  }

  Future<void> _loadTags() async {
    final tags = await _db.getAllTags();
    state = tags;
  }

  /// Add a single tag
  Future<void> addTag(Tag tag) async {
    final exists = state.any((t) => t.id == tag.id);
    if (exists) return;

    await _db.insertTag(tag);
    await _loadTags(); // Reload to ensure sync
  }

  /// Add multiple tags
  Future<void> addTags(List<Tag> tags) async {
    for (final tag in tags) {
      // Inefficient but safe for now: check one by one or rely on DB ignore
      await _db.insertTag(tag);
    }
    await _loadTags();
  }

  /// Update an existing tag
  Future<void> updateTag(Tag updated) async {
    await _db.updateTag(updated);
    await _loadTags();
  }

  /// Remove tag by id
  Future<void> removeTag(String tagId) async {
    await _db.deleteTag(tagId);
    await _loadTags();
  }

  /// Remove multiple tags
  Future<void> deleteTags(List<String> ids) async {
    for (final id in ids) {
      await _db.deleteTag(id);
    }
    await _loadTags();
  }

  /// Get tag by id (helper)
  Tag? getById(String id) {
    try {
      return state.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get tag by name (helper)
  Tag? getByName(String name) {
    try {
      return state.firstWhere(
        (t) => t.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Get tag by name or create if it doesn't exist
  Future<Tag> getOrCreateTag(String tagName) async {
    debugPrint('🔵 TagsProvider.getOrCreateTag: Looking for tag "$tagName"');
    debugPrint(
      '🔵 Current tags in state: ${state.map((t) => t.name).toList()}',
    );

    // Check if tag already exists
    final existing = getByName(tagName);
    if (existing != null) {
      debugPrint('✅ Tag "$tagName" already exists with ID: ${existing.id}');
      return existing;
    }

    debugPrint('🔵 Tag "$tagName" not found, creating new tag...');
    // Create new tag
    final newTag = Tag(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: tagName.trim(),
      created: DateTime.now(),
    );

    debugPrint('🔵 Adding new tag to database: ${newTag.name} (${newTag.id})');
    await addTag(newTag);
    debugPrint('✅ Tag created and added successfully: ${newTag.name}');
    return newTag;
  }

  /// Clear all tags
  void clear() {
    state = [];
  }
}
