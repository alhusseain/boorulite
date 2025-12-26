import 'package:flutter/foundation.dart';
import '../services/preferences_service.dart';

/// Provider class that manages application settings and preferences.
/// This includes maturity rating and dark mode settings.
class SettingsProvider extends ChangeNotifier {
  final PreferencesService _preferencesService = PreferencesService();

  // Maturity Rating: 's' (safe), 'q' (questionable), 'e' (explicit), or '' (all)
  String _maturityRating = 's'; // Default to safe only
  String get maturityRating => _maturityRating;

  // Dark Mode
  bool _isDarkMode = true; // Default to dark mode
  bool get isDarkMode => _isDarkMode;

  /// Constructor that initializes the provider by loading settings from disk.
  SettingsProvider() {
    _loadSettings();
  }

  /// Loads all settings from SharedPreferences into memory.
  Future<void> _loadSettings() async {
    _maturityRating = await _preferencesService.getString('maturity_rating', 's');
    _isDarkMode = await _preferencesService.getBool('dark_mode', true);
    debugPrint('SettingsProvider: Loaded settings - Rating: $_maturityRating, DarkMode: $_isDarkMode');
    notifyListeners();
  }

  /// Sets the maturity rating filter.
  /// [rating] - 's' (safe), 'q' (questionable), 'e' (explicit), or '' (all)
  Future<void> setMaturityRating(String rating) async {
    if (rating != _maturityRating && (rating == 's' || rating == 'q' || rating == 'e' || rating == '')) {
      _maturityRating = rating;
      await _preferencesService.setString('maturity_rating', rating);
      debugPrint('SettingsProvider: Maturity rating changed to: "$rating"');
      notifyListeners();
    }
  }

  /// Toggles dark mode setting.
  Future<void> setDarkMode(bool enabled) async {
    if (enabled != _isDarkMode) {
      _isDarkMode = enabled;
      await _preferencesService.setBool('dark_mode', enabled);
      debugPrint('SettingsProvider: Dark mode changed to: $enabled');
      notifyListeners();
    }
  }
}
