enum SmsStatus {
  draft,
  pending,
  sent,
  failed, // Optional but good practice
}

class Sms {
  final int? id;
  final String? title;
  final String message;
  final String? contact_id;
  final String? phone_number;
  final String? sender_number;
  final SmsStatus status;
  final DateTime? sentTimeStamps;
  final DateTime? schedule_time;
  final int? event_id;

  Sms({
    this.id,
    this.title,
    required this.message,
    this.contact_id,
    this.phone_number,
    this.sender_number,
    this.status = SmsStatus.draft,
    this.sentTimeStamps,
    this.schedule_time,
    this.event_id,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'contact_id': contact_id,
      'phone_number': phone_number,
      'sender_number': sender_number,
      'status': status.name, // Storing as string in DB
      'sentTimeStamps': sentTimeStamps?.toIso8601String(),
      'schedule_time': schedule_time?.toIso8601String(),
      'event_id': event_id,
    };
  }

  factory Sms.fromMap(Map<String, dynamic> map) {
    // Handle migration from legacy isSent (int/bool) if necessary,
    // or just default to draft if status is missing/invalid.
    // For now assuming we recreate DB, so status is always present.
    // But helpful to be robust.

    SmsStatus status = SmsStatus.draft;
    if (map['status'] != null) {
      try {
        status = SmsStatus.values.byName(map['status']);
      } catch (e) {
        // fallback or handle integer status if we used that
      }
    } else if (map.containsKey('isSent')) {
      // Backward compatibility for existing rows before migration if we didn't wipe
      // final isSent = (map['isSent'] as int) == 1; // Unused variable
      final isSent = (map['isSent'] as int) == 1; // Keeping logic
      status = isSent ? SmsStatus.sent : SmsStatus.pending;
    }

    return Sms(
      id: map['id'] as int?,
      title: map['title'] as String?,
      message: map['message'] as String,
      contact_id: map['contact_id'] as String?,
      phone_number: map['phone_number'] as String?,
      sender_number: map['sender_number'] as String?,
      status: status,
      sentTimeStamps: map['sentTimeStamps'] != null
          ? DateTime.parse(map['sentTimeStamps'] as String)
          : null,
      schedule_time: map['schedule_time'] != null
          ? DateTime.parse(map['schedule_time'] as String)
          : null,
      event_id: map['event_id'] as int?,
    );
  }
}
