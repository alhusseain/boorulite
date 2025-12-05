import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/post.dart';
import '../services/booru_api.dart';

class MainFeedWidget extends StatefulWidget {
  const MainFeedWidget({super.key});

  @override
  State<MainFeedWidget> createState() => _MainFeedWidgetState();
}

class _MainFeedWidgetState extends State<MainFeedWidget> {
  double _iconOpacity = 1.0;
  final ApiService _apiService = ApiService();
  List<Post> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  
  VideoPlayerController? _currentVideoController;
  int? _currentVideoIndex;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  @override
  void dispose() {
    _disposeCurrentVideo();
    super.dispose();
  }

  void _disposeCurrentVideo() {
    _currentVideoController?.pause();
    _currentVideoController?.dispose();
    _currentVideoController = null;
    _currentVideoIndex = null;
  }

  Future<void> _initializeVideo(int index) async {
    if (index < 0 || index >= _posts.length) return;
    final post = _posts[index];
    if (!post.isVideo) return;
    
    if (_currentVideoIndex == index && _currentVideoController != null) {
      if (_currentVideoController!.value.isInitialized) {
        _currentVideoController!.play();
      }
      return;
    }

    _disposeCurrentVideo();

    final videoController = VideoPlayerController.networkUrl(
      Uri.parse(post.fileUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    
    _currentVideoController = videoController;
    _currentVideoIndex = index;

    videoController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });

    try {
      await videoController.initialize();
      videoController.setLooping(true);
      if (index == _currentIndex && mounted) {
        videoController.play();
      }

      if (mounted) setState(() {});
    } catch (e) {
      _disposeCurrentVideo();
    }
  }

  void _togglePlayPause() {
    final controller = _currentVideoController;
    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    setState(() {});
  }

  void _onPageChanged(int index) {
    _currentVideoController?.pause();
    
    _currentIndex = index;
    final post = _posts[index];
    if (post.isVideo) {
      _initializeVideo(index);
    } else {
      _disposeCurrentVideo();
    }

    setState(() {
      _iconOpacity = 0.0;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _iconOpacity = 1.0;
        });
      }
    });

    if (index >= _posts.length - 3) {
      _loadMorePosts();
    }
  }

  Future<void> _fetchPosts() async {
    try {
      final posts = await _apiService.fetchPosts(page: _currentPage);
      setState(() {
        _posts = posts;
        _isLoading = false;
        _errorMessage = null;
      });
      if (_posts.isNotEmpty && _posts[0].isVideo) {
        _initializeVideo(0);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load posts: $e';
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    try {
      _currentPage++;
      final newPosts = await _apiService.fetchPosts(page: _currentPage);
      setState(() {
        _posts.addAll(newPosts);
        _isLoadingMore = false;
      });
    } catch (e) {
      _currentPage--;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Widget _buildMediaContent(Post post, int index, ColorScheme colorScheme) {
    if (post.isVideo) {
      final controller = _currentVideoController;
      final isCurrentVideo = _currentVideoIndex == index;
      
      if (isCurrentVideo && controller != null && controller.value.isInitialized) {
        return GestureDetector(
          onTap: () => _togglePlayPause(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
              if (controller.value.isBuffering)
                CircularProgressIndicator(color: colorScheme.primary),
              if (!controller.value.isBuffering)
                AnimatedOpacity(
                  opacity: controller.value.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(120),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoProgressIndicator(
                  controller,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: colorScheme.primary,
                    bufferedColor: colorScheme.primary.withAlpha(100),
                    backgroundColor: Colors.white.withAlpha(50),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        return Stack(
          alignment: Alignment.center,
          children: [
            Image.network(
              post.previewUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.broken_image,
                size: 50,
                color: colorScheme.onSurface,
              ),
            ),
            CircularProgressIndicator(color: colorScheme.primary),
          ],
        );
      }
    } else {
      return Image.network(
        post.fileUrl.isNotEmpty ? post.fileUrl : post.previewUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return CircularProgressIndicator(color: colorScheme.primary);
        },
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.broken_image, size: 50, color: colorScheme.onSurface),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 50, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _fetchPosts();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(
            'No posts found',
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          NotificationListener(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                setState(() {
                  _iconOpacity = 0.0;
                });
              } else if (notification is ScrollEndNotification) {
                setState(() {
                  _iconOpacity = 1.0;
                });
              }
              return false;
            },
            child: PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: _posts.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: colorScheme.surface,
                      child: Center(
                        child: _buildMediaContent(post, index, colorScheme),
                      ),
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
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.5,
                      right: 20,
                      child: SafeArea(
                        child: AnimatedOpacity(
                          opacity: _iconOpacity,
                          duration: const Duration(milliseconds: 300),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.surface.withAlpha(170),
                                  border: Border.all(
                                    color: colorScheme.outline.withAlpha(100),
                                    width: 1,
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: () {},
                                  icon: Icon(
                                    Icons.favorite_border_outlined,
                                    color: colorScheme.onSurface,
                                    size: 24,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.surface.withAlpha(170),
                                  border: Border.all(
                                    color: colorScheme.outline.withAlpha(100),
                                    width: 1,
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: () {},
                                  icon: Icon(
                                    Icons.thumb_down_alt_outlined,
                                    color: colorScheme.onSurface,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: Icon(
                      Icons.search,
                      color: colorScheme.onSurface.withAlpha(255),
                    ),
                    filled: true,
                    fillColor: colorScheme.surface.withAlpha(170),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
