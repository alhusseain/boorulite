import 'package:flutter/foundation.dart';
import '../models/post.dart';
import '../services/booru_api.dart';

/// Manages posts, pagination, and loading states for the main feed.
class FeedProvider extends ChangeNotifier {
  final ApiService _api;
  
  FeedProvider({ApiService? api}) : _api = api ?? ApiService();

  List<Post> _posts = [];
  int _currentPage = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  List<String> _searchTags = [];

  List<Post> get posts => List.unmodifiable(_posts);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasPosts => _posts.isNotEmpty;
  List<String> get searchTags => List.unmodifiable(_searchTags);
  bool get hasSearchTags => _searchTags.isNotEmpty;

  String get _tagsQuery => _searchTags.join(' ');

  Future<void> fetchPosts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _currentPage = 1;
      _posts = await _api.fetchPosts(
        page: _currentPage,
        tags: _tagsQuery,
        random: !hasSearchTags,
      );
      _error = null;
    } catch (e) {
      _error = 'Failed to load posts: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMorePosts() async {
    if (_isLoadingMore) return;
    
    _isLoadingMore = true;
    notifyListeners();
    
    try {
      _currentPage++;
      final newPosts = await _api.fetchPosts(
        page: _currentPage,
        tags: _tagsQuery,
        random: !hasSearchTags,
      );
      _posts = [..._posts, ...newPosts];
    } catch (e) {
      _currentPage--;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void setSearchTags(List<String> tags) {
    _searchTags = tags;
    fetchPosts();
  }

  void clearSearch() {
    _searchTags = [];
    fetchPosts();
  }

  void reset() {
    _posts = [];
    _currentPage = 1;
    _isLoading = true;
    _isLoadingMore = false;
    _error = null;
    _searchTags = [];
    notifyListeners();
  }
}
