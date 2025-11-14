import 'package:boorulite/main.dart';
import 'package:boorulite/pages/profile_page.dart';
import 'package:flutter/material.dart';

class MainNavBar extends StatelessWidget {
  final int currIndex;
  const MainNavBar({super.key, required this.currIndex});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),

      child: BottomNavigationBar(
        currentIndex: currIndex,
        onTap: (i) {
          switch (i) {
            case 0:
               Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      ProfilePage(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );           
                break;
            case 1:
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      PlaygroundScreen(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
              break;
            case 2:
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      LikedScreen(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.app_settings_alt),
            label: 'Preferences',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.thumb_up), label: 'Likes'),
        ],
      ),
    );
  }
}
