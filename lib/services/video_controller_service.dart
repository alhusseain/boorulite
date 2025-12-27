import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// Manages video player lifecycle with batch preloading.
class _PreloadedVideo {
  final int index;
  final String url;
  VideoPlayerController? controller;
  bool isInitialized = false;
  bool hasStartedPlaying = false;
  
  _PreloadedVideo({required this.index, required this.url});
}

class VideoControllerService extends ChangeNotifier {
  VideoPlayerController? _controller;
  int? _currentIndex;
  bool _isVisible = true;
  bool _isAppPaused = false;
  
  static const _batchSize = 3;
  final Map<int, _PreloadedVideo> _preloadedVideos = {};
  int _currentBatchStart = 0;
  bool _isPreloading = false;
  
  List<String> Function(int startIndex, int count)? getVideoUrlsBatch;
  int Function()? getTotalVideoCount;
  
// buffer monitoring fields
  Timer? _bufferHealthTimer;
  int _consecutiveBufferingCount = 0;
  DateTime? _bufferingStartTime;
  String? _currentVideoUrl;
  bool _hasStartedPlaying = false;
  static const _maxBufferingDuration = Duration(seconds: 10);
  static const _maxConsecutiveBuffering = 3;
  static const _initialBufferThreshold = 0;

  VideoPlayerController? get controller => _controller;
  int? get currentIndex => _currentIndex;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  bool get isPlaying => _controller?.value.isPlaying ?? false;
  bool get isBuffering => _controller?.value.isBuffering ?? false;
  bool get isWaitingForBuffer => isInitialized && !_hasStartedPlaying;
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

  void setBatchCallbacks({
    required List<String> Function(int startIndex, int count) getUrlsBatch,
    required int Function() getCount,
  }) {
    getVideoUrlsBatch = getUrlsBatch;
    getTotalVideoCount = getCount;
  }

