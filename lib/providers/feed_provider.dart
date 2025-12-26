import 'package:flutter/foundation.dart';
import '../models/post.dart';
import '../services/booru_api.dart';
import '../providers/block_list_provider.dart';
import '../providers/settings_provider.dart';

/// Manages posts, pagination, and loading states for the main feed.
class FeedProvider extends ChangeNotifier {
  final ApiService _api;
  BlockListProvider? _blockListProvider;
  SettingsProvider? _settingsProvider;

  FeedProvider({ApiService? api})
      : _api = api ?? ApiService();

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

  /// Sets the providers needed for filtering
  void setProviders(BlockListProvider blockListProvider, SettingsProvider settingsProvider) {
    _blockListProvider = blockListProvider;
    _settingsProvider = settingsProvider;
    debugPrint('FeedProvider: Providers set - BlockList: ${blockListProvider.blockList.length} tags, Rating: ${settingsProvider.maturityRating}');
  }

  String get _tagsQuery {
    final List<String> tags = List.from(_searchTags);
    
    // Add blocked tags as negative tags (-tag)
    if (_blockListProvider != null) {
      final blockList = _blockListProvider!.blockList;
      debugPrint('FeedProvider: Block list has ${blockList.length} tags');
      if (blockList.isNotEmpty) {
        for (final blockedTag in blockList) {
          // Ensure tag is not empty before adding
          if (blockedTag.isNotEmpty) {
            tags.add('-$blockedTag');
            debugPrint('FeedProvider: Adding blocked tag: -$blockedTag');
          }
        }
      }
    } else {
      debugPrint('FeedProvider: Warning - BlockListProvider is null');
    }
    
    // Add rating filter
    if (_settingsProvider != null) {
      final rating = _settingsProvider!.maturityRating;
      if (rating == 's') {
        // Safe only
        tags.add('rating:s');
        debugPrint('FeedProvider: Adding rating filter: rating:s');
      } else if (rating == 'q') {
        // Safe + Questionable (exclude explicit)
        tags.add('-rating:e');
        debugPrint('FeedProvider: Adding rating filter: -rating:e');
      } else if (rating.isEmpty) {
        debugPrint('FeedProvider: No rating filter (showing all ratings)');
      }
    } else {
      debugPrint('FeedProvider: Warning - SettingsProvider is null');
    }
    
    final query = tags.join(' ');
    debugPrint('FeedProvider: Final tags query: "$query"');
    return query;
  }

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
      
      // Verify maturity rating filter is working (for testing)
      if (_settingsProvider != null && _posts.isNotEmpty) {
        final rating = _settingsProvider!.maturityRating;
        if (rating == 's') {
          // Verify all posts are safe-rated
          final nonSafePosts = _posts.where((post) => post.rating != 's').toList();
          if (nonSafePosts.isNotEmpty) {
            debugPrint('FeedProvider: WARNING - Found ${nonSafePosts.length} non-safe posts when filter is set to safe only!');
          } else {
            debugPrint('FeedProvider: ✓ Maturity rating filter verified - all ${_posts.length} posts are safe-rated');
          }
        } else if (rating == 'q') {
          // Verify no explicit posts
          final explicitPosts = _posts.where((post) => post.rating == 'e').toList();
          if (explicitPosts.isNotEmpty) {
            debugPrint('FeedProvider: WARNING - Found ${explicitPosts.length} explicit posts when filter excludes explicit!');
          } else {
            debugPrint('FeedProvider: ✓ Maturity rating filter verified - no explicit posts in ${_posts.length} posts');
          }
        }
      }
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
