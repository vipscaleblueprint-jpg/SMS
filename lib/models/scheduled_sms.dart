class ScheduledSms {
  final int? id;
  final int groupId;
  final String title;
  final String frequency;
  final int? scheduledDay; // Day of month (1-31)
  final String message;
  final bool isActive;
  final String status; // 'draft', 'pending', 'sent'
  final DateTime? scheduledTime;

  ScheduledSms({
    this.id,
    required this.groupId,
    required this.title,
    required this.frequency,
    this.scheduledDay,
    required this.message,
    this.isActive = true,
    this.status = 'pending',
    this.scheduledTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'title': title,
      'frequency': frequency,
      'scheduled_day': scheduledDay,
      'message': message,
      'is_active': isActive ? 1 : 0,
      'status': status,
      'scheduled_time': scheduledTime?.toIso8601String(),
    };
  }

  factory ScheduledSms.fromMap(Map<String, dynamic> map) {
    return ScheduledSms(
      id: map['id'] as int?,
      groupId: map['group_id'] as int,
      title: map['title'] as String,
      frequency: map['frequency'] as String,
      scheduledDay: map['scheduled_day'] as int?,
      message: map['message'] as String,
      isActive: (map['is_active'] as int) == 1,
      status: map['status'] as String? ?? 'pending',
      scheduledTime: map['scheduled_time'] != null
          ? DateTime.parse(map['scheduled_time'] as String)
          : null,
    );
  }
}
