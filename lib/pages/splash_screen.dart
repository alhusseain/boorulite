import 'dart:async';
import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Duration _introGifDuration = Duration(seconds: 3);

  bool _showSecondGif = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_introGifDuration, () {
      if (mounted) {
        setState(() {
          _showSecondGif = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _navigateToMainScreen() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String gifPath = _showSecondGif ? 'assets/splashgifs/booru4gif.gif' : 'assets/splashgifs/booru3gif.gif';
    return GestureDetector(
      onTap: _navigateToMainScreen,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Image.asset(
            gifPath,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}
