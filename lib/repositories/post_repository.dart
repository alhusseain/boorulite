import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import '../core/database/database_provider.dart';
import '../models/post.dart';

class PostRepository {
  Future<Database> get _db async => await DatabaseProvider.database;

  Future<void> insertPost(Post post) async {
    debugPrint('DB: Inserting post ${post.id}');
    final db = await _db;
    await db.insert(
      'posts',
      {
        'id': post.id,
        'preview_url': post.previewUrl,
        'file_url': post.fileUrl,
        'tags': post.tags,
        'file_ext': post.fileExt,
        'score':post.score,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Post>> getAllPosts() async {
    final db = await _db;
    debugPrint('DB: Getting all posts');
    final result = await db.query('posts');

    final posts = result.map((row) => Post(
      id: row['id'] as int,
      previewUrl: row['preview_url'] as String,
      fileUrl: row['file_url'] as String,
      tags: row['tags'] as String,
      fileExt: row['file_ext'] as String,
      score: row['score'] as int,
    )).toList();

    debugPrint('DB: Found ${posts.length} posts');
    return posts;
  }

  Future<Post?> getPostById(int id) async {
    final db = await _db;
    debugPrint('DB: Getting post by id $id');
    final result = await db.query(
      'posts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;
    
    debugPrint('DB: Found post with id $id');
    final row = result.first;

    return Post(
      id: row['id'] as int,
      previewUrl: row['preview_url'] as String,
      fileUrl: row['file_url'] as String,
      tags: row['tags'] as String,
      fileExt: row['file_ext'] as String,
      score: row['score'] as int,
    );
  }

  Future<void> deletePost(int id) async {
    final db = await _db;
    debugPrint('DB: Deleting post with id $id');
    await db.delete(
      'posts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllPosts() async {
    final db = await _db;
    debugPrint('DB: Deleting all posts');
    await db.delete(
      'posts',
    );
  }
}
