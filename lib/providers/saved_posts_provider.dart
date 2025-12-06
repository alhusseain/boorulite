import 'package:flutter/foundation.dart';
import '../models/post.dart';
import '../repositories/post_repository.dart';

class SavedPostsProvider extends ChangeNotifier {
  final PostRepository _repository;

  List<Post> _posts = [];
  bool _isLoading = false;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;

  SavedPostsProvider({PostRepository? repository})
      : _repository = repository ?? PostRepository() {
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    _isLoading = true;
    notifyListeners();

    _posts = await _repository.getAllPosts();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> savePost(Post post) async {
    await _repository.insertPost(post);
    _posts.add(post);
    notifyListeners();
  }

  Future<void> deletePost(Post post) async {
    await _repository.deletePost(post.id);
    _posts.removeWhere((p) => p.id == post.id);
    notifyListeners();
  }

  bool isSaved(int postId) {
    return _posts.any((p) => p.id == postId);
  }
}
