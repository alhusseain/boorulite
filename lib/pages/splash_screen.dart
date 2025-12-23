import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_colors.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const Duration _introGifDuration = Duration(seconds: 3);

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;

  bool _showSecondGif = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.95).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.5).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70.0,
      ),
    ]).animate(_animationController);
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.365, 1.0, curve: Curves.easeOut),
      ),
    );

    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.3).chain(CurveTween(curve: Curves.easeIn)),
        weight: 35.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.3, end: 2.5).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 65.0,
      ),
    ]).animate(_animationController);

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
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_animationController.isAnimating) return;
    HapticFeedback.lightImpact();  
    _timer?.cancel();
    await _animationController.forward();
    if (mounted) {
      _navigateToMainScreen();
    }
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
      onTap: _handleTap,
      // sometimes clicks would go through if u clicked further away from the gif
      // so we used opaque to ensure when the gif is active, all clicks on the screen are meant for it.
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: RotationTransition(
            turns: _rotationAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: Image.asset(
                  gifPath,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
