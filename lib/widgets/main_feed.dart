import 'package:flutter/material.dart';

class MainFeedWidget extends StatefulWidget {
  const MainFeedWidget({super.key});

  @override
  State<MainFeedWidget> createState() => _MainFeedWidgetState();
}

class _MainFeedWidgetState extends State<MainFeedWidget>{
  double _iconOpacity = 1.0 ;
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
            itemCount: 10,
            onPageChanged: (index) {
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
            },
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                  'https://picsum.photos/400/800?random=$index',
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: colorScheme.surface,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: colorScheme.surface,
                    child: Center(
                      child: Icon(
                        Icons.stop_rounded,
                        size: 50,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black38,
                        ],
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
