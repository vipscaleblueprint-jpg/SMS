enum MessageStatus { pending, sending, sent, failed, cancelled }

class QueuedMessage {
  final String id;
  // ignore: non_constant_identifier_names
  final String contact_id;
  // ignore: non_constant_identifier_names
  final String phone_number;
  // ignore: non_constant_identifier_names
  final String? sender_number;
  final String message;
  final MessageStatus status;
  // ignore: non_constant_identifier_names
  final DateTime created_at;
  // ignore: non_constant_identifier_names
  final DateTime? scheduled_time;
  // ignore: non_constant_identifier_names
  final DateTime? sent_time;
  // ignore: non_constant_identifier_names
  final String? error_message;
  // ignore: non_constant_identifier_names
  final int retry_count;
  final bool isSent;

  QueuedMessage({
    required this.id,
    required this.contact_id,
    required this.phone_number,
    this.sender_number,
    required this.message,
    this.status = MessageStatus.pending,
    required this.created_at,
    this.scheduled_time,
    this.sent_time,
    this.error_message,
    this.retry_count = 0,
    this.isSent = false,
  });

  // CopyWith
  QueuedMessage copyWith({
    String? id,
    String? contact_id,
    String? phone_number,
    String? sender_number,
    String? message,
    MessageStatus? status,
    DateTime? created_at,
    DateTime? scheduled_time,
    DateTime? sent_time,
    String? error_message,
    int? retry_count,
    bool? isSent,
  }) {
    return QueuedMessage(
      id: id ?? this.id,
      contact_id: contact_id ?? this.contact_id,
      phone_number: phone_number ?? this.phone_number,
      sender_number: sender_number ?? this.sender_number,
      message: message ?? this.message,
      status: status ?? this.status,
      created_at: created_at ?? this.created_at,
      scheduled_time: scheduled_time ?? this.scheduled_time,
      sent_time: sent_time ?? this.sent_time,
      error_message: error_message ?? this.error_message,
      retry_count: retry_count ?? this.retry_count,
      isSent: isSent ?? this.isSent,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contact_id': contact_id,
      'phone_number': phone_number,
      'sender_number': sender_number,
      'message': message,
      'status': status.name,
      'created_at': created_at.toIso8601String(),
      'scheduled_time': scheduled_time?.toIso8601String(),
      'sent_time': sent_time?.toIso8601String(),
      'error_message': error_message,
      'retry_count': retry_count,
      'isSent': isSent,
    };
  }

  // From JSON
  factory QueuedMessage.fromJson(Map<String, dynamic> json) {
    return QueuedMessage(
      id: json['id'] as String,
      contact_id: json['contact_id'] as String,
      phone_number: json['phone_number'] as String,
      sender_number: json['sender_number'] as String?,
      message: json['message'] as String,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.pending,
      ),
      created_at: DateTime.parse(json['created_at'] as String),
      scheduled_time: json['scheduled_time'] != null
          ? DateTime.tryParse(json['scheduled_time'] as String)
          : null,
      sent_time: json['sent_time'] != null
          ? DateTime.tryParse(json['sent_time'] as String)
          : null,
      error_message: json['error_message'] as String?,
      retry_count: json['retry_count'] as int? ?? 0,
      isSent: json['isSent'] as bool? ?? false,
    );
  }
}
