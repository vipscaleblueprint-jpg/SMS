class Sms {
  final int? id;
  final String message;
  final String? contact_id;
  final String? phone_number;
  final String? sender_number;
  final bool isSent;
  final DateTime? sentTimeStamps;
  final DateTime? schedule_time;
  final int? event_id;

  Sms({
    this.id,
    required this.message,
    this.contact_id,
    this.phone_number,
    this.sender_number,
    this.isSent = false,
    this.sentTimeStamps,
    this.schedule_time,
    this.event_id,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'contact_id': contact_id,
      'phone_number': phone_number,
      'sender_number': sender_number,
      'isSent': isSent ? 1 : 0,
      'sentTimeStamps': sentTimeStamps?.toIso8601String(),
      'schedule_time': schedule_time?.toIso8601String(),
      'event_id': event_id,
    };
  }

  factory Sms.fromMap(Map<String, dynamic> map) {
    return Sms(
      id: map['id'] as int?,
      message: map['message'] as String,
      contact_id: map['contact_id'] as String?,
      phone_number: map['phone_number'] as String?,
      sender_number: map['sender_number'] as String?,
      isSent: (map['isSent'] as int) == 1,
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
