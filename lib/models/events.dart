enum EventStatus { draft, activate }

class Event {
  final int? id;
  final String name;
  final DateTime date;
  final EventStatus status;
  final String? recipients;

  Event({
    this.id,
    required this.name,
    required this.date,
    required this.status,
    this.recipients,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'status': status.name,
      'recipients': recipients,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] as int?,
      name: map['name'] as String,
      date: DateTime.parse(map['date'] as String),
      status: EventStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => EventStatus.draft,
      ),
      recipients: map['recipients'] as String?,
    );
  }
}
