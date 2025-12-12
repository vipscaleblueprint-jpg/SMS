class Template {
  final String id;
  final String title;
  final String content;
  // ignore: non_constant_identifier_names
  final DateTime created_at;
  // ignore: non_constant_identifier_names
  final DateTime last_used;

  Template({
    required this.id,
    required this.title,
    required this.content,
    required this.created_at,
    required this.last_used,
  });

  Template copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? created_at,
    DateTime? last_used,
  }) {
    return Template(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      created_at: created_at ?? this.created_at,
      last_used: last_used ?? this.last_used,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': created_at.toIso8601String(),
      'last_used': last_used.toIso8601String(),
    };
  }

  factory Template.fromJson(Map<String, dynamic> json) {
    return Template(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      created_at: DateTime.parse(json['created_at'] as String),
      last_used: DateTime.parse(json['last_used'] as String),
    );
  }
}
