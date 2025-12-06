import 'package:flutter/material.dart';

class VideoThumbnailWidget extends StatelessWidget {
  final String imageUrl;
  final int views;
  final VoidCallback onOptionsTap;

  const VideoThumbnailWidget({
    super.key,
    required this.imageUrl,
    required this.views,
    required this.onOptionsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
            child: ClipRect(child: Image.network(imageUrl, fit: BoxFit.cover)),
          ),
        Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
        ),

        Positioned(
          left: 6,
          bottom: 6,
          child: Row(
            children: [
              const Icon(Icons.visibility, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                "$views",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onOptionsTap,
            child: const Icon(Icons.close, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
