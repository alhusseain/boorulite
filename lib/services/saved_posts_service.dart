import '../repositories/post_repository.dart';
import '../models/post.dart';

class SavedPostService {
  final PostRepository _repository = PostRepository();

  Future<void> savePost(Post post) async {
    await _repository.insertPost(post);
  }

  Future<List<Post>> getAllSavedPosts() async {
    return await _repository.getAllPosts();
  }

  Future<Post?> getPost(int id) async {
    return await _repository.getPostById(id);
  }

  Future<void> deletePost(int id) async {
    await _repository.deletePost(id);
  }
}
