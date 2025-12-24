
class Post {
  final int id;
  final String previewUrl;
  final String fileUrl;
  final List<String> tags;
  final String fileExt;
  final int score;
  final String source;
  final String rating;

  Post({
    required this.id,
    required this.previewUrl,
    required this.fileUrl,
    required this.tags,
    required this.fileExt,
    required this.score,
    required this.source,
    required this.rating,
  });

  bool get isVideo => fileExt == 'mp4' || fileExt == 'webm';

  factory Post.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'] as String? ?? '';
    final tagList = rawTags.split(' ').where((t) => t.isNotEmpty).take(5).toList();
    
    return Post(
      id: json['id'] as int,
      previewUrl: json['preview_url'] as String? ?? '',
      fileUrl: json['file_url'] as String? ?? '',
      tags: tagList,
      fileExt: json['file_ext'] as String? ?? '',
      score: json['score'] as int,
      source: json['source'] as String? ?? 'Unknown',
      rating: json['rating'] as String? ?? 's',
    );
  }
}