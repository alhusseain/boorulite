import 'package:boorulite/widgets/video_thumb.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/block_list_provider.dart';
import 'providers/settings_provider.dart';
import 'pages/profile_page.dart';
import 'utils/app_colors.dart';
import 'widgets/main_feed.dart';
import 'widgets/main_nav_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BlockListProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'Boorulite',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: AppColors.darkScheme,
          scaffoldBackgroundColor: AppColors.darkScheme.surface,
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.darkScheme.surface,
            foregroundColor: AppColors.darkScheme.onSurface,
            elevation: 0,
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MainFeedWidget(),
      bottomNavigationBar: const MainNavBar(currIndex: 0),
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
        20,
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
