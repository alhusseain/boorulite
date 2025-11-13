import 'package:flutter/material.dart';

class MainNavBar extends StatelessWidget {
  const MainNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 1,
      onTap: (_) {},
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.app_settings_alt), label: 'Preferences'),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.thumb_up), label: 'Likes'),
      ],
    );
  }
}
