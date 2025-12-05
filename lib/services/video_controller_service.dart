import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// Manages video player lifecycle. Only ONE video will be active at a time to prevent buffer exhaustion, which happens every so often.
class VideoControllerService extends ChangeNotifier {
  VideoPlayerController? _controller;
  int? _currentIndex;
  bool _isVisible = true;
  
// buffer monitoring fields
  Timer? _bufferHealthTimer;
  int _consecutiveBufferingCount = 0;
  DateTime? _bufferingStartTime;
  String? _currentVideoUrl;
  bool _hasStartedPlaying = false;
  static const _maxBufferingDuration = Duration(seconds: 10);
  static const _maxConsecutiveBuffering = 3;
  static const _initialBufferThreshold = 0.25; // 25% buffer required before first play to attempt to mitigate long pauses after playing a portion of the clip.

  VideoPlayerController? get controller => _controller;
  int? get currentIndex => _currentIndex;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  bool get isPlaying => _controller?.value.isPlaying ?? false;
  bool get isBuffering => _controller?.value.isBuffering ?? false;
  double get aspectRatio => _controller?.value.aspectRatio ?? 16 / 9;
  
  double get bufferProgress {
    if (_controller == null || !isInitialized) return 0.0;
    final duration = _controller!.value.duration;
    if (duration == Duration.zero) return 0.0;
    
    final buffered = _controller!.value.buffered;
    if (buffered.isEmpty) return 0.0;
    
    final bufferedEnd = buffered.last.end;
    return bufferedEnd.inMilliseconds / duration.inMilliseconds;
  }
  
  bool get _hasEnoughBufferToStart => bufferProgress >= _initialBufferThreshold;

  Future<void> initializeVideo(int index, String videoUrl, {bool autoPlay = true}) async {
    if (_currentIndex == index && _controller != null) {
      if (isInitialized && autoPlay) play();
      return;
    }

    await disposeVideo();
    _currentVideoUrl = videoUrl;
    _consecutiveBufferingCount = 0;
    _hasStartedPlaying = false;

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
      _startBufferHealthMonitor();
      notifyListeners();
    } catch (e) {
      await disposeVideo();
    }
  }

  Future<void> disposeVideo() async {
    _stopBufferHealthMonitor();
    _controller?.removeListener(_onVideoStateChanged);
    _controller?.pause();
    await _controller?.dispose();
    _controller = null;
    _currentIndex = null;
    _currentVideoUrl = null;
    notifyListeners();
  }
  // we check every second if the video is stuck buffering, because the video playback function degrades as you scroll, and might need a refresh.
  void _startBufferHealthMonitor() {
    _stopBufferHealthMonitor();
    _bufferHealthTimer = Timer.periodic(const Duration(seconds: 1), (_) => _checkBufferHealth());
  }
  
  void _stopBufferHealthMonitor() {
    _bufferHealthTimer?.cancel();
    _bufferHealthTimer = null;
    _bufferingStartTime = null;
  }
  
  void _checkBufferHealth() {
    if (_controller == null || !isInitialized) return;
    
    //this segment Handles the initial 25% buffer 
    if (!_hasStartedPlaying) {
      if (_hasEnoughBufferToStart && _isVisible) {
        debugPrint('Buffer reached ${(bufferProgress * 100).toInt()}%, starting playback');
        _hasStartedPlaying = true;
        _controller?.play();
        notifyListeners();
      }
      return;
    }
    
    // Pause if buffering (prevents progress bar moving while loading)
    if (isBuffering && isPlaying) {
      _controller?.pause();
      notifyListeners();
    }
    
    // Check for stuck buffering
    if (isBuffering) {
      _bufferingStartTime ??= DateTime.now();
      final bufferingDuration = DateTime.now().difference(_bufferingStartTime!);
      
      // If buffering too long, attempt recovery
      if (bufferingDuration > _maxBufferingDuration) {
        _consecutiveBufferingCount++;
        debugPrint('Buffer stuck for ${bufferingDuration.inSeconds}s (attempt $_consecutiveBufferingCount)');
        
        if (_consecutiveBufferingCount >= _maxConsecutiveBuffering) {
          debugPrint('Max buffering attempts reached, recreating controller');
          _recreateController();
        } else {
          _attemptRecovery();
        }
      }
    } else {
      if (!isPlaying && _isVisible && _hasStartedPlaying) {
        _controller?.play();
        notifyListeners();
      }
      _bufferingStartTime = null;
      if (_consecutiveBufferingCount > 0) {
        _consecutiveBufferingCount = 0;
      }
    }
  }
  
  void _attemptRecovery() {
    final position = _controller?.value.position;
    if (position != null) {
      debugPrint('Attempting soft recovery by seeking to $position --- temp debug message, matensash teshelha');
      _controller?.seekTo(position);
      _bufferingStartTime = null;
    }
  }
  
  Future<void> _recreateController() async {
    if (_currentVideoUrl == null || _currentIndex == null) return;
    
    final url = _currentVideoUrl!;
    final index = _currentIndex!;
    final position = _controller?.value.position ?? Duration.zero;
    
    await disposeVideo();
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    final newController = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    
    _controller = newController;
    _currentIndex = index;
    _currentVideoUrl = url;
    _consecutiveBufferingCount = 0;
    newController.addListener(_onVideoStateChanged);

    try {
      await newController.initialize();
      newController.setLooping(true);
      await newController.seekTo(position);
      _startBufferHealthMonitor();
      if (_isVisible) newController.play();
      notifyListeners();
    } catch (e) {
      debugPrint('Recreation failed: $e');
      await disposeVideo();
    }
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
    _stopBufferHealthMonitor();
    _controller?.removeListener(_onVideoStateChanged);
    _controller?.dispose();
    super.dispose();
  }
}
