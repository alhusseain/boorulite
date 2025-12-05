import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../models/post.dart';
import '../providers/feed_provider.dart';
import '../services/video_controller_service.dart';

class MainFeedWidget extends StatefulWidget {
  const MainFeedWidget({super.key});

  @override
  State<MainFeedWidget> createState() => MainFeedWidgetState();
}

class MainFeedWidgetState extends State<MainFeedWidget> with WidgetsBindingObserver {
  int _currentIndex = 0;
  double _iconOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().fetchPosts();
    });
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

  // Called by parent widget on tab switch
  void pauseVideo() => context.read<VideoControllerService>().onBecameHidden();
  void resumeVideo() => context.read<VideoControllerService>().onBecameVisible();

  void _onPageChanged(int index, FeedProvider feedProvider, VideoControllerService videoService) {
    _currentIndex = index;
    
    final post = feedProvider.posts[index];
    if (post.isVideo) {
      videoService.initializeVideo(index, post.fileUrl);
    } else {
      videoService.disposeVideo();
    }

    setState(() => _iconOpacity = 0.0);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _iconOpacity = 1.0);
    });

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

    return Scaffold(
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                setState(() => _iconOpacity = 0.0);
              } else if (notification is ScrollEndNotification) {
                setState(() => _iconOpacity = 1.0);
              }
              return false;
            },
            child: PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: feedProvider.posts.length,
              onPageChanged: (index) => _onPageChanged(index, feedProvider, videoService),
              itemBuilder: (context, index) {
                final post = feedProvider.posts[index];
                return _buildPostItem(post, index, colorScheme, videoService);
              },
            ),
          ),
          Positioned(top: 0, left: 0, right: 0, child: _buildSearchBar(colorScheme)),
        ],
      ),
    );
  }

  Widget _buildPostItem(Post post, int index, ColorScheme colorScheme, VideoControllerService videoService) {
    return Stack(
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
        Positioned(
          top: MediaQuery.of(context).size.height * 0.5,
          right: 20,
          child: SafeArea(child: _buildActionButtons(colorScheme)),
        ),
      ],
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
      return GestureDetector(
        onTap: videoService.togglePlayPause,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(aspectRatio: videoService.aspectRatio, child: VideoPlayer(controller)),
            if (videoService.isBuffering) CircularProgressIndicator(color: colorScheme.primary),
            if (!videoService.isBuffering)
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

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return AnimatedOpacity(
      opacity: _iconOpacity,
      duration: const Duration(milliseconds: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(icon: Icons.favorite_border_outlined, colorScheme: colorScheme, onPressed: () {}),
          const SizedBox(height: 10),
          _buildActionButton(icon: Icons.thumb_down_alt_outlined, colorScheme: colorScheme, onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required ColorScheme colorScheme, required VoidCallback onPressed}) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surface.withAlpha(170),
        border: Border.all(color: colorScheme.outline.withAlpha(100), width: 1),
      ),
      child: IconButton(onPressed: onPressed, icon: Icon(icon, color: colorScheme.onSurface, size: 24)),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search',
            prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withAlpha(255)),
            filled: true,
            fillColor: colorScheme.surface.withAlpha(170),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide.none),
          ),
          style: TextStyle(color: colorScheme.onSurface),
        ),
      ),
    );
  }
}
