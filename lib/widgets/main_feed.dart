import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../models/post.dart';
import '../providers/feed_provider.dart';
import '../services/video_controller_service.dart';
import 'tag_search_widget.dart';
import 'tag_selection_overlay.dart';

class MainFeedWidget extends StatefulWidget {
  const MainFeedWidget({super.key});

  @override
  State<MainFeedWidget> createState() => MainFeedWidgetState();
}

class MainFeedWidgetState extends State<MainFeedWidget> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _initialVideoLoaded = false;
  bool _showTagOverlay = false;
  bool _showSearchOverlay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupVideoService();
      context.read<FeedProvider>().fetchPosts();
    });
  }

  void _setupVideoService() {
    final videoService = context.read<VideoControllerService>();
    final feedProvider = context.read<FeedProvider>();
    
    videoService.setBatchCallbacks(
      getUrlsBatch: (startIndex, count) {
        final posts = feedProvider.posts;
        final urls = <String>[];
        for (int i = startIndex; i < startIndex + count && i < posts.length; i++) {
          urls.add(posts[i].isVideo ? posts[i].fileUrl : '');
        }
        return urls;
      },
      getCount: () => feedProvider.posts.length,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final videoService = context.read<VideoControllerService>();
    if (state == AppLifecycleState.paused) {
      videoService.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      videoService.onAppResumed();
    }
  }

  void pauseVideo() => context.read<VideoControllerService>().onBecameHidden();
  void resumeVideo() => context.read<VideoControllerService>().onBecameVisible();

  void _showTagSelection() {
    context.read<VideoControllerService>().pause();
    setState(() => _showTagOverlay = true);
  }

  void _hideTagSelection() {
    setState(() => _showTagOverlay = false);
    context.read<VideoControllerService>().play();
  }

  void _showSearch() {
    context.read<VideoControllerService>().pause();
    setState(() => _showSearchOverlay = true);
  }

  void _hideSearch() {
    setState(() => _showSearchOverlay = false);
    context.read<VideoControllerService>().play();
  }

  void _onSearchTags(List<String> tags) {
    final feedProvider = context.read<FeedProvider>();
    if (tags.isEmpty) {
      feedProvider.clearSearch();
    } else {
      feedProvider.setSearchTags(tags);
    }
    _currentIndex = 0;
    _initialVideoLoaded = false;
    _hideSearch();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onTagsConfirmed(List<String> selectedTags) {
    if (selectedTags.isNotEmpty) {
      // later 
      _showSnackBar('Tags blocked!');
    }
  }

  void _onFavorite() {
    // later 
    _showSnackBar('Favorited <3');
  }

  void _onHorizontalSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 300) {
      _onFavorite();
    } else if (velocity < -300) {
      _showTagSelection();
    }
  }

  void _onPageChanged(int index, FeedProvider feedProvider, VideoControllerService videoService) {
    _currentIndex = index;
    
    final post = feedProvider.posts[index];
    if (post.isVideo) {
      videoService.initializeVideo(index, post.fileUrl);
    } else {
      videoService.disposeVideo();
    }

    if (index >= feedProvider.posts.length - 3) {
      feedProvider.loadMorePosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final feedProvider = context.watch<FeedProvider>();
    final videoService = context.watch<VideoControllerService>();

    if (feedProvider.isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
      );
    }

    if (feedProvider.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 50, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(feedProvider.error!, style: TextStyle(color: colorScheme.onSurface), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: feedProvider.fetchPosts, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (!feedProvider.hasPosts) {
      return Scaffold(
        body: Center(child: Text('No posts found', style: TextStyle(color: colorScheme.onSurface))),
      );
    }

    if (!_initialVideoLoaded && feedProvider.hasPosts) {
      _initialVideoLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final firstPost = feedProvider.posts[0];
        if (firstPost.isVideo) {
          videoService.initializeVideo(0, firstPost.fileUrl);
        }
      });
    }

    final currentPost = feedProvider.posts[_currentIndex];
    
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: feedProvider.posts.length,
            onPageChanged: (index) => _onPageChanged(index, feedProvider, videoService),
            itemBuilder: (context, index) {
              final post = feedProvider.posts[index];
              return _buildPostItem(post, index, colorScheme, videoService);
            },
          ),
          Positioned(top: 0, left: 0, right: 0, child: _buildSearchBar(colorScheme, feedProvider)),
          if (_showTagOverlay)
            TagSelectionOverlay(
              tags: currentPost.tags,
              onClose: _hideTagSelection,
              onConfirm: _onTagsConfirmed,
            ),
          if (_showSearchOverlay)
            TagSearchWidget(
              onClose: _hideSearch,
              onSearch: _onSearchTags,
              initialTags: feedProvider.searchTags,
            ),
        ],
      ),
    );
  }

  Widget _buildPostItem(Post post, int index, ColorScheme colorScheme, VideoControllerService videoService) {
    return GestureDetector(
      onHorizontalDragEnd: _onHorizontalSwipe,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: colorScheme.surface,
            child: Center(child: _buildMediaContent(post, index, colorScheme, videoService)),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black38],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent(Post post, int index, ColorScheme colorScheme, VideoControllerService videoService) {
    if (post.isVideo) {
      return _buildVideoPlayer(post, index, colorScheme, videoService);
    }
    return _buildImage(post, colorScheme);
  }

  Widget _buildVideoPlayer(Post post, int index, ColorScheme colorScheme, VideoControllerService videoService) {
    final isCurrentVideo = videoService.currentIndex == index;
    final controller = videoService.controller;
    
    if (isCurrentVideo && controller != null && videoService.isInitialized) {
      final showLoading = videoService.isBuffering || videoService.isWaitingForBuffer;
      
      return GestureDetector(
        onTap: videoService.togglePlayPause,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(aspectRatio: videoService.aspectRatio, child: VideoPlayer(controller)),
            if (showLoading) CircularProgressIndicator(color: colorScheme.primary),
            if (!showLoading)
              AnimatedOpacity(
                opacity: videoService.isPlaying ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.black.withAlpha(120), shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 50),
                ),
              ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: colorScheme.primary,
                  bufferedColor: colorScheme.primary.withAlpha(100),
                  backgroundColor: Colors.white.withAlpha(50),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              ),
            ),
          ],
        ),
      );
    }
    
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.network(
          post.previewUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 50, color: colorScheme.onSurface),
        ),
        CircularProgressIndicator(color: colorScheme.primary),
      ],
    );
  }

  Widget _buildImage(Post post, ColorScheme colorScheme) {
    return Image.network(
      post.fileUrl.isNotEmpty ? post.fileUrl : post.previewUrl,
      fit: BoxFit.contain,
      loadingBuilder: (_, child, progress) => progress == null ? child : CircularProgressIndicator(color: colorScheme.primary),
      errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 50, color: colorScheme.onSurface),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme, FeedProvider feedProvider) {
    final hasSearch = feedProvider.hasSearchTags;
    final searchText = hasSearch ? feedProvider.searchTags.join(', ') : 'Search';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GestureDetector(
          onTap: _showSearch,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface.withAlpha(170),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: colorScheme.onSurface.withAlpha(hasSearch ? 255 : 150)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    searchText,
                    style: TextStyle(
                      color: colorScheme.onSurface.withAlpha(hasSearch ? 255 : 150),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasSearch)
                  GestureDetector(
                    onTap: () {
                      feedProvider.clearSearch();
                      _currentIndex = 0;
                      _initialVideoLoaded = false;
                    },
                    child: Icon(Icons.close, color: colorScheme.onSurface, size: 20),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
