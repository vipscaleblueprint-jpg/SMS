class Tag {
  final String id;
  final String name;
  final String? color; // Optional: for UI display
  final DateTime? created;

  Tag({required this.id, required this.name, this.color, this.created});

  // CopyWith
  Tag copyWith({String? id, String? name, String? color, DateTime? created}) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      created: created ?? this.created,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'created': created?.toIso8601String(),
    };
  }

  // From JSON
  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String?,
      created: json['created'] != null
          ? DateTime.tryParse(json['created'] as String)
          : null,
    );
  }

  @override
  String toString() => 'Tag(id: $id, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
