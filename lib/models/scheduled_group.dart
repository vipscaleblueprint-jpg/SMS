class ScheduledGroup {
  final int? id;
  final String title;
  final bool isActive;
  final Set<String> contactIds;
  final Set<String> tagIds;

  ScheduledGroup({
    this.id,
    required this.title,
    this.isActive = true,
    this.contactIds = const {},
    this.tagIds = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'is_active': isActive ? 1 : 0,
      'contact_ids': contactIds.isNotEmpty
          ? contactIds.toList().join(',')
          : null,
      'tag_ids': tagIds.isNotEmpty ? tagIds.toList().join(',') : null,
    };
  }

  factory ScheduledGroup.fromMap(Map<String, dynamic> map) {
    return ScheduledGroup(
      id: map['id'] as int?,
      title: map['title'] as String,
      isActive: (map['is_active'] as int) == 1,
      contactIds: map['contact_ids'] != null
          ? (map['contact_ids'] as String).split(',').toSet()
          : {},
      tagIds: map['tag_ids'] != null
          ? (map['tag_ids'] as String).split(',').toSet()
          : {},
    );
  }
}
