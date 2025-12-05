class Tag {
  final int id;
  final String name;
  final int count;

  Tag({
    required this.id,
    required this.name,
    required this.count,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }
}
