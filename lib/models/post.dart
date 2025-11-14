
class Post {
  final int id;
  final String previewUrl;
  final String fileUrl;
  final String tags;

  Post({
    required this.id,
    required this.previewUrl,
    required this.fileUrl,
    required this.tags,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      previewUrl: json['preview_url'] as String? ?? '',
      fileUrl: json['file_url'] as String? ?? '',
      tags: json['tags'] as String? ?? '',
    );
  }
}