import 'package:boorulite/main.dart';
import 'package:boorulite/pages/profile_page.dart';
import 'package:flutter/material.dart';

class MainNavBar extends StatelessWidget {
  final int currIndex;
  final Function(int) onTabSelected;
  final GlobalKey? likesKey;
  
  const MainNavBar({
    super.key,
    required this.currIndex,
    required this.onTabSelected,
    this.likesKey,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: BottomNavigationBar(
        currentIndex: currIndex,
        onTap: onTabSelected,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.app_settings_alt),
            label: 'Preferences',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.thumb_up, key: likesKey),
            label: 'Likes',
          ),
        ],
      ),
    );
  }
}
