import 'package:boorulite/widgets/video_thumb.dart';
import 'package:flutter/material.dart';
import 'widgets/main_feed.dart';
import 'widgets/main_nav_bar.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Widget Playground',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: 
      // const PlaygroundScreen(),
      const LikedScreen(),
    );
  }
}

class PlaygroundScreen extends StatelessWidget {
  const PlaygroundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MainFeedWidget(),
      bottomNavigationBar: const MainNavBar(currIndex: 1),
    );
  }
}


class LikedScreen extends StatelessWidget {
  const LikedScreen({super.key});
  @override
  Widget build (BuildContext context){
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
    body: 
    GridView.count(crossAxisCount: width < 600 ? 3 : 5, children: [
      ...List.generate(
        8,
        (index) => VideoThumbnailWidget(
          imageUrl: 'https://picsum.photos/200/300?random=${index + 10}',
          views: (index + 1) * 35,
          onOptionsTap: () {
            print('Tapped options on thumb ${index + 1}');
          },
        ),
      )
    ]),
    bottomNavigationBar: const MainNavBar(currIndex:2 ),
    );
  }
}
