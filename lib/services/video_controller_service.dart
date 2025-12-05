import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// Manages video player lifecycle. Only ONE video will be active at a time to prevent buffer exhaustion, which happens every so often.
class VideoControllerService extends ChangeNotifier {
  VideoPlayerController? _controller;
  int? _currentIndex;
  bool _isVisible = true;

  VideoPlayerController? get controller => _controller;
  int? get currentIndex => _currentIndex;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  bool get isPlaying => _controller?.value.isPlaying ?? false;
  bool get isBuffering => _controller?.value.isBuffering ?? false;
  double get aspectRatio => _controller?.value.aspectRatio ?? 16 / 9;

  Future<void> initializeVideo(int index, String videoUrl, {bool autoPlay = true}) async {
    if (_currentIndex == index && _controller != null) {
      if (isInitialized && autoPlay) play();
      return;
    }

    await disposeVideo();

    final newController = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    
    _controller = newController;
    _currentIndex = index;
    newController.addListener(_onVideoStateChanged);

    try {
      await newController.initialize();
      newController.setLooping(true);
      if (autoPlay && _isVisible) newController.play();
      notifyListeners();
    } catch (e) {
      await disposeVideo();
    }
  }

  Future<void> disposeVideo() async {
    _controller?.removeListener(_onVideoStateChanged);
    _controller?.pause();
    await _controller?.dispose();
    _controller = null;
    _currentIndex = null;
    notifyListeners();
  }

  void _onVideoStateChanged() => notifyListeners();

  void play() {
    if (isInitialized) {
      _controller?.play();
      notifyListeners();
    }
  }

  void pause() {
    _controller?.pause();
    notifyListeners();
  }

  void togglePlayPause() => isPlaying ? pause() : play();

  void onBecameVisible() {
    _isVisible = true;
    if (isInitialized) play();
  }

  void onBecameHidden() {
    _isVisible = false;
    pause();
  }

  void onAppPaused() => pause();

  void onAppResumed() {
    if (_isVisible && isInitialized) play();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoStateChanged);
    _controller?.dispose();
    super.dispose();
  }
}
