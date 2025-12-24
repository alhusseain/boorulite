import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post.dart';
import '../models/tag.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String _baseUrl = 'https://www.sakugabooru.com';

  Future<List<Tag>> fetchTags({String namePattern = '', int limit = 25}) async {
    final uri = Uri.parse('$_baseUrl/tag.json').replace(queryParameters: {
      'limit': limit.toString(),
      'order': 'count',
      if (namePattern.isNotEmpty) 'name': '$namePattern*',
    });
    debugPrint('Final URI = $uri');
    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Tag.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load tags: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching tags: $e');
      rethrow;
    }
  }

  Future<List<Post>> fetchPosts({int limit = 10, int page = 1, String tags = '', bool random = true}) async {
    String effectiveTags = tags;
    if (random && !tags.contains('order:')) {
      effectiveTags = tags.isEmpty ? 'order:random' : '$tags order:random';
    }

    final uri = Uri.parse('$_baseUrl/post.json').replace(queryParameters: {
      'limit': limit.toString(),
      'page': page.toString(),
      if (effectiveTags.isNotEmpty) 'tags': effectiveTags,
    });

    print('Fetching posts from: $uri');

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