import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/saved_posts_provider.dart';
import '../widgets/video_thumb.dart';
import 'saved_feed.dart';

class LikedScreen extends StatefulWidget {
  const LikedScreen({super.key});

  @override
  State<LikedScreen> createState() => _LikedScreenState();
}

class _LikedScreenState extends State<LikedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SavedPostsProvider>().fetchPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final savedPostsProvider = context.watch<SavedPostsProvider>();
    double width = MediaQuery.of(context).size.width;

    if (savedPostsProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (savedPostsProvider.posts.isEmpty) {
      return const Center(
        child: Text('You have no liked posts yet.'),
      );
    }

    return GridView.count(
      crossAxisCount: width < 600 ? 3 : 5,
      childAspectRatio: 0.75,
      children: savedPostsProvider.posts.map((post) {
        return GestureDetector(
          onTap: () {
            final index = savedPostsProvider.posts.indexOf(post);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SavedFeed(
                  posts: savedPostsProvider.posts,
                  initialIndex: index,
                ),
              ),
            );
          },
          child: VideoThumbnailWidget(
            imageUrl: post.previewUrl,
            views: post.score,
            onOptionsTap: () {
              savedPostsProvider.deletePost(post);
            },
          ),
        );
      }).toList(),
    );
  }
}
