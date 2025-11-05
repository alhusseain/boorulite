import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post.dart';
// this entire file is placeholder, its an example i found off of the internet and its only here so we have a template to build upon
class ApiService {
  static const String _baseUrl = 'https://www.sakugabooru.com/post.json';

  Future<List<Post>> fetchPosts({int limit = 10, int page = 1, String tags = ''}) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'limit': limit.toString(),
      'page': page.toString(),
      if (tags.isNotEmpty) 'tags': tags,
    });

    print('Fetching: $uri');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);

        List<Post> posts = body.map((dynamic item) => Post.fromJson(item)).toList();

        return posts;
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching posts: $e');
      rethrow;
    }
  }
}