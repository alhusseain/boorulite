
class Post {
  final int id;
  final String previewUrl;
  final String fileUrl;
  final String tags;
  final String fileExt;
  final int score;

  Post({
    required this.id,
    required this.previewUrl,
    required this.fileUrl,
    required this.tags,
    required this.fileExt,
    required this.score,
  });

  bool get isVideo => fileExt == 'mp4' || fileExt == 'webm';

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      previewUrl: json['preview_url'] as String? ?? '',
      fileUrl: json['file_url'] as String? ?? '',
      tags: json['tags'] as String? ?? '',
      fileExt: json['file_ext'] as String? ?? '',
      score: json['score'] as int,
    );
  }
}