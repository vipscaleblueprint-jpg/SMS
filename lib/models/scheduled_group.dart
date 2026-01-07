class ScheduledGroup {
  final int? id;
  final String title;
  final bool isActive;

  ScheduledGroup({this.id, required this.title, this.isActive = true});

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'isActive': isActive ? 1 : 0};
  }

  factory ScheduledGroup.fromMap(Map<String, dynamic> map) {
    return ScheduledGroup(
      id: map['id'] as int?,
      title: map['title'] as String,
      isActive: (map['isActive'] as int) == 1,
    );
  }
}
