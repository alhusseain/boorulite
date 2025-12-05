import 'package:boorulite/widgets/video_thumb.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/saved_posts_provider.dart';

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
  Widget build (BuildContext context){
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
      children: savedPostsProvider.posts.map((post) => VideoThumbnailWidget(
          imageUrl: post.previewUrl,
          views: post.score,
          onOptionsTap: () {
            savedPostsProvider.deletePost(post);
          },
        )).toList(),
    );
  }
}