  Future<void> _preloadBatch(int startIndex) async {
    if (_isPreloading || getVideoUrlsBatch == null || getTotalVideoCount == null) return;
    
    final totalCount = getTotalVideoCount!();
    if (startIndex >= totalCount) return;
    
    _isPreloading = true;
    _currentBatchStart = startIndex;
    
    final keysToRemove = <int>[];
    for (final index in _preloadedVideos.keys) {
      if (index < startIndex - 1 || index >= startIndex + _batchSize + 1) {
        keysToRemove.add(index);
      }
    }

    for (final index in keysToRemove) {
      final preloaded = _preloadedVideos.remove(index);
      if (preloaded != null && preloaded.controller != null) {
        if (preloaded.controller != _controller) {
          debugPrint('Disposing stale video buffer at $index');
          preloaded.controller!.dispose();
        }
      }
    }
    
    final urls = getVideoUrlsBatch!(startIndex, _batchSize);
    
    for (int i = 0; i < urls.length; i++) {
      final index = startIndex + i;
      if (_preloadedVideos.containsKey(index)) continue;
      
      final url = urls[i];
      if (url.isEmpty) continue;
      
      final preloaded = _PreloadedVideo(index: index, url: url);
      _preloadedVideos[index] = preloaded;
      
      try {
        final controller = VideoPlayerController.networkUrl(
          Uri.parse(url),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        preloaded.controller = controller;
        await controller.initialize();
        controller.setLooping(true);
        preloaded.isInitialized = true;
        debugPrint('Preloaded video at index $index');
      } catch (e) {
        debugPrint('Failed to preload video at index $index: $e');
      }
    }
    
    _isPreloading = false;
    notifyListeners();
  }

  Future<void> initializeVideo(int index, String videoUrl, {bool autoPlay = true}) async {
    if (_currentIndex == index && _controller != null) {
      if (isInitialized && autoPlay) play();
      return;
    }

    final batchEnd = _currentBatchStart + _batchSize - 1;
    if (index >= batchEnd || !_preloadedVideos.containsKey(index)) {
      _preloadBatch(index);
    }

    _stopBufferHealthMonitor();
    _controller?.removeListener(_onVideoStateChanged);
    _controller?.pause();
    
    _currentVideoUrl = videoUrl;
    _consecutiveBufferingCount = 0;
    _hasStartedPlaying = false;

    if (_preloadedVideos.containsKey(index) && _preloadedVideos[index]!.isInitialized) {
      final preloaded = _preloadedVideos[index]!;
      _controller = preloaded.controller;
      _currentIndex = index;
      _controller!.addListener(_onVideoStateChanged);
      _controller!.seekTo(Duration.zero);
      _startBufferHealthMonitor();
      notifyListeners();
      return;
    }

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
  void pauseCurrentVideo() {
    _stopBufferHealthMonitor();
    _controller?.removeListener(_onVideoStateChanged);
    _controller?.pause();
    _hasStartedPlaying = false;
    _controller = null;
    _currentIndex = null;
    _currentVideoUrl = null;
    notifyListeners();
  }

  Future<void> disposeVideo() async {
    _stopBufferHealthMonitor();
    _controller?.removeListener(_onVideoStateChanged);
    _controller?.pause();
    final isPreloaded = _currentIndex != null && _preloadedVideos.containsKey(_currentIndex);
    if (!isPreloaded) {
      await _controller?.dispose();
    }
    _controller = null;
    _currentIndex = null;
    _currentVideoUrl = null;
    notifyListeners();
  }
  
  Future<void> disposeAllPreloaded() async {
    for (final preloaded in _preloadedVideos.values) {
      await preloaded.controller?.dispose();
    }
    _preloadedVideos.clear();
  }

  Future<void> reset() async {
    _stopBufferHealthMonitor();
    _controller?.removeListener(_onVideoStateChanged);
    _controller?.pause();
    await disposeAllPreloaded();
    _controller = null;
    _currentIndex = null;
    _currentVideoUrl = null;
    _currentBatchStart = 0;
    _isPreloading = false;
    _hasStartedPlaying = false;
    _consecutiveBufferingCount = 0;
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
    
    if (!_hasStartedPlaying) {
      if (_hasEnoughBufferToStart && _isVisible && !_isAppPaused) {
        debugPrint('Buffer reached ${(bufferProgress * 100).toInt()}%, starting playback');
        _hasStartedPlaying = true;
        _controller?.play();
        notifyListeners();
      }
      return;
    }
    
    if (isBuffering && isPlaying) {
      _controller?.pause();
      notifyListeners();
    }
    
    if (isBuffering) {
      _bufferingStartTime ??= DateTime.now();
      final bufferingDuration = DateTime.now().difference(_bufferingStartTime!);
      
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
      if (!isPlaying && _isVisible && !_isAppPaused && _hasStartedPlaying) {
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
      _controller?.seekTo(position);
      _bufferingStartTime = null;
    }
  }
  
  Future<void> _recreateController() async {
    if (_currentVideoUrl == null || _currentIndex == null) return;
    
    final url = _currentVideoUrl!;
    final index = _currentIndex!;
    final position = _controller?.value.position ?? Duration.zero;
    
    if (_preloadedVideos.containsKey(index)) {
      await _preloadedVideos[index]?.controller?.dispose();
      _preloadedVideos.remove(index);
    }
    
    _stopBufferHealthMonitor();
    _controller?.removeListener(_onVideoStateChanged);
    await _controller?.dispose();
    _controller = null;
    
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

  void onAppPaused() {
    _isAppPaused = true;
    pause();
  }

  void onAppResumed() {
    _isAppPaused = false;
    if (_isVisible && isInitialized) play();
  }

  @override
  void dispose() {
    _stopBufferHealthMonitor();
    _controller?.removeListener(_onVideoStateChanged);
    _controller?.dispose();
    disposeAllPreloaded();
    super.dispose();
  }
}
