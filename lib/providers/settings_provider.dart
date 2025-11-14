import 'package:flutter/foundation.dart';
import '../services/preferences_service.dart';

/// Provider class that manages application settings and preferences.
/// This includes content quality, display preferences, and other app-wide settings.
class SettingsProvider extends ChangeNotifier {
  final PreferencesService _preferencesService = PreferencesService();

  // Content Quality Settings
  String _contentQuality = 'high_quality'; // high_quality, medium, any
  String get contentQuality => _contentQuality;

  // Display Preferences
  bool _autoRefresh = false;
  bool get autoRefresh => _autoRefresh;

  int _refreshInterval = 30; // seconds
  int get refreshInterval => _refreshInterval;

  String _displayMode = 'grid'; // grid, list
  String get displayMode => _displayMode;

  // Content Filtering
  int _minRating = 0; // 0-5
  int get minRating => _minRating;

  bool _showOnlySakuga = true;
  bool get showOnlySakuga => _showOnlySakuga;

  // Video Settings
  bool _autoPlay = false;
  bool get autoPlay => _autoPlay;

  String _videoQuality = 'original'; // original, high, medium
  String get videoQuality => _videoQuality;

  /// Constructor that initializes the provider by loading settings from disk.
  SettingsProvider() {
    _loadSettings();
  }

  /// Loads all settings from SharedPreferences into memory.
  Future<void> _loadSettings() async {
    _contentQuality = await _preferencesService.getString('content_quality', 'high_quality');
    _autoRefresh = await _preferencesService.getBool('auto_refresh', false);
    _refreshInterval = await _preferencesService.getInt('refresh_interval', 30);
    _displayMode = await _preferencesService.getString('display_mode', 'grid');
    _minRating = await _preferencesService.getInt('min_rating', 0);
    _showOnlySakuga = await _preferencesService.getBool('show_only_sakuga', true);
    _autoPlay = await _preferencesService.getBool('auto_play', false);
    _videoQuality = await _preferencesService.getString('video_quality', 'original');
    notifyListeners();
  }

  /// Sets the content quality preference.
  Future<void> setContentQuality(String quality) async {
    if (quality != _contentQuality) {
      _contentQuality = quality;
      await _preferencesService.setString('content_quality', quality);
      notifyListeners();
    }
  }

  /// Toggles auto-refresh setting.
  Future<void> setAutoRefresh(bool enabled) async {
    if (enabled != _autoRefresh) {
      _autoRefresh = enabled;
      await _preferencesService.setBool('auto_refresh', enabled);
      notifyListeners();
    }
  }

  /// Sets the refresh interval in seconds.
  Future<void> setRefreshInterval(int seconds) async {
    if (seconds != _refreshInterval && seconds >= 10) {
      _refreshInterval = seconds;
      await _preferencesService.setInt('refresh_interval', seconds);
      notifyListeners();
    }
  }

  /// Sets the display mode (grid or list).
  Future<void> setDisplayMode(String mode) async {
    if (mode != _displayMode && (mode == 'grid' || mode == 'list')) {
      _displayMode = mode;
      await _preferencesService.setString('display_mode', mode);
      notifyListeners();
    }
  }

  /// Sets the minimum rating filter.
  Future<void> setMinRating(int rating) async {
    if (rating != _minRating && rating >= 0 && rating <= 5) {
      _minRating = rating;
      await _preferencesService.setInt('min_rating', rating);
      notifyListeners();
    }
  }

  /// Toggles the "show only sakuga" filter.
  Future<void> setShowOnlySakuga(bool enabled) async {
    if (enabled != _showOnlySakuga) {
      _showOnlySakuga = enabled;
      await _preferencesService.setBool('show_only_sakuga', enabled);
      notifyListeners();
    }
  }

  /// Toggles auto-play setting.
  Future<void> setAutoPlay(bool enabled) async {
    if (enabled != _autoPlay) {
      _autoPlay = enabled;
      await _preferencesService.setBool('auto_play', enabled);
      notifyListeners();
    }
  }

  /// Sets the video quality preference.
  Future<void> setVideoQuality(String quality) async {
    if (quality != _videoQuality) {
      _videoQuality = quality;
      await _preferencesService.setString('video_quality', quality);
      notifyListeners();
    }
  }
}

