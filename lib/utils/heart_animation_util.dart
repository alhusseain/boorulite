import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

class HeartAnimationUtil {
  static void shootHearts({
    required BuildContext context,
    required GlobalKey targetKey,
    Offset? startOffset,
  }) {
    final RenderBox? targetBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (targetBox == null) return;

    final targetOffset = targetBox.localToGlobal(Offset.zero) + 
        Offset(targetBox.size.width / 2, targetBox.size.height / 2);

    final startPosition = startOffset ?? Offset(
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).size.height / 2,
    );

    for (int i = 0; i < 6; i++) {
      Future.delayed(Duration(milliseconds: i * 60), () {
        _showSingleHeart(context, startPosition, targetOffset);
      });
    }
  }

  static void _showSingleHeart(BuildContext context, Offset start, Offset target) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _FlyingHeart(
        start: start,
        target: target,
        onComplete: () => entry.remove(),
      ),
    );

    Overlay.of(context).insert(entry);
  }
}

class _FlyingHeart extends StatefulWidget {
  final Offset start;
  final Offset target;
  final VoidCallback onComplete;

  const _FlyingHeart({
    required this.start,
    required this.target,
    required this.onComplete,
  });

  @override
  State<_FlyingHeart> createState() => _FlyingHeartState();
}

class _FlyingHeartState extends State<_FlyingHeart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _travelAnimation;

  late PathMetric _pathMetric;
  late double _randomSize;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    
    _controller = AnimationController(
      duration: Duration(milliseconds: 1000 + random.nextInt(300)),
      vsync: this,
    );

    final path = Path();
    path.moveTo(widget.start.dx, widget.start.dy);
    
    final controlPoint = Offset(
      widget.start.dx + (random.nextDouble() - 0.5) * 300,
      widget.start.dy - 200 - random.nextDouble() * 150,
    );
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, widget.target.dx, widget.target.dy);

    _pathMetric = path.computeMetrics().first;

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), 
        weight: 20
      ), 
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),          
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), 
        weight: 25
      ), 
    ]).animate(_controller);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.3, end: 1.1).chain(CurveTween(curve: Curves.easeOutCubic)), 
        weight: 30
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.1, end: 0.6).chain(CurveTween(curve: Curves.easeInOut)), 
        weight: 70
      ),
    ]).animate(_controller);

    _rotationAnimation = Tween(
      begin: (random.nextDouble() - 0.5) * 0.3, 
      end: (random.nextDouble() - 0.5) * 1.5
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(_controller);

    _travelAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _randomSize = 22 + random.nextDouble() * 10;

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pos = _pathMetric.getTangentForOffset(
          _pathMetric.length * _travelAnimation.value
        )?.position ?? widget.start;

        return Positioned(
          left: pos.dx - (_randomSize / 2),
          top: pos.dy - (_randomSize / 2),
          child: IgnorePointer(
            child: Opacity(
              opacity: _opacityAnimation.value.clamp(0.0, 1.0),
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value.clamp(0.0, 2.0),
                  child: Icon(
                    Icons.favorite,
                    color: Colors.redAccent.withOpacity(0.9),
                    size: _randomSize,
                    shadows: const [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
