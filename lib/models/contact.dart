import 'tag.dart';

class Contact {
  final String contact_id;
  final String first_name;
  final String last_name;
  final String? email;
  final String phone;
  final DateTime created;
  final List<Tag> tags;

  Contact({
    required this.contact_id,
    required this.first_name,
    required this.last_name,
    this.email,
    required this.phone,
    required this.created,
    this.tags = const [],
  });

  String get name => '$first_name $last_name'.trim();

  // CopyWith
  Contact copyWith({
    String? contact_id,
    String? first_name,
    String? last_name,
    String? email,
    String? phone,
    DateTime? created,
    List<Tag>? tags,
  }) {
    return Contact(
      contact_id: contact_id ?? this.contact_id,
      first_name: first_name ?? this.first_name,
      last_name: last_name ?? this.last_name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      created: created ?? this.created,
      tags: tags ?? this.tags,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'contact_id': contact_id,
      'first_name': first_name,
      'last_name': last_name,
      'name': name,
      'email': email,
      'phone': phone,
      'created': created.toIso8601String(),
      'tags': tags.map((t) => t.toJson()).toList(),
    };
  }

  // From JSON
  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      contact_id: json['contact_id'] as String,
      first_name: json['first_name'] as String? ?? '',
      last_name: json['last_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String? ?? '',
      created: json['created'] != null
          ? DateTime.tryParse(json['created'] as String) ?? DateTime.now()
          : DateTime.now(),
      tags:
          (json['tags'] as List<dynamic>?)
              ?.map((t) => Tag.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  String toString() {
    return 'Contact(id: $contact_id, name: $name, phone: $phone)';
  }
}
