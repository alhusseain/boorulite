import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/post.dart';

class SavedFeed extends StatefulWidget {
  final List<Post> posts;
  final int initialIndex;

  const SavedFeed({
    super.key,
    required this.posts,
    required this.initialIndex,
  });

  @override
  State<SavedFeed> createState() => _SavedFeedState();
}

class _SavedFeedState extends State<SavedFeed> {
  late PageController _pageController;
  VideoPlayerController? _controller;

  int currentIndex = 0;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;

    _pageController = PageController(initialPage: currentIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVideo(currentIndex);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _loadVideo(int index) {
    final post = widget.posts[index];

    _controller?.dispose();
    _controller = VideoPlayerController.network(post.fileUrl)
      ..initialize().then((_) {
        _controller!.play();
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: widget.posts.length,
            onPageChanged: (index) {
              setState(() => currentIndex = index);
              _loadVideo(index);
            },
            itemBuilder: (context, index) {
              final post = widget.posts[index];

              return GestureDetector(
                onTap: () => setState(() => _showControls = !_showControls),
                child: Stack(
                  children: [
                    Center(
                      child: _controller != null &&
                          _controller!.value.isInitialized &&
                          currentIndex == index
                          ? AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      )
                          : const CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),

                    // 👇 same style as your main feed UI
                    if (_showControls)
                      Positioned(
                        top: 40,
                        left: 20,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
