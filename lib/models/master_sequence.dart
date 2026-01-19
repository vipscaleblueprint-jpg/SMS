class MasterSequence {
  final int? id;
  final String title;
  final String tagId;
  final bool isActive;

  MasterSequence({
    this.id,
    required this.title,
    required this.tagId,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'tag_id': tagId,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory MasterSequence.fromMap(Map<String, dynamic> map) {
    return MasterSequence(
      id: map['id'] as int?,
      title: map['title'] as String,
      tagId: map['tag_id'] as String,
      isActive: (map['is_active'] as int) == 1,
    );
  }
}

class SequenceMessage {
  final int? id;
  final int sequenceId;
  final String title;
  final String message;
  final int delayDays; // 0 means immediate, 1 means next day, etc.

  SequenceMessage({
    this.id,
    required this.sequenceId,
    required this.title,
    required this.message,
    required this.delayDays,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sequence_id': sequenceId,
      'title': title,
      'message': message,
      'delay_days': delayDays,
    };
  }

  factory SequenceMessage.fromMap(Map<String, dynamic> map) {
    return SequenceMessage(
      id: map['id'] as int?,
      sequenceId: map['sequence_id'] as int,
      title: map['title'] as String,
      message: map['message'] as String,
      delayDays: map['delay_days'] as int,
    );
  }
}

class SequenceSubscription {
  final int? id;
  final String contactId;
  final int sequenceId;
  final DateTime subscribedAt;

  SequenceSubscription({
    this.id,
    required this.contactId,
    required this.sequenceId,
    required this.subscribedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contact_id': contactId,
      'sequence_id': sequenceId,
      'subscribed_at': subscribedAt.toIso8601String(),
    };
  }

  factory SequenceSubscription.fromMap(Map<String, dynamic> map) {
    return SequenceSubscription(
      id: map['id'] as int?,
      contactId: map['contact_id'] as String,
      sequenceId: map['sequence_id'] as int,
      subscribedAt: DateTime.parse(map['subscribed_at'] as String),
    );
  }
}
