import 'settings.dart';
import 'template.dart';
import 'dart:convert';

class User {
  final String id;
  final String name;
  final String email;
  final DateTime created;
  final String? access_token;
  final List<String> numbers;
  final Settings settings;
  final List<Template> templates;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.created,
    this.access_token,
    this.numbers = const [],
    required this.settings,
    this.templates = const [],
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    DateTime? created,
    String? access_token,
    List<String>? numbers,
    Settings? settings,
    List<Template>? templates,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      created: created ?? this.created,
      access_token: access_token ?? this.access_token,
      numbers: numbers ?? this.numbers,
      settings: settings ?? this.settings,
      templates: templates ?? this.templates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'created': created.toIso8601String(),
      'access_token': access_token,
      'numbers': numbers,
      'settings': settings.toJson(),
      'templates': templates.map((t) => t.toJson()).toList(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      created: DateTime.parse(json['created'] as String),
      access_token: json['access_token'] as String?,
      numbers:
          (json['numbers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      settings: Settings.fromJson(json['settings'] as Map<String, dynamic>),
      templates:
          (json['templates'] as List<dynamic>?)
              ?.map((t) => Template.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'created': created.toIso8601String(),
      'access_token': access_token,
      'numbers': jsonEncode(numbers),
      'settings': jsonEncode(settings.toJson()),
      'templates': jsonEncode(templates.map((t) => t.toJson()).toList()),
    };
  }

  factory User.fromDbMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      created: DateTime.parse(map['created'] as String),
      access_token: map['access_token'] as String?,
      numbers: (jsonDecode(map['numbers'] as String) as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      settings: Settings.fromJson(jsonDecode(map['settings'] as String)),
      templates: (jsonDecode(map['templates'] as String) as List<dynamic>)
          .map((t) => Template.fromJson(t))
          .toList(),
    );
  }
}
