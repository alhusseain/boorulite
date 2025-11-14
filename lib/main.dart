import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/block_list_provider.dart';
import 'providers/settings_provider.dart';
import 'pages/profile_page.dart';
import 'utils/app_colors.dart';

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
        title: 'SWAPD 402 - Content Filtering',
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
        home: const ProfilePage(),
      ),
    );
  }
}

