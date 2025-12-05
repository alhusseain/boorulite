import 'package:boorulite/widgets/video_thumb.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/block_list_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/settings_provider.dart';
import 'services/video_controller_service.dart';
import 'services/notification_service.dart';
import 'pages/profile_page.dart';
import 'utils/app_colors.dart';
import 'widgets/main_feed.dart';
import 'widgets/main_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
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
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => VideoControllerService()),
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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 1;

  // Key to access MainFeedWidget state
  final GlobalKey<MainFeedWidgetState> _feedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      NotificationService.scheduleMissYouNotification(const Duration(seconds: 10));
    } else if (state == AppLifecycleState.resumed) {
      NotificationService.cancelAllNotifications();
    }
  }

  void _onTabSelected(int index) {
    final previousIndex = _currentIndex;
    
    setState(() {
      _currentIndex = index;
    });
    // Tab switching logic for main feed
    if (previousIndex == 1 && index != 1) {
      _feedKey.currentState?.pauseVideo();
    } else if (previousIndex != 1 && index == 1) {
      _feedKey.currentState?.resumeVideo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Index 0: Preferences
          const ProfilePage(),
          // Index 1: Home Feed
          MainFeedWidget(key: _feedKey),
          // Index 2: Likes
          const LikedScreen(),
        ],
      ),
      bottomNavigationBar: MainNavBar(
        currIndex: _currentIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}

class LikedScreen extends StatelessWidget {
  const LikedScreen({super.key});
  @override
  Widget build (BuildContext context){
    double width = MediaQuery.of(context).size.width;
    return GridView.count(
      crossAxisCount: width < 600 ? 3 : 5,
      children: [
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
      ],
    );
  }
}
